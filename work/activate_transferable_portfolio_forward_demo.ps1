[CmdletBinding()]
param(
   [ValidateSet("Check", "Register", "Verify")]
   [string]$Phase = "Check",
   [string]$RegistrationPath = "",
   [string]$SentinelRegistrationPath = "",
   [string]$StatusCsvPath = "",
   [string]$StatusMarkdownPath = "",
   [string]$ArchiveDirectory = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$workspaceRoot = Split-Path -Parent $PSScriptRoot
if([string]::IsNullOrWhiteSpace($RegistrationPath)) {
   $RegistrationPath = Join-Path $workspaceRoot "outputs\TRANSFERABLE_PORTFOLIO_FORWARD_DEMO_REGISTRATION.json"
}
if([string]::IsNullOrWhiteSpace($SentinelRegistrationPath)) {
   $SentinelRegistrationPath = Join-Path $workspaceRoot "outputs\TRANSFERABLE_FORWARD_SENTINEL_REGISTRATION.json"
}
if([string]::IsNullOrWhiteSpace($StatusCsvPath)) {
   $StatusCsvPath = Join-Path $workspaceRoot "outputs\TRANSFERABLE_PORTFOLIO_FORWARD_DEMO_STATUS.csv"
}
if([string]::IsNullOrWhiteSpace($StatusMarkdownPath)) {
   $StatusMarkdownPath = Join-Path $workspaceRoot "outputs\TRANSFERABLE_PORTFOLIO_FORWARD_DEMO_STATUS.md"
}
if([string]::IsNullOrWhiteSpace($ArchiveDirectory)) {
   $ArchiveDirectory = Join-Path $workspaceRoot "archive\forward_demo_invalid_capital_20260717"
}

function Resolve-WorkspacePath {
   param([Parameter(Mandatory=$true)][string]$Path)
   if([System.IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $workspaceRoot ($Path -replace '/', '\')
}

function Get-Sha256 {
   param([Parameter(Mandatory=$true)][string]$Path)
   if(!(Test-Path -LiteralPath $Path -PathType Leaf)) { return "MISSING" }
   return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()
}

function Test-TrueText {
   param([object]$Value)
   return [string]$Value -eq "True"
}

function Add-Gate {
   param(
      [Parameter(Mandatory=$true)][AllowEmptyCollection()][System.Collections.Generic.List[object]]$Rows,
      [Parameter(Mandatory=$true)][string]$Name,
      [Parameter(Mandatory=$true)][bool]$Pass,
      [Parameter(Mandatory=$true)][string]$Evidence
   )
   [void]$Rows.Add([pscustomobject]@{ Gate=$Name; Pass=$Pass; Evidence=$Evidence })
}

function Test-EmptyEvidenceFile {
   param([Parameter(Mandatory=$true)][string]$Path)
   if(!(Test-Path -LiteralPath $Path -PathType Leaf)) { return $false }
   return @((Get-Content -LiteralPath $Path) | Where-Object { ![string]::IsNullOrWhiteSpace($_) }).Count -eq 0
}

foreach($path in @($RegistrationPath, $SentinelRegistrationPath)) {
   if(!(Test-Path -LiteralPath $path -PathType Leaf)) { throw "Required registration missing: $path" }
}

$registrationRawBefore = Get-Content -Raw -LiteralPath $RegistrationPath
$registration = $registrationRawBefore | ConvertFrom-Json
$sentinelRegistration = Get-Content -Raw -LiteralPath $SentinelRegistrationPath | ConvertFrom-Json
$sourcePath = Resolve-WorkspacePath -Path $registration.sourcePath
$profilePath = Resolve-WorkspacePath -Path $registration.profilePath
$sentinelSourcePath = Resolve-WorkspacePath -Path $sentinelRegistration.sourcePath
$sentinelProfilePath = Resolve-WorkspacePath -Path $sentinelRegistration.profilePath
$refreshPath = Join-Path $PSScriptRoot "refresh_transferable_portfolio_forward_demo_status.ps1"

& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $refreshPath `
   -RegistrationPath $RegistrationPath `
   -SentinelRegistrationPath $SentinelRegistrationPath `
   -StatusCsvPath $StatusCsvPath `
   -StatusMarkdownPath $StatusMarkdownPath | Out-Null
if($LASTEXITCODE -ne 0) { throw "Forward status refresh failed." }

$statusRows = @(Import-Csv -LiteralPath $StatusCsvPath)
if($statusRows.Count -ne 1) { throw "Expected exactly one forward status row." }
$status = $statusRows[0]
$commonFilesRoot = Join-Path $env:APPDATA "MetaQuotes\Terminal\Common\Files"
$rvLogPath = Join-Path $commonFilesRoot $registration.reversionLogFile
$moLogPath = Join-Path $commonFilesRoot $registration.momentumLogFile
$balance = [double]$status.ActualBalance
$equity = [double]$status.ActualEquity
$startingBalance = [double]$registration.startingBalance
$gates = [System.Collections.Generic.List[object]]::new()

Add-Gate $gates "candidate-source-hash" ((Get-Sha256 $sourcePath) -eq $registration.sourceSha256) "workspace source matches registration"
Add-Gate $gates "candidate-profile-hash" ((Get-Sha256 $profilePath) -eq $registration.profileSha256) "workspace profile matches registration"
Add-Gate $gates "candidate-installed-binary" (Test-TrueText $status.InstalledBinaryHashMatch) "installed candidate binary hash"
Add-Gate $gates "sentinel-source-hash" ((Get-Sha256 $sentinelSourcePath) -eq $sentinelRegistration.sourceSha256) "workspace sentinel source matches registration"
Add-Gate $gates "sentinel-profile-hash" ((Get-Sha256 $sentinelProfilePath) -eq $sentinelRegistration.profileSha256) "workspace sentinel profile matches registration"
Add-Gate $gates "sentinel-installed-binary" (Test-TrueText $status.SentinelInstalledBinaryHashMatch) "installed sentinel binary hash"
Add-Gate $gates "sentinel-heartbeat" ((Test-TrueText $status.SentinelHeartbeatPresent) -and (Test-TrueText $status.SentinelHeartbeatValid) -and (Test-TrueText $status.SentinelHeartbeatFresh) -and (Test-TrueText $status.SentinelHeartbeatIdentityPass)) "present, valid, fresh, and frozen identity"
Add-Gate $gates "demo-hedging-mode" ($status.AccountTradeMode -eq "demo" -and $status.MarginMode -eq "hedging") "mode=$($status.AccountTradeMode)/$($status.MarginMode)"
Add-Gate $gates "connected" (Test-TrueText $status.Connected) "terminal connected to broker"
Add-Gate $gates "starting-balance" ([math]::Abs($balance - $startingBalance) -le 1.0) "actual=$balance expected=$startingBalance"
Add-Gate $gates "starting-equity" ([math]::Abs($equity - $startingBalance) -le 1.0) "actual=$equity expected=$startingBalance"
Add-Gate $gates "flat-account" ([int]$status.AllPositions -eq 0 -and [int]$status.CandidatePositions -eq 0) "all=$($status.AllPositions) candidate=$($status.CandidatePositions)"
Add-Gate $gates "no-unprotected-positions" ([int]$status.AllUnprotectedPositions -eq 0 -and [int]$status.CandidateUnprotectedPositions -eq 0) "all=$($status.AllUnprotectedPositions) candidate=$($status.CandidateUnprotectedPositions)"
Add-Gate $gates "zero-open-risk" ([math]::Abs([double]$status.CandidateOpenRiskPercent) -le 0.000001) "risk=$($status.CandidateOpenRiskPercent)%"
Add-Gate $gates "empty-event-counts" ([int]$status.EntryEvents -eq 0 -and [int]$status.ClosedTrades -eq 0) "entries=$($status.EntryEvents) exits=$($status.ClosedTrades)"
Add-Gate $gates "empty-reversion-log" (Test-EmptyEvidenceFile $rvLogPath) "dedicated reversion evidence contains no events"
Add-Gate $gates "empty-momentum-log" (Test-EmptyEvidenceFile $moLogPath) "dedicated momentum evidence contains no events"
Add-Gate $gates "clean-evidence-identity" ([int]$status.InvalidRows -eq 0 -and [int]$status.ForeignIdentityRows -eq 0) "invalid=$($status.InvalidRows) foreign=$($status.ForeignIdentityRows)"
Add-Gate $gates "real-trading-disabled" (!(Test-TrueText $status.RealAccountTradingAllowed) -and !$registration.realAccountTradingAllowed) "registration and generated status remain demo-only"

$commonFailures = @($gates | Where-Object { !$_.Pass })
$tradingDisabled = !(Test-TrueText $status.TerminalTradeAllowed) -and !(Test-TrueText $status.MqlTradeAllowed)
$readyToRegister = $commonFailures.Count -eq 0 -and $tradingDisabled

if($Phase -eq "Check") {
   [pscustomobject]@{
      Phase = $Phase
      ReadyToRegister = $readyToRegister
      CommonGatePass = $commonFailures.Count -eq 0
      TradingDisabled = $tradingDisabled
      FailedGates = ($commonFailures.Gate -join ";")
      ActualBalance = $balance
      ExpectedBalance = $startingBalance
      EntryEvents = [int]$status.EntryEvents
      ClosedTrades = [int]$status.ClosedTrades
   }
   return
}

if($Phase -eq "Register") {
   if(!$readyToRegister) {
      $failureNames = @($commonFailures.Gate)
      if(!$tradingDisabled) { $failureNames += "algorithmic-trading-not-disabled" }
      throw "ACTIVATION_REFUSED: $($failureNames -join ', ')"
   }

   New-Item -ItemType Directory -Path $ArchiveDirectory -Force | Out-Null
   Copy-Item -LiteralPath $RegistrationPath -Destination (Join-Path $ArchiveDirectory "invalid_registration.json") -Force
   Copy-Item -LiteralPath $StatusCsvPath -Destination (Join-Path $ArchiveDirectory "invalid_status.csv") -Force
   Copy-Item -LiteralPath $StatusMarkdownPath -Destination (Join-Path $ArchiveDirectory "invalid_status.md") -Force

   $now = [datetimeoffset]::Now
   $registration.registeredAtLocal = $now.ToString("yyyy-MM-ddTHH:mm:sszzz", [System.Globalization.CultureInfo]::InvariantCulture)
   $registration.registeredAtUtc = $now.UtcDateTime.ToString("yyyy-MM-ddTHH:mm:ssZ", [System.Globalization.CultureInfo]::InvariantCulture)
   $registration.notes = "Activated only after the read-only sentinel proved the frozen account contract on a flat, exact-balance demo hedging account while algorithmic trading was disabled. The earlier capital-mismatched attachment is retained in Git history and the local archive."
   if($registration.PSObject.Properties.Name -contains "activationStatus") {
      $registration.activationStatus = "REGISTERED_TRADING_DISABLED"
   }
   else {
      $registration | Add-Member -NotePropertyName activationStatus -NotePropertyValue "REGISTERED_TRADING_DISABLED"
   }
   $json = ($registration | ConvertTo-Json -Depth 8) + [Environment]::NewLine
   [System.IO.File]::WriteAllText($RegistrationPath, $json, [System.Text.UTF8Encoding]::new($false))

   & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $refreshPath `
      -RegistrationPath $RegistrationPath `
      -SentinelRegistrationPath $SentinelRegistrationPath `
      -StatusCsvPath $StatusCsvPath `
      -StatusMarkdownPath $StatusMarkdownPath | Out-Null
   if($LASTEXITCODE -ne 0) { throw "Post-registration status refresh failed." }
   $registeredStatus = Import-Csv -LiteralPath $StatusCsvPath
   if([double]$registeredStatus.CalendarDays -gt 0.01 -or [int]$registeredStatus.EntryEvents -ne 0 -or [int]$registeredStatus.ClosedTrades -ne 0) {
      throw "Post-registration zero-sample verification failed."
   }

   [pscustomobject]@{
      Phase = $Phase
      Status = "REGISTERED_TRADING_DISABLED"
      RegisteredAtLocal = $registration.registeredAtLocal
      CalendarDays = [double]$registeredStatus.CalendarDays
      ActualBalance = [double]$registeredStatus.ActualBalance
      EntryEvents = [int]$registeredStatus.EntryEvents
      ClosedTrades = [int]$registeredStatus.ClosedTrades
      NextAction = "Enable algorithmic trading, wait for a fresh sentinel heartbeat, then run -Phase Verify."
   }
   return
}

if($registration.PSObject.Properties.Name -notcontains "activationStatus" -or $registration.activationStatus -ne "REGISTERED_TRADING_DISABLED") {
   throw "VERIFY_REFUSED: registration was not created by the disabled-trading activation gate."
}
$operationalPass = Test-TrueText $status.OperationalPass
$pendingPass = $status.Status -eq "PENDING"
$newClockPass = [double]$status.CalendarDays -le 1.0
if($commonFailures.Count -gt 0 -or !$operationalPass -or !$pendingPass -or !$newClockPass) {
   $failureNames = @($commonFailures.Gate)
   if(!$operationalPass) { $failureNames += "operational-permissions" }
   if(!$pendingPass) { $failureNames += "status-not-pending" }
   if(!$newClockPass) { $failureNames += "registration-clock-not-new" }
   throw "VERIFY_REFUSED: $($failureNames -join ', ')"
}

[pscustomobject]@{
   Phase = $Phase
   Status = "FORWARD_ACTIVE"
   RegisteredAtLocal = $registration.registeredAtLocal
   CalendarDays = [double]$status.CalendarDays
   ActualBalance = $balance
   AccountContractPass = Test-TrueText $status.AccountContractPass
   OperationalPass = $operationalPass
   EntryEvents = [int]$status.EntryEvents
   ClosedTrades = [int]$status.ClosedTrades
}
