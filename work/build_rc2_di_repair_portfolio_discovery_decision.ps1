param(
   [string]$ResultsPath = "outputs\RC2_DI_REPAIR_PORTFOLIO_DISCOVERY_MODEL1_RESULTS.csv",
   [string]$QueuePath = "outputs\RC2_DI_REPAIR_PORTFOLIO_DISCOVERY_MODEL1_QUEUE.csv",
   [string]$RunPath = "outputs\RC2_DI_REPAIR_PORTFOLIO_DISCOVERY_MODEL1_RUN.csv",
   [string]$DecisionCsvPath = "outputs\RC2_DI_REPAIR_PORTFOLIO_DISCOVERY_DECISION.csv",
   [string]$DecisionMarkdownPath = "outputs\RC2_DI_REPAIR_PORTFOLIO_DISCOVERY_DECISION.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$expectedSourceHash = '9141137A9550F3394DE85E1725E018671B4F2A2FF0F43A3EF23F9FB1238CD302'
function Resolve-RepoPath([string]$Path) {
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}
function Format-Money([double]$Value) {
   if($Value -ge 0) { return ('+${0:N2}' -f $Value) }
   return ('-${0:N2}' -f [math]::Abs($Value))
}

$results = @(Import-Csv -LiteralPath (Resolve-RepoPath $ResultsPath))
$queue = @(Import-Csv -LiteralPath (Resolve-RepoPath $QueuePath))
$runs = @(Import-Csv -LiteralPath (Resolve-RepoPath $RunPath))
if($results.Count -ne 24 -or $queue.Count -ne 24 -or $runs.Count -ne 24) {
   throw "Expected 24 results, queue rows, and canonical run rows."
}
if(@($results | Where-Object Status -ne 'PARSED').Count -gt 0 -or
   @($runs | Where-Object Status -ne 'REPORT_FOUND').Count -gt 0) {
   throw "Every discovery report must be identity-valid and parsed."
}
if(@($results | Where-Object { $_.To -gt '2020.12.31' }).Count -gt 0) { throw "Post-2020 data leaked into the decision." }
if(@($queue.SourceSha256 | Sort-Object -Unique).Count -ne 1 -or $queue[0].SourceSha256 -ne $expectedSourceHash) {
   throw "Unexpected source identity."
}
foreach($row in $results) {
   $q = @($queue | Where-Object QueueRank -eq $row.QueueRank)
   $run = @($runs | Where-Object QueueRank -eq $row.QueueRank)
   if($q.Count -ne 1 -or $run.Count -ne 1 -or $row.ProfileSha256 -ne $q[0].ProfileSha256 -or
      $row.SourceSha256 -ne $expectedSourceHash -or $run[0].PackageSourceSha256 -ne $expectedSourceHash) {
      throw "Identity mismatch at rank $($row.QueueRank)."
   }
}

$rows = [System.Collections.Generic.List[object]]::new()
foreach($group in ($results | Group-Object Candidate)) {
   if($group.Count -ne 4) { throw "Candidate $($group.Name) does not have four discovery windows." }
   $older = @($group.Group | Where-Object Window -eq 'older_2015_2018')
   $y2019 = @($group.Group | Where-Object Window -eq 'repair_2019')
   $y2020 = @($group.Group | Where-Object Window -eq 'repair_2020')
   $continuous = @($group.Group | Where-Object Window -eq 'continuous_2015_2020')
   if($older.Count -ne 1 -or $y2019.Count -ne 1 -or $y2020.Count -ne 1 -or $continuous.Count -ne 1) {
      throw "Candidate $($group.Name) has an unexpected window set."
   }
   $olderNet = [double]$older[0].NetProfit
   $net2019 = [double]$y2019[0].NetProfit
   $net2020 = [double]$y2020[0].NetProfit
   $pf2019 = [double]$y2019[0].ProfitFactor
   $pf2020 = [double]$y2020[0].ProfitFactor
   $net = [double]$continuous[0].NetProfit
   $pf = [double]$continuous[0].ProfitFactor
   $payoff = [double]$continuous[0].ExpectedPayoff
   $trades = [int]$continuous[0].TotalTrades
   $dd = [double]$continuous[0].MaxDrawdownPercent
   $returnToDd = if($dd -gt 0.0) { (100.0 * $net / 10000.0) / $dd } else { 0.0 }
   $basePass = $olderNet -gt 0.0 -and $net2019 -ge -25.0 -and $net2020 -ge -25.0 -and
               $pf2019 -ge 0.85 -and $pf2020 -ge 0.85 -and $net2019 + $net2020 -ge -25.0 -and
               $net -gt 0.0 -and $pf -ge 1.50 -and $payoff -gt 0.0 -and $trades -ge 190 -and
               $dd -le 3.00 -and $returnToDd -ge 2.00
   $failedGates = [System.Collections.Generic.List[string]]::new()
   if($olderNet -le 0.0) { $failedGates.Add('older-net') }
   if($net2019 -lt -25.0) { $failedGates.Add('2019-net') }
   if($pf2019 -lt 0.85) { $failedGates.Add('2019-pf') }
   if($net2020 -lt -25.0) { $failedGates.Add('2020-net') }
   if($pf2020 -lt 0.85) { $failedGates.Add('2020-pf') }
   if($net2019 + $net2020 -lt -25.0) { $failedGates.Add('repair-sum') }
   if($net -le 0.0) { $failedGates.Add('continuous-net') }
   if($pf -lt 1.50) { $failedGates.Add('continuous-pf') }
   if($payoff -le 0.0) { $failedGates.Add('payoff') }
   if($trades -lt 190) { $failedGates.Add('trades') }
   if($dd -gt 3.00) { $failedGates.Add('drawdown') }
   if($returnToDd -lt 2.00) { $failedGates.Add('return-dd') }
   $rows.Add([pscustomobject]@{
      Candidate=$group.Name;MomentumRiskPercent=[double]$continuous[0].MORiskPercent
      DIThreshold=[double]$continuous[0].RVMinimumDIEdge;Older2015To2018Net=[math]::Round($olderNet,2)
      Net2019=[math]::Round($net2019,2);PF2019=[math]::Round($pf2019,2)
      Net2020=[math]::Round($net2020,2);PF2020=[math]::Round($pf2020,2)
      Repair2019To2020Net=[math]::Round($net2019+$net2020,2);Continuous2015To2020Net=[math]::Round($net,2)
      ContinuousProfitFactor=[math]::Round($pf,2);ContinuousExpectedPayoff=[math]::Round($payoff,2)
      ContinuousTrades=$trades;ContinuousMaxDrawdownPercent=[math]::Round($dd,2)
      ContinuousReturnToDrawdown=[math]::Round($returnToDd,2);BaseGatePass=$basePass
      FailedBaseGates=$failedGates -join ';'
   }) | Out-Null
}

$center015 = @($rows | Where-Object Candidate -eq 'dir_mo015_di10_center')
$center020 = @($rows | Where-Object Candidate -eq 'dir_mo020_di10_center')
$adjacent015 = @($rows | Where-Object { $_.MomentumRiskPercent -eq 0.15 -and $_.DIThreshold -ne -10.0 -and $_.BaseGatePass }).Count
$adjacent020 = @($rows | Where-Object { $_.MomentumRiskPercent -eq 0.20 -and $_.DIThreshold -ne -10.0 -and $_.BaseGatePass }).Count
if($center015.Count -ne 1 -or $center020.Count -ne 1) { throw "Repair centers missing." }
$familyPass = $center015[0].BaseGatePass -and $center020[0].BaseGatePass -and $adjacent015 -ge 1 -and $adjacent020 -ge 1
$decisionRows = @($rows | Sort-Object MomentumRiskPercent,DIThreshold | ForEach-Object {
   [pscustomobject]@{
      Candidate=$_.Candidate;MomentumRiskPercent=$_.MomentumRiskPercent;DIThreshold=$_.DIThreshold
      Older2015To2018Net=$_.Older2015To2018Net;Net2019=$_.Net2019;PF2019=$_.PF2019
      Net2020=$_.Net2020;PF2020=$_.PF2020;Repair2019To2020Net=$_.Repair2019To2020Net
      Continuous2015To2020Net=$_.Continuous2015To2020Net;ContinuousProfitFactor=$_.ContinuousProfitFactor
      ContinuousExpectedPayoff=$_.ContinuousExpectedPayoff;ContinuousTrades=$_.ContinuousTrades
      ContinuousMaxDrawdownPercent=$_.ContinuousMaxDrawdownPercent
      ContinuousReturnToDrawdown=$_.ContinuousReturnToDrawdown;BaseGatePass=$_.BaseGatePass
      FailedBaseGates=$_.FailedBaseGates;FamilyDiscoveryPass=$familyPass
      Decision=if($familyPass -and $_.BaseGatePass){'ELIGIBLE_FOR_FROZEN_HOLDOUT'}else{'REJECTED_NO_HOLDOUT_NO_MODEL4'}
   }
})
if($familyPass) { throw "The family passed; this rejection-only builder must be revised before use." }
$decisionRows | Export-Csv -LiteralPath (Resolve-RepoPath $DecisionCsvPath) -NoTypeInformation -Encoding ASCII

$control020 = @($decisionRows | Where-Object Candidate -eq 'dir_mo020_di12_control')[0]
$strict020 = @($decisionRows | Where-Object Candidate -eq 'dir_mo020_di08_strict')[0]
$md = [System.Collections.Generic.List[string]]::new()
$md.Add('# RC2 DI-Repair Portfolio Discovery Decision')
$md.Add('')
$md.Add("Decision date: $((Get-Date).ToString('yyyy-MM-dd'))")
$md.Add('')
$md.Add('**Verdict: rejected at the frozen pre-2021 Model 1 gate. No post-2020 holdout or Model 4 configuration was opened, no new best was promoted, and the registered candidate remains unchanged.**')
$md.Add('')
$md.Add('## Evidence Boundary')
$md.Add('')
$md.Add("- Exact RC2 source SHA-256: ``$expectedSourceHash``")
$md.Add('- Identity-valid reports parsed: `24 / 24`')
$md.Add('- Profiles: `6`')
$md.Add('- Latest data used: `2020-12-31`')
$md.Add('- Post-2020 holdout runs: `0`')
$md.Add('- Model 4 runs: `0`')
$md.Add('- Real-account trading: disabled')
$md.Add('')
$md.Add('One initial portable row hit a source-identity startup race. Only that exact frozen rank was rerun; it passed, and the canonical run contains one valid result per queue rank.')
$md.Add('')
$md.Add('## Results')
$md.Add('')
$md.Add('| Profile | MO risk | DI | 2015-2018 | 2019 | PF | 2020 | PF | 2019+2020 | Continuous | PF | Trades | DD | Return/DD | Base gate |')
$md.Add('| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |')
foreach($row in $decisionRows) {
   $md.Add("| ``$($row.Candidate)`` | ``$('{0:N2}' -f $row.MomentumRiskPercent)%`` | ``$($row.DIThreshold)`` | ``$(Format-Money $row.Older2015To2018Net)`` | ``$(Format-Money $row.Net2019)`` | ``$('{0:N2}' -f $row.PF2019)`` | ``$(Format-Money $row.Net2020)`` | ``$('{0:N2}' -f $row.PF2020)`` | ``$(Format-Money $row.Repair2019To2020Net)`` | ``$(Format-Money $row.Continuous2015To2020Net)`` | ``$('{0:N2}' -f $row.ContinuousProfitFactor)`` | ``$($row.ContinuousTrades)`` | ``$('{0:N2}' -f $row.ContinuousMaxDrawdownPercent)%`` | ``$('{0:N2}' -f $row.ContinuousReturnToDrawdown)`` | ``$($row.BaseGatePass)`` |")
}
$md.Add('')
$md.Add('## Interpretation')
$md.Add('')
$md.Add("The intervention materially repaired the targeted weakness. At ``0.20%`` momentum risk, DI ``-10`` changed 2020 from ``$(Format-Money $control020.Net2020)`` to ``$(Format-Money $center020[0].Net2020)``, increased continuous pre-2021 net from ``$(Format-Money $control020.Continuous2015To2020Net)`` to ``$(Format-Money $center020[0].Continuous2015To2020Net)``, and reduced drawdown from ``$('{0:N2}' -f $control020.ContinuousMaxDrawdownPercent)%`` to ``$('{0:N2}' -f $center020[0].ContinuousMaxDrawdownPercent)%``.")
$md.Add('')
$md.Add("The primary center nevertheless reported PF ``$('{0:N2}' -f $center020[0].ContinuousProfitFactor)`` against the frozen ``1.50`` floor. The stricter DI ``-8`` neighbor passed at both risk allocations, including ``$(Format-Money $strict020.Continuous2015To2020Net)`` and PF ``$('{0:N2}' -f $strict020.ContinuousProfitFactor)`` at ``0.20%``, but the contract required both nominated DI ``-10`` centers to pass. Replacing the center after seeing results would be threshold selection, so the family stops here.")
$md.Add('')
$md.Add('## Decision')
$md.Add('')
$md.Add('- Do not use post-2020 data to rescue or choose a different DI threshold.')
$md.Add('- Skip Model 4, annual restarts, cost stress, and Monte Carlo for this branch.')
$md.Add('- Do not alter the current historical best or frozen forward candidate.')
$md.Add('- Preserve the account contract, evidence identities, and real-account hard lock.')
$md.Add('')
$md.Add('## Evidence')
$md.Add('')
$md.Add('- `outputs/RC2_DI_REPAIR_PORTFOLIO_DISCOVERY_CONTRACT.md`')
$md.Add('- `outputs/RC2_DI_REPAIR_PORTFOLIO_DISCOVERY_MODEL1_RESULTS.csv`')
$md.Add('- `outputs/RC2_DI_REPAIR_PORTFOLIO_DISCOVERY_MODEL1_RUN.csv`')
$md.Add('- `outputs/RC2_DI_REPAIR_PORTFOLIO_DISCOVERY_DECISION.csv`')
$md | Set-Content -LiteralPath (Resolve-RepoPath $DecisionMarkdownPath) -Encoding ASCII

[pscustomobject]@{
   Status='REJECTED';Reports=$results.Count;Profiles=$decisionRows.Count;BaseGatePasses=@($decisionRows | Where-Object BaseGatePass -eq $true).Count
   FamilyPass=$familyPass;HoldoutRuns=0;Model4Runs=0;NewBest=$false
}
