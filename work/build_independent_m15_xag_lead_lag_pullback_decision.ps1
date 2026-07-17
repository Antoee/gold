param(
   [string]$DiscoveryResultsPath = "outputs\INDEPENDENT_M15_XAG_LEAD_LAG_PULLBACK_DISCOVERY_MODEL1_RESULTS.csv",
   [string]$DiscoveryQueuePath = "outputs\INDEPENDENT_M15_XAG_LEAD_LAG_PULLBACK_DISCOVERY_MODEL1_QUEUE.csv",
   [string]$NeighborhoodResultsPath = "outputs\INDEPENDENT_M15_XAG_LEAD_LAG_PULLBACK_NEIGHBORHOOD_MODEL1_RESULTS.csv",
   [string]$NeighborhoodQueuePath = "outputs\INDEPENDENT_M15_XAG_LEAD_LAG_PULLBACK_NEIGHBORHOOD_MODEL1_QUEUE.csv",
   [string]$FeasibilityPath = "outputs\XAUUSD_XAGUSD_HISTORY_FEASIBILITY.csv",
   [string]$DiscoveryCompileLogPath = "outputs\INDEPENDENT_M15_XAG_LEAD_LAG_PULLBACK_COMPILE.log",
   [string]$NeighborhoodCompileLogPath = "outputs\INDEPENDENT_M15_XAG_LEAD_LAG_PULLBACK_NEIGHBORHOOD_COMPILE.log",
   [string]$DecisionCsvPath = "outputs\INDEPENDENT_M15_XAG_LEAD_LAG_PULLBACK_DECISION.csv",
   [string]$DecisionMarkdownPath = "outputs\INDEPENDENT_M15_XAG_LEAD_LAG_PULLBACK_DECISION.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
function Resolve-RepoPath([string]$Path) { if([IO.Path]::IsPathRooted($Path)) { return $Path }; return Join-Path $repo $Path }

$discovery = @(Import-Csv -LiteralPath (Resolve-RepoPath $DiscoveryResultsPath))
$discoveryQueue = @(Import-Csv -LiteralPath (Resolve-RepoPath $DiscoveryQueuePath))
$neighborhood = @(Import-Csv -LiteralPath (Resolve-RepoPath $NeighborhoodResultsPath))
$neighborhoodQueue = @(Import-Csv -LiteralPath (Resolve-RepoPath $NeighborhoodQueuePath))
$feasibility = @(Import-Csv -LiteralPath (Resolve-RepoPath $FeasibilityPath))
$compileDiscovery = Get-Content -LiteralPath (Resolve-RepoPath $DiscoveryCompileLogPath) -Raw
$compileNeighborhood = Get-Content -LiteralPath (Resolve-RepoPath $NeighborhoodCompileLogPath) -Raw
if($discovery.Count -ne 32 -or @($discovery | Where-Object Status -ne 'PARSED').Count -ne 0) { throw "Expected 32 parsed discovery results." }
if($neighborhood.Count -ne 12 -or @($neighborhood | Where-Object Status -ne 'PARSED').Count -ne 0) { throw "Expected 12 parsed neighborhood results." }
if($discoveryQueue.Count -ne 32 -or $neighborhoodQueue.Count -ne 12) { throw "Queue row counts do not match the frozen packages." }
if(@($discoveryQueue + $neighborhoodQueue | Where-Object { [datetime]$_.To -gt [datetime]'2020-12-31' -or $_.Model -ne '1' }).Count -ne 0) {
   throw "Lead-lag evidence opened forbidden data or a forbidden model."
}
if($compileDiscovery -notmatch 'Result: 0 errors, 0 warnings' -or $compileNeighborhood -notmatch 'Result: 0 errors, 0 warnings') {
   throw "Compile evidence is not clean."
}

function Convert-Pair([object[]]$Pair, [string]$Candidate, [string]$Phase, [int]$LeadLookback) {
   $older = @($Pair | Where-Object Window -eq 'older_2015_2017')
   $newer = @($Pair | Where-Object Window -eq 'discovery_2018_2020')
   if($older.Count -ne 1 -or $newer.Count -ne 1) { throw "Candidate $Candidate lacks both disjoint windows." }
   $o = $older[0]
   $n = $newer[0]
   $olderPass = [double]$o.NetProfit -gt 0 -and [double]$o.ProfitFactor -ge 1.10 -and
                [double]$o.MaxDrawdownPercent -le 5.0 -and [int]$o.TotalTrades -ge 30
   $newerPass = [double]$n.NetProfit -gt 0 -and [double]$n.ProfitFactor -ge 1.10 -and
                [double]$n.MaxDrawdownPercent -le 5.0 -and [int]$n.TotalTrades -ge 30
   return [pscustomobject]@{
      Candidate=$Candidate; EvidencePhase=$Phase; LeadLookbackBars=$LeadLookback
      OlderNetProfit=[double]$o.NetProfit; OlderAnnualizedReturnPercent=[double]$o.AnnualizedReturnPercent
      OlderProfitFactor=[double]$o.ProfitFactor; OlderDrawdownPercent=[double]$o.MaxDrawdownPercent
      OlderTrades=[int]$o.TotalTrades; OlderGatePass=$olderPass
      NewerNetProfit=[double]$n.NetProfit; NewerAnnualizedReturnPercent=[double]$n.AnnualizedReturnPercent
      NewerProfitFactor=[double]$n.ProfitFactor; NewerDrawdownPercent=[double]$n.MaxDrawdownPercent
      NewerTrades=[int]$n.TotalTrades; NewerGatePass=$newerPass
      AggregateValidationNetScore=[math]::Round([double]$o.NetProfit + [double]$n.NetProfit, 2)
      WorstEraNetProfit=[math]::Min([double]$o.NetProfit, [double]$n.NetProfit)
      NumericGatePass=($olderPass -and $newerPass)
   }
}

$discoveryRows = [Collections.Generic.List[object]]::new()
foreach($group in ($discovery | Group-Object Candidate)) {
   $queueRow = @($discoveryQueue | Where-Object Candidate -eq $group.Name | Select-Object -First 1)
   $discoveryRows.Add((Convert-Pair $group.Group $group.Name 'Discovery' ([int]$queueRow[0].LeadLookback))) | Out-Null
}
$neighborhoodRows = [Collections.Generic.List[object]]::new()
foreach($group in ($neighborhood | Group-Object Candidate)) {
   $queueRow = @($neighborhoodQueue | Where-Object Candidate -eq $group.Name | Select-Object -First 1)
   $neighborhoodRows.Add((Convert-Pair $group.Group $group.Name 'Neighborhood' ([int]$queueRow[0].LeadLookback))) | Out-Null
}

$discoveryLead4 = @($discoveryRows | Where-Object Candidate -eq 'xmll_lead4')
$neighborhoodLead4 = @($neighborhoodRows | Where-Object Candidate -eq 'xmll_lead4')
if($discoveryLead4.Count -ne 1 -or $neighborhoodLead4.Count -ne 1) { throw "Lead-4 reproduction rows are missing." }
foreach($field in @('OlderNetProfit','OlderProfitFactor','OlderTrades','OlderDrawdownPercent','NewerNetProfit','NewerProfitFactor','NewerTrades','NewerDrawdownPercent')) {
   if([string]$discoveryLead4[0].$field -ne [string]$neighborhoodLead4[0].$field) { throw "Lead-4 did not reproduce exactly for $field." }
}
$adjacent = @($neighborhoodRows | Where-Object { $_.Candidate -in @('xmll_lead3','xmll_lead5') })
$adjacentPasses = @($adjacent | Where-Object NumericGatePass).Count
$neighborhoodSupport = $adjacentPasses -gt 0

$combined = @($discoveryRows) + @($neighborhoodRows | Where-Object Candidate -ne 'xmll_lead4')
$decisionRows = foreach($row in $combined) {
   $isLead4 = $row.Candidate -eq 'xmll_lead4'
   [pscustomobject]@{
      Candidate=$row.Candidate; EvidencePhase=$row.EvidencePhase; LeadLookbackBars=$row.LeadLookbackBars
      OlderNetProfit=$row.OlderNetProfit; OlderAnnualizedReturnPercent=$row.OlderAnnualizedReturnPercent
      OlderProfitFactor=$row.OlderProfitFactor; OlderDrawdownPercent=$row.OlderDrawdownPercent
      OlderTrades=$row.OlderTrades; OlderGatePass=$row.OlderGatePass
      NewerNetProfit=$row.NewerNetProfit; NewerAnnualizedReturnPercent=$row.NewerAnnualizedReturnPercent
      NewerProfitFactor=$row.NewerProfitFactor; NewerDrawdownPercent=$row.NewerDrawdownPercent
      NewerTrades=$row.NewerTrades; NewerGatePass=$row.NewerGatePass
      AggregateValidationNetScore=$row.AggregateValidationNetScore; WorstEraNetProfit=$row.WorstEraNetProfit
      NumericGatePass=$row.NumericGatePass; NeighborhoodReproduced=$isLead4
      AdjacentSupportPass=($isLead4 -and $neighborhoodSupport); PromotionGatePass=$false
      ContinuousOpened=$false; RecentDataOpened=$false; Model4Opened=$false
      Verdict=if($isLead4){'REJECTED_ISOLATED_LOOKBACK'}else{'REJECTED_BROAD_ERAS'}
      Reason=if($isLead4){'The four-bar row reproduced, but both adjacent lookbacks failed both eras.'}else{'The candidate failed at least one disjoint-era numeric gate.'}
   }
}
$ranked = @($decisionRows | Sort-Object WorstEraNetProfit -Descending)
$ranked | Export-Csv -LiteralPath (Resolve-RepoPath $DecisionCsvPath) -NoTypeInformation -Encoding ASCII

$feasibleYears = @($feasibility | Where-Object { [int]$_.year -ge 2015 -and [int]$_.year -le 2020 })
$minimumAlignment = ($feasibleYears | Measure-Object alignment_percent -Minimum).Minimum
$minimumLookbackReady = ($feasibleYears | Measure-Object lookback_ready_percent -Minimum).Minimum
$sourceHash = ($discoveryQueue | Select-Object -First 1).SourceSha256
$numericPasses = @($discoveryRows | Where-Object NumericGatePass).Count

$md = [Collections.Generic.List[string]]::new()
$md.Add('# Independent M15 XAG Lead-Lag Pullback Decision')
$md.Add('')
$md.Add('## Decision')
$md.Add('')
$md.Add('**Rejected. The four-bar lead result reproduced, but it was an isolated parameter point. No new best, continuous test, recent-data test, or Model4 promotion was opened.**')
$md.Add('')
$md.Add('The initial 16-shape discovery screen produced one numeric pass: `xmll_lead4`. It made `+$42.08` in 2015-2017 and `+$135.46` in 2018-2020, with PF `1.13` and `1.50` on `75` and `76` trades. A frozen 2-7 bar support test reproduced those numbers exactly, but lead 3 lost `-$45.42` across the two restart windows and lead 5 lost `-$59.30`. Neither adjacent value passed either era, so the preregistered neighborhood requirement failed.')
$md.Add('')
$md.Add('## Evidence Contract')
$md.Add('')
$md.Add("- Source SHA-256: ``$sourceHash``")
$md.Add('- Compile: `0 errors, 0 warnings` in both controlled runs')
$md.Add('- Model1 reports: `44/44` parsed (`32` discovery plus `12` neighborhood)')
$md.Add('- Windows: `2015-2017` and `2018-2020`')
$md.Add('- Post-2020 strategy rows: `0`')
$md.Add('- Model4 rows: `0`')
$md.Add("- XAGUSD synchronized-history minimum alignment, 2015-2020: ``$minimumAlignment%``")
$md.Add("- XAGUSD 32-bar-lookback readiness minimum, 2015-2020: ``$minimumLookbackReady%``")
$md.Add('- Risk per accepted trade: `0.10%`; minimum-lot overflow is rejected; real-account trading defaults off.')
$md.Add('')
$md.Add('## Gate Result')
$md.Add('')
$md.Add("- Initial numeric gate passes: ``$numericPasses/16``")
$md.Add("- Adjacent lead-3/lead-5 gate passes: ``$adjacentPasses/2``")
$md.Add('- Final promotion gate passes: `0`')
$md.Add('')
$md.Add('| Candidate | Phase | Lead bars | 2015-2017 net | Annualized | PF | Trades | 2018-2020 net | Annualized | PF | Trades | Decision |')
$md.Add('|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|')
foreach($row in $ranked) {
   $md.Add(('| `{0}` | {1} | {2} | {3:+$#,##0.00;-$#,##0.00;$0.00} | {4:0.00}% | {5:0.00} | {6} | {7:+$#,##0.00;-$#,##0.00;$0.00} | {8:0.00}% | {9:0.00} | {10} | `{11}` |' -f
      $row.Candidate, $row.EvidencePhase, $row.LeadLookbackBars, $row.OlderNetProfit,
      $row.OlderAnnualizedReturnPercent, $row.OlderProfitFactor, $row.OlderTrades,
      $row.NewerNetProfit, $row.NewerAnnualizedReturnPercent, $row.NewerProfitFactor,
      $row.NewerTrades, $row.Verdict))
}
$md.Add('')
$md.Add('Aggregate validation scores add restart windows only for comparison; they are not sequential account returns.')
$md.Add('')
$md.Add('## Interpretation')
$md.Add('')
$md.Add('The delayed silver-lead idea was materially better than the earlier XAU/XAG fade and same-bar continuation families, but its edge existed only at exactly four M15 bars. A one-bar change on either side turned both eras negative. That sensitivity is classic parameter instability, so opening newer data would reward overfitting rather than test a robust hypothesis.')
$md.Add('')
$md.Add('This completes three distinct XAG-based families without a supported promotion. Further near-term research should move away from XAG as the primary signal source.')
$md | Set-Content -LiteralPath (Resolve-RepoPath $DecisionMarkdownPath) -Encoding ASCII

[pscustomobject]@{
   Status='REJECTED_ISOLATED_LOOKBACK'; UniqueCandidates=$ranked.Count; ParsedReports=($discovery.Count + $neighborhood.Count)
   InitialNumericPasses=$numericPasses; AdjacentPasses=$adjacentPasses; PromotionPasses=0
   Lead4Reproduced=$true; ContinuousOpened=$false; RecentDataOpened=$false; Model4Opened=$false
}
