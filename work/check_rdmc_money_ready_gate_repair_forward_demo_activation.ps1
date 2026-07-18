[CmdletBinding()]
param(
   [string]$RegistrationPath = 'outputs\RDMC_MONEY_READY_GATE_REPAIR_FORWARD_DEMO_DRAFT_REGISTRATION.json',
   [string]$PrimaryDecisionPath = 'outputs\RDMC_MONEY_READY_GATE_REPAIR_EXECUTABLE_DECISION.csv',
   [string]$LedgerDecisionPath = 'outputs\RDMC_MONEY_READY_GATE_REPAIR_EXECUTABLE_LEDGER_STRESS_DECISION.csv',
   [string]$SecondBrokerDecisionPath = 'outputs\RDMC_MONEY_READY_GATE_REPAIR_SECOND_BROKER_VALIDATION_DECISION.csv',
   [string]$HeartbeatPath = '',
   [string]$EvidenceLogPath = '',
   [string]$StatusCsvPath = 'outputs\RDMC_MONEY_READY_GATE_REPAIR_FORWARD_DEMO_PREFLIGHT.csv',
   [string]$StatusMarkdownPath = 'outputs\RDMC_MONEY_READY_GATE_REPAIR_FORWARD_DEMO_PREFLIGHT.md'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'seasonal_gate_helpers.ps1')

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$commonFiles = Join-Path $env:APPDATA 'MetaQuotes\Terminal\Common\Files'

function Resolve-RepoPath {
   param([Parameter(Mandatory=$true)][string]$Path)
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo ($Path -replace '/', '\')
}

function Get-Sha256 {
   param([AllowNull()][string]$Path)
   if([string]::IsNullOrWhiteSpace($Path) -or !(Test-Path -LiteralPath $Path -PathType Leaf)) { return 'MISSING' }
   return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()
}

function ConvertTo-BoolStrict {
   param([object]$Value)
   return ([string]$Value).Trim().ToLowerInvariant() -eq 'true'
}

function Add-Gate {
   param(
      [System.Collections.Generic.List[object]]$Rows,
      [string]$Gate,
      [bool]$Pass,
      [string]$Evidence
   )
   [void]$Rows.Add([pscustomobject]@{Gate=$Gate;Pass=$Pass;Evidence=$Evidence})
}

function Import-OneCsvRow {
   param([string]$Path, [string]$Label)
   if(!(Test-Path -LiteralPath $Path -PathType Leaf)) { throw "$Label missing: $Path" }
   $rows = @(Import-Csv -LiteralPath $Path)
   if($rows.Count -ne 1) { throw "$Label must contain exactly one row." }
   return $rows[0]
}

function Test-NoEvidenceEvents {
   param([string]$Path)
   if(!(Test-Path -LiteralPath $Path -PathType Leaf)) { return $true }
   return @((Get-Content -LiteralPath $Path) | Where-Object { ![string]::IsNullOrWhiteSpace($_) }).Count -eq 0
}

$registrationFull = Resolve-RepoPath $RegistrationPath
$statusCsvFull = Resolve-RepoPath $StatusCsvPath
$statusMarkdownFull = Resolve-RepoPath $StatusMarkdownPath
if(!(Test-Path -LiteralPath $registrationFull -PathType Leaf)) { throw "Registration draft missing: $registrationFull" }
$registrationRawBefore = Get-Content -Raw -LiteralPath $registrationFull
$registration = $registrationRawBefore | ConvertFrom-Json

if([string]::IsNullOrWhiteSpace($HeartbeatPath)) { $HeartbeatPath = Join-Path $commonFiles $registration.heartbeatFile }
if([string]::IsNullOrWhiteSpace($EvidenceLogPath)) { $EvidenceLogPath = Join-Path $commonFiles $registration.evidenceLogFile }
$heartbeatFull = Resolve-RepoPath $HeartbeatPath
$evidenceLogFull = Resolve-RepoPath $EvidenceLogPath

$source = Resolve-RepoPath $registration.sourcePath
$researchProfile = Resolve-RepoPath $registration.researchProfilePath
$forwardProfile = Resolve-RepoPath $registration.forwardProfilePath
$sentinelSource = Resolve-RepoPath $registration.sentinelSourcePath
$sentinelProfile = Resolve-RepoPath $registration.sentinelProfilePath
$primaryDecision = Import-OneCsvRow (Resolve-RepoPath $PrimaryDecisionPath) 'Primary executable decision'
$ledgerDecision = Import-OneCsvRow (Resolve-RepoPath $LedgerDecisionPath) 'Executable ledger decision'
$secondBrokerDecision = Import-OneCsvRow (Resolve-RepoPath $SecondBrokerDecisionPath) 'Second-broker decision'
$gates = [System.Collections.Generic.List[object]]::new()

$forbiddenProperties = @('accountLogin', 'accountNumber', 'accountId', 'brokerServer', 'serverName')
$forbiddenPresent = @($forbiddenProperties | Where-Object { $registration.PSObject.Properties.Name -contains $_ })
Add-Gate $gates 'draft-state' ($registration.activationStatus -eq 'PREPARED_NOT_REGISTERED' -and $null -eq $registration.registeredAtLocal -and $null -eq $registration.registeredAtUtc -and $null -eq $registration.initialFundingAdjustmentCount) 'No registration time or funding baseline exists.'
Add-Gate $gates 'account-identifier-excluded' (!$registration.accountIdentifierPublished -and $forbiddenPresent.Count -eq 0) 'No account or server identifier field is permitted.'
Add-Gate $gates 'candidate-source-hash' ((Get-Sha256 $source) -eq $registration.sourceSha256) 'Frozen source identity.'
Add-Gate $gates 'research-profile-hash' ((Get-Sha256 $researchProfile) -eq $registration.researchProfileSha256) 'Frozen research profile identity.'
Add-Gate $gates 'forward-profile-hash' ((Get-Sha256 $forwardProfile) -eq $registration.forwardProfileSha256) 'Derived demo profile identity.'
Add-Gate $gates 'sentinel-source-hash' ((Get-Sha256 $sentinelSource) -eq $registration.sentinelSourceSha256) 'Read-only sentinel source identity.'
Add-Gate $gates 'sentinel-profile-hash' ((Get-Sha256 $sentinelProfile) -eq $registration.sentinelProfileSha256) 'Read-only sentinel profile identity.'

$baseInputs = Import-SetInputs -Path $researchProfile
$forwardInputs = Import-SetInputs -Path $forwardProfile
$changed = @($baseInputs.Keys | Where-Object { !$forwardInputs.ContainsKey($_) -or $baseInputs[$_] -ne $forwardInputs[$_] } | Sort-Object)
$extra = @($forwardInputs.Keys | Where-Object { !$baseInputs.ContainsKey($_) })
$allowed = @($registration.allowedOperationalDifferences | Sort-Object)
Add-Gate $gates 'input-count' ($baseInputs.Keys.Count -eq 589 -and $forwardInputs.Keys.Count -eq 589 -and $extra.Count -eq 0) 'Both profiles must contain exactly 589 inputs.'
Add-Gate $gates 'operational-difference-allowlist' (!(Compare-Object -ReferenceObject $allowed -DifferenceObject $changed)) "Changed fields: $($changed -join ', ')."
Add-Gate $gates 'strategy-risk-inputs-unchanged' ([int]$registration.strategyRiskInputsChanged -eq 0) 'No strategy or risk setting was changed for the draft.'

$auditTempCsv = Join-Path ([IO.Path]::GetTempPath()) "rdmc-forward-audit-$PID.csv"
$auditTempMarkdown = Join-Path ([IO.Path]::GetTempPath()) "rdmc-forward-audit-$PID.md"
try {
   $static = & (Join-Path $PSScriptRoot 'audit_rdmc_forward_demo_profile.ps1') `
      -ProfilePath $forwardProfile -StatusCsvPath $auditTempCsv -StatusMarkdownPath $auditTempMarkdown `
      -AllowValidatedBandVWAPReversion
}
finally {
   Remove-Item -LiteralPath $auditTempCsv,$auditTempMarkdown -Force -ErrorAction SilentlyContinue
}
$registeredBlockers = @($registration.staticReadinessBlockers | Sort-Object)
$currentBlockers = @(([string]$static.FailedRules -split ';') | Where-Object { $_ } | Sort-Object)
Add-Gate $gates 'static-blocker-identity' (!(Compare-Object -ReferenceObject $registeredBlockers -DifferenceObject $currentBlockers)) "Blockers: $(if($currentBlockers.Count -eq 0){'none'}else{$currentBlockers -join ', '})."
Add-Gate $gates 'static-trade-readiness' ([bool]$static.Pass) "Status=$($static.Status); blockers=$(if($currentBlockers.Count -eq 0){'none'}else{$currentBlockers -join ', '})."

$expectedPrimaryManifest = if($registration.PSObject.Properties.Name -contains 'primaryExecutableManifestSha256') { [string]$registration.primaryExecutableManifestSha256 } else { [string]$primaryDecision.ManifestSha256 }
$expectedSecondBrokerManifest = if($registration.PSObject.Properties.Name -contains 'secondBrokerManifestSha256') { [string]$registration.secondBrokerManifestSha256 } else { [string]$secondBrokerDecision.ManifestSha256 }
$primaryIdentity = $primaryDecision.SourceSha256 -eq $registration.sourceSha256 -and $primaryDecision.ProfileSha256 -eq $registration.researchProfileSha256 -and $primaryDecision.ManifestSha256 -eq $expectedPrimaryManifest
$primaryPass = $primaryIdentity -and (ConvertTo-BoolStrict $primaryDecision.ExecutableGatePass)
Add-Gate $gates 'primary-executable-gate' $primaryPass "status=$($primaryDecision.Status); identity=$primaryIdentity."
$ledgerIdentity = $ledgerDecision.SourceSha256 -eq $registration.sourceSha256 -and $ledgerDecision.ProfileSha256 -eq $registration.researchProfileSha256 -and $ledgerDecision.ManifestSha256 -eq $expectedPrimaryManifest
$ledgerPass = $ledgerIdentity -and (ConvertTo-BoolStrict $ledgerDecision.ExecutableGatePass) -and (ConvertTo-BoolStrict $ledgerDecision.ExecutableLedgerPresent) -and (ConvertTo-BoolStrict $ledgerDecision.CostGatePass) -and (ConvertTo-BoolStrict $ledgerDecision.OrderAwareMonteCarloPass)
Add-Gate $gates 'executable-ledger-stress' $ledgerPass "status=$($ledgerDecision.Status); identity=$ledgerIdentity."
$brokerIdentity = $secondBrokerDecision.SourceSha256 -eq $registration.sourceSha256 -and $secondBrokerDecision.ProfileSha256 -eq $registration.researchProfileSha256 -and $secondBrokerDecision.ManifestSha256 -eq $expectedSecondBrokerManifest
$brokerPass = $brokerIdentity -and (ConvertTo-BoolStrict $secondBrokerDecision.PrimaryPrerequisitePass) -and (ConvertTo-BoolStrict $secondBrokerDecision.SpecificationPass) -and (ConvertTo-BoolStrict $secondBrokerDecision.SecondBrokerGatePass)
Add-Gate $gates 'distinct-broker-gate' $brokerPass "status=$($secondBrokerDecision.Status); identity=$brokerIdentity."

$candidateBinaryPath = if($null -eq $registration.candidateBinaryPath) { '' } else { Resolve-RepoPath ([string]$registration.candidateBinaryPath) }
$candidateBinaryPass = $registration.candidateBinaryStatus -eq 'FROZEN_EXECUTABLE_GATE_PASS' -and ![string]::IsNullOrWhiteSpace([string]$registration.candidateBinarySha256) -and (Get-Sha256 $candidateBinaryPath) -eq $registration.candidateBinarySha256
Add-Gate $gates 'candidate-compiled-binary' $candidateBinaryPass "status=$($registration.candidateBinaryStatus)."
$sentinelBinaryPath = if($null -eq $registration.sentinelBinaryPath) { '' } else { Resolve-RepoPath ([string]$registration.sentinelBinaryPath) }
$sentinelBinaryPass = $registration.sentinelBinaryStatus -eq 'FROZEN_NONTRADING_BINARY' -and ![string]::IsNullOrWhiteSpace([string]$registration.sentinelBinarySha256) -and (Get-Sha256 $sentinelBinaryPath) -eq $registration.sentinelBinarySha256
Add-Gate $gates 'sentinel-compiled-binary' $sentinelBinaryPass "status=$($registration.sentinelBinaryStatus)."

$heartbeatRows = @()
$heartbeatPresent = Test-Path -LiteralPath $heartbeatFull -PathType Leaf
if($heartbeatPresent) { $heartbeatRows = @(Import-Csv -LiteralPath $heartbeatFull -Delimiter "`t") }
$heartbeatValid = $heartbeatRows.Count -eq 1
$heartbeat = if($heartbeatValid) { $heartbeatRows[0] } else { $null }
$requiredColumns = @(
   'local_time', 'server_time', 'run_label', 'source_sha256', 'profile_sha256',
   'account_trade_mode', 'margin_mode', 'account_currency', 'history_available',
   'funding_adjustment_count', 'foreign_trade_count', 'connected',
   'terminal_trade_allowed', 'account_trade_allowed', 'account_expert_allowed',
   'mql_trade_allowed', 'expected_symbol', 'balance', 'equity', 'all_positions',
   'candidate_positions', 'all_unprotected_positions', 'candidate_unprotected_positions',
   'candidate_open_risk_percent'
)
$heartbeatSchema = $heartbeatValid -and @($requiredColumns | Where-Object { $heartbeat.PSObject.Properties.Name -notcontains $_ }).Count -eq 0 -and $heartbeat.PSObject.Properties.Name.Count -eq $requiredColumns.Count
Add-Gate $gates 'heartbeat-present' $heartbeatPresent 'Dedicated read-only heartbeat exists.'
Add-Gate $gates 'heartbeat-schema' $heartbeatSchema 'One row with the exact nonidentifying account-contract schema.'

$balance = [double]::NaN
$equity = [double]::NaN
$fundingCount = -1
if($heartbeatSchema) {
   $balance = [double]::Parse($heartbeat.balance, [Globalization.CultureInfo]::InvariantCulture)
   $equity = [double]::Parse($heartbeat.equity, [Globalization.CultureInfo]::InvariantCulture)
   $fundingCount = [int]$heartbeat.funding_adjustment_count
   $foreignCount = [int]$heartbeat.foreign_trade_count
   $parsedTime = [datetime]::MinValue
   foreach($format in @('yyyy.MM.dd HH:mm:ss', 'yyyy-MM-dd HH:mm:ss', 'yyyy-MM-ddTHH:mm:ssK')) {
      if([datetime]::TryParseExact($heartbeat.local_time, $format, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::AllowWhiteSpaces, [ref]$parsedTime)) { break }
   }
   $heartbeatAge = if($parsedTime -eq [datetime]::MinValue) { [double]::PositiveInfinity } else { [math]::Abs(((Get-Date) - $parsedTime).TotalSeconds) }
   $expectedBalance = [double]$registration.expectedStartingBalance
   $tolerance = [double]$registration.startingBalanceTolerance
   Add-Gate $gates 'heartbeat-fresh' ($heartbeatAge -le [double]$registration.maximumHeartbeatAgeSeconds) "age_seconds=$([math]::Round($heartbeatAge, 1))."
   Add-Gate $gates 'heartbeat-identity' ($heartbeat.run_label -eq $registration.runLabel -and $heartbeat.source_sha256 -eq $registration.sourceSha256 -and $heartbeat.profile_sha256 -eq $registration.forwardProfileSha256) 'Run, source, and profile match the draft.'
   Add-Gate $gates 'demo-hedging-usd' ($heartbeat.account_trade_mode -eq 'demo' -and $heartbeat.margin_mode -eq 'hedging' -and $heartbeat.account_currency -eq $registration.expectedCurrency) "mode=$($heartbeat.account_trade_mode)/$($heartbeat.margin_mode); currency=$($heartbeat.account_currency)."
   Add-Gate $gates 'expected-symbol' ($heartbeat.expected_symbol -eq $registration.expectedSymbol) "symbol=$($heartbeat.expected_symbol)."
   Add-Gate $gates 'history-available' (ConvertTo-BoolStrict $heartbeat.history_available) 'Account-history snapshot succeeded.'
   Add-Gate $gates 'funding-baseline-observable' ($fundingCount -ge 0) "observed_count=$fundingCount; not frozen."
   Add-Gate $gates 'no-foreign-trades' ($foreignCount -eq 0) "foreign_trade_count=$foreignCount."
   Add-Gate $gates 'connected' (ConvertTo-BoolStrict $heartbeat.connected) 'Terminal broker connection.'
   Add-Gate $gates 'starting-balance' ([math]::Abs($balance - $expectedBalance) -le $tolerance) "actual=$balance; expected=$expectedBalance; tolerance=$tolerance."
   Add-Gate $gates 'starting-equity' ([math]::Abs($equity - $expectedBalance) -le $tolerance) "actual=$equity; expected=$expectedBalance; tolerance=$tolerance."
   Add-Gate $gates 'flat-account' ([int]$heartbeat.all_positions -eq 0 -and [int]$heartbeat.candidate_positions -eq 0) "all=$($heartbeat.all_positions); candidate=$($heartbeat.candidate_positions)."
   Add-Gate $gates 'no-unprotected-positions' ([int]$heartbeat.all_unprotected_positions -eq 0 -and [int]$heartbeat.candidate_unprotected_positions -eq 0) "all=$($heartbeat.all_unprotected_positions); candidate=$($heartbeat.candidate_unprotected_positions)."
   Add-Gate $gates 'zero-open-risk' ([math]::Abs([double]$heartbeat.candidate_open_risk_percent) -le 0.000001) "candidate_risk=$($heartbeat.candidate_open_risk_percent)%."
   Add-Gate $gates 'algorithmic-trading-disabled' (!(ConvertTo-BoolStrict $heartbeat.terminal_trade_allowed) -and !(ConvertTo-BoolStrict $heartbeat.mql_trade_allowed)) "terminal=$($heartbeat.terminal_trade_allowed); mql=$($heartbeat.mql_trade_allowed)."
}
else {
   foreach($gate in @('heartbeat-fresh','heartbeat-identity','demo-hedging-usd','expected-symbol','history-available','funding-baseline-observable','no-foreign-trades','connected','starting-balance','starting-equity','flat-account','no-unprotected-positions','zero-open-risk','algorithmic-trading-disabled')) {
      Add-Gate $gates $gate $false 'Heartbeat unavailable or invalid.'
   }
}

Add-Gate $gates 'empty-evidence-log' (Test-NoEvidenceEvents $evidenceLogFull) 'Dedicated evidence log is absent or empty.'
Add-Gate $gates 'real-account-lock' (!$registration.realAccountTradingAllowed) 'Real-account trading remains disabled.'

$failed = @($gates | Where-Object { !$_.Pass })
$ready = $failed.Count -eq 0
$gates | Export-Csv -LiteralPath $statusCsvFull -NoTypeInformation -Encoding ASCII
@(
   '# RDMC Money-Ready Gate-Repair Forward-Demo Activation Preflight', '',
   "**Ready to register: $ready.**", '',
   'This read-only preflight did not register an account, freeze a funding baseline, amend the candidate, or publish an account identifier.', '',
   "- Draft state: ``$($registration.activationStatus)``",
   "- Observed balance: ``$balance``",
   "- Required balance: ``$($registration.expectedStartingBalance)`` (+/- ``$($registration.startingBalanceTolerance)``)",
   "- Observed funding-history count: ``$fundingCount`` (not frozen)",
   "- Failed gates: ``$(if($failed.Count -eq 0){'none'}else{$failed.Gate -join ', '})``", '',
   '| Gate | Pass | Evidence |', '|---|---:|---|'
) + @($gates | ForEach-Object { "| $($_.Gate) | $($_.Pass) | $($_.Evidence) |" }) |
   Set-Content -LiteralPath $statusMarkdownFull -Encoding ASCII

if((Get-Content -Raw -LiteralPath $registrationFull) -ne $registrationRawBefore) { throw 'Preflight mutated the registration draft.' }

[pscustomobject]@{
   Status = if($ready) { 'READY_TO_REGISTER' } else { 'REFUSED' }
   ReadyToRegister = $ready
   FailedGates = @($failed | Select-Object -ExpandProperty Gate) -join ';'
   ObservedBalance = $balance
   ExpectedBalance = [double]$registration.expectedStartingBalance
   ObservedFundingAdjustmentCount = $fundingCount
   RegistrationMutated = $false
   AccountIdentifierPublished = $false
}
