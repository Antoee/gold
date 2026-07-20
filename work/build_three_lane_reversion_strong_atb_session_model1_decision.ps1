param(
   [string]$ManifestPath = 'outputs\THREE_LANE_REVERSION_STRONG_ATB_SESSION_MODEL1_MANIFEST.csv',
   [string]$ReportDir = 'outputs\three_lane_reversion_strong_atb_session_model1_package\reports_here',
   [string]$ResultsPath = 'outputs\THREE_LANE_REVERSION_STRONG_ATB_SESSION_MODEL1_RESULTS.csv',
   [string]$SummaryPath = 'outputs\THREE_LANE_REVERSION_STRONG_ATB_SESSION_MODEL1_SUMMARY.csv',
   [string]$DecisionCsvPath = 'outputs\THREE_LANE_REVERSION_STRONG_ATB_SESSION_MODEL1_DECISION.csv',
   [string]$DecisionMarkdownPath = 'outputs\THREE_LANE_REVERSION_STRONG_ATB_SESSION_MODEL1_DECISION.md',
   [string]$RunAttestationPath = 'outputs\THREE_LANE_REVERSION_STRONG_ATB_SESSION_MODEL1_RUN_ATTESTATION.csv'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$expectedSourceSha256 = '096B49D31562D8A40FF6A3A4E80E40ACA7C3880285D2BB08EEE6CE2F77EA4248'
$expectedBinarySha256 = 'C8F436B0474D166020B210731EF553E64F9BC49700C99FB25F2AA69972ECFBC2'
$championName = 'rvsats_champion'
$strongName = 'rvsats_strong'
$lowerName = 'rvsats_12_1'
$centerName = 'rvsats_16_1'
$upperName = 'rvsats_16_9'
$continuousWindow = 'continuous_2015_2026'
$windows = @('older_2015_2018','middle_2019_2022','recent_2023_2026',$continuousWindow)

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
if($manifest.Count -ne 20) { throw 'Expected twenty frozen Model 1 manifest rows.' }
if(@($manifest | Where-Object { $_.SourceSha256 -ne $expectedSourceSha256 -or [int]$_.Model -ne 1 }).Count -ne 0) {
   throw 'Manifest source or model identity changed.'
}
if(@($manifest.Candidate | Sort-Object -Unique).Count -ne 5 -or @($manifest.Window | Sort-Object -Unique).Count -ne 4) {
   throw 'Manifest candidate/window topology changed.'
}

$rawResults = 'work\RVSATSM1_RAW_RESULTS.csv'
$rawSummary = 'work\RVSATSM1_RAW_SUMMARY.csv'
$rawMetrics = 'work\RVSATSM1_RAW_METRICS.md'
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'collect_validation_results.ps1') `
   -RepoRoot $repo -ManifestPath $ManifestPath -ReportDir $ReportDir -ReportNameTemplate '{ExpectedReportName}' `
   -OutResults $rawResults -OutSummary $rawSummary -OutMarkdown $rawMetrics | Out-Null
if($LASTEXITCODE -ne 0) { throw 'Shared report collector failed.' }

$raw = @(Import-Csv -LiteralPath (Resolve-RepoPath $rawResults))
if($raw.Count -ne 20 -or @($raw | Where-Object Status -ne 'PARSED').Count -ne 0) {
   throw 'Expected twenty parsed reports.'
}
$rawByReport = @{}
foreach($row in $raw) { $rawByReport[[string]$row.ExpectedReportName] = $row }

$workerRows = [Collections.Generic.List[object]]::new()
$workerFiles = @(
   Get-ChildItem (Join-Path $repo 'outputs') -Filter 'THREE_LANE_REVERSION_STRONG_ATB_SESSION_MODEL1_EXACT_?.csv' -File
   Get-ChildItem (Join-Path $repo 'outputs') -Filter 'THREE_LANE_REVERSION_STRONG_ATB_SESSION_MODEL1_RETRY_?.csv' -File
) | Sort-Object Name
foreach($file in $workerFiles) {
   foreach($row in @(Import-Csv -LiteralPath $file.FullName)) { $workerRows.Add($row) | Out-Null }
}
if($workerRows.Count -ne 21 -or @($workerRows | Where-Object {
   $_.PackageSourceSha256 -ne $expectedSourceSha256 -or
   $_.PortableExpertRecompiled -ne 'False' -or
   ($_.Status -eq 'REPORT_FOUND' -and $_.PortableBinarySha256 -ne $expectedBinarySha256)
}).Count -ne 0) {
   throw 'Runner evidence is incomplete or has an identity mismatch.'
}
$workerByRank = @{}
foreach($rank in 1..20) {
   $attempts = @($workerRows | Where-Object { [int]$_.QueueRank -eq $rank })
   $valid = @($attempts | Where-Object Status -eq 'REPORT_FOUND' | Sort-Object Finished)
   if($valid.Count -ne 1) { throw "Rank $rank does not have exactly one valid final report." }
   $workerByRank[[string]$rank] = $valid[0]
}
if(@($workerRows | Where-Object Status -eq 'ERROR').Count -ne 1) {
   throw 'Expected one preserved identity-only refusal.'
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
      $identity.ReportSha256 -ne $run.ReportSha256) {
      throw "Identity sidecar mismatch for rank $($item.QueueRank)."
   }
   $returnDrawdown = if([double]$parsed.MaxDrawdownPercent -gt 0.0) {
      [double]$parsed.TotalReturnPercent / [double]$parsed.MaxDrawdownPercent
   } else { 0.0 }
   $results.Add([pscustomobject][ordered]@{
      QueueRank=[int]$item.QueueRank;Candidate=$item.Candidate;Role=$item.Role
      StrongSignalRiskEnabled=$item.StrongSignalRiskEnabled;ATBSessionEnabled=$item.ATBSessionEnabled
      ATBSessionStartHour=[int]$item.ATBSessionStartHour;ATBSessionEndHour=[int]$item.ATBSessionEndHour
      Window=$item.Window;From=$item.From;To=$item.To;Model=[int]$item.Model
      ProfileSha256=$item.ProfileSha256;SourceSha256=$item.SourceSha256;BinarySha256=$run.PortableBinarySha256
      Status=$parsed.Status;NetProfit=[math]::Round([double]$parsed.NetProfit,2)
      TotalReturnPercent=[math]::Round([double]$parsed.TotalReturnPercent,2);CagrPercent=[math]::Round([double]$parsed.CagrPercent,2)
      ProfitFactor=[math]::Round([double]$parsed.ProfitFactor,2);TotalTrades=[int]$parsed.TotalTrades
      WinRatePercent=[math]::Round([double]$parsed.WinRatePercent,2);MaxDrawdownPercent=[math]::Round([double]$parsed.MaxDrawdownPercent,2)
      RecoveryFactor=[math]::Round([double]$parsed.RecoveryFactor,4);ReturnDrawdown=[math]::Round($returnDrawdown,4)
      SharpeRatio=[math]::Round([double]$parsed.SharpeRatio,2);MaxConsecutiveLosses=[int]$parsed.MaxConsecutiveLosses
      ReportSha256=$run.ReportSha256
   }) | Out-Null
   $attestation.Add([pscustomobject][ordered]@{
      QueueRank=[int]$item.QueueRank;Candidate=$item.Candidate;Window=$item.Window;Status=$run.Status
      Attempts=@($workerRows | Where-Object { [int]$_.QueueRank -eq [int]$item.QueueRank }).Count
      IdentityRetries=@($workerRows | Where-Object { [int]$_.QueueRank -eq [int]$item.QueueRank -and $_.Status -eq 'ERROR' }).Count
      SourceSha256=$run.PackageSourceSha256;BinarySha256=$run.PortableBinarySha256;ConfigSha256=$run.PackageConfigSha256
      ReportSha256=$run.ReportSha256;IdentitySidecarPresent=$true;PortableExpertRecompiled=$false
      Started=$run.Started;Finished=$run.Finished
   }) | Out-Null
}
$results | Export-Csv -LiteralPath (Resolve-RepoPath $ResultsPath) -NoTypeInformation -Encoding ASCII
$attestation | Export-Csv -LiteralPath (Resolve-RepoPath $RunAttestationPath) -NoTypeInformation -Encoding ASCII

$byCandidateWindow = @{}
foreach($row in $results) { $byCandidateWindow["$($row.Candidate)|$($row.Window)"] = $row }
$champion = $byCandidateWindow["$championName|$continuousWindow"]
$strong = $byCandidateWindow["$strongName|$continuousWindow"]
$lower = $byCandidateWindow["$lowerName|$continuousWindow"]
$center = $byCandidateWindow["$centerName|$continuousWindow"]
$upper = $byCandidateWindow["$upperName|$continuousWindow"]

function EveryWindowAtLeast([string]$CandidateName, [string]$ControlName, [double]$Ratio) {
   return @($windows | Where-Object {
      [double]$byCandidateWindow["$CandidateName|$_"].NetProfit -lt $Ratio * [double]$byCandidateWindow["$ControlName|$_"].NetProfit
   }).Count -eq 0
}
function NeighborPass($Neighbor, [string]$Name) {
   return (EveryWindowAtLeast $Name $strongName 0.99) -and
      [double]$Neighbor.NetProfit -ge 1.01 * [double]$strong.NetProfit -and
      [double]$Neighbor.CagrPercent -ge [double]$strong.CagrPercent + 0.02 -and
      [double]$Neighbor.ProfitFactor -ge [double]$strong.ProfitFactor -and
      [double]$Neighbor.RecoveryFactor -ge [double]$strong.RecoveryFactor -and
      [double]$Neighbor.ReturnDrawdown -ge [double]$strong.ReturnDrawdown -and
      [double]$Neighbor.MaxDrawdownPercent -le 1.25 -and [int]$Neighbor.TotalTrades -ge 385
}

$allWindowsPositive = @($results | Where-Object { [double]$_.NetProfit -le 0.0 }).Count -eq 0
$centerBeatsChampionEveryWindow = EveryWindowAtLeast $centerName $championName 1.0
$centerBeatsStrongEveryWindow = EveryWindowAtLeast $centerName $strongName 1.0
$centerGrowth = [double]$center.NetProfit -ge 1.10 * [double]$champion.NetProfit -and [double]$center.NetProfit -ge 1.02 * [double]$strong.NetProfit
$centerCagr = [double]$center.CagrPercent -ge [double]$champion.CagrPercent + 0.15 -and [double]$center.CagrPercent -ge [double]$strong.CagrPercent + 0.03
$centerEfficiency = [double]$center.ProfitFactor -ge [math]::Max([double]$champion.ProfitFactor,[double]$strong.ProfitFactor) -and
   [double]$center.RecoveryFactor -ge [math]::Max([double]$champion.RecoveryFactor,[double]$strong.RecoveryFactor) -and
   [double]$center.ReturnDrawdown -ge [math]::Max([double]$champion.ReturnDrawdown,[double]$strong.ReturnDrawdown)
$centerRisk = [double]$center.MaxDrawdownPercent -le 1.25 -and [double]$center.MaxDrawdownPercent -le [double]$champion.MaxDrawdownPercent + 0.08 -and [int]$center.TotalTrades -ge 380
$lowerGate = NeighborPass $lower $lowerName
$upperGate = NeighborPass $upper $upperName
$passed = $allWindowsPositive -and $centerBeatsChampionEveryWindow -and $centerBeatsStrongEveryWindow -and
   $centerGrowth -and $centerCagr -and $centerEfficiency -and $centerRisk -and $lowerGate -and $upperGate

$summary = foreach($name in @($championName,$strongName,$lowerName,$centerName,$upperName)) {
   $continuous = $byCandidateWindow["$name|$continuousWindow"]
   [pscustomobject][ordered]@{
      Candidate=$name;Role=$continuous.Role;ATBSessionEnabled=$continuous.ATBSessionEnabled
      ATBSessionStartHour=$continuous.ATBSessionStartHour;ATBSessionEndHour=$continuous.ATBSessionEndHour
      OlderNetProfit=$byCandidateWindow["$name|older_2015_2018"].NetProfit
      MiddleNetProfit=$byCandidateWindow["$name|middle_2019_2022"].NetProfit
      RecentNetProfit=$byCandidateWindow["$name|recent_2023_2026"].NetProfit
      ContinuousNetProfit=$continuous.NetProfit;TotalReturnPercent=$continuous.TotalReturnPercent;CagrPercent=$continuous.CagrPercent
      ProfitFactor=$continuous.ProfitFactor;TotalTrades=$continuous.TotalTrades;MaxDrawdownPercent=$continuous.MaxDrawdownPercent
      RecoveryFactor=$continuous.RecoveryFactor;ReturnDrawdown=$continuous.ReturnDrawdown
   }
}
$summary | Export-Csv -LiteralPath (Resolve-RepoPath $SummaryPath) -NoTypeInformation -Encoding ASCII

$decision = [pscustomobject][ordered]@{
   Status=if($passed){'MODEL1_GATE_PASSED'}else{'REJECTED_IN_MODEL1'};ReportsParsed=$results.Count
   IdentityValidReports=$attestation.Count;TotalAttempts=$workerRows.Count;IdentityRetries=@($workerRows|Where-Object Status -eq 'ERROR').Count
   AllWindowsPositive=$allWindowsPositive;CenterBeatsChampionEveryWindow=$centerBeatsChampionEveryWindow
   CenterBeatsStrongControlEveryWindow=$centerBeatsStrongEveryWindow;CenterGrowthGate=$centerGrowth;CenterCagrGate=$centerCagr
   CenterEfficiencyGate=$centerEfficiency;CenterRiskAndActivityGate=$centerRisk;LowerNeighborGate=$lowerGate;UpperNeighborGate=$upperGate
   Model4ValidationPermitted=$passed;ResearchPromotionPermitted=$false;ForwardCandidateChanged=$false;RealAccountTradingAllowed=$false
   ChampionNetProfit=$champion.NetProfit;StrongControlNetProfit=$strong.NetProfit;CenterNetProfit=$center.NetProfit
   LowerNeighborNetProfit=$lower.NetProfit;UpperNeighborNetProfit=$upper.NetProfit
   SourceSha256=$expectedSourceSha256;BinarySha256=$expectedBinarySha256;CenterProfileSha256=$center.ProfileSha256
}
$decision | Export-Csv -LiteralPath (Resolve-RepoPath $DecisionCsvPath) -NoTypeInformation -Encoding ASCII

$lines = [Collections.Generic.List[string]]::new()
$lines.Add('# Three-Lane Strong-Reversion / ATB Session Model 1 Decision')
$lines.Add('')
$lines.Add($(if($passed){'**Decision: MODEL 1 GATE PASSED. Model 4 may open; no promotion or forward change is authorized.**'}else{'**Decision: REJECTED IN MODEL 1. No Model 4, promotion, forward change, or live approval is permitted.**'}))
$lines.Add('')
$lines.Add('- Reports: `20 / 20` parsed and exact source/binary identity valid')
$lines.Add('- Attempts: `21`; identity-only retries: `1`')
$lines.Add("- Exact source SHA-256: ``$expectedSourceSha256``")
$lines.Add("- Exact EX5 SHA-256: ``$expectedBinarySha256``")
$lines.Add('- Strong-reversion allocation: completed-H1 body ratio `0.25`, requested risk `0.70%`; adaptive-trend risk `0.15%`')
$lines.Add('- Real-account trading: disabled')
$lines.Add('')
$lines.Add('| Profile | 2015-18 | 2019-22 | 2023-26 | Continuous | Return | CAGR | PF | Trades | DD | Recovery | Return/DD |')
$lines.Add('|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|')
foreach($row in $summary) {
   $label = switch($row.Candidate) {
      $championName {'ATB150 champion control'};$strongName {'Strong-reversion control'};$lowerName {'Session 12-1'};$centerName {'Session 16-1 center'};$upperName {'Session 16-9'}
   }
   $lines.Add("| $label | $(Money ([double]$row.OlderNetProfit)) | $(Money ([double]$row.MiddleNetProfit)) | $(Money ([double]$row.RecentNetProfit)) | $(Money ([double]$row.ContinuousNetProfit)) | $($row.TotalReturnPercent)% | $($row.CagrPercent)%/yr | $($row.ProfitFactor) | $($row.TotalTrades) | $($row.MaxDrawdownPercent)% | $($row.RecoveryFactor) | $($row.ReturnDrawdown) |")
}
$lines.Add('')
$lines.Add('## Frozen Gate')
$lines.Add('')
$lines.Add("- Every report profitable: ``$allWindowsPositive`` ($(BoolText $allWindowsPositive))")
$lines.Add("- Center beats champion in every era: ``$centerBeatsChampionEveryWindow`` ($(BoolText $centerBeatsChampionEveryWindow))")
$lines.Add("- Center beats strong control in every era: ``$centerBeatsStrongEveryWindow`` ($(BoolText $centerBeatsStrongEveryWindow))")
$lines.Add("- Center growth gate: ``$centerGrowth`` ($(BoolText $centerGrowth))")
$lines.Add("- Center CAGR gate: ``$centerCagr`` ($(BoolText $centerCagr))")
$lines.Add("- Center PF/recovery/return-DD gate: ``$centerEfficiency`` ($(BoolText $centerEfficiency))")
$lines.Add("- Center drawdown/activity gate: ``$centerRisk`` ($(BoolText $centerRisk))")
$lines.Add("- Session 12-1 neighbor gate: ``$lowerGate`` ($(BoolText $lowerGate))")
$lines.Add("- Session 16-9 neighbor gate: ``$upperGate`` ($(BoolText $upperGate))")
$lines.Add('')
$lines.Add('## Interpretation')
$lines.Add('')
$lines.Add("The 16-1 center reduced continuous net from strong control at ``$(Money ([double]$strong.NetProfit))`` to ``$(Money ([double]$center.NetProfit))`` and reduced trades from ``$($strong.TotalTrades)`` to ``$($center.TotalTrades)``. Its older-era net fell from ``$(Money ([double]$byCandidateWindow["$strongName|older_2015_2018"].NetProfit))`` to ``$(Money ([double]$byCandidateWindow["$centerName|older_2015_2018"].NetProfit))``. The 12-1 neighbor was weaker, while 16-9 added only ``$(Money ([double]$upper.NetProfit - [double]$strong.NetProfit))`` and did not improve CAGR.")
$lines.Add('')
$lines.Add($(if($passed){'The complete preregistered neighborhood passed. A fixed Model 4 comparison may open, but ATB150 and the registered forward candidate remain unchanged.'}else{'The ledger-hour pattern did not transfer into a robust portfolio improvement. The session family is rejected without another hour search, Model 4 stays closed, and ATB150 remains the historical champion.'}))
$lines.Add('')
$lines.Add('The registered forward candidate, invalid-account boundary, evidence logs, and real-account lock remain unchanged.')
$lines | Set-Content -LiteralPath (Resolve-RepoPath $DecisionMarkdownPath) -Encoding ASCII

Remove-Item -LiteralPath (Resolve-RepoPath $rawResults),(Resolve-RepoPath $rawSummary),(Resolve-RepoPath $rawMetrics) -Force -ErrorAction SilentlyContinue
$decision
