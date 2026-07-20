[CmdletBinding()]
param(
   [string]$ManifestPath = 'outputs\THREE_LANE_CAPITAL_EFFICIENCY_RISK_LADDER_DISCOVERY_MODEL1_MANIFEST.csv',
   [string]$ReportDir = 'outputs\three_lane_capital_efficiency_risk_ladder_discovery_model1_package\reports_here',
   [string]$ResultsPath = 'outputs\THREE_LANE_CAPITAL_EFFICIENCY_RISK_LADDER_DISCOVERY_MODEL1_RESULTS.csv',
   [string]$SummaryPath = 'outputs\THREE_LANE_CAPITAL_EFFICIENCY_RISK_LADDER_DISCOVERY_SUMMARY.csv',
   [string]$DecisionCsvPath = 'outputs\THREE_LANE_CAPITAL_EFFICIENCY_RISK_LADDER_DISCOVERY_DECISION.csv',
   [string]$DecisionMarkdownPath = 'outputs\THREE_LANE_CAPITAL_EFFICIENCY_RISK_LADDER_DISCOVERY_DECISION.md',
   [string]$RunAttestationPath = 'outputs\THREE_LANE_CAPITAL_EFFICIENCY_RISK_LADDER_DISCOVERY_RUN_ATTESTATION.csv'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$expectedSourceSha256 = 'B6810B305549968E2273DAAF736A63759FE5C16F3B416F5C69E39840FBE5173E'
$expectedBinarySha256 = 'D0619DFEF164F5A70F5AC48D124F553C554F30CE613C9A2A208B150B2E71C7FC'
$expectedManifestSha256 = '36BADB8D3656E921BD544F35FA4DA6B2B95438DF200EC0866723B4E75566584E'
$controlName = 'cerl_control100'
$centerName = 'cerl_center150'
$neighborNames = @('cerl_low125','cerl_high175')
$eraNames = @('older_2015_2018','middle_2019_2020','recent_2021_2023','latest_2024_2026')
$continuousName = 'continuous_2015_2026'

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
if($manifest.Count -ne 20 -or @($manifest.Candidate | Sort-Object -Unique).Count -ne 4 -or
   @($manifest.Window | Sort-Object -Unique).Count -ne 5) {
   throw 'Frozen manifest topology changed.'
}
if(@($manifest | Where-Object {
   $_.SourceSha256 -ne $expectedSourceSha256 -or [int]$_.Model -ne 1 -or [double]$_.Deposit -ne 10000
}).Count -ne 0) {
   throw 'Manifest source, model, or deposit identity changed.'
}
foreach($item in $manifest) {
   $config = Resolve-RepoPath ([string]$item.PackageConfig)
   if((Get-FileHash -LiteralPath $config -Algorithm SHA256).Hash.ToUpperInvariant() -ne $item.ConfigSha256) {
      throw "Config identity changed at rank $($item.QueueRank)."
   }
}

$rawResults = 'work\CERL_DECISION_RAW_RESULTS.csv'
$rawSummary = 'work\CERL_DECISION_RAW_SUMMARY.csv'
$rawMetrics = 'work\CERL_DECISION_RAW_METRICS.md'
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'collect_validation_results.ps1') `
   -RepoRoot $repo -Manifest $ManifestPath -ReportDir $ReportDir -ReportNameTemplate '{ExpectedReportName}' `
   -OutResults $rawResults -OutSummary $rawSummary -OutMarkdown $rawMetrics | Out-Null
if($LASTEXITCODE -ne 0) { throw 'Shared report collector failed.' }
$raw = @(Import-Csv -LiteralPath (Resolve-RepoPath $rawResults))
if($raw.Count -ne 20 -or @($raw | Where-Object Status -ne 'PARSED').Count -ne 0) {
   throw 'Expected twenty parsed reports.'
}
$rawByReport = @{}
foreach($row in $raw) { $rawByReport[[string]$row.ExpectedReportName] = $row }

$firstRuns = @(Get-ChildItem (Resolve-RepoPath 'outputs') -Filter 'THREE_LANE_CAPITAL_EFFICIENCY_RISK_LADDER_DISCOVERY_WORKER_*.csv' -File |
   ForEach-Object { Import-Csv -LiteralPath $_.FullName })
$recoveryRuns = @(Get-ChildItem (Resolve-RepoPath 'outputs') -Filter 'THREE_LANE_CAPITAL_EFFICIENCY_RISK_LADDER_DISCOVERY_RECOVERY_*.csv' -File |
   ForEach-Object { Import-Csv -LiteralPath $_.FullName })
$identityRefusals = @($firstRuns | Where-Object Status -eq 'ERROR').Count
$acceptedRuns = @($firstRuns + $recoveryRuns | Where-Object Status -eq 'REPORT_FOUND')
$runByKey = @{}
foreach($run in $acceptedRuns) { $runByKey["$($run.Candidate)|$($run.Window)"] = $run }
if($firstRuns.Count -ne 20 -or $identityRefusals -ne 1 -or $runByKey.Count -ne 20) {
   throw 'Expected nineteen first-pass reports, one identity refusal, and one successful recovery.'
}

$results = [Collections.Generic.List[object]]::new()
$attestation = [Collections.Generic.List[object]]::new()
foreach($item in ($manifest | Sort-Object { [int]$_.QueueRank })) {
   $parsed = $rawByReport[[string]$item.ExpectedReportName]
   $run = $runByKey["$($item.Candidate)|$($item.Window)"]
   if($null -eq $parsed -or $null -eq $run) { throw "Evidence missing for rank $($item.QueueRank)." }
   if($run.PackageSourceSha256 -ne $expectedSourceSha256 -or
      $run.PortableBinarySha256 -ne $expectedBinarySha256 -or $run.PortableExpertRecompiled -ne 'False') {
      throw "Run identity mismatch for rank $($item.QueueRank)."
   }
   $identityPath = [string]$run.ReportIdentityPath
   if(!(Test-Path -LiteralPath $identityPath -PathType Leaf)) { throw "Identity sidecar missing for rank $($item.QueueRank)." }
   $identity = Get-Content -LiteralPath $identityPath -Raw | ConvertFrom-Json
   if($identity.SourceSha256 -ne $expectedSourceSha256 -or
      $identity.PortableBinarySha256 -ne $expectedBinarySha256 -or
      $identity.ReportSha256 -ne $run.ReportSha256 -or $identity.ConfigSha256 -ne $run.PackageConfigSha256) {
      throw "Identity sidecar mismatch for rank $($item.QueueRank)."
   }
   $returnDrawdown = if([double]$parsed.MaxDrawdownPercent -gt 0.0) {
      [double]$parsed.TotalReturnPercent / [double]$parsed.MaxDrawdownPercent
   } else { 0.0 }
   $results.Add([pscustomobject][ordered]@{
      QueueRank=[int]$item.QueueRank;Candidate=$item.Candidate;Role=$item.Role;Window=$item.Window
      From=$item.From;To=$item.To;Model=[int]$item.Model;RiskScaleFactor=[double]$item.RiskScaleFactor
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

$by = @{}
foreach($row in $results) { $by["$($row.Candidate)|$($row.Window)"] = $row }
$control = $by["$controlName|$continuousName"]
$center = $by["$centerName|$continuousName"]

function All-Eras-Positive([string]$Name) {
   return @($eraNames | Where-Object { [double]$by["$Name|$_"].NetProfit -le 0.0 }).Count -eq 0
}
function Center-Pass {
   return (All-Eras-Positive $centerName) -and
      [double]$center.NetProfit -ge 1.20 * [double]$control.NetProfit -and
      [double]$center.CagrPercent -ge [double]$control.CagrPercent + 0.30 -and
      [int]$center.TotalTrades -ge [Math]::Ceiling(0.90 * [int]$control.TotalTrades) -and
      [double]$center.ProfitFactor -ge 0.90 * [double]$control.ProfitFactor -and
      [double]$center.RecoveryFactor -ge 0.80 * [double]$control.RecoveryFactor -and
      [double]$center.ReturnDrawdown -ge 0.80 * [double]$control.ReturnDrawdown -and
      [double]$center.MaxDrawdownPercent -le 2.00
}
function Neighbor-Pass([string]$Name) {
   $row = $by["$Name|$continuousName"]
   return (All-Eras-Positive $Name) -and [double]$row.NetProfit -ge 1.10 * [double]$control.NetProfit -and
      [double]$row.ProfitFactor -ge 0.80 * [double]$control.ProfitFactor -and
      [double]$row.RecoveryFactor -ge 0.80 * [double]$control.RecoveryFactor -and
      [double]$row.ReturnDrawdown -ge 0.80 * [double]$control.ReturnDrawdown -and
      [double]$row.MaxDrawdownPercent -le 2.25
}

$allRowsPositive = @($results | Where-Object { [double]$_.NetProfit -le 0.0 }).Count -eq 0
$centerPass = Center-Pass
$neighborPasses = [ordered]@{}
foreach($name in $neighborNames) { $neighborPasses[$name] = Neighbor-Pass $name }
$bothNeighborsPass = @($neighborPasses.Values | Where-Object { $_ }).Count -eq 2
$passed = $allRowsPositive -and $centerPass -and $bothNeighborsPass

$orderedNames = @($controlName,'cerl_low125',$centerName,'cerl_high175')
$summary = foreach($name in $orderedNames) {
   $row = $by["$name|$continuousName"]
   [pscustomobject][ordered]@{
      Candidate=$name;RiskScaleFactor=$row.RiskScaleFactor
      OlderNetProfit=$by["$name|older_2015_2018"].NetProfit
      MiddleNetProfit=$by["$name|middle_2019_2020"].NetProfit
      RecentNetProfit=$by["$name|recent_2021_2023"].NetProfit
      LatestNetProfit=$by["$name|latest_2024_2026"].NetProfit
      ContinuousNetProfit=$row.NetProfit;TotalReturnPercent=$row.TotalReturnPercent;CagrPercent=$row.CagrPercent
      ProfitFactor=$row.ProfitFactor;TotalTrades=$row.TotalTrades;MaxDrawdownPercent=$row.MaxDrawdownPercent
      RecoveryFactor=$row.RecoveryFactor;ReturnDrawdown=$row.ReturnDrawdown
      FrozenGate=if($name -eq $controlName){'CONTROL'}elseif($name -eq $centerName){$centerPass}else{$neighborPasses[$name]}
   }
}
$summary | Export-Csv -LiteralPath (Resolve-RepoPath $SummaryPath) -NoTypeInformation -Encoding ASCII
$bestHeadline = @($summary | Sort-Object {[double]$_.ContinuousNetProfit} -Descending)[0]

$decision = [pscustomobject][ordered]@{
   Status=if($passed){'DISCOVERY_GATE_PASSED'}else{'REJECTED_IN_DISCOVERY'}
   ReportsParsed=20;IdentityValidReports=20;PreservedIdentityRefusals=$identityRefusals
   EveryRowProfitable=$allRowsPositive;CenterGatePass=$centerPass
   LowNeighborGatePass=$neighborPasses['cerl_low125'];HighNeighborGatePass=$neighborPasses['cerl_high175']
   BothNeighborsPass=$bothNeighborsPass;Model4ValidationPermitted=$passed;ResearchPromotionPermitted=$false
   ForwardCandidateChanged=$false;RealAccountTradingAllowed=$false
   ControlNetProfit=$control.NetProfit;ControlCagrPercent=$control.CagrPercent;ControlMaxDrawdownPercent=$control.MaxDrawdownPercent
   CenterNetProfit=$center.NetProfit;CenterCagrPercent=$center.CagrPercent;CenterMaxDrawdownPercent=$center.MaxDrawdownPercent
   BestHeadlineCandidate=$bestHeadline.Candidate;BestHeadlineNetProfit=$bestHeadline.ContinuousNetProfit
   SourceSha256=$expectedSourceSha256;BinarySha256=$expectedBinarySha256;ManifestSha256=$expectedManifestSha256
}
$decision | Export-Csv -LiteralPath (Resolve-RepoPath $DecisionCsvPath) -NoTypeInformation -Encoding ASCII

$lines = [Collections.Generic.List[string]]::new()
$lines.Add('# Capital-Efficiency Risk Ladder Discovery Decision')
$lines.Add('')
$lines.Add($(if($passed){'**Decision: DISCOVERY GATE PASSED. Model 4 confirmation is permitted; promotion and live trading remain closed.**'}else{'**Decision: REJECTED IN DISCOVERY. No Model 4 run, promotion, forward change, or real trading is permitted.**'}))
$lines.Add('')
$lines.Add('- Exact accepted Model 1 reports: `20/20`; preserved first-pass identity refusal: `1`; successful isolated recovery: `1`')
$lines.Add("- Source SHA-256: ``$expectedSourceSha256``")
$lines.Add("- EX5 SHA-256: ``$expectedBinarySha256``")
$lines.Add("- Manifest SHA-256: ``$expectedManifestSha256``")
$lines.Add('- Test contract: XAUUSD M15, `$10,000`, Model 1, 2015-01-01 through 2026-07-12')
$lines.Add('- The `5%` equity drawdown lock and daily, weekly, monthly, cooldown, entry, and exit controls were unchanged.')
$lines.Add('')
$lines.Add('| Risk scale | 2015-18 | 2019-20 | 2021-23 | 2024-26 | Continuous | CAGR | PF | Trades | DD | Recovery | Return/DD | Gate |')
$lines.Add('|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|')
foreach($row in $summary) {
   $label = if($row.Candidate -eq $centerName) { '**1.50x center**' } else { "$($row.RiskScaleFactor.ToString('N2',[Globalization.CultureInfo]::InvariantCulture))x" }
   $lines.Add("| $label | $(Money ([double]$row.OlderNetProfit)) | $(Money ([double]$row.MiddleNetProfit)) | $(Money ([double]$row.RecentNetProfit)) | $(Money ([double]$row.LatestNetProfit)) | $(Money ([double]$row.ContinuousNetProfit)) | $($row.CagrPercent)%/yr | $($row.ProfitFactor) | $($row.TotalTrades) | $($row.MaxDrawdownPercent)% | $($row.RecoveryFactor) | $($row.ReturnDrawdown) | $($row.FrozenGate) |")
}
$lines.Add('')
$lines.Add('## Frozen Gate')
$lines.Add('')
$lines.Add("- Every row and all four disjoint eras profitable: ``$allRowsPositive``")
$lines.Add("- Center continuous net at least 20% above control: ``$([double]$center.NetProfit -ge 1.20 * [double]$control.NetProfit)``")
$lines.Add("- Center CAGR at least 0.30 point above control: ``$([double]$center.CagrPercent -ge [double]$control.CagrPercent + 0.30)``")
$lines.Add("- Center retains 90% of PF: ``$([double]$center.ProfitFactor -ge 0.90 * [double]$control.ProfitFactor)``")
$lines.Add("- Center retains 80% of recovery and return/DD: ``$([double]$center.RecoveryFactor -ge 0.80 * [double]$control.RecoveryFactor -and [double]$center.ReturnDrawdown -ge 0.80 * [double]$control.ReturnDrawdown)``")
$lines.Add("- Center drawdown no greater than 2.00%: ``$([double]$center.MaxDrawdownPercent -le 2.00)``")
$lines.Add("- Both adjacent profiles pass their 10% growth, 80% quality, and 2.25% DD gates: ``$bothNeighborsPass``")
$lines.Add('')
$lines.Add('## Interpretation')
$lines.Add('')
$lines.Add("The 1.50x center raised continuous net from ``$(Money ([double]$control.NetProfit))`` to ``$(Money ([double]$center.NetProfit))`` and CAGR from ``$($control.CagrPercent)%`` to ``$($center.CagrPercent)%``. It did not earn the required 20% improvement, while PF fell from ``$($control.ProfitFactor)`` to ``$($center.ProfitFactor)``, drawdown rose from ``$($control.MaxDrawdownPercent)%`` to ``$($center.MaxDrawdownPercent)%``, recovery fell from ``$($control.RecoveryFactor)`` to ``$($center.RecoveryFactor)``, and return/DD fell from ``$($control.ReturnDrawdown)`` to ``$($center.ReturnDrawdown)``.")
$lines.Add('')
$lines.Add("The best headline row was ``$($bestHeadline.Candidate)`` at ``$(Money ([double]$bestHeadline.ContinuousNetProfit))``, but neither adjacent profile passed. Increasing risk changed position eligibility and skipped-trade behavior, so the ladder was not a clean proportional return increase. Model 4 is closed under the preregistered gate.")
$lines.Add('')
$lines.Add('The verified Model 4 same-side exit-cooldown leader remains unchanged. The invalid `$100,000` demo is not forward evidence, the registered candidate is unchanged, and real-account trading remains disabled.')
$lines | Set-Content -LiteralPath (Resolve-RepoPath $DecisionMarkdownPath) -Encoding ASCII

Remove-Item -LiteralPath (Resolve-RepoPath $rawResults),(Resolve-RepoPath $rawSummary),(Resolve-RepoPath $rawMetrics) -Force -ErrorAction SilentlyContinue
$decision
