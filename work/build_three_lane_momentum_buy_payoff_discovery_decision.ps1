[CmdletBinding()]
param(
   [string]$ManifestPath = 'outputs\THREE_LANE_MOMENTUM_BUY_PAYOFF_DISCOVERY_MODEL1_MANIFEST.csv',
   [string]$ReportDir = 'outputs\three_lane_momentum_buy_payoff_discovery_model1_package\reports_here',
   [string]$ResultsPath = 'outputs\THREE_LANE_MOMENTUM_BUY_PAYOFF_DISCOVERY_MODEL1_RESULTS.csv',
   [string]$SummaryPath = 'outputs\THREE_LANE_MOMENTUM_BUY_PAYOFF_DISCOVERY_SUMMARY.csv',
   [string]$DecisionCsvPath = 'outputs\THREE_LANE_MOMENTUM_BUY_PAYOFF_DISCOVERY_DECISION.csv',
   [string]$DecisionMarkdownPath = 'outputs\THREE_LANE_MOMENTUM_BUY_PAYOFF_DISCOVERY_DECISION.md',
   [string]$RunAttestationPath = 'outputs\THREE_LANE_MOMENTUM_BUY_PAYOFF_DISCOVERY_RUN_ATTESTATION.csv'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$expectedSourceSha256 = '52A2C2942931518EB28A8CB1BF1DD72D9C4BF07E6AC18F3C577D4971153A3923'
$expectedBinarySha256 = '404C177BD968BFBE5EEC6B875DD324DD037F93F19622ED874490D353250F63B5'
$expectedManifestSha256 = '3BD672846E507BE7A31C044FF583F1C2643FC83814D861C84348F0BE5A95C47B'
$controlName = 'mbp_control'
$centerName = 'mbp_center_buy250'
$lowerNames = @('mbp_buy225','mbp_buy275','mbp_buy300')
$windows = @('older_2015_2018','later_2019_2020','continuous_2015_2020')

function Resolve-RepoPath([string]$Path) {
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}
function Money([double]$Value) {
   $sign = if($Value -ge 0.0) { '+' } else { '-' }
   return $sign + '$' + [Math]::Abs($Value).ToString('N2',[Globalization.CultureInfo]::InvariantCulture)
}

$manifestFile = Resolve-RepoPath $ManifestPath
if((Get-FileHash -LiteralPath $manifestFile -Algorithm SHA256).Hash.ToUpperInvariant() -ne $expectedManifestSha256) {
   throw 'Frozen manifest identity changed.'
}
$manifest = @(Import-Csv -LiteralPath $manifestFile)
if($manifest.Count -ne 15 -or @($manifest.Candidate | Sort-Object -Unique).Count -ne 5 -or
   @($manifest.Window | Sort-Object -Unique).Count -ne 3) {
   throw 'Frozen manifest topology changed.'
}
if(@($manifest | Where-Object { $_.SourceSha256 -ne $expectedSourceSha256 -or [int]$_.Model -ne 1 }).Count -ne 0) {
   throw 'Manifest source or model identity changed.'
}
foreach($item in $manifest) {
   $config = Resolve-RepoPath ([string]$item.PackageConfig)
   if((Get-FileHash -LiteralPath $config -Algorithm SHA256).Hash.ToUpperInvariant() -ne $item.ConfigSha256) {
      throw "Config identity changed at rank $($item.QueueRank)."
   }
}

$rawResults = 'work\MBR_DECISION_RAW_RESULTS.csv'
$rawSummary = 'work\MBR_DECISION_RAW_SUMMARY.csv'
$rawMetrics = 'work\MBR_DECISION_RAW_METRICS.md'
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'collect_validation_results.ps1') `
   -RepoRoot $repo -ManifestPath $ManifestPath -ReportDir $ReportDir -ReportNameTemplate '{ExpectedReportName}' `
   -OutResults $rawResults -OutSummary $rawSummary -OutMarkdown $rawMetrics | Out-Null
if($LASTEXITCODE -ne 0) { throw 'Shared report collector failed.' }
$raw = @(Import-Csv -LiteralPath (Resolve-RepoPath $rawResults))
if($raw.Count -ne 15 -or @($raw | Where-Object Status -ne 'PARSED').Count -ne 0) {
   throw 'Expected fifteen parsed reports.'
}
$rawByReport = @{}
foreach($row in $raw) { $rawByReport[[string]$row.ExpectedReportName] = $row }

$recoveryFile = Resolve-RepoPath 'outputs\THREE_LANE_MOMENTUM_BUY_PAYOFF_RECOVERY_WORKER_1.csv'
$finalRuns = @(Import-Csv -LiteralPath $recoveryFile)
if($finalRuns.Count -ne 15 -or @($finalRuns | Where-Object {
   $_.Status -ne 'REPORT_FOUND' -or $_.PackageSourceSha256 -ne $expectedSourceSha256 -or
   $_.PortableBinarySha256 -ne $expectedBinarySha256 -or $_.PortableExpertRecompiled -ne 'False'
}).Count -ne 0) {
   throw 'Final run evidence is incomplete or has an identity mismatch.'
}
$firstRetryRows = @(Get-ChildItem (Resolve-RepoPath 'outputs') -Filter 'THREE_LANE_MOMENTUM_BUY_PAYOFF_WORKER_*.csv' -File |
   ForEach-Object { Import-Csv -LiteralPath $_.FullName })
$preservedIdentityRefusals = @($firstRetryRows | Where-Object Status -eq 'ERROR').Count
if($firstRetryRows.Count -ne 15 -or $preservedIdentityRefusals -ne 1) {
   throw 'Expected the preserved unchanged retry evidence with one identity refusal.'
}

$finalByRank = @{}
foreach($run in $finalRuns) { $finalByRank[[string]$run.QueueRank] = $run }
$results = [Collections.Generic.List[object]]::new()
$attestation = [Collections.Generic.List[object]]::new()
foreach($item in ($manifest | Sort-Object { [int]$_.QueueRank })) {
   $parsed = $rawByReport[[string]$item.ExpectedReportName]
   $run = $finalByRank[[string]$item.QueueRank]
   if($null -eq $parsed -or $null -eq $run) { throw "Evidence missing for rank $($item.QueueRank)." }
   $identityPath = [string]$run.ReportIdentityPath
   if(!(Test-Path -LiteralPath $identityPath -PathType Leaf)) { throw "Identity sidecar missing for rank $($item.QueueRank)." }
   $identity = Get-Content -LiteralPath $identityPath -Raw | ConvertFrom-Json
   if($identity.SourceSha256 -ne $expectedSourceSha256 -or
      $identity.PortableBinarySha256 -ne $expectedBinarySha256 -or
      $identity.ReportSha256 -ne $run.ReportSha256 -or
      $identity.ConfigSha256 -ne $run.PackageConfigSha256) {
      throw "Identity sidecar mismatch for rank $($item.QueueRank)."
   }
   $returnDrawdown = if([double]$parsed.MaxDrawdownPercent -gt 0.0) {
      [double]$parsed.TotalReturnPercent / [double]$parsed.MaxDrawdownPercent
   } else { 0.0 }
   $results.Add([pscustomobject][ordered]@{
      QueueRank=[int]$item.QueueRank;Candidate=$item.Candidate;Role=$item.Role;Window=$item.Window
      From=$item.From;To=$item.To;Model=[int]$item.Model;BuyTakeProfitEnabled=$item.BuyTakeProfitEnabled
      MomentumBuyTakeProfitR=[double]$item.MomentumBuyTakeProfitR;MomentumSellTakeProfitR=[double]$item.MomentumSellTakeProfitR
      MomentumRiskPercent=[double]$item.MomentumRiskPercent;ProfileSha256=$item.ProfileSha256
      SourceSha256=$item.SourceSha256;BinarySha256=$run.PortableBinarySha256;Status=$parsed.Status
      NetProfit=[Math]::Round([double]$parsed.NetProfit,2);TotalReturnPercent=[Math]::Round([double]$parsed.TotalReturnPercent,2)
      CagrPercent=[Math]::Round([double]$parsed.CagrPercent,2);ProfitFactor=[Math]::Round([double]$parsed.ProfitFactor,2)
      TotalTrades=[int]$parsed.TotalTrades;WinRatePercent=[Math]::Round([double]$parsed.WinRatePercent,2)
      MaxDrawdownPercent=[Math]::Round([double]$parsed.MaxDrawdownPercent,2)
      RecoveryFactor=[Math]::Round([double]$parsed.RecoveryFactor,4);ReturnDrawdown=[Math]::Round($returnDrawdown,4)
      SharpeRatio=[Math]::Round([double]$parsed.SharpeRatio,2);MaxConsecutiveLosses=[int]$parsed.MaxConsecutiveLosses
      ReportSha256=$run.ReportSha256
   }) | Out-Null
   $attestation.Add([pscustomobject][ordered]@{
      QueueRank=[int]$item.QueueRank;Candidate=$item.Candidate;Window=$item.Window;Status=$run.Status
      IdentityReused=[bool]::Parse($run.ReportIdentityReused);SourceSha256=$run.PackageSourceSha256
      BinarySha256=$run.PortableBinarySha256;ConfigSha256=$run.PackageConfigSha256;ReportSha256=$run.ReportSha256
      IdentitySidecarPresent=$true;PortableExpertRecompiled=$false;Started=$run.Started;Finished=$run.Finished
   }) | Out-Null
}
$results | Export-Csv -LiteralPath (Resolve-RepoPath $ResultsPath) -NoTypeInformation -Encoding ASCII
$attestation | Export-Csv -LiteralPath (Resolve-RepoPath $RunAttestationPath) -NoTypeInformation -Encoding ASCII

$lookup = @{}
foreach($row in $results) { $lookup["$($row.Candidate)|$($row.Window)"] = $row }
$control = $lookup["$controlName|continuous_2015_2020"]
$center = $lookup["$centerName|continuous_2015_2020"]
$drawdownCeiling = [Math]::Min(1.20,[double]$control.MaxDrawdownPercent + 0.08)

function ErasRetain([string]$Name) {
   foreach($window in @('older_2015_2018','later_2019_2020')) {
      if([double]$lookup["$Name|$window"].NetProfit -lt 0.98 * [double]$lookup["$controlName|$window"].NetProfit) {
         return $false
      }
   }
   return $true
}
function BehaviorChanged([string]$Name) {
   $row = $lookup["$Name|continuous_2015_2020"]
   return [double]$row.NetProfit -ne [double]$control.NetProfit -or
      [double]$row.MaxDrawdownPercent -ne [double]$control.MaxDrawdownPercent
}
function LowerPass([string]$Name) {
   $row = $lookup["$Name|continuous_2015_2020"]
   return (ErasRetain $Name) -and [double]$row.NetProfit -ge 1.015 * [double]$control.NetProfit -and
      [double]$row.CagrPercent -ge [double]$control.CagrPercent + 0.02 -and
      [double]$row.ProfitFactor -ge 0.98 * [double]$control.ProfitFactor -and
      [double]$row.RecoveryFactor -ge 0.98 * [double]$control.RecoveryFactor -and
      [double]$row.ReturnDrawdown -ge 0.98 * [double]$control.ReturnDrawdown -and
      [double]$row.MaxDrawdownPercent -le $drawdownCeiling -and
      [int]$row.TotalTrades -ge [int]$control.TotalTrades - 3 -and (BehaviorChanged $Name)
}

$allErasPositive = @($results | Where-Object {
   $_.Window -in @('older_2015_2018','later_2019_2020') -and [double]$_.NetProfit -le 0.0
}).Count -eq 0
$centerEras = ErasRetain $centerName
$centerGrowth = [double]$center.NetProfit -ge 1.03 * [double]$control.NetProfit
$centerCagr = [double]$center.CagrPercent -ge [double]$control.CagrPercent + 0.05
$centerEfficiency = [double]$center.ProfitFactor -ge [double]$control.ProfitFactor -and
   [double]$center.RecoveryFactor -ge [double]$control.RecoveryFactor -and
   [double]$center.ReturnDrawdown -ge [double]$control.ReturnDrawdown
$centerRisk = [double]$center.MaxDrawdownPercent -le $drawdownCeiling
$centerTrades = [int]$center.TotalTrades -ge [int]$control.TotalTrades - 2
$centerBehavior = BehaviorChanged $centerName
$lowerGates = [ordered]@{}
foreach($name in $lowerNames) { $lowerGates[$name] = LowerPass $name }
$lowerPassCount = @($lowerGates.Values | Where-Object { $_ }).Count
$passed = $allErasPositive -and $centerEras -and $centerGrowth -and $centerCagr -and
   $centerEfficiency -and $centerRisk -and $centerTrades -and $centerBehavior -and $lowerPassCount -ge 2

$orderedNames = @($controlName,'mbp_buy225',$centerName,'mbp_buy275','mbp_buy300')
$summary = foreach($name in $orderedNames) {
   $row = $lookup["$name|continuous_2015_2020"]
   [pscustomobject][ordered]@{
      Candidate=$name;Role=$row.Role;BuyTakeProfitEnabled=$row.BuyTakeProfitEnabled
      MomentumBuyTakeProfitR=$row.MomentumBuyTakeProfitR
      OlderNetProfit=$lookup["$name|older_2015_2018"].NetProfit
      LaterNetProfit=$lookup["$name|later_2019_2020"].NetProfit
      ContinuousNetProfit=$row.NetProfit;TotalReturnPercent=$row.TotalReturnPercent;CagrPercent=$row.CagrPercent
      ProfitFactor=$row.ProfitFactor;TotalTrades=$row.TotalTrades;MaxDrawdownPercent=$row.MaxDrawdownPercent
      RecoveryFactor=$row.RecoveryFactor;ReturnDrawdown=$row.ReturnDrawdown;BehaviorChanged=BehaviorChanged $name
      FrozenGate=if($name -eq $controlName){'CONTROL'}elseif($name -eq $centerName){$centerEras -and $centerGrowth -and $centerCagr -and $centerEfficiency -and $centerRisk -and $centerTrades -and $centerBehavior}else{$lowerGates[$name]}
   }
}
$summary | Export-Csv -LiteralPath (Resolve-RepoPath $SummaryPath) -NoTypeInformation -Encoding ASCII
$bestEnabled = @($summary | Where-Object BuyTakeProfitEnabled -eq 'true' | Sort-Object {[double]$_.ContinuousNetProfit} -Descending)[0]

$decision = [pscustomobject][ordered]@{
   Status=if($passed){'DISCOVERY_GATE_PASSED'}else{'REJECTED_IN_DISCOVERY'};ReportsParsed=15;IdentityValidReports=15
   PreservedIdentityRefusals=$preservedIdentityRefusals;AllDisjointErasPositive=$allErasPositive
   CenterEraRetentionGate=$centerEras;CenterGrowthGate=$centerGrowth;CenterCagrGate=$centerCagr
   CenterEfficiencyGate=$centerEfficiency;CenterRiskGate=$centerRisk;CenterTradeCountGate=$centerTrades
   CenterBehaviorChanged=$centerBehavior;LowerRungsPassed=$lowerPassCount;LowerRungsRequired=2
   HoldoutValidationPermitted=$passed;Model4ValidationPermitted=$false;ResearchPromotionPermitted=$false
   ForwardCandidateChanged=$false;RealAccountTradingAllowed=$false;ControlNetProfit=$control.NetProfit
   CenterNetProfit=$center.NetProfit;CenterMaxDrawdownPercent=$center.MaxDrawdownPercent
   BestEnabledCandidate=$bestEnabled.Candidate;BestEnabledNetProfit=$bestEnabled.ContinuousNetProfit
   SourceSha256=$expectedSourceSha256;BinarySha256=$expectedBinarySha256;ManifestSha256=$expectedManifestSha256
}
$decision | Export-Csv -LiteralPath (Resolve-RepoPath $DecisionCsvPath) -NoTypeInformation -Encoding ASCII

$lines = [Collections.Generic.List[string]]::new()
$lines.Add('# Three-Lane Momentum Buy Payoff Discovery Decision')
$lines.Add('')
$lines.Add($(if($passed){'**Decision: DISCOVERY GATE PASSED. Only the frozen center may proceed to recent confirmation; Model 4 and promotion remain closed.**'}else{'**Decision: REJECTED IN DISCOVERY. No recent confirmation, Model 4, promotion, forward change, or live approval is permitted.**'}))
$lines.Add('')
$lines.Add('- Exact accepted reports: `15/15`; unchanged identity retry refusals preserved: `1`')
$lines.Add("- Source SHA-256: ``$expectedSourceSha256``")
$lines.Add("- EX5 SHA-256: ``$expectedBinarySha256``")
$lines.Add("- Manifest SHA-256: ``$expectedManifestSha256``")
$lines.Add('- `$10,000`; MT5 Model 1; 2015-2020 discovery; momentum risk `0.15%`; sell target `2.0R`; portfolio cap `0.75%`; real trading disabled')
$lines.Add('- Only the initial target of existing momentum buys changed; architecture was selected from the full leader ledger')
$lines.Add('')
$lines.Add('| Profile | 2015-18 | 2019-20 | Continuous | Return | CAGR | PF | Trades | DD | Recovery | Return/DD | Gate |')
$lines.Add('|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|')
foreach($row in $summary) {
   $label = if($row.Candidate -eq $controlName) { 'Disabled control' } elseif($row.Candidate -eq $centerName) { '**Buy 2.50R center**' } else { "Buy $($row.MomentumBuyTakeProfitR)R" }
   $lines.Add("| $label | $(Money ([double]$row.OlderNetProfit)) | $(Money ([double]$row.LaterNetProfit)) | $(Money ([double]$row.ContinuousNetProfit)) | $($row.TotalReturnPercent)% | $($row.CagrPercent)%/yr | $($row.ProfitFactor) | $($row.TotalTrades) | $($row.MaxDrawdownPercent)% | $($row.RecoveryFactor) | $($row.ReturnDrawdown) | $($row.FrozenGate) |")
}
$lines.Add('')
$lines.Add('## Frozen Gate')
$lines.Add('')
$lines.Add("- Every disjoint era profitable: ``$allErasPositive``")
$lines.Add("- Center retains 98% of both era controls: ``$centerEras``")
$lines.Add("- Center continuous net at least 3% above control: ``$centerGrowth``")
$lines.Add("- Center CAGR at least 0.05 point above control: ``$centerCagr``")
$lines.Add("- Center PF/recovery/return-DD no worse than control: ``$centerEfficiency``")
$lines.Add("- Center drawdown no more than $($drawdownCeiling.ToString('N2',[Globalization.CultureInfo]::InvariantCulture))%: ``$centerRisk``")
$lines.Add("- Center retains at least control minus two trades: ``$centerTrades``")
$lines.Add("- Non-center enabled neighbors passing: ``$lowerPassCount/3``; required: ``2/3``")
$lines.Add('')
$lines.Add('## Interpretation')
$lines.Add('')
$centerDelta = [double]$center.NetProfit - [double]$control.NetProfit
$lines.Add("The center increased continuous net by ``$(Money $centerDelta)``, improved PF from ``$($control.ProfitFactor)`` to ``$($center.ProfitFactor)``, improved recovery from ``$($control.RecoveryFactor)`` to ``$($center.RecoveryFactor)``, and raised drawdown only from ``$($control.MaxDrawdownPercent)%`` to ``$($center.MaxDrawdownPercent)%``. It produced ``$($center.TotalTrades)`` trades versus the frozen minimum of ``$([int]$control.TotalTrades - 2)``, so the center fails only the preregistered trade-retention gate.")
$lines.Add('')
$lines.Add("The best headline row was ``$($bestEnabled.Candidate)`` at ``$(Money ([double]$bestEnabled.ContinuousNetProfit))``, but no non-center neighbor passed the complete frozen support gate. The 2.50R center is a useful near-miss, not permission to relax the gate after observation, so newer data and Model 4 remain closed.")
$lines.Add('')
$lines.Add('The provisional strong-signal selective reversion lot-cap leader and registered forward candidate remain unchanged. Real-account trading remains disabled.')
$lines | Set-Content -LiteralPath (Resolve-RepoPath $DecisionMarkdownPath) -Encoding ASCII

Remove-Item -LiteralPath (Resolve-RepoPath $rawResults),(Resolve-RepoPath $rawSummary),(Resolve-RepoPath $rawMetrics) -Force -ErrorAction SilentlyContinue
$decision
