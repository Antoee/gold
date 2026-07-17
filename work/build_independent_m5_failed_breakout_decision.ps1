param(
   [string]$ResultsPath = "outputs\INDEPENDENT_M5_FAILED_BREAKOUT_DISCOVERY_MODEL1_RESULTS.csv",
   [string]$QueuePath = "outputs\INDEPENDENT_M5_FAILED_BREAKOUT_DISCOVERY_MODEL1_QUEUE.csv",
   [string]$CompileLogPath = "outputs\INDEPENDENT_M5_FAILED_BREAKOUT_COMPILE.log",
   [string]$DecisionCsvPath = "outputs\INDEPENDENT_M5_FAILED_BREAKOUT_DECISION.csv",
   [string]$DecisionMarkdownPath = "outputs\INDEPENDENT_M5_FAILED_BREAKOUT_DECISION.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$expectedSourceHash = "6774D7E94A78E985630C34EE372086BF2C8A6EA4C77690078F15641B86119D3B"
function Resolve-RepoPath([string]$Path) { if([IO.Path]::IsPathRooted($Path)) { return $Path }; return Join-Path $repo $Path }

$results = @(Import-Csv -LiteralPath (Resolve-RepoPath $ResultsPath))
$queue = @(Import-Csv -LiteralPath (Resolve-RepoPath $QueuePath))
$compile = Get-Content -LiteralPath (Resolve-RepoPath $CompileLogPath) -Raw
if($results.Count -ne 24 -or @($results | Where-Object Status -ne 'PARSED').Count -ne 0) { throw "Expected 24 parsed M5 results." }
if($queue.Count -ne 24 -or @($queue | Where-Object { [datetime]$_.To -gt [datetime]'2020-12-31' -or $_.Model -ne '1' }).Count -ne 0) {
   throw "Queue count, date boundary, or model mismatch."
}
if(@($queue | Where-Object { $_.SourceSha256 -ne $expectedSourceHash -or $_.SignalTimeframe -ne '5' }).Count -ne 0) {
   throw "M5 source or timeframe identity mismatch."
}
if($compile -notmatch 'Result: 0 errors, 0 warnings') { throw "Compile evidence is not clean." }

$decisionRows = [Collections.Generic.List[object]]::new()
foreach($group in ($results | Group-Object Candidate)) {
   $older = @($group.Group | Where-Object Window -eq 'older_2015_2017')
   $newer = @($group.Group | Where-Object Window -eq 'discovery_2018_2020')
   if($older.Count -ne 1 -or $newer.Count -ne 1) { throw "Candidate $($group.Name) lacks both equal eras." }
   $o = $older[0]
   $n = $newer[0]
   $olderPass = [double]$o.NetProfit -gt 0 -and [double]$o.ProfitFactor -ge 1.10 -and
                [double]$o.MaxDrawdownPercent -le 5.0 -and [int]$o.TotalTrades -ge 100
   $newerPass = [double]$n.NetProfit -gt 0 -and [double]$n.ProfitFactor -ge 1.10 -and
                [double]$n.MaxDrawdownPercent -le 5.0 -and [int]$n.TotalTrades -ge 100
   $decisionRows.Add([pscustomobject]@{
      Candidate=$group.Name
      OlderNetProfit=[double]$o.NetProfit; OlderAnnualizedReturnPercent=[double]$o.AnnualizedReturnPercent
      OlderProfitFactor=[double]$o.ProfitFactor; OlderDrawdownPercent=[double]$o.MaxDrawdownPercent
      OlderTrades=[int]$o.TotalTrades; OlderGatePass=$olderPass
      NewerNetProfit=[double]$n.NetProfit; NewerAnnualizedReturnPercent=[double]$n.AnnualizedReturnPercent
      NewerProfitFactor=[double]$n.ProfitFactor; NewerDrawdownPercent=[double]$n.MaxDrawdownPercent
      NewerTrades=[int]$n.TotalTrades; NewerGatePass=$newerPass
      AggregateValidationNetScore=[math]::Round([double]$o.NetProfit + [double]$n.NetProfit, 2)
      WorstEraNetProfit=[math]::Min([double]$o.NetProfit, [double]$n.NetProfit)
      TotalRestartWindowTrades=([int]$o.TotalTrades + [int]$n.TotalTrades)
      DiscoveryGatePass=($olderPass -and $newerPass)
      ContinuousOpened=$false; RecentDataOpened=$false; Model4Opened=$false
      Verdict='REJECTED_BROAD_ERAS'
      Reason='The native M5 failed-breakout shape failed profit, PF, activity, or multiple discovery requirements.'
   }) | Out-Null
}
$ranked = @($decisionRows | Sort-Object AggregateValidationNetScore -Descending)
if($ranked.Count -ne 12 -or @($ranked | Where-Object DiscoveryGatePass).Count -ne 0) { throw "Unexpected M5 promotion pass." }
$ranked | Export-Csv -LiteralPath (Resolve-RepoPath $DecisionCsvPath) -NoTypeInformation -Encoding ASCII

$profitableBoth = @($ranked | Where-Object { $_.OlderNetProfit -gt 0 -and $_.NewerNetProfit -gt 0 }).Count
$pfBoth = @($ranked | Where-Object { $_.OlderProfitFactor -ge 1.10 -and $_.NewerProfitFactor -ge 1.10 }).Count
$activityBoth = @($ranked | Where-Object { $_.OlderTrades -ge 100 -and $_.NewerTrades -ge 100 }).Count
$lead = $ranked[0]

$md = [Collections.Generic.List[string]]::new()
$md.Add('# Independent M5 Failed-Breakout Trap Decision')
$md.Add('')
$md.Add('## Decision')
$md.Add('')
$md.Add('**Rejected. No new best, continuous test, recent-data test, or Model4 promotion was opened.**')
$md.Add('')
$md.Add('The native M5 version did not preserve the positive M15 failed-breakout clue. Every one of the 12 frozen 14/16/18-bar structural and fixed-R shapes lost in both equal three-year eras. The least-bad aggregate validation score was `' + ('{0:+$#,##0.00;-$#,##0.00;$0.00}' -f $lead.AggregateValidationNetScore) + '` from `' + $lead.Candidate + '`, and it produced only `' + $lead.TotalRestartWindowTrades + '` restart-window trades.')
$md.Add('')
$md.Add('## Evidence Contract')
$md.Add('')
$md.Add("- Source SHA-256: ``$expectedSourceHash``")
$md.Add('- Compile: `0 errors, 0 warnings`')
$md.Add('- Model1 reports: `24/24` parsed')
$md.Add('- Windows: `2015-2017` and `2018-2020`')
$md.Add('- Post-2020 rows: `0`')
$md.Add('- Model4 rows: `0`')
$md.Add('- Risk per accepted trade: `0.10%`; minimum-lot overflow is rejected; real-account trading defaults off.')
$md.Add('')
$md.Add('## Gate Result')
$md.Add('')
$md.Add("- Profitable in both eras: ``$profitableBoth/12``")
$md.Add("- PF at least 1.10 in both eras: ``$pfBoth/12``")
$md.Add("- At least 100 trades in both eras: ``$activityBoth/12``")
$md.Add('- Full discovery gate passes: `0/12`')
$md.Add('')
$md.Add('| Candidate | 2015-2017 net | Annualized | PF | Trades | 2018-2020 net | Annualized | PF | Trades | Aggregate score | Decision |')
$md.Add('|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|')
foreach($row in $ranked) {
   $md.Add(('| `{0}` | {1:+$#,##0.00;-$#,##0.00;$0.00} | {2:0.00}% | {3:0.00} | {4} | {5:+$#,##0.00;-$#,##0.00;$0.00} | {6:0.00}% | {7:0.00} | {8} | {9:+$#,##0.00;-$#,##0.00;$0.00} | `{10}` |' -f
      $row.Candidate, $row.OlderNetProfit, $row.OlderAnnualizedReturnPercent, $row.OlderProfitFactor,
      $row.OlderTrades, $row.NewerNetProfit, $row.NewerAnnualizedReturnPercent, $row.NewerProfitFactor,
      $row.NewerTrades, $row.AggregateValidationNetScore, $row.Verdict))
}
$md.Add('')
$md.Add('Aggregate validation scores add restart windows only for comparison; they are not sequential account returns.')
$md.Add('')
$md.Add('## Interpretation')
$md.Add('')
$md.Add('Changing the signal timeframe from M15 to native M5 bar geometry increased noise rather than useful activity. No candidate reached the frozen 100-trade floor in both eras, and every candidate had negative expectancy. This branch should not receive looser gates, continuous testing, newer data, or execution-model escalation.')
$md | Set-Content -LiteralPath (Resolve-RepoPath $DecisionMarkdownPath) -Encoding ASCII

[pscustomobject]@{
   Status='REJECTED'; Candidates=$ranked.Count; ParsedReports=$results.Count
   ProfitableBoth=$profitableBoth; PFBoth=$pfBoth; ActivityBoth=$activityBoth; GatePasses=0
   ContinuousOpened=$false; RecentDataOpened=$false; Model4Opened=$false
}
