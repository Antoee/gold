[CmdletBinding()]
param(
   [string]$ManifestPath = 'outputs\THREE_LANE_MOMENTUM_D1_EMA_SLOPE_GUARD_DISCOVERY_MODEL1_MANIFEST.csv',
   [string]$ResultsPath = 'outputs\THREE_LANE_MOMENTUM_D1_EMA_SLOPE_GUARD_DISCOVERY_MODEL1_RESULTS.csv',
   [string]$DecisionCsvPath = 'outputs\THREE_LANE_MOMENTUM_D1_EMA_SLOPE_GUARD_DISCOVERY_DECISION.csv',
   [string]$DecisionMarkdownPath = 'outputs\THREE_LANE_MOMENTUM_D1_EMA_SLOPE_GUARD_DISCOVERY_DECISION.md'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$expectedManifestHash = '576A33A2517FAD0E45FEB8F488EC3BC89AC5FC346BEF8CBE9A710C2A4C9F1597'
$expectedResultsHash = '17EC6E1E73807B9DA8C7FD6F6F2F63B52B6BFDB5FB334DA768CB7EB255DEE293'
$disjointWindows = @('older_2015_2018','middle_2019_2020','recent_2021_2023','latest_2024_2026')

function Resolve-RepoPath([string]$Path) {
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}
function Format-Money([double]$Value) {
   return $(if($Value -ge 0.0){'+'}else{'-'}) + '$' + [math]::Abs($Value).ToString('N2',[Globalization.CultureInfo]::InvariantCulture)
}

$manifestFile = Resolve-RepoPath $ManifestPath
$resultsFile = Resolve-RepoPath $ResultsPath
if((Get-FileHash $manifestFile -Algorithm SHA256).Hash.ToUpperInvariant() -ne $expectedManifestHash) {
   throw 'D1 EMA-slope discovery manifest identity changed.'
}
if((Get-FileHash $resultsFile -Algorithm SHA256).Hash.ToUpperInvariant() -ne $expectedResultsHash) {
   throw 'D1 EMA-slope discovery results identity changed.'
}
$manifest = @(Import-Csv $manifestFile)
$results = @(Import-Csv $resultsFile)
if($manifest.Count -ne 20 -or $results.Count -ne 20 -or @($results | Where-Object Status -ne 'PARSED').Count -ne 0) {
   throw 'D1 EMA-slope discovery evidence is incomplete.'
}

$joined = foreach($result in $results) {
   $queued = $manifest | Where-Object ExpectedReportName -eq $result.ExpectedReportName | Select-Object -First 1
   if($null -eq $queued) { throw "Unmatched result: $($result.ExpectedReportName)" }
   [pscustomobject]@{
      Candidate=$queued.Candidate;Role=$queued.Role;Window=$result.Window
      Net=[double]$result.NetProfit;PF=[double]$result.ProfitFactor;Trades=[int]$result.TotalTrades
      DD=[double]$result.MaxDrawdownPercent;Recovery=[double]$result.RecoveryFactor
      ReturnPercent=[double]$result.TotalReturnPercent;CAGR=[double]$result.CagrPercent
   }
}
$controlFull = $joined | Where-Object { $_.Candidate -eq 'mdes_control' -and $_.Window -eq 'continuous_2015_2026' } | Select-Object -First 1
if($null -eq $controlFull) { throw 'Continuous default-off control is missing.' }
$controlReturnDD = $controlFull.ReturnPercent / $controlFull.DD

$rows = foreach($candidate in @('mdes_control','mdes_low075','mdes_center100','mdes_high125')) {
   $candidateRows = @($joined | Where-Object Candidate -eq $candidate)
   $full = $candidateRows | Where-Object Window -eq 'continuous_2015_2026' | Select-Object -First 1
   $disjoint = @($candidateRows | Where-Object Window -in $disjointWindows)
   $allBroadProfitable = $disjoint.Count -eq 4 -and @($disjoint | Where-Object Net -le 0.0).Count -eq 0
   $behaviorChanged = $candidate -ne 'mdes_control' -and $full.Trades -ne $controlFull.Trades
   $netImproved = $candidate -ne 'mdes_control' -and $full.Net -gt $controlFull.Net
   $pfImproved = $candidate -ne 'mdes_control' -and $full.PF -gt $controlFull.PF
   $returnDD = $full.ReturnPercent / $full.DD
   $centerRiskPass = $candidate -ne 'mdes_center100' -or
      ($full.DD -le 1.25 -and $full.Recovery -ge $controlFull.Recovery -and
       $returnDD -ge $controlReturnDD -and $full.Trades -ge [math]::Ceiling(0.60*$controlFull.Trades))
   $gate = if($candidate -eq 'mdes_control'){'CONTROL'}elseif(
      $allBroadProfitable -and $behaviorChanged -and $netImproved -and $pfImproved -and $centerRiskPass
   ){'PASS'}else{'FAIL'}
   [pscustomobject][ordered]@{
      Candidate=$candidate;Role=$full.Role;ContinuousNet=[math]::Round($full.Net,2)
      ImprovementVsControl=[math]::Round($full.Net-$controlFull.Net,2);ContinuousPF=$full.PF
      ContinuousTrades=$full.Trades;ContinuousDDPercent=$full.DD;ContinuousCAGRPercent=$full.CAGR
      Recovery=$full.Recovery;ReturnToDD=[math]::Round($returnDD,4)
      Net2015_2018=($disjoint|Where-Object Window -eq 'older_2015_2018').Net
      Net2019_2020=($disjoint|Where-Object Window -eq 'middle_2019_2020').Net
      Net2021_2023=($disjoint|Where-Object Window -eq 'recent_2021_2023').Net
      Net2024_2026=($disjoint|Where-Object Window -eq 'latest_2024_2026').Net
      AllBroadWindowsProfitable=$allBroadProfitable;BehaviorChanged=$behaviorChanged
      ContinuousNetImproved=$netImproved;ContinuousPFImproved=$pfImproved
      CenterRiskGate=$centerRiskPass;FrozenGate=$gate
   }
}
$centerPass = ($rows | Where-Object Candidate -eq 'mdes_center100').FrozenGate -eq 'PASS'
$neighborPasses = @($rows | Where-Object { $_.Candidate -in @('mdes_low075','mdes_high125') -and $_.FrozenGate -eq 'PASS' }).Count
$passed = $centerPass -and $neighborPasses -eq 2
$rows | Export-Csv (Resolve-RepoPath $DecisionCsvPath) -NoTypeInformation -Encoding ASCII

$md = [Collections.Generic.List[string]]::new()
$md.Add('# Momentum D1 EMA-Slope Guard Discovery Decision'); $md.Add('')
$md.Add($(if($passed){
   '**Decision: MODEL 1 GATE PASSED. Fresh strategy Model 4 confirmation is permitted.**'
}else{
   '**Decision: REJECTED IN MODEL 1 NEIGHBORHOOD. No strategy Model 4 run, promotion, forward substitution, or live approval is permitted.**'
})); $md.Add('')
$md.Add("- Manifest SHA-256: ``$expectedManifestHash``")
$md.Add("- Results SHA-256: ``$expectedResultsHash``")
$md.Add("- Reports parsed: ``$($results.Count) / 20``")
$md.Add("- Center complete gate: ``$centerPass``")
$md.Add("- Passing neighbors: ``$neighborPasses / 2``")
$md.Add('')
$md.Add('| Candidate | Role | Full net | Delta | PF | Trades | DD | CAGR | 2015-18 | 2019-20 | 2021-23 | 2024-26 | Gate |')
$md.Add('|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|')
foreach($row in $rows) {
   $md.Add("| ``$($row.Candidate)`` | $($row.Role) | $(Format-Money $row.ContinuousNet) | $(Format-Money $row.ImprovementVsControl) | $($row.ContinuousPF) | $($row.ContinuousTrades) | $($row.ContinuousDDPercent)% | $($row.ContinuousCAGRPercent)% | $(Format-Money $row.Net2015_2018) | $(Format-Money $row.Net2019_2020) | $(Format-Money $row.Net2021_2023) | $(Format-Money $row.Net2024_2026) | $($row.FrozenGate) |")
}
$md.Add(''); $md.Add('## Why It Stopped'); $md.Add('')
$md.Add('The `1.00 ATR` center improved continuous profit, PF, drawdown, recovery, and return/drawdown while every broad era remained profitable. The neighborhood did not confirm the profit improvement: both `0.75 ATR` and `1.25 ATR` finished below the default-off control. That isolated peak is treated as overfit risk, so the family stops before strategy Model 4 confirmation.')
$md.Add(''); $md.Add('The published historical leader and registered forward identity remain unchanged. The attached demo account still violates the frozen $10,000 contract, and real-account trading remains locked.')
$md | Set-Content (Resolve-RepoPath $DecisionMarkdownPath) -Encoding ASCII

[pscustomobject][ordered]@{
   Status=$(if($passed){'MODEL1_GATE_PASSED'}else{'REJECTED_IN_MODEL1_NEIGHBORHOOD'})
   CenterPass=$centerPass;PassingNeighbors=$neighborPasses;RequiredNeighbors=2
   StrategyModel4Permitted=$passed;PromotionPermitted=$false
   ForwardCandidateChanged=$false;RealAccountTradingAllowed=$false
}
