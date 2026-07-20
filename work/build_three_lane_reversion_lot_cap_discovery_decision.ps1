[CmdletBinding()]
param(
   [string]$ManifestPath = 'outputs\THREE_LANE_REVERSION_LOT_CAP_DISCOVERY_MODEL1_MANIFEST.csv',
   [string]$ReportDir = 'outputs\three_lane_reversion_lot_cap_discovery_model1_package\reports_here',
   [string]$CompileAuditPath = 'outputs\THREE_LANE_REVERSION_LOT_CAP_COMPILE_AUDIT.csv',
   [string]$ResultsPath = 'outputs\THREE_LANE_REVERSION_LOT_CAP_DISCOVERY_MODEL1_RESULTS.csv',
   [string]$SummaryPath = 'outputs\THREE_LANE_REVERSION_LOT_CAP_DISCOVERY_MODEL1_SUMMARY.csv',
   [string]$DecisionCsvPath = 'outputs\THREE_LANE_REVERSION_LOT_CAP_DISCOVERY_DECISION.csv',
   [string]$DecisionMarkdownPath = 'outputs\THREE_LANE_REVERSION_LOT_CAP_DISCOVERY_DECISION.md',
   [string]$RunAttestationPath = 'outputs\THREE_LANE_REVERSION_LOT_CAP_DISCOVERY_MODEL1_RUN_ATTESTATION.csv'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$expectedSourceSha256 = '2F1C1C74067DA6173EB4133DB75C0B0DB4DE7BE46F2BB7A453AEE044536B2158'
$controlName = 'rvlc_control'
$lowerName = 'rvlc_low012'
$centerName = 'rvlc_center015'
$upperName = 'rvlc_high018'
$stressName = 'rvlc_stress020'
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
$audit = Import-Csv -LiteralPath (Resolve-RepoPath $CompileAuditPath)
if($manifest.Count -ne 15) { throw 'Expected fifteen frozen Model 1 manifest rows.' }
if($audit.Status -ne 'COMPILE_PASS' -or $audit.SourceSha256 -ne $expectedSourceSha256 -or
   $audit.CompileErrors -ne '0' -or $audit.CompileWarnings -ne '0' -or
   $audit.LaunchLocksRestored -ne 'True' -or $audit.MT5Processes -ne '0') {
   throw 'Compile audit is not an exact clean pass.'
}
$expectedBinarySha256 = ([string]$audit.PortableBinarySha256).ToUpperInvariant()
if($expectedBinarySha256 -notmatch '^[A-F0-9]{64}$') { throw 'Compile audit binary identity is invalid.' }
if(@($manifest | Where-Object {
   $_.SourceSha256 -ne $expectedSourceSha256 -or [int]$_.Model -ne 1 -or [int]$_.Deposit -ne 10000
}).Count -ne 0) { throw 'Manifest source, model, or capital identity changed.' }
if(@($manifest.Candidate | Sort-Object -Unique).Count -ne 5 -or @($manifest.Window | Sort-Object -Unique).Count -ne 3) {
   throw 'Manifest candidate/window topology changed.'
}
foreach($item in $manifest) {
   $configPath = Resolve-RepoPath ([string]$item.PackageConfig)
   if((Get-FileHash -LiteralPath $configPath -Algorithm SHA256).Hash.ToUpperInvariant() -ne $item.ConfigSha256) {
      throw "Config identity changed at rank $($item.QueueRank)."
   }
}

$rawResults = 'work\RVLC_DECISION_RAW_RESULTS.csv'
$rawSummary = 'work\RVLC_DECISION_RAW_SUMMARY.csv'
$rawMetrics = 'work\RVLC_DECISION_RAW_METRICS.md'
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

$workerRows = [Collections.Generic.List[object]]::new()
foreach($pattern in @(
   'THREE_LANE_REVERSION_LOT_CAP_DISCOVERY_MODEL1_EXACT_?.csv',
   'THREE_LANE_REVERSION_LOT_CAP_DISCOVERY_MODEL1_RETRY_?.csv'
)) {
   foreach($file in Get-ChildItem (Join-Path $repo 'outputs') -Filter $pattern -File) {
      foreach($row in @(Import-Csv -LiteralPath $file.FullName)) { $workerRows.Add($row) | Out-Null }
   }
}
if($workerRows.Count -lt 15 -or @($workerRows | Where-Object {
   $_.PackageSourceSha256 -ne $expectedSourceSha256 -or
   $_.PortableExpertRecompiled -ne 'False' -or
   ($_.Status -eq 'REPORT_FOUND' -and $_.PortableBinarySha256 -ne $expectedBinarySha256)
}).Count -ne 0) { throw 'Runner evidence is incomplete or has an identity mismatch.' }

$workerByRank = @{}
foreach($rank in 1..15) {
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
      ReversionRiskPercent=[double]$item.ReversionRiskPercent
      ReversionMaximumPositionLots=[double]$item.ReversionMaximumPositionLots
      Window=$item.Window;From=$item.From;To=$item.To;Model=[int]$item.Model
      ProfileSha256=$item.ProfileSha256;SourceSha256=$item.SourceSha256;BinarySha256=$run.PortableBinarySha256
      Status=$parsed.Status;NetProfit=[math]::Round([double]$parsed.NetProfit,2)
      TotalReturnPercent=[math]::Round([double]$parsed.TotalReturnPercent,2)
      CagrPercent=[math]::Round([double]$parsed.CagrPercent,2)
      ProfitFactor=[math]::Round([double]$parsed.ProfitFactor,2);TotalTrades=[int]$parsed.TotalTrades
      WinRatePercent=[math]::Round([double]$parsed.WinRatePercent,2)
      MaxDrawdownPercent=[math]::Round([double]$parsed.MaxDrawdownPercent,2)
      RecoveryFactor=[math]::Round([double]$parsed.RecoveryFactor,4)
      ReturnDrawdown=[math]::Round($returnDrawdown,4)
      SharpeRatio=[math]::Round([double]$parsed.SharpeRatio,2)
      MaxConsecutiveLosses=[int]$parsed.MaxConsecutiveLosses;ReportSha256=$run.ReportSha256
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
$lower = $byCandidateWindow["$lowerName|$continuousWindow"]
$center = $byCandidateWindow["$centerName|$continuousWindow"]
$upper = $byCandidateWindow["$upperName|$continuousWindow"]
$stress = $byCandidateWindow["$stressName|$continuousWindow"]

function BehaviorChanged([string]$CandidateName) {
   foreach($window in $windows) {
      $candidate = $byCandidateWindow["$CandidateName|$window"]
      $reference = $byCandidateWindow["$controlName|$window"]
      if([double]$candidate.NetProfit -ne [double]$reference.NetProfit -or
         [double]$candidate.ProfitFactor -ne [double]$reference.ProfitFactor -or
         [int]$candidate.TotalTrades -ne [int]$reference.TotalTrades -or
         [double]$candidate.MaxDrawdownPercent -ne [double]$reference.MaxDrawdownPercent -or
         [double]$candidate.RecoveryFactor -ne [double]$reference.RecoveryFactor) { return $true }
   }
   return $false
}
function NoWorseDisjointEras([string]$CandidateName) {
   foreach($window in @('older_2015_2018','later_2019_2020')) {
      if([double]$byCandidateWindow["$CandidateName|$window"].NetProfit -lt
         [double]$byCandidateWindow["$controlName|$window"].NetProfit) { return $false }
   }
   return $true
}
function NeighborPass([string]$CandidateName) {
   $candidate = $byCandidateWindow["$CandidateName|$continuousWindow"]
   return (NoWorseDisjointEras $CandidateName) -and (BehaviorChanged $CandidateName) -and
      [double]$candidate.NetProfit -ge 1.03 * [double]$control.NetProfit -and
      [double]$candidate.CagrPercent -ge [double]$control.CagrPercent + 0.05 -and
      [double]$candidate.ProfitFactor -ge 0.93 * [double]$control.ProfitFactor -and
      [double]$candidate.RecoveryFactor -ge 0.93 * [double]$control.RecoveryFactor -and
      [double]$candidate.ReturnDrawdown -ge 0.93 * [double]$control.ReturnDrawdown -and
      [double]$candidate.MaxDrawdownPercent -le 1.35
}

$allWindowsPositive = @($results | Where-Object { [double]$_.NetProfit -le 0.0 }).Count -eq 0
$centerActive = BehaviorChanged $centerName
$centerNoWorseEras = NoWorseDisjointEras $centerName
$centerGrowth = [double]$center.NetProfit -ge 1.06 * [double]$control.NetProfit
$centerCagr = [double]$center.CagrPercent -ge [double]$control.CagrPercent + 0.10
$centerEfficiency = [double]$center.ProfitFactor -ge 0.95 * [double]$control.ProfitFactor -and
   [double]$center.RecoveryFactor -ge 0.95 * [double]$control.RecoveryFactor -and
   [double]$center.ReturnDrawdown -ge 0.95 * [double]$control.ReturnDrawdown
$centerRisk = [double]$center.MaxDrawdownPercent -le 1.35 -and
   [double]$center.MaxDrawdownPercent -le [double]$control.MaxDrawdownPercent + 0.20
$centerTrades = [int]$center.TotalTrades -ge [int]$control.TotalTrades - 2
$lowerGate = NeighborPass $lowerName
$upperGate = NeighborPass $upperName
$stressGate = (BehaviorChanged $stressName) -and
   @($results | Where-Object { $_.Candidate -eq $stressName -and [double]$_.NetProfit -le 0.0 }).Count -eq 0 -and
   [double]$stress.RecoveryFactor -ge 0.85 * [double]$control.RecoveryFactor -and
   [double]$stress.ReturnDrawdown -ge 0.85 * [double]$control.ReturnDrawdown -and
   [double]$stress.MaxDrawdownPercent -le 1.50
$passed = $allWindowsPositive -and $centerActive -and $centerNoWorseEras -and $centerGrowth -and
   $centerCagr -and $centerEfficiency -and $centerRisk -and $centerTrades -and
   $lowerGate -and $upperGate -and $stressGate

$orderedNames = @($controlName,$lowerName,$centerName,$upperName,$stressName)
$summary = foreach($name in $orderedNames) {
   $continuous = $byCandidateWindow["$name|$continuousWindow"]
   [pscustomobject][ordered]@{
      Candidate=$name;Role=$continuous.Role;ReversionMaximumPositionLots=$continuous.ReversionMaximumPositionLots
      OlderNetProfit=$byCandidateWindow["$name|older_2015_2018"].NetProfit
      LaterNetProfit=$byCandidateWindow["$name|later_2019_2020"].NetProfit
      ContinuousNetProfit=$continuous.NetProfit;TotalReturnPercent=$continuous.TotalReturnPercent
      CagrPercent=$continuous.CagrPercent;ProfitFactor=$continuous.ProfitFactor;TotalTrades=$continuous.TotalTrades
      MaxDrawdownPercent=$continuous.MaxDrawdownPercent;RecoveryFactor=$continuous.RecoveryFactor
      ReturnDrawdown=$continuous.ReturnDrawdown;BehaviorChangedVsControl=BehaviorChanged $name
   }
}
$summary | Export-Csv -LiteralPath (Resolve-RepoPath $SummaryPath) -NoTypeInformation -Encoding ASCII

$decision = [pscustomobject][ordered]@{
   Status=if($passed){'DISCOVERY_GATE_PASSED'}else{'REJECTED_IN_DISCOVERY'};ReportsParsed=$results.Count
   IdentityValidReports=$attestation.Count;TotalAttempts=$workerRows.Count
   IdentityRefusals=@($workerRows | Where-Object Status -eq 'ERROR').Count
   AllWindowsPositive=$allWindowsPositive;CenterBehaviorChanged=$centerActive
   CenterNoWorseDisjointEras=$centerNoWorseEras;CenterGrowthGate=$centerGrowth
   CenterCagrGate=$centerCagr;CenterEfficiencyGate=$centerEfficiency;CenterRiskGate=$centerRisk
   CenterTradeCountGate=$centerTrades;LowerNeighborGate=$lowerGate;UpperNeighborGate=$upperGate
   UpperStressGate=$stressGate;HoldoutValidationPermitted=$passed;Model4ValidationPermitted=$false
   ResearchPromotionPermitted=$false;ForwardCandidateChanged=$false;RealAccountTradingAllowed=$false
   ControlNetProfit=$control.NetProfit;CenterNetProfit=$center.NetProfit
   SourceSha256=$expectedSourceSha256;BinarySha256=$expectedBinarySha256;CenterProfileSha256=$center.ProfileSha256
}
$decision | Export-Csv -LiteralPath (Resolve-RepoPath $DecisionCsvPath) -NoTypeInformation -Encoding ASCII

$lines = [Collections.Generic.List[string]]::new()
$lines.Add('# Three-Lane Reversion Lot-Cap Discovery Decision')
$lines.Add('')
$lines.Add($(if($passed){'**Decision: DISCOVERY GATE PASSED. Only the exact frozen 0.15-lot center may proceed to recent-data validation; Model 4 and promotion remain closed.**'}else{'**Decision: REJECTED IN DISCOVERY. No holdout, Model 4, promotion, forward change, or live approval is permitted.**'}))
$lines.Add('')
$lines.Add("- Reports: ``$($results.Count) / 15`` parsed with exact source, EX5, config, and report identity")
$lines.Add("- Attempts: ``$($workerRows.Count)``; identity refusals: ``$(@($workerRows | Where-Object Status -eq 'ERROR').Count)`` (excluded)")
$lines.Add("- Exact ATB150 source SHA-256: ``$expectedSourceSha256``")
$lines.Add("- Exact EX5 SHA-256: ``$expectedBinarySha256``")
$lines.Add('- Starting balance: `$10,000`; discovery data: `2015-01-01` through `2020-12-31`; model: MT5 Model 1')
$lines.Add('- Only trading input changed: `InpRVMaximumPositionLots`; requested reversion risk stayed `0.45%`')
$lines.Add('- Real-account trading: disabled')
$lines.Add('')
$lines.Add('| Reversion lot cap | 2015-18 | 2019-20 | Continuous | Return | CAGR | PF | Trades | DD | Recovery | Return/DD |')
$lines.Add('|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|')
foreach($row in $summary) {
   $label = ([double]$row.ReversionMaximumPositionLots).ToString('0.00',[Globalization.CultureInfo]::InvariantCulture)
   if($row.Candidate -eq $centerName) { $label = "**$label center**" }
   $lines.Add("| $label | $(Money ([double]$row.OlderNetProfit)) | $(Money ([double]$row.LaterNetProfit)) | $(Money ([double]$row.ContinuousNetProfit)) | $($row.TotalReturnPercent)% | $($row.CagrPercent)%/yr | $($row.ProfitFactor) | $($row.TotalTrades) | $($row.MaxDrawdownPercent)% | $($row.RecoveryFactor) | $($row.ReturnDrawdown) |")
}
$lines.Add('')
$lines.Add('## Frozen Gate')
$lines.Add('')
$lines.Add("- Every report profitable: ``$allWindowsPositive`` ($(BoolText $allWindowsPositive))")
$lines.Add("- Center changed behavior: ``$centerActive`` ($(BoolText $centerActive))")
$lines.Add("- Center no worse in both disjoint eras: ``$centerNoWorseEras`` ($(BoolText $centerNoWorseEras))")
$lines.Add("- Center continuous growth: ``$centerGrowth`` ($(BoolText $centerGrowth))")
$lines.Add("- Center CAGR improvement: ``$centerCagr`` ($(BoolText $centerCagr))")
$lines.Add("- Center PF/recovery/return-DD retention: ``$centerEfficiency`` ($(BoolText $centerEfficiency))")
$lines.Add("- Center drawdown: ``$centerRisk`` ($(BoolText $centerRisk))")
$lines.Add("- Center trade count: ``$centerTrades`` ($(BoolText $centerTrades))")
$lines.Add("- 0.12 lower neighbor: ``$lowerGate`` ($(BoolText $lowerGate))")
$lines.Add("- 0.18 upper neighbor: ``$upperGate`` ($(BoolText $upperGate))")
$lines.Add("- 0.20 upper stress: ``$stressGate`` ($(BoolText $stressGate))")
$lines.Add('')
$lines.Add('## Boundary')
$lines.Add('')
$lines.Add('The lot cap is not a new risk percentage. It only determines whether an already-approved 0.45% reversion risk request can reach its broker-calculated lot size. Initial-stop valuation, the 0.75% portfolio exposure cap, post-fill reconciliation, period loss limits, and the 5% equity guard remain authoritative.')
$lines.Add('')
$lines.Add($(if($passed){'The frozen center and both neighbors met the sealed pre-2021 gate. A separate recent-data package is required before Model 4 can open; this discovery result is not a new best.'}else{'The sealed family did not establish a robust risk-adjusted improvement. Recent data and Model 4 remain unopened, and no different cap may be selected from these results.'}))
$lines.Add('')
$lines.Add('ATB150 remains the historical champion unless and until all later gates pass. The registered forward candidate, invalid-account boundary, evidence logs, and real-account lock remain unchanged.')
$lines | Set-Content -LiteralPath (Resolve-RepoPath $DecisionMarkdownPath) -Encoding ASCII

Remove-Item -LiteralPath (Resolve-RepoPath $rawResults),(Resolve-RepoPath $rawSummary),(Resolve-RepoPath $rawMetrics) -Force -ErrorAction SilentlyContinue
$decision
