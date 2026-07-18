param(
   [string]$ResultsPath = "outputs\REVERSION_SHOCK_GUARD_PORTFOLIO_DISCOVERY_MODEL1_RESULTS.csv",
   [string]$QueuePath = "outputs\REVERSION_SHOCK_GUARD_PORTFOLIO_DISCOVERY_MODEL1_QUEUE.csv",
   [string]$RunPath = "outputs\REVERSION_SHOCK_GUARD_PORTFOLIO_DISCOVERY_MODEL1_RUN.csv",
   [string]$CompileEvidencePath = "outputs\REVERSION_SHOCK_GUARD_PORTFOLIO_DISCOVERY_COMPILE_EVIDENCE.csv",
   [string]$DecisionCsvPath = "outputs\REVERSION_SHOCK_GUARD_PORTFOLIO_DISCOVERY_DECISION.csv",
   [string]$DecisionMarkdownPath = "outputs\REVERSION_SHOCK_GUARD_PORTFOLIO_DISCOVERY_DECISION.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$expectedSourceHash = 'A681A1371E3DC2A07234C373F9E4574CC16F0E3C96C9C48E2B703962D2A5B8A9'
$expectedBinaryHash = '7B6386477A6205F77AB91484A585E27B88517B3BE288F700AC911A5B7C8BFABB'
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
$compile = @(Import-Csv -LiteralPath (Resolve-RepoPath $CompileEvidencePath))
if($results.Count -ne 56 -or $queue.Count -ne 56 -or $runs.Count -ne 56) {
   throw "Expected 56 results, queue rows, and canonical run rows."
}
if($compile.Count -ne 1 -or $compile[0].SourceSha256 -ne $expectedSourceHash -or
   $compile[0].BinarySha256 -ne $expectedBinaryHash -or $compile[0].Result -ne '0 errors, 0 warnings') {
   throw "Compile evidence does not match the frozen source and binary."
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
   $basePass = $olderNet -gt 0.0 -and $net2019 -ge 0.0 -and $net2020 -ge 0.0 -and
               $pf2019 -ge 1.00 -and $pf2020 -ge 1.00 -and $net2019 + $net2020 -gt 0.0 -and
               $net -gt 0.0 -and $pf -ge 1.50 -and $payoff -gt 0.0 -and $trades -ge 190 -and
               $dd -le 3.00 -and $returnToDd -ge 2.00
   $failedGates = [System.Collections.Generic.List[string]]::new()
   if($olderNet -le 0.0) { $failedGates.Add('older-net') }
   if($net2019 -lt 0.0) { $failedGates.Add('2019-net') }
   if($pf2019 -lt 1.00) { $failedGates.Add('2019-pf') }
   if($net2020 -lt 0.0) { $failedGates.Add('2020-net') }
   if($pf2020 -lt 1.00) { $failedGates.Add('2020-pf') }
   if($net2019 + $net2020 -le 0.0) { $failedGates.Add('repair-sum') }
   if($net -le 0.0) { $failedGates.Add('continuous-net') }
   if($pf -lt 1.50) { $failedGates.Add('continuous-pf') }
   if($payoff -le 0.0) { $failedGates.Add('payoff') }
   if($trades -lt 190) { $failedGates.Add('trades') }
   if($dd -gt 3.00) { $failedGates.Add('drawdown') }
   if($returnToDd -lt 2.00) { $failedGates.Add('return-dd') }
   $rows.Add([pscustomobject]@{
      Candidate=$group.Name;MomentumRiskPercent=[double]$continuous[0].MORiskPercent
      DIThreshold=[double]$continuous[0].RVMinimumDIEdge
      BodyGate=[System.Convert]::ToBoolean($continuous[0].RVUseMinimumBodyGate)
      MinimumBodyPercent=[double]$continuous[0].RVMinimumBodyPercent
      Older2015To2018Net=[math]::Round($olderNet,2);Net2019=[math]::Round($net2019,2)
      PF2019=[math]::Round($pf2019,2);Net2020=[math]::Round($net2020,2);PF2020=[math]::Round($pf2020,2)
      Repair2019To2020Net=[math]::Round($net2019+$net2020,2);Continuous2015To2020Net=[math]::Round($net,2)
      ContinuousProfitFactor=[math]::Round($pf,2);ContinuousExpectedPayoff=[math]::Round($payoff,2)
      ContinuousTrades=$trades;ContinuousMaxDrawdownPercent=[math]::Round($dd,2)
      ContinuousReturnToDrawdown=[math]::Round($returnToDd,2);BaseGatePass=$basePass
      FailedBaseGates=$failedGates -join ';'
   }) | Out-Null
}

$center015 = @($rows | Where-Object Candidate -eq 'rsg_mo015_combo25')
$center020 = @($rows | Where-Object Candidate -eq 'rsg_mo020_combo25')
$adjacent015 = @($rows | Where-Object { $_.MomentumRiskPercent -eq 0.15 -and $_.Candidate -match '_combo(20|30)$' -and $_.BaseGatePass }).Count
$adjacent020 = @($rows | Where-Object { $_.MomentumRiskPercent -eq 0.20 -and $_.Candidate -match '_combo(20|30)$' -and $_.BaseGatePass }).Count
if($center015.Count -ne 1 -or $center020.Count -ne 1) { throw "Shock-guard centers missing." }
$familyPass = $center015[0].BaseGatePass -and $center020[0].BaseGatePass -and $adjacent015 -ge 1 -and $adjacent020 -ge 1
$decisionRows = @($rows | Sort-Object MomentumRiskPercent,Candidate | ForEach-Object {
   [pscustomobject]@{
      Candidate=$_.Candidate;MomentumRiskPercent=$_.MomentumRiskPercent;DIThreshold=$_.DIThreshold
      BodyGate=$_.BodyGate;MinimumBodyPercent=$_.MinimumBodyPercent
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

$control015 = @($decisionRows | Where-Object Candidate -eq 'rsg_mo015_control')[0]
$control020 = @($decisionRows | Where-Object Candidate -eq 'rsg_mo020_control')[0]
$strict015 = @($decisionRows | Where-Object Candidate -eq 'rsg_mo015_combo25_di08')[0]
$strict020 = @($decisionRows | Where-Object Candidate -eq 'rsg_mo020_combo25_di08')[0]
$md = [System.Collections.Generic.List[string]]::new()
$md.Add('# Reversion Shock-Guard Portfolio Discovery Decision')
$md.Add('')
$md.Add("Decision date: $((Get-Date).ToString('yyyy-MM-dd'))")
$md.Add('')
$md.Add('**Verdict: rejected at the frozen pre-2021 Model 1 gate. No post-2020 holdout or Model 4 configuration was opened, no new best was promoted, and the registered candidate remains unchanged.**')
$md.Add('')
$md.Add('## Evidence Boundary')
$md.Add('')
$md.Add("- Research source SHA-256: ``$expectedSourceHash``")
$md.Add("- Compiled binary SHA-256: ``$expectedBinaryHash``")
$md.Add('- Compile result: `0 errors, 0 warnings`')
$md.Add('- Identity-valid reports parsed: `56 / 56`')
$md.Add('- Profiles: `14`')
$md.Add('- Latest data used: `2020-12-31`')
$md.Add('- Post-2020 holdout runs: `0`')
$md.Add('- Model 4 runs: `0`')
$md.Add('- Real-account trading: disabled')
$md.Add('')
$md.Add('Five initial portable rows hit source-identity startup races. Only those exact frozen ranks were rerun; all five passed, and the canonical run contains one valid result per queue rank.')
$md.Add('')
$md.Add('## Results')
$md.Add('')
$md.Add('| Profile | MO risk | DI | Body gate/min | 2015-2018 | 2019 / PF | 2020 / PF | 2019+2020 | Continuous / PF | Trades | DD | Return/DD | Base gate | Failed gates |')
$md.Add('| --- | ---: | ---: | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- |')
foreach($row in $decisionRows) {
   $body = if($row.BodyGate) { "$($row.MinimumBodyPercent)%" } else { 'off' }
   $md.Add("| ``$($row.Candidate)`` | ``$('{0:N2}' -f $row.MomentumRiskPercent)%`` | ``$($row.DIThreshold)`` | ``$body`` | ``$(Format-Money $row.Older2015To2018Net)`` | ``$(Format-Money $row.Net2019) / $('{0:N2}' -f $row.PF2019)`` | ``$(Format-Money $row.Net2020) / $('{0:N2}' -f $row.PF2020)`` | ``$(Format-Money $row.Repair2019To2020Net)`` | ``$(Format-Money $row.Continuous2015To2020Net) / $('{0:N2}' -f $row.ContinuousProfitFactor)`` | ``$($row.ContinuousTrades)`` | ``$('{0:N2}' -f $row.ContinuousMaxDrawdownPercent)%`` | ``$('{0:N2}' -f $row.ContinuousReturnToDrawdown)`` | ``$($row.BaseGatePass)`` | ``$($row.FailedBaseGates)`` |")
}
$md.Add('')
$md.Add('## Interpretation')
$md.Add('')
$md.Add("The mechanism repaired the targeted 2020 weakness. At ``0.15%`` momentum risk, the nominated body-25 center changed 2020 from ``$(Format-Money $control015.Net2020)`` to ``$(Format-Money $center015[0].Net2020)``. At ``0.20%``, it changed 2020 from ``$(Format-Money $control020.Net2020)`` to ``$(Format-Money $center020[0].Net2020)``.")
$md.Add('')
$md.Add("It did not repair both weak years. The ``0.15%`` center still returned ``$(Format-Money $center015[0].Net2019)`` with PF ``$('{0:N2}' -f $center015[0].PF2019)`` in 2019. The ``0.20%`` center returned ``$(Format-Money $center020[0].Net2019)`` with PF ``$('{0:N2}' -f $center020[0].PF2019)``, and its continuous PF was ``$('{0:N2}' -f $center020[0].ContinuousProfitFactor)`` against the frozen ``1.50`` floor.")
$md.Add('')
$md.Add("The stricter DI ``-8`` rows were the only two base-gate passes: ``$(Format-Money $strict015.Continuous2015To2020Net)`` at ``0.15%`` and ``$(Format-Money $strict020.Continuous2015To2020Net)`` at ``0.20%``. The contract explicitly required both nominated DI ``-10`` centers plus body-threshold neighbors. Substituting the isolated stricter-DI rows after seeing results would be threshold selection, so the family stops here.")
$md.Add('')
$md.Add('## Decision')
$md.Add('')
$md.Add('- Do not use post-2020 data to rescue or choose another threshold.')
$md.Add('- Skip Model 4, annual restarts, cost stress, and Monte Carlo for this branch.')
$md.Add('- Do not alter the current historical best or frozen forward candidate.')
$md.Add('- Preserve the account contract, evidence identities, and real-account hard lock.')
$md.Add('')
$md.Add('## Evidence')
$md.Add('')
$md.Add('- `outputs/REVERSION_SHOCK_GUARD_PORTFOLIO_DISCOVERY_CONTRACT.md`')
$md.Add('- `outputs/REVERSION_SHOCK_GUARD_PORTFOLIO_DISCOVERY_COMPILE_EVIDENCE.csv`')
$md.Add('- `outputs/REVERSION_SHOCK_GUARD_PORTFOLIO_DISCOVERY_MODEL1_RESULTS.csv`')
$md.Add('- `outputs/REVERSION_SHOCK_GUARD_PORTFOLIO_DISCOVERY_MODEL1_RUN.csv`')
$md.Add('- `outputs/REVERSION_SHOCK_GUARD_PORTFOLIO_DISCOVERY_DECISION.csv`')
$md | Set-Content -LiteralPath (Resolve-RepoPath $DecisionMarkdownPath) -Encoding ASCII

[pscustomobject]@{
   Status='REJECTED';Reports=$results.Count;Profiles=$decisionRows.Count
   BaseGatePasses=@($decisionRows | Where-Object BaseGatePass -eq $true).Count
   FamilyPass=$familyPass;HoldoutRuns=0;Model4Runs=0;NewBest=$false
}
