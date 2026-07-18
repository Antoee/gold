[CmdletBinding()]
param(
   [string]$RegistrationPath = "outputs\OPERATIONAL_HARDENING_RC2_FORWARD_REGISTRATION_DRAFT.json",
   [string]$SentinelRegistrationPath = "outputs\OPERATIONAL_HARDENING_RC2_FORWARD_SENTINEL_REGISTRATION_DRAFT.json",
   [string]$HeartbeatPath = "",
   [string]$ReversionLogPath = "",
   [string]$MomentumLogPath = "",
   [string]$StatusCsvPath = "outputs\OPERATIONAL_HARDENING_RC2_FORWARD_PREFLIGHT.csv",
   [string]$StatusMarkdownPath = "outputs\OPERATIONAL_HARDENING_RC2_FORWARD_PREFLIGHT.md"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$commonFiles = Join-Path $env:APPDATA "MetaQuotes\Terminal\Common\Files"

function Resolve-RepoPath {
   param([Parameter(Mandatory=$true)][string]$Path)
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo ($Path -replace '/', '\')
}

function Get-Sha256 {
   param([Parameter(Mandatory=$true)][string]$Path)
   if(!(Test-Path -LiteralPath $Path -PathType Leaf)) { return "MISSING" }
   return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()
}

function ConvertTo-BoolStrict {
   param([object]$Value)
   return ([string]$Value).Trim().ToLowerInvariant() -eq "true"
}

function Test-NoEvidenceEvents {
   param([Parameter(Mandatory=$true)][string]$Path)
   if(!(Test-Path -LiteralPath $Path -PathType Leaf)) { return $true }
   return @((Get-Content -LiteralPath $Path) | Where-Object { ![string]::IsNullOrWhiteSpace($_) }).Count -eq 0
}

function Add-Gate {
   param(
      [Parameter(Mandatory=$true)][AllowEmptyCollection()][System.Collections.Generic.List[object]]$Rows,
      [Parameter(Mandatory=$true)][string]$Gate,
      [Parameter(Mandatory=$true)][bool]$Pass,
      [Parameter(Mandatory=$true)][string]$Evidence
   )
   [void]$Rows.Add([pscustomobject]@{Gate=$Gate;Pass=$Pass;Evidence=$Evidence})
}

$registrationFull = Resolve-RepoPath $RegistrationPath
$sentinelRegistrationFull = Resolve-RepoPath $SentinelRegistrationPath
$statusCsvFull = Resolve-RepoPath $StatusCsvPath
$statusMarkdownFull = Resolve-RepoPath $StatusMarkdownPath
foreach($path in @($registrationFull, $sentinelRegistrationFull)) {
   if(!(Test-Path -LiteralPath $path -PathType Leaf)) { throw "Required draft missing: $path" }
}

$registrationRawBefore = Get-Content -Raw -LiteralPath $registrationFull
$sentinelRegistrationRawBefore = Get-Content -Raw -LiteralPath $sentinelRegistrationFull
$registration = $registrationRawBefore | ConvertFrom-Json
$sentinelRegistration = $sentinelRegistrationRawBefore | ConvertFrom-Json

if([string]::IsNullOrWhiteSpace($HeartbeatPath)) {
   $HeartbeatPath = Join-Path $commonFiles $sentinelRegistration.heartbeatFile
}
if([string]::IsNullOrWhiteSpace($ReversionLogPath)) {
   $ReversionLogPath = Join-Path $commonFiles $registration.reversionLogFile
}
if([string]::IsNullOrWhiteSpace($MomentumLogPath)) {
   $MomentumLogPath = Join-Path $commonFiles $registration.momentumLogFile
}
$heartbeatFull = Resolve-RepoPath $HeartbeatPath
$reversionLogFull = Resolve-RepoPath $ReversionLogPath
$momentumLogFull = Resolve-RepoPath $MomentumLogPath

$heartbeatRows = @()
$heartbeatPresent = Test-Path -LiteralPath $heartbeatFull -PathType Leaf
if($heartbeatPresent) {
   $heartbeatRows = @(Import-Csv -LiteralPath $heartbeatFull -Delimiter "`t")
}
$heartbeatValid = $heartbeatRows.Count -eq 1
$heartbeat = if($heartbeatValid) { $heartbeatRows[0] } else { $null }
$requiredHeartbeatColumns = @(
   "local_time", "server_time", "run_label", "source_sha256", "profile_sha256",
   "account_trade_mode", "margin_mode", "account_currency", "history_available",
   "funding_adjustment_count", "foreign_trade_count", "connected",
   "terminal_trade_allowed", "account_trade_allowed", "account_expert_allowed",
   "mql_trade_allowed", "expected_symbol", "balance", "equity", "all_positions",
   "candidate_positions", "all_unprotected_positions", "candidate_unprotected_positions",
   "candidate_open_risk_percent"
)
$heartbeatSchemaPass = $heartbeatValid -and
   @($requiredHeartbeatColumns | Where-Object { $heartbeat.PSObject.Properties.Name -notcontains $_ }).Count -eq 0 -and
   $heartbeat.PSObject.Properties.Name.Count -eq $requiredHeartbeatColumns.Count

$heartbeatAgeSeconds = [double]::PositiveInfinity
if($heartbeatSchemaPass) {
   $parsedTime = [datetime]::MinValue
   $formats = @("yyyy.MM.dd HH:mm:ss", "yyyy-MM-dd HH:mm:ss", "yyyy-MM-ddTHH:mm:ssK")
   foreach($format in $formats) {
      if([datetime]::TryParseExact($heartbeat.local_time, $format,
            [Globalization.CultureInfo]::InvariantCulture,
            [Globalization.DateTimeStyles]::AllowWhiteSpaces, [ref]$parsedTime)) { break }
   }
   if($parsedTime -ne [datetime]::MinValue) {
      $heartbeatAgeSeconds = [math]::Abs(((Get-Date) - $parsedTime).TotalSeconds)
   }
}

$sourcePath = Resolve-RepoPath $registration.sourcePath
$binaryPath = Resolve-RepoPath $registration.binaryPath
$profilePath = Resolve-RepoPath $registration.profilePath
$sentinelSourcePath = Resolve-RepoPath $sentinelRegistration.sourcePath
$sentinelBinaryPath = Resolve-RepoPath $sentinelRegistration.binaryPath
$sentinelProfilePath = Resolve-RepoPath $sentinelRegistration.profilePath
$gates = [System.Collections.Generic.List[object]]::new()

Add-Gate $gates "candidate-draft-state" ($registration.activationStatus -eq "PREPARED_NOT_REGISTERED" -and $null -eq $registration.registeredAtLocal -and $null -eq $registration.initialFundingAdjustmentCount) "prepared identity has no registration time or funding baseline"
Add-Gate $gates "sentinel-draft-state" ($sentinelRegistration.activationStatus -eq "PREPARED_NOT_REGISTERED" -and $null -eq $sentinelRegistration.registeredAtLocal) "sentinel identity is not registered"
Add-Gate $gates "candidate-source-hash" ((Get-Sha256 $sourcePath) -eq $registration.sourceSha256) "workspace source identity"
Add-Gate $gates "candidate-binary-hash" ((Get-Sha256 $binaryPath) -eq $registration.binarySha256) "local compiled binary identity"
Add-Gate $gates "candidate-profile-hash" ((Get-Sha256 $profilePath) -eq $registration.profileSha256) "forward profile identity"
Add-Gate $gates "sentinel-source-hash" ((Get-Sha256 $sentinelSourcePath) -eq $sentinelRegistration.sourceSha256) "read-only sentinel source identity"
Add-Gate $gates "sentinel-binary-hash" ((Get-Sha256 $sentinelBinaryPath) -eq $sentinelRegistration.binarySha256) "read-only sentinel binary identity"
Add-Gate $gates "sentinel-profile-hash" ((Get-Sha256 $sentinelProfilePath) -eq $sentinelRegistration.profileSha256) "sentinel profile identity"
Add-Gate $gates "heartbeat-present" $heartbeatPresent "dedicated sentinel heartbeat exists"
Add-Gate $gates "heartbeat-schema" $heartbeatSchemaPass "one row with exact account-contract schema"

if($heartbeatSchemaPass) {
   $balance = [double]$heartbeat.balance
   $equity = [double]$heartbeat.equity
   $fundingCount = [int]$heartbeat.funding_adjustment_count
   $foreignCount = [int]$heartbeat.foreign_trade_count
   $expectedBalance = [double]$registration.expectedStartingBalance
   $tolerance = [double]$registration.startingBalanceTolerance
   Add-Gate $gates "heartbeat-fresh" ($heartbeatAgeSeconds -le [double]$sentinelRegistration.maximumHeartbeatAgeSeconds) "age_seconds=$([math]::Round($heartbeatAgeSeconds, 1))"
   Add-Gate $gates "heartbeat-identity" ($heartbeat.run_label -eq $registration.runLabel -and $heartbeat.source_sha256 -eq $registration.sourceSha256 -and $heartbeat.profile_sha256 -eq $registration.profileSha256) "run/source/profile match the frozen package"
   Add-Gate $gates "demo-hedging-usd" ($heartbeat.account_trade_mode -eq "demo" -and $heartbeat.margin_mode -eq "hedging" -and $heartbeat.account_currency -eq $registration.expectedCurrency) "mode=$($heartbeat.account_trade_mode)/$($heartbeat.margin_mode) currency=$($heartbeat.account_currency)"
   Add-Gate $gates "expected-symbol" ($heartbeat.expected_symbol -eq $registration.expectedSymbol) "symbol=$($heartbeat.expected_symbol)"
   Add-Gate $gates "history-available" (ConvertTo-BoolStrict $heartbeat.history_available) "account history snapshot succeeded"
   Add-Gate $gates "funding-baseline-observable" ($fundingCount -ge 0) "observed_count=$fundingCount; not frozen by preflight"
   Add-Gate $gates "no-foreign-trades" ($foreignCount -eq [int]$registration.requiredForeignTradeCount) "foreign_trade_count=$foreignCount"
   Add-Gate $gates "connected" (ConvertTo-BoolStrict $heartbeat.connected) "terminal broker connection"
   Add-Gate $gates "starting-balance" ([math]::Abs($balance - $expectedBalance) -le $tolerance) "actual=$balance expected=$expectedBalance tolerance=$tolerance"
   Add-Gate $gates "starting-equity" ([math]::Abs($equity - $expectedBalance) -le $tolerance) "actual=$equity expected=$expectedBalance tolerance=$tolerance"
   Add-Gate $gates "flat-account" ([int]$heartbeat.all_positions -eq 0 -and [int]$heartbeat.candidate_positions -eq 0) "all=$($heartbeat.all_positions) candidate=$($heartbeat.candidate_positions)"
   Add-Gate $gates "no-unprotected-positions" ([int]$heartbeat.all_unprotected_positions -eq 0 -and [int]$heartbeat.candidate_unprotected_positions -eq 0) "all=$($heartbeat.all_unprotected_positions) candidate=$($heartbeat.candidate_unprotected_positions)"
   Add-Gate $gates "zero-open-risk" ([math]::Abs([double]$heartbeat.candidate_open_risk_percent) -le 0.000001) "candidate_risk=$($heartbeat.candidate_open_risk_percent)%"
   Add-Gate $gates "algorithmic-trading-disabled" (!(ConvertTo-BoolStrict $heartbeat.terminal_trade_allowed) -and !(ConvertTo-BoolStrict $heartbeat.mql_trade_allowed)) "terminal=$($heartbeat.terminal_trade_allowed) mql=$($heartbeat.mql_trade_allowed)"
}
else {
   foreach($gate in @("heartbeat-fresh", "heartbeat-identity", "demo-hedging-usd", "expected-symbol", "history-available", "funding-baseline-observable", "no-foreign-trades", "connected", "starting-balance", "starting-equity", "flat-account", "no-unprotected-positions", "zero-open-risk", "algorithmic-trading-disabled")) {
      Add-Gate $gates $gate $false "heartbeat unavailable or invalid"
   }
   $fundingCount = -1
   $balance = [double]::NaN
   $equity = [double]::NaN
}

Add-Gate $gates "empty-reversion-log" (Test-NoEvidenceEvents $reversionLogFull) "dedicated reversion log absent or empty"
Add-Gate $gates "empty-momentum-log" (Test-NoEvidenceEvents $momentumLogFull) "dedicated momentum log absent or empty"
Add-Gate $gates "real-account-lock" (!$registration.realAccountTradingAllowed) "real-account trading remains disabled"

$failed = @($gates | Where-Object { !$_.Pass })
$ready = $failed.Count -eq 0
$gates | Export-Csv -LiteralPath $statusCsvFull -NoTypeInformation -Encoding ASCII
@(
   "# Operational-Hardening rc2 Forward Activation Preflight", "",
   "**Ready to register: $ready**", "",
   "This is a read-only check. It did not create or amend a registration, funding baseline, candidate profile, or evidence log. It contains no account identifier.", "",
   "- Draft state: $($registration.activationStatus)",
   "- Observed balance: $balance",
   "- Required balance: $($registration.expectedStartingBalance) (+/- $($registration.startingBalanceTolerance))",
   "- Observed funding-history count: $fundingCount (not frozen)",
   "- Failed gates: $(if($failed.Count -eq 0){'none'}else{$failed.Gate -join ', '})", "",
   "| Gate | Pass | Evidence |", "|---|---:|---|"
) + @($gates | ForEach-Object { "| $($_.Gate) | $($_.Pass) | $($_.Evidence) |" }) |
   Set-Content -LiteralPath $statusMarkdownFull -Encoding ASCII

if((Get-Content -Raw -LiteralPath $registrationFull) -ne $registrationRawBefore) { throw "Preflight mutated candidate draft." }
if((Get-Content -Raw -LiteralPath $sentinelRegistrationFull) -ne $sentinelRegistrationRawBefore) { throw "Preflight mutated sentinel draft." }

[pscustomobject]@{
   Status = if($ready) { "READY_TO_REGISTER" } else { "REFUSED" }
   ReadyToRegister = $ready
   FailedGates = if($failed.Count -eq 0) { "" } else { @($failed | Select-Object -ExpandProperty Gate) -join ";" }
   ObservedBalance = $balance
   ExpectedBalance = [double]$registration.expectedStartingBalance
   ObservedFundingAdjustmentCount = $fundingCount
   RegistrationMutated = $false
   AccountIdentifierPublished = $false
}
