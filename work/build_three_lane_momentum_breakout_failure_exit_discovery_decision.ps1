[CmdletBinding()]
param(
   [string]$ManifestPath = 'outputs\THREE_LANE_MOMENTUM_BREAKOUT_FAILURE_EXIT_DISCOVERY_MODEL1_MANIFEST.csv',
   [string]$ReportDir = 'outputs\three_lane_momentum_breakout_failure_exit_discovery_model1_package\reports_here',
   [string]$ResultsPath = 'outputs\THREE_LANE_MOMENTUM_BREAKOUT_FAILURE_EXIT_DISCOVERY_MODEL1_RESULTS.csv',
   [string]$SummaryPath = 'outputs\THREE_LANE_MOMENTUM_BREAKOUT_FAILURE_EXIT_DISCOVERY_MODEL1_SUMMARY.csv',
   [string]$DecisionCsvPath = 'outputs\THREE_LANE_MOMENTUM_BREAKOUT_FAILURE_EXIT_DISCOVERY_DECISION.csv',
   [string]$DecisionMarkdownPath = 'outputs\THREE_LANE_MOMENTUM_BREAKOUT_FAILURE_EXIT_DISCOVERY_DECISION.md',
   [string]$RunAttestationPath = 'outputs\THREE_LANE_MOMENTUM_BREAKOUT_FAILURE_EXIT_DISCOVERY_MODEL1_RUN_ATTESTATION.csv'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$expectedSourceSha256 = 'CBC2309B98AE3EC4969E52B4ADBD5E8A4EFCE8780E0654F5F9B1E9A36AD25EE4'
$expectedBinarySha256 = '412C2F81D9C6A0B4159AEBA677EF640BCE168E01FEC66AAA4F5DA1672EDEBA22'
$controlName = 'mobfe_control'
$centerName = 'mobfe_center'
$neighborNames = @('mobfe_bars2','mobfe_bars4','mobfe_buffer000','mobfe_buffer010')
$continuousWindow = 'continuous_2015_2020'
$windows = @('older_2015_2018','later_2019_2020',$continuousWindow)

function Resolve-RepoPath([string]$Path) {
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}
function Money([double]$Value) {
   $sign = if($Value -ge 0.0) { '+' } else { '-' }
   return $sign + '$' + [Math]::Abs($Value).ToString('N2',[Globalization.CultureInfo]::InvariantCulture)
}
function BoolText([bool]$Value) {
   if($Value) { return 'PASS' }
   return 'FAIL'
}

$manifest = @(Import-Csv -LiteralPath (Resolve-RepoPath $ManifestPath))
if($manifest.Count -ne 18) { throw 'Expected eighteen frozen Model 1 manifest rows.' }
if(@($manifest | Where-Object { $_.SourceSha256 -ne $expectedSourceSha256 -or [int]$_.Model -ne 1 }).Count -ne 0) {
   throw 'Manifest source or model identity changed.'
}
if(@($manifest.Candidate | Sort-Object -Unique).Count -ne 6 -or @($manifest.Window | Sort-Object -Unique).Count -ne 3) {
   throw 'Manifest candidate/window topology changed.'
}
foreach($item in $manifest) {
   $configPath = Resolve-RepoPath ([string]$item.PackageConfig)
   if((Get-FileHash -LiteralPath $configPath -Algorithm SHA256).Hash.ToUpperInvariant() -ne $item.ConfigSha256) {
      throw "Config identity changed at rank $($item.QueueRank)."
   }
}

$rawResults = 'work\MOBFE_DECISION_RAW_RESULTS.csv'
$rawSummary = 'work\MOBFE_DECISION_RAW_SUMMARY.csv'
$rawMetrics = 'work\MOBFE_DECISION_RAW_METRICS.md'
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

$workerRows = [Collections.Generic.List[object]]::new()
foreach($pattern in @(
   'THREE_LANE_MOMENTUM_BREAKOUT_FAILURE_EXIT_DISCOVERY_MODEL1_EXACT_?.csv',
   'THREE_LANE_MOMENTUM_BREAKOUT_FAILURE_EXIT_DISCOVERY_MODEL1_RETRY_?.csv'
)) {
   foreach($file in Get-ChildItem (Join-Path $repo 'outputs') -Filter $pattern -File) {
      foreach($row in @(Import-Csv -LiteralPath $file.FullName)) { $workerRows.Add($row) | Out-Null }
   }
}
if($workerRows.Count -ne 20 -or @($workerRows | Where-Object {
   $_.PackageSourceSha256 -ne $expectedSourceSha256 -or
   $_.PortableExpertRecompiled -ne 'False' -or
   ($_.Status -eq 'REPORT_FOUND' -and $_.PortableBinarySha256 -ne $expectedBinarySha256)
}).Count -ne 0) {
   throw 'Runner evidence is incomplete or has an identity mismatch.'
}
if(@($workerRows | Where-Object Status -eq 'ERROR').Count -ne 2) {
   throw 'Expected two preserved source-identity refusals.'
}
$workerByRank = @{}
foreach($rank in 1..18) {
   $attempts = @($workerRows | Where-Object { [int]$_.QueueRank -eq $rank })
   $valid = @($attempts | Where-Object Status -eq 'REPORT_FOUND' | Sort-Object Finished)
   if($valid.Count -ne 1) { throw "Rank $rank does not have exactly one valid final report." }
   $workerByRank[[string]$rank] = $valid[0]
}

$results = [Collections.Generic.List[object]]::new()
$attestation = [Collections.Generic.List[object]]::new()
foreach($item in ($manifest | Sort-Object { [int]$_.QueueRank })) {
   $parsed = $rawByReport[[string]$item.ExpectedReportName]
   $run = $workerByRank[[string]$item.QueueRank]
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
      QueueRank=[int]$item.QueueRank;Candidate=$item.Candidate;Role=$item.Role
      BreakoutFailureExitEnabled=$item.BreakoutFailureExitEnabled;MaximumBars=[int]$item.MaximumBars
      BufferATR=[double]$item.BufferATR;Window=$item.Window;From=$item.From;To=$item.To;Model=[int]$item.Model
      ProfileSha256=$item.ProfileSha256;SourceSha256=$item.SourceSha256;BinarySha256=$run.PortableBinarySha256
      Status=$parsed.Status;NetProfit=[math]::Round([double]$parsed.NetProfit,2)
      TotalReturnPercent=[math]::Round([double]$parsed.TotalReturnPercent,2);CagrPercent=[math]::Round([double]$parsed.CagrPercent,2)
      ProfitFactor=[math]::Round([double]$parsed.ProfitFactor,2);TotalTrades=[int]$parsed.TotalTrades
      WinRatePercent=[math]::Round([double]$parsed.WinRatePercent,2);MaxDrawdownPercent=[math]::Round([double]$parsed.MaxDrawdownPercent,2)
      RecoveryFactor=[math]::Round([double]$parsed.RecoveryFactor,4);ReturnDrawdown=[math]::Round($returnDrawdown,4)
      SharpeRatio=[math]::Round([double]$parsed.SharpeRatio,2);MaxConsecutiveLosses=[int]$parsed.MaxConsecutiveLosses
      ReportSha256=$run.ReportSha256
   }) | Out-Null
   $attempts = @($workerRows | Where-Object { [int]$_.QueueRank -eq [int]$item.QueueRank })
   $attestation.Add([pscustomobject][ordered]@{
      QueueRank=[int]$item.QueueRank;Candidate=$item.Candidate;Window=$item.Window;Status=$run.Status
      Attempts=$attempts.Count;IdentityRetries=@($attempts | Where-Object Status -eq 'ERROR').Count
      SourceSha256=$run.PackageSourceSha256;BinarySha256=$run.PortableBinarySha256
      ConfigSha256=$run.PackageConfigSha256;ReportSha256=$run.ReportSha256
      IdentitySidecarPresent=$true;PortableExpertRecompiled=$false;Started=$run.Started;Finished=$run.Finished
   }) | Out-Null
}
$results | Export-Csv -LiteralPath (Resolve-RepoPath $ResultsPath) -NoTypeInformation -Encoding ASCII
$attestation | Export-Csv -LiteralPath (Resolve-RepoPath $RunAttestationPath) -NoTypeInformation -Encoding ASCII

$byCandidateWindow = @{}
foreach($row in $results) { $byCandidateWindow["$($row.Candidate)|$($row.Window)"] = $row }
$control = $byCandidateWindow["$controlName|$continuousWindow"]
$center = $byCandidateWindow["$centerName|$continuousWindow"]

function NoWorseDisjointEras([string]$CandidateName) {
   foreach($window in @('older_2015_2018','later_2019_2020')) {
      if([double]$byCandidateWindow["$CandidateName|$window"].NetProfit -lt
         [double]$byCandidateWindow["$controlName|$window"].NetProfit) { return $false }
   }
   return $true
}
function BehaviorChanged([string]$CandidateName) {
   $candidate = $byCandidateWindow["$CandidateName|$continuousWindow"]
   return [double]$candidate.NetProfit -ne [double]$control.NetProfit -or
      [int]$candidate.TotalTrades -ne [int]$control.TotalTrades -or
      [double]$candidate.MaxDrawdownPercent -ne [double]$control.MaxDrawdownPercent
}
function NeighborPass([string]$CandidateName) {
   $candidate = $byCandidateWindow["$CandidateName|$continuousWindow"]
   return (NoWorseDisjointEras $CandidateName) -and
      [double]$candidate.NetProfit -ge 1.02 * [double]$control.NetProfit -and
      [double]$candidate.CagrPercent -ge [double]$control.CagrPercent + 0.03 -and
      [double]$candidate.ProfitFactor -ge [double]$control.ProfitFactor -and
      [double]$candidate.RecoveryFactor -ge [double]$control.RecoveryFactor -and
      [double]$candidate.ReturnDrawdown -ge [double]$control.ReturnDrawdown -and
      [double]$candidate.MaxDrawdownPercent -le 1.25 -and (BehaviorChanged $CandidateName)
}

$allWindowsPositive = @($results | Where-Object { [double]$_.NetProfit -le 0.0 }).Count -eq 0
$centerNoWorseEras = NoWorseDisjointEras $centerName
$centerGrowth = [double]$center.NetProfit -ge 1.05 * [double]$control.NetProfit
$centerCagr = [double]$center.CagrPercent -ge [double]$control.CagrPercent + 0.08
$centerEfficiency = [double]$center.ProfitFactor -ge [double]$control.ProfitFactor -and
   [double]$center.RecoveryFactor -ge [double]$control.RecoveryFactor -and
   [double]$center.ReturnDrawdown -ge [double]$control.ReturnDrawdown
$centerRisk = [double]$center.MaxDrawdownPercent -le 1.20 -and
   [double]$center.MaxDrawdownPercent -le [double]$control.MaxDrawdownPercent + 0.08
$centerTrades = [int]$center.TotalTrades -ge [int]$control.TotalTrades
$centerBehavior = BehaviorChanged $centerName
$neighborGates = [ordered]@{}
foreach($name in $neighborNames) { $neighborGates[$name] = NeighborPass $name }
$allNeighborsPass = @($neighborGates.Values | Where-Object { !$_ }).Count -eq 0
$passed = $allWindowsPositive -and $centerNoWorseEras -and $centerGrowth -and $centerCagr -and
   $centerEfficiency -and $centerRisk -and $centerTrades -and $centerBehavior -and $allNeighborsPass

$orderedNames = @($controlName,'mobfe_bars2',$centerName,'mobfe_bars4','mobfe_buffer000','mobfe_buffer010')
$summary = foreach($name in $orderedNames) {
   $continuous = $byCandidateWindow["$name|$continuousWindow"]
   [pscustomobject][ordered]@{
      Candidate=$name;Role=$continuous.Role;Enabled=$continuous.BreakoutFailureExitEnabled
      MaximumBars=$continuous.MaximumBars;BufferATR=$continuous.BufferATR
      OlderNetProfit=$byCandidateWindow["$name|older_2015_2018"].NetProfit
      LaterNetProfit=$byCandidateWindow["$name|later_2019_2020"].NetProfit
      ContinuousNetProfit=$continuous.NetProfit;TotalReturnPercent=$continuous.TotalReturnPercent
      CagrPercent=$continuous.CagrPercent;ProfitFactor=$continuous.ProfitFactor;TotalTrades=$continuous.TotalTrades
      MaxDrawdownPercent=$continuous.MaxDrawdownPercent;RecoveryFactor=$continuous.RecoveryFactor
      ReturnDrawdown=$continuous.ReturnDrawdown;BehaviorChanged=BehaviorChanged $name
   }
}
$summary | Export-Csv -LiteralPath (Resolve-RepoPath $SummaryPath) -NoTypeInformation -Encoding ASCII
$bestEnabled = @($summary | Where-Object Enabled -eq 'true' | Sort-Object {[double]$_.ContinuousNetProfit} -Descending)[0]

$decision = [pscustomobject][ordered]@{
   Status=if($passed){'DISCOVERY_GATE_PASSED'}else{'REJECTED_IN_DISCOVERY'};ReportsParsed=$results.Count
   IdentityValidReports=$attestation.Count;TotalAttempts=$workerRows.Count
   IdentityRefusals=@($workerRows | Where-Object Status -eq 'ERROR').Count
   AllWindowsPositive=$allWindowsPositive;CenterNoWorseDisjointEras=$centerNoWorseEras
   CenterGrowthGate=$centerGrowth;CenterCagrGate=$centerCagr;CenterEfficiencyGate=$centerEfficiency
   CenterRiskGate=$centerRisk;CenterTradeCountGate=$centerTrades;CenterBehaviorChanged=$centerBehavior
   Bars2NeighborGate=$neighborGates['mobfe_bars2'];Bars4NeighborGate=$neighborGates['mobfe_bars4']
   Buffer000NeighborGate=$neighborGates['mobfe_buffer000'];Buffer010NeighborGate=$neighborGates['mobfe_buffer010']
   HoldoutValidationPermitted=$passed;Model4ValidationPermitted=$false;ResearchPromotionPermitted=$false
   ForwardCandidateChanged=$false;RealAccountTradingAllowed=$false
   ControlNetProfit=$control.NetProfit;CenterNetProfit=$center.NetProfit;CenterMaxDrawdownPercent=$center.MaxDrawdownPercent
   BestEnabledCandidate=$bestEnabled.Candidate;BestEnabledNetProfit=$bestEnabled.ContinuousNetProfit
   SourceSha256=$expectedSourceSha256;BinarySha256=$expectedBinarySha256;CenterProfileSha256=$center.ProfileSha256
}
$decision | Export-Csv -LiteralPath (Resolve-RepoPath $DecisionCsvPath) -NoTypeInformation -Encoding ASCII

$centerDelta = [double]$center.NetProfit - [double]$control.NetProfit
$centerRelative = 100.0 * $centerDelta / [double]$control.NetProfit
$lines = [Collections.Generic.List[string]]::new()
$lines.Add('# Three-Lane Momentum Breakout-Failure Exit Discovery Decision')
$lines.Add('')
$lines.Add($(if($passed){'**Decision: DISCOVERY GATE PASSED. Only the exact frozen center may proceed to holdout; Model 4 and promotion remain closed.**'}else{'**Decision: REJECTED IN DISCOVERY. No holdout, Model 4, promotion, forward change, or live approval is permitted.**'}))
$lines.Add('')
$lines.Add('- Reports: `18 / 18` parsed with exact source, EX5, config, and report identity')
$lines.Add('- Attempts: `20`; source-identity refusals: `2` (preserved and excluded)')
$lines.Add("- Exact source SHA-256: ``$expectedSourceSha256``")
$lines.Add("- Exact EX5 SHA-256: ``$expectedBinarySha256``")
$lines.Add('- Starting balance: `$10,000`; discovery data: `2015-01-01` through `2020-12-31`; model: MT5 Model 1')
$lines.Add('- Real-account trading: disabled')
$lines.Add('')
$lines.Add('| Profile | 2015-18 | 2019-20 | Continuous | Return | CAGR | PF | Trades | DD | Recovery | Return/DD |')
$lines.Add('|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|')
foreach($row in $summary) {
   $label = switch($row.Candidate) {
      $controlName {'Control (disabled)'}
      'mobfe_bars2' {'2 bars / 0.05 ATR'}
      $centerName {'Center: 3 bars / 0.05 ATR'}
      'mobfe_bars4' {'4 bars / 0.05 ATR'}
      'mobfe_buffer000' {'3 bars / 0.00 ATR'}
      'mobfe_buffer010' {'3 bars / 0.10 ATR'}
   }
   $lines.Add("| $label | $(Money ([double]$row.OlderNetProfit)) | $(Money ([double]$row.LaterNetProfit)) | $(Money ([double]$row.ContinuousNetProfit)) | $($row.TotalReturnPercent)% | $($row.CagrPercent)%/yr | $($row.ProfitFactor) | $($row.TotalTrades) | $($row.MaxDrawdownPercent)% | $($row.RecoveryFactor) | $($row.ReturnDrawdown) |")
}
$lines.Add('')
$lines.Add('## Frozen Gate')
$lines.Add('')
$lines.Add("- Every report profitable: ``$allWindowsPositive`` ($(BoolText $allWindowsPositive))")
$lines.Add("- Center no worse in both disjoint eras: ``$centerNoWorseEras`` ($(BoolText $centerNoWorseEras))")
$lines.Add("- Center continuous growth: ``$centerGrowth`` ($(BoolText $centerGrowth))")
$lines.Add("- Center CAGR improvement: ``$centerCagr`` ($(BoolText $centerCagr))")
$lines.Add("- Center PF/recovery/return-DD: ``$centerEfficiency`` ($(BoolText $centerEfficiency))")
$lines.Add("- Center drawdown: ``$centerRisk`` ($(BoolText $centerRisk))")
$lines.Add("- Center trade count: ``$centerTrades`` ($(BoolText $centerTrades))")
$lines.Add("- Center changed behavior: ``$centerBehavior`` ($(BoolText $centerBehavior))")
foreach($name in $neighborNames) { $lines.Add("- $name neighbor: ``$($neighborGates[$name])`` ($(BoolText $neighborGates[$name]))") }
$lines.Add('')
$lines.Add('## Interpretation')
$lines.Add('')
$lines.Add("The frozen center reduced continuous net by ``$(Money $centerDelta)`` (``$($centerRelative.ToString('N2',[Globalization.CultureInfo]::InvariantCulture))%``) versus control and raised drawdown from ``$($control.MaxDrawdownPercent)%`` to ``$($center.MaxDrawdownPercent)%``. It also reduced PF, recovery, return/drawdown, and trade count.")
$lines.Add('')
$lines.Add("The best enabled neighbor was ``$($bestEnabled.Candidate)`` at ``$(Money ([double]$bestEnabled.ContinuousNetProfit))``, still below the disabled control at ``$(Money ([double]$control.NetProfit))``. The mechanism appears to cut recoverable momentum trades too early, so the entire family is rejected without opening 2021-2026 or spending Model 4 time.")
$lines.Add('')
$lines.Add('ATB150 remains the historical champion. The registered forward candidate, invalid-account boundary, evidence logs, and real-account lock remain unchanged.')
$lines | Set-Content -LiteralPath (Resolve-RepoPath $DecisionMarkdownPath) -Encoding ASCII

Remove-Item -LiteralPath (Resolve-RepoPath $rawResults),(Resolve-RepoPath $rawSummary),(Resolve-RepoPath $rawMetrics) -Force -ErrorAction SilentlyContinue
$decision
