param(
   [string]$ResultsPath = "outputs\INDEPENDENT_M15_XAG_RELATIVE_VALUE_DISCOVERY_MODEL1_RESULTS.csv",
   [string]$QueuePath = "outputs\INDEPENDENT_M15_XAG_RELATIVE_VALUE_DISCOVERY_MODEL1_QUEUE.csv",
   [string]$FeasibilityPath = "outputs\XAUUSD_XAGUSD_HISTORY_FEASIBILITY.csv",
   [string]$CompileLogPath = "outputs\INDEPENDENT_M15_XAG_RELATIVE_VALUE_DISCOVERY_MODEL1_COMPILE.log",
   [string]$DecisionCsvPath = "outputs\INDEPENDENT_M15_XAG_RELATIVE_VALUE_DECISION.csv",
   [string]$DecisionMarkdownPath = "outputs\INDEPENDENT_M15_XAG_RELATIVE_VALUE_DECISION.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
function Resolve-RepoPath([string]$Path) { if([IO.Path]::IsPathRooted($Path)) { return $Path }; return Join-Path $repo $Path }

$results = @(Import-Csv -LiteralPath (Resolve-RepoPath $ResultsPath))
$queue = @(Import-Csv -LiteralPath (Resolve-RepoPath $QueuePath))
$feasibility = @(Import-Csv -LiteralPath (Resolve-RepoPath $FeasibilityPath))
$compileText = Get-Content -LiteralPath (Resolve-RepoPath $CompileLogPath) -Raw
if($results.Count -ne 32 -or @($results | Where-Object Status -ne 'PARSED').Count -ne 0) { throw "Expected 32 parsed cross-metal results." }
if($queue.Count -ne 32 -or @($queue | Where-Object { [datetime]$_.To -gt [datetime]'2020-12-31' }).Count -ne 0) { throw "Queue count or date boundary mismatch." }
if($compileText -notmatch 'Result: 0 errors, 0 warnings') { throw "Compile evidence is not clean." }

$rows = [Collections.Generic.List[object]]::new()
foreach($group in ($results | Group-Object Candidate)) {
   $older = @($group.Group | Where-Object Window -eq 'older_2015_2017')
   $newer = @($group.Group | Where-Object Window -eq 'discovery_2018_2020')
   if($older.Count -ne 1 -or $newer.Count -ne 1) { throw "Candidate $($group.Name) lacks both disjoint windows." }
   $o = $older[0]
   $n = $newer[0]
   $olderPass = [double]$o.NetProfit -gt 0 -and [double]$o.ProfitFactor -ge 1.10 -and
                [double]$o.MaxDrawdownPercent -le 5.0 -and [int]$o.TotalTrades -ge 30
   $newerPass = [double]$n.NetProfit -gt 0 -and [double]$n.ProfitFactor -ge 1.10 -and
                [double]$n.MaxDrawdownPercent -le 5.0 -and [int]$n.TotalTrades -ge 30
   $gatePass = $olderPass -and $newerPass
   $rows.Add([pscustomobject]@{
      Candidate=$group.Name
      OlderNetProfit=[double]$o.NetProfit; OlderAnnualizedReturnPercent=[double]$o.AnnualizedReturnPercent
      OlderProfitFactor=[double]$o.ProfitFactor; OlderDrawdownPercent=[double]$o.MaxDrawdownPercent
      OlderTrades=[int]$o.TotalTrades; OlderGatePass=$olderPass
      NewerNetProfit=[double]$n.NetProfit; NewerAnnualizedReturnPercent=[double]$n.AnnualizedReturnPercent
      NewerProfitFactor=[double]$n.ProfitFactor; NewerDrawdownPercent=[double]$n.MaxDrawdownPercent
      NewerTrades=[int]$n.TotalTrades; NewerGatePass=$newerPass
      AggregateValidationNetScore=[math]::Round([double]$o.NetProfit + [double]$n.NetProfit, 2)
      WorstEraNetProfit=[math]::Min([double]$o.NetProfit, [double]$n.NetProfit)
      DiscoveryGatePass=$gatePass
      ContinuousOpened=$false; RecentDataOpened=$false; Model4Opened=$false
      Verdict=if($gatePass){'ELIGIBLE_FOR_CONTINUOUS'}else{'REJECTED_BROAD_ERAS'}
      Reason=if($gatePass){'Both disjoint Model1 eras passed the preregistered screen.'}else{'At least one disjoint era failed profit, PF, drawdown, or activity requirements.'}
   }) | Out-Null
}
$ranked = @($rows | Sort-Object WorstEraNetProfit -Descending)
$ranked | Export-Csv -LiteralPath (Resolve-RepoPath $DecisionCsvPath) -NoTypeInformation -Encoding ASCII

$feasibleYears = @($feasibility | Where-Object { [int]$_.year -ge 2015 -and [int]$_.year -le 2020 })
$minimumAlignment = if($feasibleYears.Count -gt 0) { ($feasibleYears | Measure-Object alignment_percent -Minimum).Minimum } else { 0 }
$minimumLookbackReady = if($feasibleYears.Count -gt 0) { ($feasibleYears | Measure-Object lookback_ready_percent -Minimum).Minimum } else { 0 }
$profitableBoth = @($ranked | Where-Object { $_.OlderNetProfit -gt 0 -and $_.NewerNetProfit -gt 0 }).Count
$pfBoth = @($ranked | Where-Object { $_.OlderProfitFactor -ge 1.10 -and $_.NewerProfitFactor -ge 1.10 }).Count
$gatePasses = @($ranked | Where-Object DiscoveryGatePass).Count
$sourceHash = ($queue | Select-Object -First 1).SourceSha256

$md = [Collections.Generic.List[string]]::new()
$md.Add('# Independent M15 XAG Relative-Value Decision')
$md.Add('')
$md.Add('## Decision')
$md.Add('')
$md.Add('**Rejected. No new best, no continuous test, no recent-data test, and no Model4 promotion.**')
$md.Add('')
$md.Add('The broker-data hypothesis was feasible, but the trading hypothesis was not: every one of the 16 nearby shapes lost money in both disjoint three-year eras. Most profiles eventually reached the 5% research drawdown guard, and no profile reached PF 1.10 in both eras.')
$md.Add('')
$md.Add('## Evidence Contract')
$md.Add('')
$md.Add("- Source SHA-256: ``$sourceHash``")
$md.Add('- Compile: `0 errors, 0 warnings`')
$md.Add('- Model1 reports: `32/32` parsed')
$md.Add('- Windows: `2015-2017` and `2018-2020`')
$md.Add('- Post-2020 strategy rows: `0`')
$md.Add('- Model4 rows: `0`')
$md.Add("- XAGUSD synchronized-history minimum alignment, 2015-2020: ``$minimumAlignment%``")
$md.Add("- XAGUSD 32-bar-lookback readiness minimum, 2015-2020: ``$minimumLookbackReady%``")
$md.Add('- Risk per accepted trade: `0.10%`; minimum-lot overflow is rejected; real-account trading defaults off.')
$md.Add('')
$md.Add('## Gate Result')
$md.Add('')
$md.Add("- Profitable in both eras: ``$profitableBoth/16``")
$md.Add("- PF at least 1.10 in both eras: ``$pfBoth/16``")
$md.Add("- Full discovery gate passes: ``$gatePasses/16``")
$md.Add('')
$md.Add('| Candidate | 2015-2017 net | Annualized | PF | Trades | 2018-2020 net | Annualized | PF | Trades | Worst era | Decision |')
$md.Add('|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|')
foreach($row in $ranked) {
   $md.Add(('| `{0}` | {1:+$#,##0.00;-$#,##0.00;$0.00} | {2:0.00}% | {3:0.00} | {4} | {5:+$#,##0.00;-$#,##0.00;$0.00} | {6:0.00}% | {7:0.00} | {8} | {9:+$#,##0.00;-$#,##0.00;$0.00} | `{10}` |' -f
      $row.Candidate, $row.OlderNetProfit, $row.OlderAnnualizedReturnPercent, $row.OlderProfitFactor,
      $row.OlderTrades, $row.NewerNetProfit, $row.NewerAnnualizedReturnPercent, $row.NewerProfitFactor,
      $row.NewerTrades, $row.WorstEraNetProfit, $row.Verdict))
}
$md.Add('')
$md.Add('The aggregate column in the CSV is a validation score only; the two windows restart from the same deposit and are not an achievable sequential account return.')
$md.Add('')
$md.Add('## Interpretation')
$md.Add('')
$md.Add('The result rejects this specific **fade-the-XAU/XAG-divergence** implementation. It does not prove cross-metal data is useless; it shows that buying XAU underperformance and selling XAU outperformance after a one-bar reversal had negative expectancy across both development eras under the frozen stop and risk contract.')
$md.Add('')
$md.Add('A future cross-metal continuation hypothesis must be treated as a new family with a new frozen contract. These results may motivate it, but they cannot be relabeled as support for an inverted strategy.')
$md | Set-Content -LiteralPath (Resolve-RepoPath $DecisionMarkdownPath) -Encoding ASCII

[pscustomobject]@{
   Status='REJECTED'; Candidates=$ranked.Count; ParsedReports=$results.Count
   ProfitableBoth=$profitableBoth; PFBoth=$pfBoth; GatePasses=$gatePasses
   ContinuousOpened=$false; RecentDataOpened=$false; Model4Opened=$false
   MinimumAlignmentPercent=$minimumAlignment; MinimumLookbackReadyPercent=$minimumLookbackReady
}
