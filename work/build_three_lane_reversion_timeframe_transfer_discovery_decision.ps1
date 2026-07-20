param(
   [string]$ResultsPath='outputs\THREE_LANE_REVERSION_TIMEFRAME_TRANSFER_DISCOVERY_MODEL1_RESULTS.csv',
   [string]$ManifestPath='outputs\THREE_LANE_REVERSION_TIMEFRAME_TRANSFER_DISCOVERY_MODEL1_MANIFEST.csv',
   [string]$RunPath='outputs\THREE_LANE_REVERSION_TIMEFRAME_TRANSFER_DISCOVERY_RUN_ATTESTATION.csv',
   [string]$CompilePath='outputs\THREE_LANE_REVERSION_TIMEFRAME_TRANSFER_COMPILE_AUDIT.csv',
   [string]$DecisionCsvPath='outputs\THREE_LANE_REVERSION_TIMEFRAME_TRANSFER_DISCOVERY_DECISION.csv',
   [string]$DecisionMarkdownPath='outputs\THREE_LANE_REVERSION_TIMEFRAME_TRANSFER_DISCOVERY_DECISION.md'
)

Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$expectedSource='B6810B305549968E2273DAAF736A63759FE5C16F3B416F5C69E39840FBE5173E'
$expectedBinary='D9B60597A7D44D142FD9283147B1C32BED61B7A4A7FD4EA2462D6E59439719B4'
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
   $pass=[double]$older[0].NetProfit -gt 0 -and [double]$recent[0].NetProfit -gt 0 -and [double]$c.NetProfit -gt 0 -and [double]$c.ProfitFactor -ge 1.50 -and [int]$c.TotalTrades -ge 24 -and [double]$c.MaxDrawdownPercent -le 1.50 -and [double]$c.RecoveryFactor -ge 2.0
   $base.Add([pscustomobject]@{Candidate=$group.Name;Family=$c.Family;OlderNet=[math]::Round([double]$older[0].NetProfit,2);OlderPF=[math]::Round([double]$older[0].ProfitFactor,4);RecentNet=[math]::Round([double]$recent[0].NetProfit,2);RecentPF=[math]::Round([double]$recent[0].ProfitFactor,4);ContinuousNet=[math]::Round([double]$c.NetProfit,2);Cagr=[math]::Round([double]$c.CagrPercent,4);PF=[math]::Round([double]$c.ProfitFactor,4);Trades=[int]$c.TotalTrades;DD=[math]::Round([double]$c.MaxDrawdownPercent,2);Recovery=[math]::Round([double]$c.RecoveryFactor,4);BaseGatePass=$pass})|Out-Null
}
$control=@($base|Where-Object Candidate -eq 'rvtf_h1_control')
if($control.Count -ne 1){throw 'Isolated H1 control is missing.'}
$rows=foreach($row in $base){
   $familyPasses=@($base|Where-Object {$_.Family -eq $row.Family -and $_.BaseGatePass}).Count
   $improves=$row.ContinuousNet -ge 1.10*$control[0].ContinuousNet -and $row.Cagr -ge $control[0].Cagr+0.10 -and $row.Trades -ge $control[0].Trades
   $gate=$row.Family -ne 'h1' -and $row.BaseGatePass -and $familyPasses -ge 2 -and $improves
   [pscustomobject]@{Candidate=$row.Candidate;Family=$row.Family;OlderNet=$row.OlderNet;OlderPF=$row.OlderPF;RecentNet=$row.RecentNet;RecentPF=$row.RecentPF;ContinuousNet=$row.ContinuousNet;CagrPercent=$row.Cagr;ProfitFactor=$row.PF;Trades=$row.Trades;MaxDrawdownPercent=$row.DD;RecoveryFactor=$row.Recovery;BaseGatePass=$row.BaseGatePass;FamilyBasePasses=$familyPasses;ImprovesH1Control=$improves;DiscoveryGatePass=$gate;Decision=if($gate){'OPEN_FROZEN_HOLDOUT'}else{'REJECTED_NO_HOLDOUT_NO_MODEL4'}}
}
$ordered=@($rows|Sort-Object ContinuousNet -Descending)
if($ordered.Count -ne 7 -or @($ordered|Where-Object DiscoveryGatePass -eq $true).Count -gt 0){throw 'A row passed; revise this rejection-only publication.'}
$ordered|Export-Csv -LiteralPath (Resolve-RepoPath $DecisionCsvPath) -NoTypeInformation -Encoding ASCII

$md=[Collections.Generic.List[string]]::new()
$md.Add('# Reversion Timeframe-Transfer Discovery Decision');$md.Add('');$md.Add('**Decision: rejected in frozen pre-2021 discovery. No holdout, Model 4, promotion, forward change, or live approval was opened.**');$md.Add('')
$md.Add('- Exact leader source SHA-256: `'+$expectedSource+'`');$md.Add('- Exact four-worker EX5 SHA-256: `'+$expectedBinary+'`');$md.Add('- Reports: `21 / 21` parsed and identity-valid after two unchanged export recoveries.');$md.Add('- Risk: `0.45%` requested reversion risk; `0.75%` portfolio cap; minimum-lot refusal unchanged.');$md.Add('- Data: 2015-2020 Model 1 only.');$md.Add('')
$md.Add('| Candidate | Family | 2015-18 | 2019-20 | Continuous | CAGR | PF | Trades | DD | Recovery | Decision |');$md.Add('|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---|')
foreach($row in $ordered){$md.Add("| ``$($row.Candidate)`` | ``$($row.Family)`` | ``$(Money $row.OlderNet)`` | ``$(Money $row.RecentNet)`` | ``$(Money $row.ContinuousNet)`` | ``$('{0:N2}' -f $row.CagrPercent)%`` | ``$('{0:N2}' -f $row.ProfitFactor)`` | ``$($row.Trades)`` | ``$('{0:N2}' -f $row.MaxDrawdownPercent)%`` | ``$('{0:N2}' -f $row.RecoveryFactor)`` | rejected |")}
$md.Add('');$md.Add('The isolated H1 control remained profitable at `+$568.70`, PF `3.19`, and `0.93%/yr`, but produced only 19 trades. H2 local made `+$326.93` from seven trades; its two horizon neighbors failed. Every M30 row lost continuously, from `-$51.60` to `-$302.31`. No adjacent family supplied the required activity, broad-era profitability, and support.');$md.Add('')
$md.Add('- Reject M30/H2 timeframe transfer at these fixed horizons.');$md.Add('- Do not tune the failed M30 rows or open post-2020 data.');$md.Add('- Preserve the historical leader and invalid forward registration unchanged.')
$md|Set-Content -LiteralPath (Resolve-RepoPath $DecisionMarkdownPath) -Encoding ASCII
[pscustomobject]@{Status='REJECTED';Reports=21;Candidates=7;GatePasses=0;HoldoutRuns=0;Model4Runs=0;NewBest=$false}
