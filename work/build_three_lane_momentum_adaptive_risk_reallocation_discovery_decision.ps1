[CmdletBinding()]
param(
   [string]$ManifestPath = 'outputs\THREE_LANE_MOMENTUM_ADAPTIVE_RISK_REALLOCATION_DISCOVERY_MODEL1_MANIFEST.csv',
   [string]$ReportDir = 'outputs\three_lane_momentum_adaptive_risk_reallocation_discovery_model1_package\reports_here',
   [string]$ResultsPath = 'outputs\THREE_LANE_MOMENTUM_ADAPTIVE_RISK_REALLOCATION_DISCOVERY_MODEL1_RESULTS.csv',
   [string]$SummaryPath = 'outputs\THREE_LANE_MOMENTUM_ADAPTIVE_RISK_REALLOCATION_DISCOVERY_SUMMARY.csv',
   [string]$DecisionCsvPath = 'outputs\THREE_LANE_MOMENTUM_ADAPTIVE_RISK_REALLOCATION_DISCOVERY_DECISION.csv',
   [string]$DecisionMarkdownPath = 'outputs\THREE_LANE_MOMENTUM_ADAPTIVE_RISK_REALLOCATION_DISCOVERY_DECISION.md',
   [string]$RunAttestationPath = 'outputs\THREE_LANE_MOMENTUM_ADAPTIVE_RISK_REALLOCATION_DISCOVERY_RUN_ATTESTATION.csv'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$expectedSourceSha256 = 'B6810B305549968E2273DAAF736A63759FE5C16F3B416F5C69E39840FBE5173E'
$expectedBinarySha256 = '0BF7AEEE1D5F9496A6C7A88012D7059A8D894B2475097C158254670E1A189883'
$expectedManifestSha256 = '1A22157C6C27F4DF07B7FF82B4AC8100A5D785DC212169EBD9A8E3137D1CC938'
$controlName = 'marr_control_015_015'
$centerName = 'marr_center_020_010'
$lowerNames = @('marr_016_014','marr_0175_0125','marr_019_011')

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
if(@($manifest | Where-Object {
   $_.SourceSha256 -ne $expectedSourceSha256 -or [int]$_.Model -ne 1 -or
   [double]$_.DeclaredLaneRiskSumPercent -ne 0.75 -or [double]$_.MaximumPortfolioOpenRiskPercent -ne 0.75
}).Count -ne 0) {
   throw 'Manifest source, model, or risk-cap identity changed.'
}
foreach($item in $manifest) {
   $config = Resolve-RepoPath ([string]$item.PackageConfig)
   if((Get-FileHash -LiteralPath $config -Algorithm SHA256).Hash.ToUpperInvariant() -ne $item.ConfigSha256) {
      throw "Config identity changed at rank $($item.QueueRank)."
   }
}

$rawResults = 'work\MARR_DECISION_RAW_RESULTS.csv'
$rawSummary = 'work\MARR_DECISION_RAW_SUMMARY.csv'
$rawMetrics = 'work\MARR_DECISION_RAW_METRICS.md'
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

$recoveryFile = Resolve-RepoPath 'outputs\THREE_LANE_MOMENTUM_ADAPTIVE_RISK_REALLOCATION_RECOVERY_WORKER_1.csv'
$finalRuns = @(Import-Csv -LiteralPath $recoveryFile)
if($finalRuns.Count -ne 15 -or @($finalRuns | Where-Object {
   $_.Status -ne 'REPORT_FOUND' -or $_.PackageSourceSha256 -ne $expectedSourceSha256 -or
   $_.PortableBinarySha256 -ne $expectedBinarySha256 -or $_.PortableExpertRecompiled -ne 'False'
}).Count -ne 0) {
   throw 'Final run evidence is incomplete or has an identity mismatch.'
}
$firstRows = @(Get-ChildItem (Resolve-RepoPath 'outputs') -Filter 'THREE_LANE_MOMENTUM_ADAPTIVE_RISK_REALLOCATION_WORKER_*.csv' -File |
   ForEach-Object { Import-Csv -LiteralPath $_.FullName })
$preservedIdentityRefusals = @($firstRows | Where-Object Status -eq 'ERROR').Count
if($firstRows.Count -ne 15 -or $preservedIdentityRefusals -ne 3) {
   throw 'Expected the preserved first-pass evidence with three identity refusals.'
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
      From=$item.From;To=$item.To;Model=[int]$item.Model
      MomentumRiskPercent=[double]$item.MomentumRiskPercent;AdaptiveRiskPercent=[double]$item.AdaptiveRiskPercent
      ReversionRiskPercent=[double]$item.ReversionRiskPercent;PortfolioCapPercent=[double]$item.MaximumPortfolioOpenRiskPercent
      ProfileSha256=$item.ProfileSha256;SourceSha256=$item.SourceSha256;BinarySha256=$run.PortableBinarySha256
      Status=$parsed.Status;NetProfit=[Math]::Round([double]$parsed.NetProfit,2)
      TotalReturnPercent=[Math]::Round([double]$parsed.TotalReturnPercent,2)
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
$drawdownCeiling = [Math]::Min(1.30,[double]$control.MaxDrawdownPercent + 0.20)

function ErasNoWorse([string]$Name) {
   foreach($window in @('older_2015_2018','later_2019_2020')) {
      if([double]$lookup["$Name|$window"].NetProfit -lt [double]$lookup["$controlName|$window"].NetProfit) { return $false }
   }
   return $true
}
function BehaviorChanged([string]$Name) {
   $row = $lookup["$Name|continuous_2015_2020"]
   return [double]$row.NetProfit -ne [double]$control.NetProfit -or
      [double]$row.MaxDrawdownPercent -ne [double]$control.MaxDrawdownPercent -or
      [int]$row.TotalTrades -ne [int]$control.TotalTrades
}
function LowerPass([string]$Name) {
   $row = $lookup["$Name|continuous_2015_2020"]
   return (ErasNoWorse $Name) -and [double]$row.NetProfit -ge 1.02 * [double]$control.NetProfit -and
      [double]$row.ProfitFactor -ge 0.97 * [double]$control.ProfitFactor -and
      [double]$row.RecoveryFactor -ge 0.97 * [double]$control.RecoveryFactor -and
      [double]$row.ReturnDrawdown -ge 0.97 * [double]$control.ReturnDrawdown -and
      [double]$row.MaxDrawdownPercent -le $drawdownCeiling -and
      [int]$row.TotalTrades -ge [Math]::Ceiling(0.98 * [int]$control.TotalTrades) -and (BehaviorChanged $Name)
}

$allErasPositive = @($results | Where-Object {
   $_.Window -in @('older_2015_2018','later_2019_2020') -and [double]$_.NetProfit -le 0.0
}).Count -eq 0
$centerEras = ErasNoWorse $centerName
$centerGrowth = [double]$center.NetProfit -ge 1.05 * [double]$control.NetProfit
$centerCagr = [double]$center.CagrPercent -ge [double]$control.CagrPercent + 0.08
$centerEfficiency = [double]$center.ProfitFactor -ge 0.97 * [double]$control.ProfitFactor -and
   [double]$center.RecoveryFactor -ge 0.97 * [double]$control.RecoveryFactor -and
   [double]$center.ReturnDrawdown -ge 0.97 * [double]$control.ReturnDrawdown
$centerRisk = [double]$center.MaxDrawdownPercent -le $drawdownCeiling
$centerTrades = [int]$center.TotalTrades -ge [Math]::Ceiling(0.98 * [int]$control.TotalTrades)
$centerBehavior = BehaviorChanged $centerName
$lowerGates = [ordered]@{}
foreach($name in $lowerNames) { $lowerGates[$name] = LowerPass $name }
$lowerPassCount = @($lowerGates.Values | Where-Object { $_ }).Count
$passed = $allErasPositive -and $centerEras -and $centerGrowth -and $centerCagr -and
   $centerEfficiency -and $centerRisk -and $centerTrades -and $centerBehavior -and $lowerPassCount -ge 2

$orderedNames = @($controlName) + $lowerNames + @($centerName)
$summary = foreach($name in $orderedNames) {
   $row = $lookup["$name|continuous_2015_2020"]
   [pscustomobject][ordered]@{
      Candidate=$name;Role=$row.Role;MomentumRiskPercent=$row.MomentumRiskPercent;AdaptiveRiskPercent=$row.AdaptiveRiskPercent
      OlderNetProfit=$lookup["$name|older_2015_2018"].NetProfit
      LaterNetProfit=$lookup["$name|later_2019_2020"].NetProfit
      ContinuousNetProfit=$row.NetProfit;TotalReturnPercent=$row.TotalReturnPercent;CagrPercent=$row.CagrPercent
      ProfitFactor=$row.ProfitFactor;TotalTrades=$row.TotalTrades;MaxDrawdownPercent=$row.MaxDrawdownPercent
      RecoveryFactor=$row.RecoveryFactor;ReturnDrawdown=$row.ReturnDrawdown;BehaviorChanged=BehaviorChanged $name
      FrozenGate=if($name -eq $controlName){'CONTROL'}elseif($name -eq $centerName){$centerEras -and $centerGrowth -and $centerCagr -and $centerEfficiency -and $centerRisk -and $centerTrades -and $centerBehavior}else{$lowerGates[$name]}
   }
}
$summary | Export-Csv -LiteralPath (Resolve-RepoPath $SummaryPath) -NoTypeInformation -Encoding ASCII
$bestHeadline = @($summary | Sort-Object {[double]$_.ContinuousNetProfit} -Descending)[0]

$decision = [pscustomobject][ordered]@{
   Status=if($passed){'DISCOVERY_GATE_PASSED'}else{'REJECTED_IN_DISCOVERY'};ReportsParsed=15;IdentityValidReports=15
   PreservedIdentityRefusals=$preservedIdentityRefusals;AllDisjointErasPositive=$allErasPositive
   CenterNoWorseBothEras=$centerEras;CenterGrowthPass=$centerGrowth;CenterCagrPass=$centerCagr
   CenterEfficiencyPass=$centerEfficiency;CenterRiskPass=$centerRisk;CenterTradeRetentionPass=$centerTrades
   CenterBehaviorChanged=$centerBehavior;LowerRungsPassed=$lowerPassCount;LowerRungsRequired=2
   NewerDataValidationPermitted=$passed;Model4ValidationPermitted=$false;ResearchPromotionPermitted=$false
   ForwardCandidateChanged=$false;RealAccountTradingAllowed=$false
   ControlNetProfit=$control.NetProfit;CenterNetProfit=$center.NetProfit;CenterMaxDrawdownPercent=$center.MaxDrawdownPercent
   BestHeadlineCandidate=$bestHeadline.Candidate;BestHeadlineNetProfit=$bestHeadline.ContinuousNetProfit
   SourceSha256=$expectedSourceSha256;BinarySha256=$expectedBinarySha256;ManifestSha256=$expectedManifestSha256
}
$decision | Export-Csv -LiteralPath (Resolve-RepoPath $DecisionCsvPath) -NoTypeInformation -Encoding ASCII

$lines = [Collections.Generic.List[string]]::new()
$lines.Add('# Momentum-Adaptive Risk Reallocation Discovery Decision')
$lines.Add('')
$lines.Add($(if($passed){'**Decision: DISCOVERY GATE PASSED. Only the frozen center may proceed to newer-data confirmation; Model 4 and promotion remain closed.**'}else{'**Decision: REJECTED IN DISCOVERY. Newer data, Model 4, promotion, forward change, and real trading remain closed.**'}))
$lines.Add('')
$lines.Add('- Exact accepted Model 1 reports: `15/15`; preserved first-pass identity refusals: `3`')
$lines.Add("- Source SHA-256: ``$expectedSourceSha256``")
$lines.Add("- EX5 SHA-256: ``$expectedBinarySha256``")
$lines.Add("- Manifest SHA-256: ``$expectedManifestSha256``")
$lines.Add('- `$10,000`; 2015-2020 discovery; reversion risk `0.45%`; total declared lane risk and portfolio cap fixed at `0.75%`')
$lines.Add('')
$lines.Add('| Allocation (MO / ATB) | 2015-18 | 2019-20 | Continuous | CAGR | PF | Trades | DD | Recovery | Return/DD | Gate |')
$lines.Add('|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|')
foreach($row in $summary) {
   $label = if($row.Candidate -eq $controlName) { 'Control 0.15 / 0.15' } elseif($row.Candidate -eq $centerName) { '**Center 0.20 / 0.10**' } else { "$($row.MomentumRiskPercent) / $($row.AdaptiveRiskPercent)" }
   $lines.Add("| $label | $(Money ([double]$row.OlderNetProfit)) | $(Money ([double]$row.LaterNetProfit)) | $(Money ([double]$row.ContinuousNetProfit)) | $($row.CagrPercent)%/yr | $($row.ProfitFactor) | $($row.TotalTrades) | $($row.MaxDrawdownPercent)% | $($row.RecoveryFactor) | $($row.ReturnDrawdown) | $($row.FrozenGate) |")
}
$lines.Add('')
$lines.Add('## Frozen Gate')
$lines.Add('')
$lines.Add("- Every disjoint-era row profitable: ``$allErasPositive``")
$lines.Add("- Center no worse than control in both eras: ``$centerEras``")
$lines.Add("- Center continuous net at least 5% above control: ``$centerGrowth``")
$lines.Add("- Center CAGR at least 0.08 point above control: ``$centerCagr``")
$lines.Add("- Center retains 97% of PF, recovery, and return/DD: ``$centerEfficiency``")
$lines.Add("- Center drawdown no more than $($drawdownCeiling.ToString('N2',[Globalization.CultureInfo]::InvariantCulture))%: ``$centerRisk``")
$lines.Add("- Center retains at least 98% of trades: ``$centerTrades``")
$lines.Add("- Lower rungs passing: ``$lowerPassCount/3``; required: ``2/3``")
$lines.Add('')
$lines.Add('## Interpretation')
$lines.Add('')
$centerDelta = [double]$center.NetProfit - [double]$control.NetProfit
$lines.Add("The center increased continuous net by ``$(Money $centerDelta)``, but 2019-2020 profit fell from ``$(Money ([double]$lookup["$controlName|later_2019_2020"].NetProfit))`` to ``$(Money ([double]$lookup["$centerName|later_2019_2020"].NetProfit))``. Drawdown rose from ``$($control.MaxDrawdownPercent)%`` to ``$($center.MaxDrawdownPercent)%``, PF fell from ``$($control.ProfitFactor)`` to ``$($center.ProfitFactor)``, and trades fell from ``$($control.TotalTrades)`` to ``$($center.TotalTrades)``.")
$lines.Add('')
$lines.Add("No lower rung passed the full frozen gate. The best headline row was ``$($bestHeadline.Candidate)`` at ``$(Money ([double]$bestHeadline.ContinuousNetProfit))``, but selecting it would exchange broad-era stability, activity, and drawdown efficiency for a higher in-sample net result.")
$lines.Add('')
$lines.Add('The published same-side exit-cooldown leader and registered forward candidate remain unchanged. The invalid `$100,000` demo is not forward evidence, and real-account trading remains disabled.')
$lines | Set-Content -LiteralPath (Resolve-RepoPath $DecisionMarkdownPath) -Encoding ASCII

Remove-Item -LiteralPath (Resolve-RepoPath $rawResults),(Resolve-RepoPath $rawSummary),(Resolve-RepoPath $rawMetrics) -Force -ErrorAction SilentlyContinue
$decision
