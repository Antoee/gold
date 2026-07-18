param(
   [string]$ResultsPath = "outputs\TREND_LIQUIDITY_RECLAIM_DISCOVERY_MODEL1_RESULTS.csv",
   [string]$QueuePath = "outputs\TREND_LIQUIDITY_RECLAIM_DISCOVERY_MODEL1_QUEUE.csv",
   [string]$RunPath = "outputs\TREND_LIQUIDITY_RECLAIM_DISCOVERY_MODEL1_RUN.csv",
   [string]$CompileEvidencePath = "outputs\TREND_LIQUIDITY_RECLAIM_DISCOVERY_COMPILE_EVIDENCE.csv",
   [string]$DecisionCsvPath = "outputs\TREND_LIQUIDITY_RECLAIM_DISCOVERY_DECISION.csv",
   [string]$DecisionMarkdownPath = "outputs\TREND_LIQUIDITY_RECLAIM_DISCOVERY_DECISION.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$expectedSourceHash = '67167ACC0BFEA04357EE17195C30320342DEE0D566F2C94E01CC1BF521F26002'
$expectedBinaryHash = '4C994BED00F214361978D7585B4813FE22DCD0AEA4646235D049F91DBEC8226B'
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
if($results.Count -ne 28 -or $queue.Count -ne 28 -or $runs.Count -ne 28) {
   throw "Expected 28 results, queue rows, and canonical run rows."
}
if($compile.Count -ne 1 -or $compile[0].SourceSha256 -ne $expectedSourceHash -or
   $compile[0].BinarySha256 -ne $expectedBinaryHash -or $compile[0].Result -ne '0 errors, 0 warnings') {
   throw "Compile evidence is not clean or identity-matched."
}
if(@($results | Where-Object Status -ne 'PARSED').Count -gt 0 -or
   @($runs | Where-Object Status -ne 'REPORT_FOUND').Count -gt 0) {
   throw "Every discovery report must be identity-valid and parsed."
}
if(@($results | Where-Object { $_.To -gt '2020.12.31' }).Count -gt 0) { throw "Post-2020 data leaked into the decision." }
if(@($queue.SourceSha256 | Sort-Object -Unique).Count -ne 1 -or $queue[0].SourceSha256 -ne $expectedSourceHash) {
   throw "Unexpected source identity in the queue."
}
foreach($row in $results) {
   $q = @($queue | Where-Object QueueRank -eq $row.QueueRank)
   $run = @($runs | Where-Object QueueRank -eq $row.QueueRank)
   if($q.Count -ne 1 -or $run.Count -ne 1 -or $row.ProfileSha256 -ne $q[0].ProfileSha256 -or
      $row.SourceSha256 -ne $expectedSourceHash -or $run[0].PackageSourceSha256 -ne $expectedSourceHash) {
      throw "Identity mismatch at rank $($row.QueueRank)."
   }
}

$baseRows = [System.Collections.Generic.List[object]]::new()
foreach($group in ($results | Group-Object Candidate)) {
   if($group.Count -ne 4) { throw "Candidate $($group.Name) does not have four discovery windows." }
   $older = @($group.Group | Where-Object Window -eq 'older_2015_2018')[0]
   $y2019 = @($group.Group | Where-Object Window -eq 'repair_2019')[0]
   $y2020 = @($group.Group | Where-Object Window -eq 'repair_2020')[0]
   $continuous = @($group.Group | Where-Object Window -eq 'continuous_2015_2020')[0]
   $olderNet=[double]$older.NetProfit; $olderPf=[double]$older.ProfitFactor
   $net2019=[double]$y2019.NetProfit; $pf2019=[double]$y2019.ProfitFactor; $trades2019=[int]$y2019.TotalTrades
   $net2020=[double]$y2020.NetProfit; $pf2020=[double]$y2020.ProfitFactor; $trades2020=[int]$y2020.TotalTrades
   $net=[double]$continuous.NetProfit; $pf=[double]$continuous.ProfitFactor
   $payoff=[double]$continuous.ExpectedPayoff; $trades=[int]$continuous.TotalTrades
   $dd=[double]$continuous.MaxDrawdownPercent
   $returnToDd = if($dd -gt 0.0) { (100.0*$net/10000.0)/$dd } else { 0.0 }
   $pf2019Pass = ($trades2019 -eq 0 -and $net2019 -eq 0.0) -or $pf2019 -ge 1.00
   $pf2020Pass = ($trades2020 -eq 0 -and $net2020 -eq 0.0) -or $pf2020 -ge 1.00
   $basePass = $olderNet -gt 0.0 -and $olderPf -ge 1.05 -and
               $net2019 -ge 0.0 -and $net2020 -ge 0.0 -and $pf2019Pass -and $pf2020Pass -and
               $net -gt 0.0 -and $pf -ge 1.25 -and $payoff -gt 0.0 -and $trades -ge 60 -and
               $dd -le 2.00 -and $returnToDd -ge 1.50
   $failed = [System.Collections.Generic.List[string]]::new()
   if($olderNet -le 0.0){$failed.Add('older-net')};if($olderPf -lt 1.05){$failed.Add('older-pf')}
   if($net2019 -lt 0.0){$failed.Add('2019-net')};if(!$pf2019Pass){$failed.Add('2019-pf')}
   if($net2020 -lt 0.0){$failed.Add('2020-net')};if(!$pf2020Pass){$failed.Add('2020-pf')}
   if($net -le 0.0){$failed.Add('continuous-net')};if($pf -lt 1.25){$failed.Add('continuous-pf')}
   if($payoff -le 0.0){$failed.Add('payoff')};if($trades -lt 60){$failed.Add('trades')}
   if($dd -gt 2.00){$failed.Add('drawdown')};if($returnToDd -lt 1.50){$failed.Add('return-dd')}
   $baseRows.Add([pscustomobject]@{
      Candidate=$group.Name;Role=$continuous.Role;LiquidityLookbackBars=[int]$continuous.LiquidityLookbackBars
      MinimumBodyPercent=[double]$continuous.MinimumBodyPercent
      PostLossQuarantineDays=[int]$continuous.PostLossQuarantineDays
      Older2015To2018Net=[math]::Round($olderNet,2);OlderProfitFactor=[math]::Round($olderPf,2)
      Net2019=[math]::Round($net2019,2);PF2019=[math]::Round($pf2019,2)
      Net2020=[math]::Round($net2020,2);PF2020=[math]::Round($pf2020,2)
      Continuous2015To2020Net=[math]::Round($net,2);ContinuousProfitFactor=[math]::Round($pf,2)
      ContinuousExpectedPayoff=[math]::Round($payoff,2);ContinuousTrades=$trades
      ContinuousMaxDrawdownPercent=[math]::Round($dd,2);ContinuousReturnToDrawdown=[math]::Round($returnToDd,2)
      BaseGatePass=$basePass;FailedBaseGates=$failed -join ';'
   }) | Out-Null
}

$center=@($baseRows|Where-Object Candidate -eq 'tlr_center_q14')
$quarantinePass=@($baseRows|Where-Object{$_.Role -eq 'quarantine_neighbor' -and $_.BaseGatePass}).Count
$structuralPass=@($baseRows|Where-Object{$_.Role -eq 'structural_neighbor' -and $_.BaseGatePass}).Count
if($center.Count -ne 1){throw 'Frozen center is missing.'}
$familyPass=$center[0].BaseGatePass -and $quarantinePass -ge 1 -and $structuralPass -ge 1
$decisionRows=@($baseRows|Sort-Object Continuous2015To2020Net -Descending|ForEach-Object{
   [pscustomobject]@{Candidate=$_.Candidate;Role=$_.Role;LiquidityLookbackBars=$_.LiquidityLookbackBars
      MinimumBodyPercent=$_.MinimumBodyPercent;PostLossQuarantineDays=$_.PostLossQuarantineDays
      Older2015To2018Net=$_.Older2015To2018Net;OlderProfitFactor=$_.OlderProfitFactor
      Net2019=$_.Net2019;PF2019=$_.PF2019;Net2020=$_.Net2020;PF2020=$_.PF2020
      Continuous2015To2020Net=$_.Continuous2015To2020Net;ContinuousProfitFactor=$_.ContinuousProfitFactor
      ContinuousExpectedPayoff=$_.ContinuousExpectedPayoff;ContinuousTrades=$_.ContinuousTrades
      ContinuousMaxDrawdownPercent=$_.ContinuousMaxDrawdownPercent
      ContinuousReturnToDrawdown=$_.ContinuousReturnToDrawdown;BaseGatePass=$_.BaseGatePass
      FailedBaseGates=$_.FailedBaseGates;FamilyDiscoveryPass=$familyPass
      Decision=if($familyPass -and $_.BaseGatePass){'OPEN_FROZEN_HOLDOUT'}else{'REJECTED_NO_HOLDOUT_NO_MODEL4'}}
})
if($familyPass){throw 'The family passed; revise this rejection-only builder before use.'}
$decisionRows|Export-Csv -LiteralPath (Resolve-RepoPath $DecisionCsvPath) -NoTypeInformation -Encoding ASCII

$control=@($decisionRows|Where-Object Candidate -eq 'tlr_control_q0')[0]
$q07=@($decisionRows|Where-Object Candidate -eq 'tlr_q07')[0]
$md=[System.Collections.Generic.List[string]]::new()
$md.Add('# Trend-Liquidity Reclaim Discovery Decision');$md.Add('')
$md.Add("Decision date: $((Get-Date).ToString('yyyy-MM-dd'))");$md.Add('')
$md.Add('**Verdict: rejected during the frozen pre-2021 Model 1 screen. No post-2020 holdout or Model 4 configuration was opened, no new best was promoted, and the registered candidate remains unchanged.**');$md.Add('')
$md.Add('## Evidence Boundary');$md.Add('')
$md.Add("- Source SHA-256: ``$expectedSourceHash``");$md.Add("- Binary SHA-256: ``$expectedBinaryHash``")
$md.Add('- Compile: `0 errors, 0 warnings`');$md.Add('- Identity-valid reports: `28 / 28`')
$md.Add('- Profiles: `7`');$md.Add('- Latest data: `2020-12-31`');$md.Add('- Post-2020 runs: `0`')
$md.Add('- Model 4 runs: `0`');$md.Add('- Real-account trading: disabled');$md.Add('')
$md.Add('Three initial portable rows hit source-identity startup races. Only those exact frozen ranks were rerun; all passed, leaving one canonical identity-valid result per rank.');$md.Add('')
$md.Add('## Results');$md.Add('')
$md.Add('| Profile | Role | Lookback | Body | Quarantine | 2015-2018 / PF | 2019 / PF | 2020 / PF | Continuous / PF | Trades | DD | Return/DD | Failed gates |')
$md.Add('| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |')
foreach($row in $decisionRows){
   $md.Add("| ``$($row.Candidate)`` | $($row.Role) | ``$($row.LiquidityLookbackBars)`` | ``$($row.MinimumBodyPercent)%`` | ``$($row.PostLossQuarantineDays)d`` | ``$(Format-Money $row.Older2015To2018Net) / $('{0:N2}' -f $row.OlderProfitFactor)`` | ``$(Format-Money $row.Net2019) / $('{0:N2}' -f $row.PF2019)`` | ``$(Format-Money $row.Net2020) / $('{0:N2}' -f $row.PF2020)`` | ``$(Format-Money $row.Continuous2015To2020Net) / $('{0:N2}' -f $row.ContinuousProfitFactor)`` | ``$($row.ContinuousTrades)`` | ``$('{0:N2}' -f $row.ContinuousMaxDrawdownPercent)%`` | ``$('{0:N2}' -f $row.ContinuousReturnToDrawdown)`` | ``$($row.FailedBaseGates)`` |")
}
$md.Add('');$md.Add('## Interpretation');$md.Add('')
$md.Add("The no-quarantine control lost ``$(Format-Money $control.Continuous2015To2020Net)`` at PF ``$('{0:N2}' -f $control.ContinuousProfitFactor)``. The 14-day center lost ``$(Format-Money $center[0].Continuous2015To2020Net)`` at PF ``$('{0:N2}' -f $center[0].ContinuousProfitFactor)``. The least-bad 7-day neighbor still lost ``$(Format-Money $q07.Continuous2015To2020Net)`` at PF ``$('{0:N2}' -f $q07.ContinuousProfitFactor)``.")
$md.Add('')
$md.Add('Every row lost in 2015-2018 and continuously. Quarantine reduced some losses but did not create an edge, while body and lookback neighbors failed as well. The earlier high-PF session result therefore does not survive extraction into this clean date-independent mechanism; importing the old monolithic strategy would not be justified by transferable evidence.')
$md.Add('');$md.Add('## Decision');$md.Add('')
$md.Add('- Reject this trend-liquidity reclaim family without tuning it on recent data.')
$md.Add('- Skip holdout, Model 4, annual, cost, and Monte Carlo testing for this branch.')
$md.Add('- Do not merge the old session engine into RC2 based on its historical headline.')
$md.Add('- Preserve the forward identity, account contract, evidence logs, and hard real-account lock.')
$md.Add('');$md.Add('## Evidence');$md.Add('')
$md.Add('- `outputs/TREND_LIQUIDITY_RECLAIM_DISCOVERY_CONTRACT.md`')
$md.Add('- `outputs/TREND_LIQUIDITY_RECLAIM_DISCOVERY_MODEL1_RESULTS.csv`')
$md.Add('- `outputs/TREND_LIQUIDITY_RECLAIM_DISCOVERY_MODEL1_RUN.csv`')
$md.Add('- `outputs/TREND_LIQUIDITY_RECLAIM_DISCOVERY_DECISION.csv`')
$md|Set-Content -LiteralPath (Resolve-RepoPath $DecisionMarkdownPath) -Encoding ASCII

[pscustomobject]@{Status='REJECTED';Reports=$results.Count;Profiles=$decisionRows.Count;BaseGatePasses=@($decisionRows|Where-Object BaseGatePass -eq $true).Count;FamilyPass=$familyPass;HoldoutRuns=0;Model4Runs=0;NewBest=$false}
