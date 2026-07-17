param(
   [string]$ResultsCsv = "outputs\REVERSION_INDEPENDENT_V2_DISCOVERY_MODEL1_RESULTS.csv",
   [string]$DecisionCsv = "outputs\REVERSION_INDEPENDENT_V2_DISCOVERY_DECISION.csv",
   [string]$ControlTradesCsv = "outputs\REVERSION_INDEPENDENT_CONTROL_MODEL1_TRADES.csv",
   [string]$V1TradesCsv = "outputs\REVERSION_INDEPENDENT_M10_R30_MODEL1_TRADES.csv",
   [string]$V2TradesCsv = "outputs\REVERSION_INDEPENDENT_V2_M10_R30_MODEL1_TRADES.csv",
   [string]$DecisionMarkdown = "outputs\REVERSION_INDEPENDENT_V2_DISCOVERY_DECISION.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
function Resolve-RepoPath([string]$Path) { if([IO.Path]::IsPathRooted($Path)) { return $Path }; return Join-Path $repo $Path }
function PrimaryTrades([object[]]$Rows) { return @($Rows | Where-Object { $_.EntryComment -notlike 'RRO;Band VWAP reversion*' }) }

$results = @(Import-Csv -LiteralPath (Resolve-RepoPath $ResultsCsv))
$decision = @(Import-Csv -LiteralPath (Resolve-RepoPath $DecisionCsv))
if($results.Count -ne 45 -or @($results | Where-Object Status -ne 'PARSED').Count -ne 0) { throw "Expected 45 parsed clean V2 discovery results." }
if($decision.Count -ne 5) { throw "Expected one control and four corrected candidate rows." }

$control = @($decision | Where-Object Role -eq 'CONTROL')
$candidates = @($decision | Where-Object Role -eq 'CANDIDATE')
if($control.Count -ne 1 -or $control[0].Decision -ne 'CONTROL_CONFIRMED') { throw "Exact V2 control was not confirmed." }
if($candidates.Count -ne 4 -or @($candidates | Where-Object Decision -ne 'REJECTED_NO_RETROSPECTIVE_NO_MODEL4').Count -ne 0) { throw "Every corrected candidate must be rejected before recent data and Model 4." }

$controlNewer = [double]$control[0].NewerDiscoveryNet
$control2017 = [double]$control[0].Year2017Net
$control2019 = [double]$control[0].Year2019Net
if([math]::Abs([double]$control[0].OlderDiscoveryNet - 184.32) -gt 0.001 -or
   [math]::Abs($controlNewer - 108.33) -gt 0.001 -or
   [math]::Abs([double]$control[0].ContinuousDiscoveryNet - 252.65) -gt 0.001) { throw "V2 control compatibility changed." }
if(@($candidates | Where-Object {
   [double]$_.NewerDiscoveryNet -ge $controlNewer -or
   [double]$_.Year2017Net -ge $control2017 -or
   [double]$_.Year2019Net -ge $control2019
}).Count -ne 0) { throw "Candidate rows do not prove the broad-era and annual rejection gates." }

$controlTrades = PrimaryTrades @(Import-Csv -LiteralPath (Resolve-RepoPath $ControlTradesCsv))
$v1Trades = PrimaryTrades @(Import-Csv -LiteralPath (Resolve-RepoPath $V1TradesCsv))
$v2Trades = PrimaryTrades @(Import-Csv -LiteralPath (Resolve-RepoPath $V2TradesCsv))
$v1ExtraPrimary = @($v1Trades | Where-Object { $_.EntryTime -notin $controlTrades.EntryTime })
$v2ExtraPrimary = @($v2Trades | Where-Object { $_.EntryTime -notin $controlTrades.EntryTime })
if($controlTrades.Count -ne 12 -or $v1ExtraPrimary.Count -ne 5) { throw "V1 primary-lane confound was not reproduced." }
if($v2Trades.Count -ne 12 -or $v2ExtraPrimary.Count -ne 0 -or @(Compare-Object $controlTrades.EntryTime $v2Trades.EntryTime).Count -ne 0) { throw "V2 did not preserve exact control primary entry times." }

$text = Get-Content -LiteralPath (Resolve-RepoPath $DecisionMarkdown) -Raw
foreach($token in @(
   'No 2021-2026 retrospective implementation run was opened',
   'Model 4 was skipped',
   'no new best was promoted',
   'adds only six Band/VWAP reversion entries',
   'real-account trading remains disabled'
)) {
   if($text.IndexOf($token, [StringComparison]::OrdinalIgnoreCase) -lt 0) { throw "Decision token missing: $token" }
}

[pscustomobject]@{ Status='PASS'; Results=45; Candidates=4; Rejected=4; V1ExtraPrimary=$v1ExtraPrimary.Count; V2ExtraPrimary=$v2ExtraPrimary.Count; Model4Allowed=$false }
