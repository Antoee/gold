param(
   [string]$DiagnosticPath = "outputs\XAUUSD_H4_CHANNEL_CAPITAL_FEASIBILITY.csv",
   [int]$RecentStartYear = 2021,
   [double]$MinimumRecentFeasiblePercent = 80.0,
   [int]$MinimumRecentSignals = 30,
   [string]$OutCsv = "outputs\XAUUSD_H4_CHANNEL_CAPITAL_FEASIBILITY_GATE.csv",
   [string]$OutMarkdown = "outputs\XAUUSD_H4_CHANNEL_CAPITAL_FEASIBILITY_GATE.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
function Resolve-RepoPath([string]$Path) { if([IO.Path]::IsPathRooted($Path)) { return $Path }; return Join-Path $repo $Path }
function Ensure-Parent([string]$Path) { $parent = Split-Path -Parent $Path; if($parent -and !(Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null } }
function Number([object]$Value) { return [double]::Parse([string]$Value, [Globalization.CultureInfo]::InvariantCulture) }
function Integer([object]$Value) { return [int]::Parse([string]$Value, [Globalization.CultureInfo]::InvariantCulture) }

$diagnosticFull = Resolve-RepoPath $DiagnosticPath
if(!(Test-Path -LiteralPath $diagnosticFull)) { throw "Capital-feasibility diagnostic missing: $diagnosticFull" }
$rows = @(Import-Csv -LiteralPath $diagnosticFull)
$summaries = @($rows | Where-Object { $_.row_type -eq "summary" })
if($summaries.Count -eq 0) { throw "No summary rows found in capital-feasibility diagnostic." }
$gateRows = [Collections.Generic.List[object]]::new()
foreach($summary in $summaries) {
   $yearRows = @($rows | Where-Object {
      $_.row_type -eq "year" -and $_.probe_id -eq $summary.probe_id -and (Integer $_.year) -ge $RecentStartYear
   })
   $recentSignals = [int](($yearRows | Measure-Object -Property signals -Sum).Sum)
   $recentFeasible = [int](($yearRows | Measure-Object -Property feasible_signals -Sum).Sum)
   $recentFailures = [int](($yearRows | Measure-Object -Property order_calc_failures -Sum).Sum)
   $recentPercent = if($recentSignals -gt 0) { 100.0 * $recentFeasible / $recentSignals } else { 0.0 }
   $latest = $yearRows | Where-Object { (Integer $_.signals) -gt 0 } | Sort-Object { Integer $_.year } -Descending | Select-Object -First 1
   $status = if($recentSignals -lt $MinimumRecentSignals) {
      "FAIL_INSUFFICIENT_SIGNALS"
   } elseif($recentFailures -gt 0) {
      "FAIL_ORDER_CALC"
   } elseif($recentPercent -lt $MinimumRecentFeasiblePercent) {
      "FAIL_MINIMUM_LOT_FEASIBILITY"
   } else {
      "PASS"
   }
   $gateRows.Add([pscustomobject]@{
      ProbeId = $summary.probe_id
      SourceSha256 = $summary.source_sha256
      EntryLookback = Integer $summary.entry_lookback
      AssumedEquity = Number $summary.assumed_equity
      RiskPercent = Number $summary.risk_percent
      MinimumVolume = Number $summary.minimum_volume
      TotalSignals = Integer $summary.signals
      OverallFeasibleSignals = Integer $summary.feasible_signals
      OverallFeasiblePercent = [math]::Round((Number $summary.feasible_percent), 4)
      RecentStartYear = $RecentStartYear
      RecentSignals = $recentSignals
      RecentFeasibleSignals = $recentFeasible
      RecentFeasiblePercent = [math]::Round($recentPercent, 4)
      LatestSignalYear = if($null -eq $latest) { 0 } else { Integer $latest.year }
      LatestRequiredEquityMin = if($null -eq $latest) { 0.0 } else { Number $latest.required_equity_min }
      LatestRequiredEquityP50 = if($null -eq $latest) { 0.0 } else { Number $latest.required_equity_p50 }
      LatestRequiredEquityP95 = if($null -eq $latest) { 0.0 } else { Number $latest.required_equity_p95 }
      OrderCalcFailures = $recentFailures
      MinimumRecentFeasiblePercent = $MinimumRecentFeasiblePercent
      GateStatus = $status
   }) | Out-Null
}

$outCsvFull = Resolve-RepoPath $OutCsv
$outMarkdownFull = Resolve-RepoPath $OutMarkdown
Ensure-Parent $outCsvFull
Ensure-Parent $outMarkdownFull
$gateRows | Export-Csv -LiteralPath $outCsvFull -NoTypeInformation -Encoding ASCII
$failed = @($gateRows | Where-Object { $_.GateStatus -ne "PASS" })
$verdict = if($failed.Count -eq 0) { "PASS" } else { "FAIL" }
$md = [Collections.Generic.List[string]]::new()
$md.Add("# XAUUSD Capital-Feasibility Gate") | Out-Null
$md.Add("") | Out-Null
$md.Add("**Verdict: ``$verdict``. This is a sizing/activity gate, not a strategy-profit test.**") | Out-Null
$md.Add("") | Out-Null
$md.Add("A candidate passes only when at least ``$MinimumRecentSignals`` eligible signals exist from $RecentStartYear onward, broker-native ``OrderCalcProfit`` has zero failures, and at least ``$MinimumRecentFeasiblePercent%`` of those signals can trade the broker minimum volume without exceeding the declared equity/risk budget.") | Out-Null
$md.Add("") | Out-Null
$md.Add("| Probe | Lookback | Equity | Risk | Min lot | All signals | All feasible | Recent signals | Recent feasible | Latest signal year | Latest required equity min / median / p95 | Gate |") | Out-Null
$md.Add("| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |") | Out-Null
foreach($row in $gateRows) {
   $md.Add(('| `{0}` | {1} | `${2:N2}` | `{3:N2}%` | `{4:N2}` | {5} | `{6:N2}%` | {7} | `{8:N2}%` | {9} | `${10:N2} / ${11:N2} / ${12:N2}` | `{13}` |' -f
      $row.ProbeId, $row.EntryLookback, $row.AssumedEquity, $row.RiskPercent, $row.MinimumVolume,
      $row.TotalSignals, $row.OverallFeasiblePercent, $row.RecentSignals, $row.RecentFeasiblePercent,
      $row.LatestSignalYear, $row.LatestRequiredEquityMin, $row.LatestRequiredEquityP50,
      $row.LatestRequiredEquityP95, $row.GateStatus)) | Out-Null
}
$md.Add("") | Out-Null
$md.Add("A failed candidate must change its strategy economics before performance testing: use a tighter evidence-based stop, a broker/symbol with a smaller minimum risk quantum, or a declared larger account. Forcing the minimum lot or silently raising risk is prohibited.") | Out-Null
$md.Add("") | Out-Null
$md.Add("Diagnostic source and settings are immutable evidence for this gate. Changing them requires a new diagnostic identity.") | Out-Null
$md | Set-Content -LiteralPath $outMarkdownFull -Encoding ASCII

[pscustomobject]@{
   Verdict = $verdict
   Probes = $gateRows.Count
   Passed = $gateRows.Count - $failed.Count
   Failed = $failed.Count
   OutCsv = $OutCsv
   OutMarkdown = $OutMarkdown
}
