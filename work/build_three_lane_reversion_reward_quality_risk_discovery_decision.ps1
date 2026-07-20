param(
   [string]$ResultsPath='outputs\THREE_LANE_REVERSION_REWARD_QUALITY_RISK_DISCOVERY_MODEL1_RESULTS.csv',
   [string]$ManifestPath='outputs\THREE_LANE_REVERSION_REWARD_QUALITY_RISK_DISCOVERY_MODEL1_MANIFEST.csv',
   [string]$RunPath='outputs\THREE_LANE_REVERSION_REWARD_QUALITY_RISK_DISCOVERY_RUN_ATTESTATION.csv',
   [string]$CompilePath='outputs\THREE_LANE_REVERSION_REWARD_QUALITY_RISK_COMPILE_AUDIT.csv',
   [string]$DecisionCsvPath='outputs\THREE_LANE_REVERSION_REWARD_QUALITY_RISK_DISCOVERY_DECISION.csv',
   [string]$DecisionMarkdownPath='outputs\THREE_LANE_REVERSION_REWARD_QUALITY_RISK_DISCOVERY_DECISION.md'
)

Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$expectedSource='A300713711328CE221447E452B889C0A2F9E449E2BF721BE7E49E0A354A4C416'
$expectedBinary='65745C6F0F6651AA0050B8DEDDB76B4746DC06C2956CB1AD771B06103F713FA4'
function Resolve-RepoPath([string]$Path){if([IO.Path]::IsPathRooted($Path)){return $Path};return Join-Path $repo $Path}
function Money([double]$Value){if($Value -ge 0){return ('+${0:N2}' -f $Value)};return ('-${0:N2}' -f [math]::Abs($Value))}

$results=@(Import-Csv -LiteralPath (Resolve-RepoPath $ResultsPath))
$manifest=@(Import-Csv -LiteralPath (Resolve-RepoPath $ManifestPath))
$runs=@(Import-Csv -LiteralPath (Resolve-RepoPath $RunPath))
$compile=@(Import-Csv -LiteralPath (Resolve-RepoPath $CompilePath))
if($results.Count -ne 21 -or $manifest.Count -ne 21 -or $runs.Count -ne 21){throw 'Expected 21 results, manifest rows, and canonical run rows.'}
if(@($results|Where-Object Status -ne 'PARSED').Count -gt 0 -or @($runs|Where-Object Status -ne 'REPORT_FOUND').Count -gt 0){throw 'Evidence is incomplete.'}
if(@($results|Where-Object {$_.To -gt '2020.12.31'}).Count -gt 0){throw 'Post-2020 data leaked into the decision.'}
if($compile.Count -ne 1 -or $compile[0].Status -ne 'COMPILE_PASS' -or $compile[0].SourceSha256 -ne $expectedSource -or $compile[0].PortableBinarySha256 -ne $expectedBinary -or [int]$compile[0].CompileErrors -ne 0 -or [int]$compile[0].CompileWarnings -ne 0){throw 'Compile evidence mismatch.'}
foreach($row in $results){
   $m=@($manifest|Where-Object QueueRank -eq $row.QueueRank)
   $run=@($runs|Where-Object QueueRank -eq $row.QueueRank)
   if($m.Count -ne 1 -or $run.Count -ne 1 -or $row.ProfileSha256 -ne $m[0].ProfileSha256 -or $row.SourceSha256 -ne $expectedSource -or $run[0].PackageSourceSha256 -ne $expectedSource -or $run[0].PortableBinarySha256 -ne $expectedBinary){throw "Identity mismatch at rank $($row.QueueRank)."}
}

$base=[Collections.Generic.List[object]]::new()
foreach($group in ($results|Group-Object Candidate)){
   $older=@($group.Group|Where-Object Window -eq 'older_2015_2018')
   $recent=@($group.Group|Where-Object Window -eq 'discovery_2019_2020')
   $continuous=@($group.Group|Where-Object Window -eq 'continuous_2015_2020')
   if($group.Count -ne 3 -or $older.Count -ne 1 -or $recent.Count -ne 1 -or $continuous.Count -ne 1){throw "Unexpected windows for $($group.Name)."}
   $c=$continuous[0]
   $base.Add([pscustomobject]@{
      Candidate=$group.Name;Role=$c.Role;OlderNet=[double]$older[0].NetProfit;RecentNet=[double]$recent[0].NetProfit
      ContinuousNet=[double]$c.NetProfit;Cagr=[double]$c.CagrPercent;PF=[double]$c.ProfitFactor
      Trades=[int]$c.TotalTrades;DD=[double]$c.MaxDrawdownPercent;Recovery=[double]$c.RecoveryFactor
      ReturnDD=if([double]$c.MaxDrawdownPercent -gt 0){[double]$c.TotalReturnPercent/[double]$c.MaxDrawdownPercent}else{0}
   })|Out-Null
}
$control=@($base|Where-Object Candidate -eq 'rqri_control')
if($control.Count -ne 1){throw 'Exact control is missing.'}
$control=$control[0]
$neighbors=@('rqri_rr135','rqri_rr165','rqri_risk065','rqri_risk075')
$rows=foreach($row in $base){
   $olderRetention=if($control.OlderNet -ne 0){$row.OlderNet/$control.OlderNet}else{0}
   $recentRetention=if($control.RecentNet -ne 0){$row.RecentNet/$control.RecentNet}else{0}
   $netGrowth=if($control.ContinuousNet -ne 0){$row.ContinuousNet/$control.ContinuousNet-1}else{0}
   $cagrGrowth=$row.Cagr-$control.Cagr
   $positiveEras=$row.OlderNet -gt 0 -and $row.RecentNet -gt 0
   $retainsEras=$olderRetention -ge 0.98 -and $recentRetention -ge 0.98
   $sameTrades=$row.Trades -eq $control.Trades
   $efficiency=$row.PF -ge $control.PF -and $row.Recovery -ge $control.Recovery -and $row.ReturnDD -ge $control.ReturnDD
   $ddPass=$row.DD -le 1.35 -and $row.DD -le $control.DD+0.15
   $growthRequirement=if($row.Candidate -eq 'rqri_center150_070'){$netGrowth -ge 0.05 -and $cagrGrowth -ge 0.10}elseif($neighbors -contains $row.Candidate){$netGrowth -ge 0.03 -and $cagrGrowth -ge 0.05}else{$false}
   $gate=$row.Candidate -ne 'rqri_control' -and $row.Candidate -ne 'rqri_body070' -and $positiveEras -and $retainsEras -and $sameTrades -and $efficiency -and $ddPass -and $growthRequirement
   [pscustomobject]@{
      Candidate=$row.Candidate;Role=$row.Role;OlderNet=[math]::Round($row.OlderNet,2);OlderRetentionPercent=[math]::Round(100*$olderRetention,2)
      RecentNet=[math]::Round($row.RecentNet,2);RecentRetentionPercent=[math]::Round(100*$recentRetention,2)
      ContinuousNet=[math]::Round($row.ContinuousNet,2);NetGrowthPercent=[math]::Round(100*$netGrowth,2)
      CagrPercent=[math]::Round($row.Cagr,2);CagrGrowthPoints=[math]::Round($cagrGrowth,2)
      ProfitFactor=[math]::Round($row.PF,2);Trades=$row.Trades;MaxDrawdownPercent=[math]::Round($row.DD,2)
      RecoveryFactor=[math]::Round($row.Recovery,4);ReturnDrawdownRatio=[math]::Round($row.ReturnDD,4)
      PositiveEras=$positiveEras;RetainsBothEras=$retainsEras;SameTrades=$sameTrades;EfficiencyNoWorse=$efficiency
      DrawdownPass=$ddPass;GrowthPass=$growthRequirement;DiscoveryGatePass=$gate
      Decision=if($gate){'OPEN_FROZEN_HOLDOUT'}else{'REJECTED_NO_HOLDOUT_NO_MODEL4'}
   }
}
$ordered=@($rows|Sort-Object ContinuousNet -Descending)
$neighborPasses=@($ordered|Where-Object {$neighbors -contains $_.Candidate -and $_.DiscoveryGatePass}).Count
$center=@($ordered|Where-Object Candidate -eq 'rqri_center150_070')
if($ordered.Count -ne 7 -or $center.Count -ne 1 -or $center[0].DiscoveryGatePass -or $neighborPasses -ne 0){throw 'A row passed; revise this rejection-only publication.'}
$ordered|Export-Csv -LiteralPath (Resolve-RepoPath $DecisionCsvPath) -NoTypeInformation -Encoding ASCII

$md=[Collections.Generic.List[string]]::new()
$md.Add('# Reversion Reward-Quality Risk Discovery Decision');$md.Add('');$md.Add('**Decision: rejected in frozen pre-2021 discovery. No holdout, Model 4, promotion, forward change, or live approval was opened.**');$md.Add('')
$md.Add('- Research source SHA-256: `'+$expectedSource+'`');$md.Add('- Exact four-worker EX5 SHA-256: `'+$expectedBinary+'`');$md.Add('- Reports: `21 / 21` parsed and identity-valid after two unchanged export recoveries.');$md.Add('- Data: 2015-2020 Model 1 only; no post-2020 data was opened.');$md.Add('- Risk: existing body-based `0.15`-lot cap retained; experimental strong risk `0.65%-0.75%`; portfolio cap and minimum-lot refusal unchanged.');$md.Add('')
$md.Add('| Candidate | Role | 2015-18 | 2019-20 | Continuous | Change | CAGR | PF | Trades | DD | Recovery | Decision |');$md.Add('|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|')
foreach($row in $ordered){$md.Add("| ``$($row.Candidate)`` | ``$($row.Role)`` | ``$(Money $row.OlderNet)`` | ``$(Money $row.RecentNet)`` | ``$(Money $row.ContinuousNet)`` | ``$('{0:N2}' -f $row.NetGrowthPercent)%`` | ``$('{0:N2}' -f $row.CagrPercent)%`` | ``$('{0:N2}' -f $row.ProfitFactor)`` | ``$($row.Trades)`` | ``$('{0:N2}' -f $row.MaxDrawdownPercent)%`` | ``$('{0:N2}' -f $row.RecoveryFactor)`` | rejected |")}
$md.Add('');$md.Add('The exact control remained best at `+$1,379.93`, `2.18%/yr` CAGR, PF `1.88`, and `1.05%` drawdown. Every strong-risk or reward-quality row returned the same `+$1,369.88`, `2.16%/yr` CAGR, PF `1.87`, and `1.06%` drawdown. Recent-era profit retention was only `95.76%`; recovery and return/drawdown also declined. The fixed RR thresholds did not discriminate among the body-qualified trades, so the interaction supplied no stable gain.');$md.Add('')
$md.Add('- Reject this reward-quality strong-risk interaction at the preregistered thresholds.');$md.Add('- Do not tune thresholds against post-2020 data or spend real-tick runs on this failed branch.');$md.Add('- Preserve the historical leader and invalid forward registration unchanged.')
$md|Set-Content -LiteralPath (Resolve-RepoPath $DecisionMarkdownPath) -Encoding ASCII
[pscustomobject]@{Status='REJECTED';Reports=21;Candidates=7;CenterGatePass=$false;NeighborPasses=$neighborPasses;HoldoutRuns=0;Model4Runs=0;NewBest=$false}
