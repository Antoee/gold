[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$workspaceRoot = Split-Path -Parent $PSScriptRoot
$registrationPath = Join-Path $workspaceRoot "outputs\TRANSFERABLE_PORTFOLIO_FORWARD_DEMO_REGISTRATION.json"
$profilePath = Join-Path $workspaceRoot "outputs\TRANSFERABLE_PORTFOLIO_FORWARD_DEMO_PROFILE.set"
$sourcePath = Join-Path $workspaceRoot "work\Professional_XAUUSD_Transferable_Portfolio.mq5"
$sentinelRegistrationPath = Join-Path $workspaceRoot "outputs\TRANSFERABLE_FORWARD_SENTINEL_REGISTRATION.json"
$sentinelProfilePath = Join-Path $workspaceRoot "outputs\TRANSFERABLE_FORWARD_SENTINEL_PROFILE.set"
$sentinelSourcePath = Join-Path $workspaceRoot "work\Professional_XAUUSD_Forward_Sentinel.mq5"
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
$sentinelRegistrationRawBefore = Get-Content -Raw -LiteralPath $sentinelRegistrationPath
$sentinelRegistration = $sentinelRegistrationRawBefore | ConvertFrom-Json
$sourceHashBefore = Get-Sha256 -Path $sourcePath
$profileHashBefore = Get-Sha256 -Path $profilePath
$sentinelSourceHashBefore = Get-Sha256 -Path $sentinelSourcePath
$sentinelProfileHashBefore = Get-Sha256 -Path $sentinelProfilePath

$refreshOutput = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $refreshPath
Assert-True -Condition ($LASTEXITCODE -eq 0) -Message "Forward status refresh failed."

$status = Import-Csv -LiteralPath $statusCsvPath
$statusMarkdown = Get-Content -Raw -LiteralPath $statusMarkdownPath
$registrationRawAfter = Get-Content -Raw -LiteralPath $registrationPath
$sentinelRegistrationRawAfter = Get-Content -Raw -LiteralPath $sentinelRegistrationPath
$profileText = Get-Content -Raw -LiteralPath $profilePath
$sentinelSourceText = Get-Content -Raw -LiteralPath $sentinelSourcePath
$sentinelHeartbeatPath = Join-Path (Join-Path $env:APPDATA "MetaQuotes\Terminal\Common\Files") $sentinelRegistration.heartbeatFile
$sentinelHeartbeatHeader = if(Test-Path -LiteralPath $sentinelHeartbeatPath) { Get-Content -LiteralPath $sentinelHeartbeatPath -TotalCount 1 } else { "" }

Assert-True -Condition ($sourceHashBefore -eq $registration.sourceSha256) -Message "Workspace source does not match the registered frozen hash."
Assert-True -Condition ($profileHashBefore -eq $registration.profileSha256) -Message "Forward profile does not match the registered frozen hash."
Assert-True -Condition ((Get-Sha256 -Path $sourcePath) -eq $sourceHashBefore) -Message "Status refresh modified the EA source."
Assert-True -Condition ((Get-Sha256 -Path $profilePath) -eq $profileHashBefore) -Message "Status refresh modified the forward profile."
Assert-True -Condition ($registrationRawAfter -ceq $registrationRawBefore) -Message "Status refresh modified the registration."
Assert-True -Condition ($sentinelSourceHashBefore -eq $sentinelRegistration.sourceSha256) -Message "Workspace sentinel source does not match its registered hash."
Assert-True -Condition ($sentinelProfileHashBefore -eq $sentinelRegistration.profileSha256) -Message "Sentinel profile does not match its registered hash."
Assert-True -Condition ((Get-Sha256 -Path $sentinelSourcePath) -eq $sentinelSourceHashBefore) -Message "Status refresh modified the sentinel source."
Assert-True -Condition ((Get-Sha256 -Path $sentinelProfilePath) -eq $sentinelProfileHashBefore) -Message "Status refresh modified the sentinel profile."
Assert-True -Condition ($sentinelRegistrationRawAfter -ceq $sentinelRegistrationRawBefore) -Message "Status refresh modified the sentinel registration."
Assert-True -Condition ($status.SourceHashMatch -eq "True") -Message "Generated status reports a source hash mismatch."
Assert-True -Condition ($status.ProfileHashMatch -eq "True") -Message "Generated status reports a profile hash mismatch."
Assert-True -Condition ($status.InstalledBinaryHashMatch -eq "True") -Message "Generated status reports an installed binary hash mismatch."
Assert-True -Condition ($status.SentinelSourceHashMatch -eq "True") -Message "Generated status reports a sentinel source hash mismatch."
Assert-True -Condition ($status.SentinelProfileHashMatch -eq "True") -Message "Generated status reports a sentinel profile hash mismatch."
Assert-True -Condition ($status.SentinelInstalledBinaryHashMatch -eq "True") -Message "Generated status reports a sentinel binary hash mismatch."
Assert-True -Condition ($status.SentinelCodeIdentityPass -eq "True") -Message "Generated status reports a sentinel code-identity failure."
Assert-True -Condition ($status.SentinelHeartbeatPresent -eq "True" -and $status.SentinelHeartbeatValid -eq "True") -Message "Sentinel heartbeat is absent or invalid."
Assert-True -Condition ($status.SentinelHeartbeatIdentityPass -eq "True") -Message "Sentinel heartbeat identity does not match the frozen run."
Assert-True -Condition ($status.AccountTradeMode -eq "demo" -and $status.MarginMode -eq "hedging") -Message "Sentinel did not observe the required demo hedging account."
Assert-True -Condition ($status.Connected -eq "True") -Message "Sentinel reports that MT5 is disconnected."
Assert-True -Condition ($status.ReversionLogPresent -eq "True" -and $status.MomentumLogPresent -eq "True") -Message "Dedicated forward evidence logs are missing."
Assert-True -Condition ($status.ForeignIdentityRows -eq "0") -Message "Foreign run identity rows were found in the evidence logs."
Assert-True -Condition ($status.RealAccountTradingAllowed -eq "False") -Message "Generated status permits real-account trading."
Assert-True -Condition (!$registration.realAccountTradingAllowed) -Message "Registration permits real-account trading."
Assert-True -Condition (!$registration.accountIdentifierPublished) -Message "Registration says the account identifier is published."
Assert-True -Condition (!$sentinelRegistration.accountIdentifierPublished) -Message "Sentinel registration says the account identifier is published."
Assert-True -Condition ($sentinelRegistration.nonTrading) -Message "Sentinel registration does not identify the sentinel as non-trading."
Assert-True -Condition ($sentinelRegistration.candidateSourceSha256 -eq $registration.sourceSha256) -Message "Sentinel registration targets a different candidate source."
Assert-True -Condition ($sentinelRegistration.candidateProfileSha256 -eq $registration.profileSha256) -Message "Sentinel registration targets a different candidate profile."
Assert-True -Condition ($profileText -match '(?m)^InpAllowRealAccountTrading=false\|') -Message "Forward profile does not disable real-account trading."
Assert-True -Condition ($profileText -match '(?m)^InpRealAccountApprovalCode=DISABLED\s*$') -Message "Forward profile real-account approval code is not disabled."
Assert-True -Condition ($profileText -match '(?m)^InpRequireHedgingAccount=true\|') -Message "Forward profile does not require a hedging account."
Assert-True -Condition ($profileText -match '(?m)^InpUseRealAccountSafetyLock=true\|') -Message "Forward profile real-account safety lock is disabled."
Assert-True -Condition ($profileText -match '(?m)^InpUseSymbolSafetyLock=true\|') -Message "Forward profile symbol safety lock is disabled."
Assert-True -Condition (@("PENDING", "PASS", "FAIL", "ATTENTION") -contains $status.Status) -Message "Generated status is not a recognized state."
Assert-True -Condition ($statusMarkdown -match 'account identifier is not published') -Message "Published status omits its account-privacy statement."
Assert-True -Condition ($sentinelSourceText -notmatch '(?i)\b(?:OrderSend|PositionClose|PositionModify|CTrade)\b') -Message "Read-only sentinel source contains a trading function or class."
Assert-True -Condition ($sentinelSourceText -notmatch '\bACCOUNT_LOGIN\b') -Message "Read-only sentinel source accesses the account login."
Assert-True -Condition ($sentinelHeartbeatHeader -notmatch '(?i)account.?id|account.?number|login') -Message "Sentinel heartbeat publishes an account identifier field."

$disallowedRegistrationFields = @("accountNumber", "accountId", "login", "accountLogin")
$registrationFields = @($registration.PSObject.Properties.Name)
Assert-True -Condition (@($disallowedRegistrationFields | Where-Object { $registrationFields -contains $_ }).Count -eq 0) -Message "Registration contains a disallowed account identifier field."
$sentinelRegistrationFields = @($sentinelRegistration.PSObject.Properties.Name)
Assert-True -Condition (@($disallowedRegistrationFields | Where-Object { $sentinelRegistrationFields -contains $_ }).Count -eq 0) -Message "Sentinel registration contains a disallowed account identifier field."

if([double]$status.ActualBalance -ne [double]$status.ExpectedBalance) {
   Assert-True -Condition ($status.BalanceContractPass -eq "False") -Message "Capital mismatch did not fail the balance contract."
   Assert-True -Condition ($status.AccountContractPass -eq "False") -Message "Capital mismatch did not fail the account contract."
   Assert-True -Condition ($status.Status -eq "FAIL") -Message "Capital-mismatched forward sample was not marked FAIL."
   Assert-True -Condition ($statusMarkdown -match 'sample is invalid') -Message "Capital-mismatch decision does not clearly invalidate the sample."
}

Write-Output "PASS: $checks forward-demo monitor checks"
$refreshOutput | ForEach-Object { Write-Output $_ }
