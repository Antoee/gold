[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$workspaceRoot = Split-Path -Parent $PSScriptRoot
$registrationPath = Join-Path $workspaceRoot "outputs\TRANSFERABLE_PORTFOLIO_FORWARD_DEMO_REGISTRATION.json"
$profilePath = Join-Path $workspaceRoot "outputs\TRANSFERABLE_PORTFOLIO_FORWARD_DEMO_PROFILE.set"
$sourcePath = Join-Path $workspaceRoot "work\Professional_XAUUSD_Transferable_Portfolio.mq5"
$refreshPath = Join-Path $workspaceRoot "work\refresh_transferable_portfolio_forward_demo_status.ps1"
$statusCsvPath = Join-Path $workspaceRoot "outputs\TRANSFERABLE_PORTFOLIO_FORWARD_DEMO_STATUS.csv"
$statusMarkdownPath = Join-Path $workspaceRoot "outputs\TRANSFERABLE_PORTFOLIO_FORWARD_DEMO_STATUS.md"
$checks = 0

function Assert-True {
   param(
      [Parameter(Mandatory = $true)]
      [bool]$Condition,

      [Parameter(Mandatory = $true)]
      [string]$Message
   )

   if(!$Condition) { throw $Message }
   $script:checks++
}

function Get-Sha256 {
   param([Parameter(Mandatory = $true)][string]$Path)
   return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToUpperInvariant()
}

$registrationRawBefore = Get-Content -Raw -LiteralPath $registrationPath
$registration = $registrationRawBefore | ConvertFrom-Json
$sourceHashBefore = Get-Sha256 -Path $sourcePath
$profileHashBefore = Get-Sha256 -Path $profilePath

$refreshOutput = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $refreshPath
Assert-True -Condition ($LASTEXITCODE -eq 0) -Message "Forward status refresh failed."

$status = Import-Csv -LiteralPath $statusCsvPath
$statusMarkdown = Get-Content -Raw -LiteralPath $statusMarkdownPath
$registrationRawAfter = Get-Content -Raw -LiteralPath $registrationPath
$profileText = Get-Content -Raw -LiteralPath $profilePath

Assert-True -Condition ($sourceHashBefore -eq $registration.sourceSha256) -Message "Workspace source does not match the registered frozen hash."
Assert-True -Condition ($profileHashBefore -eq $registration.profileSha256) -Message "Forward profile does not match the registered frozen hash."
Assert-True -Condition ((Get-Sha256 -Path $sourcePath) -eq $sourceHashBefore) -Message "Status refresh modified the EA source."
Assert-True -Condition ((Get-Sha256 -Path $profilePath) -eq $profileHashBefore) -Message "Status refresh modified the forward profile."
Assert-True -Condition ($registrationRawAfter -ceq $registrationRawBefore) -Message "Status refresh modified the registration."
Assert-True -Condition ($status.SourceHashMatch -eq "True") -Message "Generated status reports a source hash mismatch."
Assert-True -Condition ($status.ProfileHashMatch -eq "True") -Message "Generated status reports a profile hash mismatch."
Assert-True -Condition ($status.InstalledBinaryHashMatch -eq "True") -Message "Generated status reports an installed binary hash mismatch."
Assert-True -Condition ($status.ReversionLogPresent -eq "True" -and $status.MomentumLogPresent -eq "True") -Message "Dedicated forward evidence logs are missing."
Assert-True -Condition ($status.ForeignIdentityRows -eq "0") -Message "Foreign run identity rows were found in the evidence logs."
Assert-True -Condition ($status.RealAccountTradingAllowed -eq "False") -Message "Generated status permits real-account trading."
Assert-True -Condition (!$registration.realAccountTradingAllowed) -Message "Registration permits real-account trading."
Assert-True -Condition (!$registration.accountIdentifierPublished) -Message "Registration says the account identifier is published."
Assert-True -Condition ($profileText -match '(?m)^InpAllowRealAccountTrading=false\|') -Message "Forward profile does not disable real-account trading."
Assert-True -Condition ($profileText -match '(?m)^InpRealAccountApprovalCode=DISABLED\s*$') -Message "Forward profile real-account approval code is not disabled."
Assert-True -Condition ($profileText -match '(?m)^InpRequireHedgingAccount=true\|') -Message "Forward profile does not require a hedging account."
Assert-True -Condition ($profileText -match '(?m)^InpUseRealAccountSafetyLock=true\|') -Message "Forward profile real-account safety lock is disabled."
Assert-True -Condition ($profileText -match '(?m)^InpUseSymbolSafetyLock=true\|') -Message "Forward profile symbol safety lock is disabled."
Assert-True -Condition (@("PENDING", "PASS", "FAIL", "ATTENTION") -contains $status.Status) -Message "Generated status is not a recognized state."
Assert-True -Condition ($statusMarkdown -match 'account identifier is not published') -Message "Published status omits its account-privacy statement."

$disallowedRegistrationFields = @("accountNumber", "accountId", "login", "accountLogin")
$registrationFields = @($registration.PSObject.Properties.Name)
Assert-True -Condition (@($disallowedRegistrationFields | Where-Object { $registrationFields -contains $_ }).Count -eq 0) -Message "Registration contains a disallowed account identifier field."

Write-Output "PASS: $checks forward-demo monitor checks"
$refreshOutput | ForEach-Object { Write-Output $_ }
