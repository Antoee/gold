param(
   [string]$ResultsPath='outputs\THREE_LANE_REVERSION_SOLO_STRONG_SIGNAL_LOT_CAP_DISCOVERY_MODEL1_RESULTS.csv',
   [string]$ManifestPath='outputs\THREE_LANE_REVERSION_SOLO_STRONG_SIGNAL_LOT_CAP_DISCOVERY_MODEL1_MANIFEST.csv',
   [string]$RunPath='outputs\THREE_LANE_REVERSION_SOLO_STRONG_SIGNAL_LOT_CAP_DISCOVERY_RUN_ATTESTATION.csv',
   [string]$CompilePath='outputs\THREE_LANE_REVERSION_SOLO_STRONG_SIGNAL_LOT_CAP_COMPILE_AUDIT.csv',
   [string]$DecisionCsvPath='outputs\THREE_LANE_REVERSION_SOLO_STRONG_SIGNAL_LOT_CAP_DISCOVERY_DECISION.csv',
   [string]$DecisionMarkdownPath='outputs\THREE_LANE_REVERSION_SOLO_STRONG_SIGNAL_LOT_CAP_DISCOVERY_DECISION.md'
)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$repo=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$expectedSource='726BCABFA64C25FA3D22E78B41AB4868EA8D5235609294F7ED68DC3DB9088EEE'
$expectedBinary='712BA114BB0589E34AC32D1A487A958CB6BAD0C4CEC3417F03400119A99EBFC8'
function Resolve-RepoPath([string]$Path){if([IO.Path]::IsPathRooted($Path)){return $Path};return Join-Path $repo $Path}
function Money([double]$Value){if($Value-ge0){return ('+${0:N2}'-f$Value)};return ('-${0:N2}'-f[math]::Abs($Value))}

$results=@(Import-Csv (Resolve-RepoPath $ResultsPath))
$manifest=@(Import-Csv (Resolve-RepoPath $ManifestPath))
$runs=@(Import-Csv (Resolve-RepoPath $RunPath))
$compile=@(Import-Csv (Resolve-RepoPath $CompilePath))
if($results.Count-ne15-or$manifest.Count-ne15-or$runs.Count-ne15){throw 'Expected 15 results, manifest rows, and canonical runs.'}
if(@($results|Where-Object Status -ne PARSED).Count-or@($runs|Where-Object Status -ne REPORT_FOUND).Count){throw 'Evidence is incomplete.'}
if(@($results|Where-Object{$_.To-gt'2020.12.31'}).Count){throw 'Post-2020 data leaked into discovery.'}
if($compile.Count-ne1-or$compile[0].Status-ne'COMPILE_PASS'-or$compile[0].SourceSha256-ne$expectedSource-or$compile[0].PortableBinarySha256-ne$expectedBinary-or[int]$compile[0].CompileErrors-ne0-or[int]$compile[0].CompileWarnings-ne0){throw 'Compile identity mismatch.'}
foreach($row in $results){
   $m=@($manifest|Where-Object QueueRank -eq $row.QueueRank)
   $run=@($runs|Where-Object QueueRank -eq $row.QueueRank)
   if($m.Count-ne1-or$run.Count-ne1-or$row.ProfileSha256-ne$m[0].ProfileSha256-or$row.SourceSha256-ne$expectedSource-or$run[0].PackageSourceSha256-ne$expectedSource-or$run[0].PortableBinarySha256-ne$expectedBinary){throw "Identity mismatch at rank $($row.QueueRank)."}
}

$base=@()
foreach($group in ($results|Group-Object Candidate)){
   $older=@($group.Group|Where-Object Window -eq older_2015_2018)
   $recent=@($group.Group|Where-Object Window -eq discovery_2019_2020)
   $continuous=@($group.Group|Where-Object Window -eq continuous_2015_2020)
   if($group.Count-ne3-or$older.Count-ne1-or$recent.Count-ne1-or$continuous.Count-ne1){throw "Window mismatch for $($group.Name)."}
   $x=$continuous[0]
   $base+=[pscustomobject]@{
      Candidate=$group.Name;Role=$x.Role;Enabled=[bool]::Parse($x.FeatureEnabled);Cap=[double]$x.SoloStrongSignalMaximumPositionLots
      Older=[double]$older[0].NetProfit;Recent=[double]$recent[0].NetProfit;Net=[double]$x.NetProfit
      Cagr=[double]$x.CagrPercent;PF=[double]$x.ProfitFactor;Trades=[int]$x.TotalTrades
      DD=[double]$x.MaxDrawdownPercent;Recovery=[double]$x.RecoveryFactor
      ReturnDD=if([double]$x.MaxDrawdownPercent-gt0){[double]$x.TotalReturnPercent/[double]$x.MaxDrawdownPercent}else{0}
   }
}
$control=@($base|Where-Object Candidate -eq rvsolo_control015)
if($control.Count-ne1){throw 'Exact leader control is missing.'}
$control=$control[0]
$rows=foreach($row in $base){
   $olderGrowth=$row.Older/$control.Older-1
   $recentGrowth=$row.Recent/$control.Recent-1
   $netGrowth=$row.Net/$control.Net-1
   $cagrGrowth=$row.Cagr-$control.Cagr
   $positive=$row.Older-gt0-and$row.Recent-gt0-and$row.Net-gt0
   $exactTrades=$row.Trades-eq$control.Trades
   $drawdown=$row.DD-le1.25-and$row.DD-le$control.DD+.10
   $changed=[math]::Abs($row.Net-$control.Net)-gt.01
   $centerGate=$row.Candidate-eq'rvsolo_center018'-and$row.Enabled-and$positive-and$olderGrowth-ge.03-and$recentGrowth-ge.03-and$netGrowth-ge.045-and$cagrGrowth-ge.08-and$row.PF-ge$control.PF-and$row.Recovery-ge$control.Recovery-and$row.ReturnDD-ge$control.ReturnDD-and$exactTrades-and$drawdown-and$changed
   $supportGate=$row.Candidate-in@('rvsolo_low017','rvsolo_high019')-and$row.Enabled-and$positive-and$olderGrowth-gt0-and$recentGrowth-gt0-and$netGrowth-ge.03-and$cagrGrowth-ge.05-and$row.PF-ge.98*$control.PF-and$row.Recovery-ge.98*$control.Recovery-and$row.ReturnDD-ge.98*$control.ReturnDD-and$exactTrades-and$drawdown-and$changed
   [pscustomobject]@{
      Candidate=$row.Candidate;Role=$row.Role;FeatureEnabled=$row.Enabled;SoloLotCap=$row.Cap
      OlderNet=[math]::Round($row.Older,2);OlderGrowthPercent=[math]::Round(100*$olderGrowth,2)
      RecentNet=[math]::Round($row.Recent,2);RecentGrowthPercent=[math]::Round(100*$recentGrowth,2)
      ContinuousNet=[math]::Round($row.Net,2);NetGrowthPercent=[math]::Round(100*$netGrowth,2)
      CagrPercent=[math]::Round($row.Cagr,2);CagrGrowthPoints=[math]::Round($cagrGrowth,2)
      ProfitFactor=[math]::Round($row.PF,2);Trades=$row.Trades;MaxDrawdownPercent=[math]::Round($row.DD,2)
      RecoveryFactor=[math]::Round($row.Recovery,4);ReturnDrawdownRatio=[math]::Round($row.ReturnDD,4)
      PositiveAllWindows=$positive;ExactTradeCount=$exactTrades;DrawdownPass=$drawdown
      CenterGatePass=$centerGate;NeighborSupportPass=$supportGate
   }
}
$center=@($rows|Where-Object Candidate -eq rvsolo_center018)
$support=@($rows|Where-Object NeighborSupportPass).Count
$open=$center.Count-eq1-and$center[0].CenterGatePass-and$support-ge1
$decisionRows=$rows|Sort-Object SoloLotCap,FeatureEnabled|ForEach-Object{$_|Add-Member -NotePropertyName Decision -NotePropertyValue $(if($open-and$_.Candidate-eq'rvsolo_center018'){'OPEN_FROZEN_POST2020_GATE'}else{'REJECTED_OR_CONTROL'}) -PassThru}
$decisionRows|Export-Csv (Resolve-RepoPath $DecisionCsvPath) -NoTypeInformation -Encoding ASCII

$md=[Collections.Generic.List[string]]::new()
$md.Add('# Portfolio-Solo Strong Reversion Lot-Cap Discovery Decision')
$md.Add('')
$md.Add($(if($open){'**Decision: pre-2021 discovery passed. Open only the exact 0.18 center in a separately frozen post-2020 gate.**'}else{'**Decision: rejected in frozen pre-2021 discovery. No post-2020 test, Model 4 run, promotion, forward change, or live approval was opened.**'}))
$md.Add('')
$md.Add("- Research source SHA-256: ``$expectedSource``")
$md.Add("- Four-worker EX5 SHA-256: ``$expectedBinary``")
$md.Add('- Reports: `15 / 15` parsed and identity-valid after one unchanged export recovery.')
$md.Add('- Data: 2015-2020 Model 1 only; newer data remained unopened for this exact code rule.')
$md.Add('')
$md.Add('| Candidate | Solo cap | 2015-18 | Change | 2019-20 | Change | Continuous | Change | CAGR | PF | Trades | DD | Recovery | Gate |')
$md.Add('|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|')
foreach($row in $decisionRows){
   $gate=$row.CenterGatePass-or$row.NeighborSupportPass
   $md.Add("| ``$($row.Candidate)`` | ``$('{0:N2}'-f$row.SoloLotCap)`` | ``$(Money $row.OlderNet)`` | ``$('{0:N2}'-f$row.OlderGrowthPercent)%`` | ``$(Money $row.RecentNet)`` | ``$('{0:N2}'-f$row.RecentGrowthPercent)%`` | ``$(Money $row.ContinuousNet)`` | ``$('{0:N2}'-f$row.NetGrowthPercent)%`` | ``$('{0:N2}'-f$row.CagrPercent)%`` | ``$('{0:N2}'-f$row.ProfitFactor)`` | ``$($row.Trades)`` | ``$('{0:N2}'-f$row.MaxDrawdownPercent)%`` | ``$('{0:N2}'-f$row.RecoveryFactor)`` | ``$(if($gate){'pass'}else{'fail/control'})`` |")
}
$md.Add('')
$md.Add($(if($open){"The fixed center passed with $support preregistered adjacent support row(s). This only opens a separate post-2020 historical validation; it is not a promotion."}else{'The fixed center and its neighborhood did not satisfy the frozen broad-era gate. The lot cap is not moved after observation.'}))
$md.Add('')
$md.Add('- The published leader, frozen forward candidate, invalid $100,000 demo registration, and real-account lock remain unchanged.')
$md|Set-Content (Resolve-RepoPath $DecisionMarkdownPath) -Encoding ASCII
[pscustomobject]@{Status=if($open){'OPEN_FROZEN_POST2020_GATE'}else{'REJECTED'};Reports=15;Candidates=5;CenterPass=$center[0].CenterGatePass;AdjacentPasses=$support;Post2020Opened=$open;Model4Runs=0;NewBest=$false}
