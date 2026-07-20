[CmdletBinding()]
param(
   [string]$ManifestPath = 'outputs\THREE_LANE_MOMENTUM_BUY_RESIDUAL_RISK_DISCOVERY_MODEL1_MANIFEST.csv',
   [string]$ReportDir = 'outputs\three_lane_momentum_buy_residual_risk_discovery_model1_package\reports_here',
   [string]$ResultsPath = 'outputs\THREE_LANE_MOMENTUM_BUY_RESIDUAL_RISK_DISCOVERY_MODEL1_RESULTS.csv',
   [string]$SummaryPath = 'outputs\THREE_LANE_MOMENTUM_BUY_RESIDUAL_RISK_DISCOVERY_SUMMARY.csv',
   [string]$DecisionCsvPath = 'outputs\THREE_LANE_MOMENTUM_BUY_RESIDUAL_RISK_DISCOVERY_DECISION.csv',
   [string]$DecisionMarkdownPath = 'outputs\THREE_LANE_MOMENTUM_BUY_RESIDUAL_RISK_DISCOVERY_DECISION.md',
   [string]$RunAttestationPath = 'outputs\THREE_LANE_MOMENTUM_BUY_RESIDUAL_RISK_DISCOVERY_RUN_ATTESTATION.csv'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$expectedSourceSha256 = '872028C76FDD4183E6266BB0E48125BB6B0F48EA3E77B9663B92A7F68B9ACD04'
$expectedBinarySha256 = '0093251D7E6D9EAFBAC1B8B056DBB876CC1C63D462F93BDE5FCDE98BC9162642'
$expectedManifestSha256 = 'DFF64057A4A8B9969198F3CE517E07E53FCF3A16CE4CFCB198FB79BA772CA53F'
$controlName = 'mbr_control'
$centerName = 'mbr_center_buy020'
$lowerNames = @('mbr_buy016','mbr_buy017','mbr_buy018','mbr_buy019')
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
if($manifest.Count -ne 18 -or @($manifest.Candidate | Sort-Object -Unique).Count -ne 6 -or
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
if($raw.Count -ne 18 -or @($raw | Where-Object Status -ne 'PARSED').Count -ne 0) {
   throw 'Expected eighteen parsed reports.'
}
$rawByReport = @{}
foreach($row in $raw) { $rawByReport[[string]$row.ExpectedReportName] = $row }

$recoveryFile = Resolve-RepoPath 'outputs\THREE_LANE_MOMENTUM_BUY_RESIDUAL_RISK_RECOVERY_WORKER_1.csv'
$finalRuns = @(Import-Csv -LiteralPath $recoveryFile)
if($finalRuns.Count -ne 18 -or @($finalRuns | Where-Object {
   $_.Status -ne 'REPORT_FOUND' -or $_.PackageSourceSha256 -ne $expectedSourceSha256 -or
   $_.PortableBinarySha256 -ne $expectedBinarySha256 -or $_.PortableExpertRecompiled -ne 'False'
}).Count -ne 0) {
   throw 'Final run evidence is incomplete or has an identity mismatch.'
}
$firstRetryRows = @(Get-ChildItem (Resolve-RepoPath 'outputs') -Filter 'THREE_LANE_MOMENTUM_BUY_RESIDUAL_RISK_WORKER_*.csv' -File |
   ForEach-Object { Import-Csv -LiteralPath $_.FullName })
$preservedIdentityRefusals = @($firstRetryRows | Where-Object Status -eq 'ERROR').Count
if($firstRetryRows.Count -ne 18 -or $preservedIdentityRefusals -ne 1) {
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
      From=$item.From;To=$item.To;Model=[int]$item.Model;BuyResidualRiskEnabled=$item.BuyResidualRiskEnabled
      MomentumBuyRiskPercent=[double]$item.MomentumBuyRiskPercent;MomentumSellRiskPercent=[double]$item.MomentumSellRiskPercent
      BaseLotEligibility=$item.BaseLotEligibility;ProfileSha256=$item.ProfileSha256
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
$drawdownCeiling = [Math]::Min(1.20,[double]$control.MaxDrawdownPercent + 0.10)

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
   return (ErasRetain $Name) -and [double]$row.NetProfit -ge 1.02 * [double]$control.NetProfit -and
      [double]$row.ProfitFactor -ge 0.97 * [double]$control.ProfitFactor -and
      [double]$row.RecoveryFactor -ge 0.97 * [double]$control.RecoveryFactor -and
      [double]$row.ReturnDrawdown -ge 0.97 * [double]$control.ReturnDrawdown -and
      [double]$row.MaxDrawdownPercent -le $drawdownCeiling -and
      [int]$row.TotalTrades -eq [int]$control.TotalTrades -and (BehaviorChanged $Name)
}

$allErasPositive = @($results | Where-Object {
   $_.Window -in @('older_2015_2018','later_2019_2020') -and [double]$_.NetProfit -le 0.0
}).Count -eq 0
$centerEras = ErasRetain $centerName
$centerGrowth = [double]$center.NetProfit -ge 1.04 * [double]$control.NetProfit
$centerCagr = [double]$center.CagrPercent -ge [double]$control.CagrPercent + 0.06
$centerEfficiency = [double]$center.ProfitFactor -ge 0.97 * [double]$control.ProfitFactor -and
   [double]$center.RecoveryFactor -ge 0.97 * [double]$control.RecoveryFactor -and
   [double]$center.ReturnDrawdown -ge 0.97 * [double]$control.ReturnDrawdown
$centerRisk = [double]$center.MaxDrawdownPercent -le $drawdownCeiling
$centerTrades = [int]$center.TotalTrades -eq [int]$control.TotalTrades
$centerBehavior = BehaviorChanged $centerName
$lowerGates = [ordered]@{}
foreach($name in $lowerNames) { $lowerGates[$name] = LowerPass $name }
$lowerPassCount = @($lowerGates.Values | Where-Object { $_ }).Count
$passed = $allErasPositive -and $centerEras -and $centerGrowth -and $centerCagr -and
   $centerEfficiency -and $centerRisk -and $centerTrades -and $centerBehavior -and $lowerPassCount -ge 3

$orderedNames = @($controlName) + $lowerNames + @($centerName)
$summary = foreach($name in $orderedNames) {
   $row = $lookup["$name|continuous_2015_2020"]
   [pscustomobject][ordered]@{
      Candidate=$name;Role=$row.Role;BuyResidualRiskEnabled=$row.BuyResidualRiskEnabled
      MomentumBuyRiskPercent=$row.MomentumBuyRiskPercent
      OlderNetProfit=$lookup["$name|older_2015_2018"].NetProfit
      LaterNetProfit=$lookup["$name|later_2019_2020"].NetProfit
      ContinuousNetProfit=$row.NetProfit;TotalReturnPercent=$row.TotalReturnPercent;CagrPercent=$row.CagrPercent
      ProfitFactor=$row.ProfitFactor;TotalTrades=$row.TotalTrades;MaxDrawdownPercent=$row.MaxDrawdownPercent
      RecoveryFactor=$row.RecoveryFactor;ReturnDrawdown=$row.ReturnDrawdown;BehaviorChanged=BehaviorChanged $name
      FrozenGate=if($name -eq $controlName){'CONTROL'}elseif($name -eq $centerName){$centerEras -and $centerGrowth -and $centerCagr -and $centerEfficiency -and $centerRisk -and $centerTrades -and $centerBehavior}else{$lowerGates[$name]}
   }
}
$summary | Export-Csv -LiteralPath (Resolve-RepoPath $SummaryPath) -NoTypeInformation -Encoding ASCII
$bestEnabled = @($summary | Where-Object BuyResidualRiskEnabled -eq 'true' | Sort-Object {[double]$_.ContinuousNetProfit} -Descending)[0]

$decision = [pscustomobject][ordered]@{
   Status=if($passed){'DISCOVERY_GATE_PASSED'}else{'REJECTED_IN_DISCOVERY'};ReportsParsed=18;IdentityValidReports=18
   PreservedIdentityRefusals=$preservedIdentityRefusals;AllDisjointErasPositive=$allErasPositive
   CenterEraRetentionGate=$centerEras;CenterGrowthGate=$centerGrowth;CenterCagrGate=$centerCagr
   CenterEfficiencyGate=$centerEfficiency;CenterRiskGate=$centerRisk;CenterTradeCountGate=$centerTrades
   CenterBehaviorChanged=$centerBehavior;LowerRungsPassed=$lowerPassCount;LowerRungsRequired=3
   HoldoutValidationPermitted=$passed;Model4ValidationPermitted=$false;ResearchPromotionPermitted=$false
   ForwardCandidateChanged=$false;RealAccountTradingAllowed=$false;ControlNetProfit=$control.NetProfit
   CenterNetProfit=$center.NetProfit;CenterMaxDrawdownPercent=$center.MaxDrawdownPercent
   BestEnabledCandidate=$bestEnabled.Candidate;BestEnabledNetProfit=$bestEnabled.ContinuousNetProfit
   SourceSha256=$expectedSourceSha256;BinarySha256=$expectedBinarySha256;ManifestSha256=$expectedManifestSha256
}
$decision | Export-Csv -LiteralPath (Resolve-RepoPath $DecisionCsvPath) -NoTypeInformation -Encoding ASCII

$lines = [Collections.Generic.List[string]]::new()
$lines.Add('# Three-Lane Momentum Buy Residual-Risk Discovery Decision')
$lines.Add('')
$lines.Add($(if($passed){'**Decision: DISCOVERY GATE PASSED. Only the frozen center may proceed to recent confirmation; Model 4 and promotion remain closed.**'}else{'**Decision: REJECTED IN DISCOVERY. No recent confirmation, Model 4, promotion, forward change, or live approval is permitted.**'}))
$lines.Add('')
$lines.Add('- Exact accepted reports: `18/18`; unchanged identity retry refusals preserved: `1`')
$lines.Add("- Source SHA-256: ``$expectedSourceSha256``")
$lines.Add("- EX5 SHA-256: ``$expectedBinarySha256``")
$lines.Add("- Manifest SHA-256: ``$expectedManifestSha256``")
$lines.Add('- `$10,000`; MT5 Model 1; 2015-2020 discovery; base momentum risk `0.15%`; portfolio cap `0.75%`; real trading disabled')
$lines.Add('- Base-lot eligibility was required before residual sizing; architecture was selected from the full leader ledger')
$lines.Add('')
$lines.Add('| Profile | 2015-18 | 2019-20 | Continuous | Return | CAGR | PF | Trades | DD | Recovery | Return/DD | Gate |')
$lines.Add('|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|')
foreach($row in $summary) {
   $label = if($row.Candidate -eq $controlName) { 'Disabled control' } elseif($row.Candidate -eq $centerName) { '**Buy 0.20% center**' } else { "Buy $($row.MomentumBuyRiskPercent)%" }
   $lines.Add("| $label | $(Money ([double]$row.OlderNetProfit)) | $(Money ([double]$row.LaterNetProfit)) | $(Money ([double]$row.ContinuousNetProfit)) | $($row.TotalReturnPercent)% | $($row.CagrPercent)%/yr | $($row.ProfitFactor) | $($row.TotalTrades) | $($row.MaxDrawdownPercent)% | $($row.RecoveryFactor) | $($row.ReturnDrawdown) | $($row.FrozenGate) |")
}
$lines.Add('')
$lines.Add('## Frozen Gate')
$lines.Add('')
$lines.Add("- Every disjoint era profitable: ``$allErasPositive``")
$lines.Add("- Center retains 98% of both era controls: ``$centerEras``")
$lines.Add("- Center continuous net at least 4% above control: ``$centerGrowth``")
$lines.Add("- Center CAGR at least 0.06 point above control: ``$centerCagr``")
$lines.Add("- Center retains 97% PF/recovery/return-DD: ``$centerEfficiency``")
$lines.Add("- Center drawdown no more than $($drawdownCeiling.ToString('N2',[Globalization.CultureInfo]::InvariantCulture))%: ``$centerRisk``")
$lines.Add("- Center preserves control trade count: ``$centerTrades``")
$lines.Add("- Lower rungs passing: ``$lowerPassCount/4``; required: ``3/4``")
$lines.Add('')
$lines.Add('## Interpretation')
$lines.Add('')
$centerDelta = [double]$center.NetProfit - [double]$control.NetProfit
$lines.Add("The center increased continuous net by ``$(Money $centerDelta)``, but drawdown rose from ``$($control.MaxDrawdownPercent)%`` to ``$($center.MaxDrawdownPercent)%``, PF fell from ``$($control.ProfitFactor)`` to ``$($center.ProfitFactor)``, and recovery fell from ``$($control.RecoveryFactor)`` to ``$($center.RecoveryFactor)``. It also added one trade despite frozen base-lot eligibility. The center therefore fails the efficiency, risk, and trade-count gates.")
$lines.Add('')
$lines.Add("The best headline row was ``$($bestEnabled.Candidate)`` at ``$(Money ([double]$bestEnabled.ContinuousNetProfit))``, but no lower rung passed the full frozen gate. Selecting it after observing the ladder would trade a stable neighborhood for higher drawdown, so newer data and Model 4 remain closed.")
$lines.Add('')
$lines.Add('An earlier direction-specific prototype produced zero trades because its static preflight metadata used the source default adaptive risk instead of the exact leader profile value. That run is classified as an invalid configuration, excluded from strategy evidence, and not published as a strategy result.')
$lines.Add('')
$lines.Add('The provisional strong-signal selective reversion lot-cap leader and registered forward candidate remain unchanged. Real-account trading remains disabled.')
$lines | Set-Content -LiteralPath (Resolve-RepoPath $DecisionMarkdownPath) -Encoding ASCII

Remove-Item -LiteralPath (Resolve-RepoPath $rawResults),(Resolve-RepoPath $rawSummary),(Resolve-RepoPath $rawMetrics) -Force -ErrorAction SilentlyContinue
$decision
