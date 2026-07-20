param(
   [string]$ResultsPath='outputs\THREE_LANE_REVERSION_RETRACEMENT_ENTRY_DISCOVERY_MODEL1_RESULTS.csv',
   [string]$ManifestPath='outputs\THREE_LANE_REVERSION_RETRACEMENT_ENTRY_DISCOVERY_MODEL1_MANIFEST.csv',
   [string]$RunPath='outputs\THREE_LANE_REVERSION_RETRACEMENT_ENTRY_DISCOVERY_RUN_ATTESTATION.csv',
   [string]$CompilePath='outputs\THREE_LANE_REVERSION_RETRACEMENT_ENTRY_COMPILE_AUDIT.csv',
   [string]$DecisionCsvPath='outputs\THREE_LANE_REVERSION_RETRACEMENT_ENTRY_DISCOVERY_DECISION.csv',
   [string]$DecisionMarkdownPath='outputs\THREE_LANE_REVERSION_RETRACEMENT_ENTRY_DISCOVERY_DECISION.md',
   [string]$EntryEvidencePath='outputs\THREE_LANE_REVERSION_RETRACEMENT_ENTRY_DISCOVERY_ENTRY_EVIDENCE.csv'
)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$repo=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$expectedSource='76F0E1B6E7841BAB5B2BCA9D273AE04AD88047F1E90539E3052C0134A0A9A4C8'
$expectedBinary='FA97956179F5BBDC6CC1EA7B9A38BFFC9D621003FE9AE8EF887015D2DD19A2B3'
$expectedManifest='FE174004374EDE1F8C812A475F609828D10BBEE5875AAF6AE14679B5CCBD7CA1'
$candidateNames=@('rre_control','rre_offset10','rre_center15','rre_offset20','rre_center15_bars2')

function Resolve-RepoPath([string]$Path){if([IO.Path]::IsPathRooted($Path)){return $Path};return Join-Path $repo $Path}
function Money([double]$Value){if($Value-ge0){return ('+${0:N2}'-f$Value)};return ('-${0:N2}'-f[Math]::Abs($Value))}
function Near([double]$Left,[double]$Right,[double]$Tolerance=0.0001){return [Math]::Abs($Left-$Right)-le$Tolerance}
function Sum-Profit([object[]]$Rows){if($Rows.Count-eq0){return 0.0};return [double](($Rows|Measure-Object Profit -Sum).Sum)}

$manifestFile=Resolve-RepoPath $ManifestPath
if((Get-FileHash -LiteralPath $manifestFile -Algorithm SHA256).Hash.ToUpperInvariant()-ne$expectedManifest){throw 'Frozen manifest identity changed.'}
$results=@(Import-Csv -LiteralPath (Resolve-RepoPath $ResultsPath))
$manifest=@(Import-Csv -LiteralPath $manifestFile)
$runs=@(Import-Csv -LiteralPath (Resolve-RepoPath $RunPath))
$compile=@(Import-Csv -LiteralPath (Resolve-RepoPath $CompilePath))
if($results.Count-ne15-or$manifest.Count-ne15-or$runs.Count-ne15){throw 'Expected 15 results, manifest rows, and canonical runs.'}
if(@($results|Where-Object Status -ne 'PARSED').Count-or@($runs|Where-Object Status -ne 'REPORT_FOUND').Count){throw 'Evidence is incomplete.'}
if(@($results|Where-Object{$_.To-gt'2020.12.31'}).Count){throw 'Post-2020 data leaked into discovery.'}
if($compile.Count-ne1-or$compile[0].Status-ne'COMPILE_PASS'-or$compile[0].SourceSha256-ne$expectedSource-or
   $compile[0].PortableBinarySha256-ne$expectedBinary-or[int]$compile[0].CompileErrors-ne0-or
   [int]$compile[0].CompileWarnings-ne0){throw 'Compile identity mismatch.'}
foreach($row in $results){
   $m=@($manifest|Where-Object QueueRank -eq $row.QueueRank)
   $run=@($runs|Where-Object QueueRank -eq $row.QueueRank)
   if($m.Count-ne1-or$run.Count-ne1-or$row.ProfileSha256-ne$m[0].ProfileSha256-or
      $row.SourceSha256-ne$expectedSource-or$run[0].PackageSourceSha256-ne$expectedSource-or
      $run[0].PortableBinarySha256-ne$expectedBinary){throw "Identity mismatch at rank $($row.QueueRank)."}
}

$by=@{}
foreach($row in $results){$by["$($row.Candidate)|$($row.Window)"]=$row}
$base=[Collections.Generic.List[object]]::new()
foreach($name in $candidateNames){
   $older=$by["$name|older_2015_2018"];$later=$by["$name|later_2019_2020"];$continuous=$by["$name|continuous_2015_2020"]
   if($null-eq$older-or$null-eq$later-or$null-eq$continuous){throw "Window evidence missing for $name."}
   $returnDD=if([double]$continuous.MaxDrawdownPercent-gt0){[double]$continuous.TotalReturnPercent/[double]$continuous.MaxDrawdownPercent}else{0.0}
   $base.Add([pscustomobject]@{
      Candidate=$name;Role=$continuous.Role;Enabled=[bool]::Parse($continuous.RetracementEntryEnabled)
      OffsetATR=[double]$continuous.RetracementEntryOffsetATR;LifetimeBars=[int]$continuous.RetracementEntryLifetimeBars
      Older=[double]$older.NetProfit;Later=[double]$later.NetProfit;Net=[double]$continuous.NetProfit
      Cagr=[double]$continuous.CagrPercent;PF=[double]$continuous.ProfitFactor;Trades=[int]$continuous.TotalTrades
      DD=[double]$continuous.MaxDrawdownPercent;Recovery=[double]$continuous.RecoveryFactor;ReturnDD=$returnDD
   })|Out-Null
}
$control=@($base|Where-Object Candidate -eq 'rre_control')[0]
$center=@($base|Where-Object Candidate -eq 'rre_center15')[0]
$lifetime=@($base|Where-Object Candidate -eq 'rre_center15_bars2')[0]
$controlExact=(Near $control.Older 1036.19)-and(Near $control.Later 370.60)-and(Near $control.Net 1379.93)-and
   (Near $control.Cagr 2.18)-and(Near $control.PF 1.88)-and$control.Trades-eq261-and
   (Near $control.DD 1.05)-and(Near $control.Recovery 11.6775)

$entryEvidence=[Collections.Generic.List[object]]::new()
foreach($name in $candidateNames){
   $report="outputs\three_lane_reversion_retracement_entry_discovery_model1_package\reports_here\${name}_continuous_2015_2020_m1.htm"
   $tempTrades="work\RRE_${name}_TRADES.csv";$tempSummary="work\RRE_${name}_SUMMARY.csv";$tempMd="work\RRE_${name}_SUMMARY.md"
   try{
      & (Join-Path $PSScriptRoot 'analyze_mt5_report_trade_segments.ps1') -ReportPath $report -OutTrades $tempTrades -OutSummary $tempSummary -OutMarkdown $tempMd|Out-Null
      $trades=@(Import-Csv -LiteralPath (Resolve-RepoPath $tempTrades));$rro=@($trades|Where-Object EntryComment -like 'RRO;*');$rre=@($trades|Where-Object EntryComment -like 'RRE;*')
      $entryEvidence.Add([pscustomobject][ordered]@{
         Candidate=$name;ReportTrades=$trades.Count;OriginalReversionEntries=$rro.Count;RetracementEntries=$rre.Count
         OriginalReversionNet=[Math]::Round((Sum-Profit $rro),2)
         RetracementEntryNet=[Math]::Round((Sum-Profit $rre),2)
      })|Out-Null
   }finally{
      Remove-Item -LiteralPath (Resolve-RepoPath $tempTrades),(Resolve-RepoPath $tempSummary),(Resolve-RepoPath $tempMd) -Force -ErrorAction SilentlyContinue
   }
}
$entryEvidence|Export-Csv -LiteralPath (Resolve-RepoPath $EntryEvidencePath) -NoTypeInformation -Encoding ASCII
$centerRRE=[int](@($entryEvidence|Where-Object Candidate -eq 'rre_center15')[0].RetracementEntries)
$behaviorChanged=$centerRRE-gt0-and(-not (Near $center.Net $control.Net))

$rows=foreach($row in $base){
   $netGrowth=$row.Net/$control.Net-1.0;$cagrChange=$row.Cagr-$control.Cagr
   $eraNoWorse=$row.Older-ge$control.Older-and$row.Later-ge$control.Later
   $pfRetention=if($control.PF-gt0){$row.PF/$control.PF}else{0};$recoveryRetention=if($control.Recovery-gt0){$row.Recovery/$control.Recovery}else{0}
   $rddRetention=if($control.ReturnDD-gt0){$row.ReturnDD/$control.ReturnDD}else{0};$tradeRetention=$row.Trades/[double]$control.Trades
   $positive=$row.Older-gt0-and$row.Later-gt0
   $gate=if($row.Candidate-eq'rre_control'){$controlExact}elseif($row.Candidate-eq'rre_center15'){
      $positive-and$eraNoWorse-and$netGrowth-ge.03-and$cagrChange-ge.05-and$pfRetention-ge.97-and
      $recoveryRetention-ge.97-and$rddRetention-ge.97-and$row.DD-le$control.DD+.10-and$tradeRetention-ge.97-and$behaviorChanged
   }elseif($row.Candidate-in@('rre_offset10','rre_offset20')){
      $positive-and$eraNoWorse-and$netGrowth-gt0-and$pfRetention-ge.95-and$recoveryRetention-ge.95-and
      $rddRetention-ge.95-and$row.DD-le$control.DD+.12-and$tradeRetention-ge.96
   }else{
      $positive-and$row.Net-ge.90*$center.Net-and$row.PF-ge.90*$center.PF-and$row.Recovery-ge.90*$center.Recovery-and
      $row.ReturnDD-ge.90*$center.ReturnDD-and$row.DD-le$center.DD+.12
   }
   $ev=@($entryEvidence|Where-Object Candidate -eq $row.Candidate)[0]
   [pscustomobject][ordered]@{
      Candidate=$row.Candidate;Role=$row.Role;Enabled=$row.Enabled;OffsetATR=$row.OffsetATR;LifetimeBars=$row.LifetimeBars
      OlderNet=[Math]::Round($row.Older,2);LaterNet=[Math]::Round($row.Later,2);ContinuousNet=[Math]::Round($row.Net,2)
      NetGrowthPercent=[Math]::Round(100*$netGrowth,2);CagrPercent=[Math]::Round($row.Cagr,2);CagrChangePoints=[Math]::Round($cagrChange,2)
      ProfitFactor=[Math]::Round($row.PF,2);PFRetentionPercent=[Math]::Round(100*$pfRetention,2);Trades=$row.Trades
      TradeRetentionPercent=[Math]::Round(100*$tradeRetention,2);MaxDrawdownPercent=[Math]::Round($row.DD,2)
      RecoveryFactor=[Math]::Round($row.Recovery,4);RecoveryRetentionPercent=[Math]::Round(100*$recoveryRetention,2)
      ReturnDrawdown=[Math]::Round($row.ReturnDD,4);ReturnDrawdownRetentionPercent=[Math]::Round(100*$rddRetention,2)
      RetracementEntries=[int]$ev.RetracementEntries;RetracementEntryNet=[double]$ev.RetracementEntryNet
      PositiveEras=$positive;EraNoWorseThanControl=$eraNoWorse;FrozenGatePass=$gate
      Decision=if($row.Candidate-eq'rre_control'){'CONTROL'}elseif($gate){'ELIGIBLE_ONLY_IF_FAMILY_PASSES'}else{'REJECT_BEFORE_HOLDOUT'}
   }
}
$rows|Export-Csv -LiteralPath (Resolve-RepoPath $DecisionCsvPath) -NoTypeInformation -Encoding ASCII
$centerPass=[bool](@($rows|Where-Object Candidate -eq 'rre_center15')[0].FrozenGatePass)
$adjacentPasses=@($rows|Where-Object{$_.Candidate-in@('rre_offset10','rre_offset20')-and$_.FrozenGatePass}).Count
$lifetimePass=[bool](@($rows|Where-Object Candidate -eq 'rre_center15_bars2')[0].FrozenGatePass)
$familyPass=$controlExact-and$centerPass-and$adjacentPasses-eq2-and$lifetimePass

$md=[Collections.Generic.List[string]]::new();$md.Add('# Reversion Retracement-Entry Discovery Decision');$md.Add('')
$md.Add($(if($familyPass){'**Decision: discovery passed. Only the frozen family may proceed to recent Model 1 confirmation.**'}else{'**Decision: rejected in frozen pre-2021 discovery. No recent holdout, Model 4, promotion, forward change, or live approval is permitted.**'}));$md.Add('')
$md.Add("- Exact source SHA-256: ``$expectedSource``");$md.Add("- Exact four-worker EX5 SHA-256: ``$expectedBinary``");$md.Add("- Frozen manifest SHA-256: ``$expectedManifest``")
$md.Add('- Reports: `15 / 15` parsed and identity-valid after two preserved startup identity refusals and one unchanged single-worker recovery.');$md.Add('- Data: `$10,000`, XAUUSD M15, Model 1, 2015-2020 only.');$md.Add("- Disabled control exact reproduction: ``$controlExact``; enabled-center RRE fills: ``$centerRRE``.");$md.Add('')
$md.Add('| Profile | Offset | Life | 2015-18 | 2019-20 | Continuous | Change | CAGR | PF | Trades | DD | Recovery | RRE fills | RRE net | Gate |')
$md.Add('|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|')
foreach($row in $rows){$md.Add("| ``$($row.Candidate)`` | ``$($row.OffsetATR) ATR`` | ``$($row.LifetimeBars)`` | ``$(Money $row.OlderNet)`` | ``$(Money $row.LaterNet)`` | ``$(Money $row.ContinuousNet)`` | ``$($row.NetGrowthPercent)%`` | ``$($row.CagrPercent)%`` | ``$($row.ProfitFactor)`` | ``$($row.Trades)`` | ``$($row.MaxDrawdownPercent)%`` | ``$($row.RecoveryFactor)`` | ``$($row.RetracementEntries)`` | ``$(Money $row.RetracementEntryNet)`` | ``$($row.FrozenGatePass)`` |")}
$md.Add('');$md.Add('## Interpretation');$md.Add('')
$md.Add('The mechanism was active and behaved as intended, but waiting for a retracement missed too many high-value older-era entries. The least-damaging enabled row, `0.10 ATR`, improved 2019-2020 slightly but reduced continuous net from `+$1,379.93` to `+$1,250.30`. The frozen `0.15 ATR` center fell to `+$1,067.56`, PF `1.75`, and recovery `9.4759`.')
$md.Add('');$md.Add('The two-bar lifetime retained the center neighborhood but could not repair the underlying loss of older winners. Offsets are not moved closer to zero after observation; that would convert this bounded test into threshold fitting. The family is closed before newer data and real ticks.')
$md.Add('');$md.Add('- The provisional historical leader remains the 60-minute same-side momentum exit-cooldown profile.');$md.Add('- The registered forward candidate and invalid `$100,000` account boundary remain unchanged.');$md.Add('- Real-account trading remains disabled.')
$md|Set-Content -LiteralPath (Resolve-RepoPath $DecisionMarkdownPath) -Encoding ASCII
[pscustomobject]@{Status=if($familyPass){'OPEN_FROZEN_HOLDOUT'}else{'REJECTED'};Reports=15;ControlExact=$controlExact;CenterPass=$centerPass;AdjacentPasses=$adjacentPasses;LifetimePass=$lifetimePass;BehaviorChanged=$behaviorChanged;HoldoutOpened=$familyPass;Model4Runs=0;NewBest=$false}
