param(
   [string]$ManifestPath = "outputs\THREE_LANE_REVERSION_STRONG_REWARD_QUALITY_MODEL1_MANIFEST.csv",
   [string]$ReportDir = "outputs\three_lane_reversion_strong_reward_quality_model1_package\reports_here",
   [string]$ResultsPath = "outputs\THREE_LANE_REVERSION_STRONG_REWARD_QUALITY_MODEL1_RESULTS.csv",
   [string]$SummaryPath = "outputs\THREE_LANE_REVERSION_STRONG_REWARD_QUALITY_MODEL1_SUMMARY.csv",
   [string]$DecisionCsvPath = "outputs\THREE_LANE_REVERSION_STRONG_REWARD_QUALITY_MODEL1_DECISION.csv",
   [string]$DecisionMarkdownPath = "outputs\THREE_LANE_REVERSION_STRONG_REWARD_QUALITY_MODEL1_DECISION.md",
   [string]$RunAttestationPath = "outputs\THREE_LANE_REVERSION_STRONG_REWARD_QUALITY_MODEL1_RUN_ATTESTATION.csv"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$expectedSourceSha256 = "0AF69BFE66200C6CB6F1D4C83A3F4BF3989DFA79E15596A27F384787991A3186"
$expectedBinarySha256 = "730E3A347B4A1C8D2C724E7B5A124137AD50F0B91F200BC3D848CBDAECB9EF03"
$controlName = "rvsrq_control"
$diagnosticName = "rvsrq_unfiltered"
$lowerName = "rvsrq_rr135"
$candidateName = "rvsrq_rr150"
$upperName = "rvsrq_rr165"
$continuousWindow = "continuous_2015_2026"
$windows = @("older_2015_2018","middle_2019_2022","recent_2023_2026",$continuousWindow)

function Resolve-RepoPath([string]$Path) {
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}

function Money([double]$Value) {
   $sign = if($Value -ge 0.0) { "+" } else { "-" }
   return $sign + '$' + [Math]::Abs($Value).ToString("N2",[Globalization.CultureInfo]::InvariantCulture)
}

function BoolText([bool]$Value) {
   if($Value) { return "PASS" }
   return "FAIL"
}

$manifest = @(Import-Csv -LiteralPath (Resolve-RepoPath $ManifestPath))
if($manifest.Count -ne 20) { throw "Expected twenty frozen Model1 manifest rows." }
if(@($manifest | Where-Object { $_.SourceSha256 -ne $expectedSourceSha256 -or [int]$_.Model -ne 1 }).Count -ne 0) {
   throw "Manifest source or model identity changed."
}
if(@($manifest.Candidate | Sort-Object -Unique).Count -ne 5 -or
   @($manifest.Window | Sort-Object -Unique).Count -ne 4) {
   throw "Manifest candidate/window topology changed."
}

$rawResults = "work\RVSRQ_RAW_RESULTS.csv"
$rawSummary = "work\RVSRQ_RAW_SUMMARY.csv"
$rawMetrics = "work\RVSRQ_RAW_METRICS.md"
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "collect_validation_results.ps1") `
   -RepoRoot $repo `
   -ManifestPath $ManifestPath `
   -ReportDir $ReportDir `
   -ReportNameTemplate "{ExpectedReportName}" `
   -OutResults $rawResults `
   -OutSummary $rawSummary `
   -OutMarkdown $rawMetrics | Out-Null
if($LASTEXITCODE -ne 0) { throw "Shared report collector failed." }

$raw = @(Import-Csv -LiteralPath (Resolve-RepoPath $rawResults))
if($raw.Count -ne 20 -or @($raw | Where-Object Status -ne "PARSED").Count -ne 0) {
   throw "Expected twenty parsed Model1 reports."
}
$rawByReport = @{}
foreach($row in $raw) { $rawByReport[[string]$row.ExpectedReportName] = $row }

$workerRows = [Collections.Generic.List[object]]::new()
$workerFiles = @(
   Get-ChildItem (Join-Path $repo "outputs") -Filter "THREE_LANE_REVERSION_STRONG_REWARD_QUALITY_MODEL1_EXACT_?.csv" -File
   Get-ChildItem (Join-Path $repo "outputs") -Filter "THREE_LANE_REVERSION_STRONG_REWARD_QUALITY_MODEL1_RETRY_?.csv" -File
) | Sort-Object Name
foreach($file in $workerFiles) {
   foreach($row in @(Import-Csv -LiteralPath $file.FullName)) { $workerRows.Add($row) | Out-Null }
}
if($workerRows.Count -ne 22 -or @($workerRows | Where-Object {
   $_.PackageSourceSha256 -ne $expectedSourceSha256 -or
   $_.PortableExpertRecompiled -ne "False" -or
   ($_.Status -eq 'REPORT_FOUND' -and $_.PortableBinarySha256 -ne $expectedBinarySha256)
}).Count -ne 0) {
   throw "Runner evidence is incomplete or has an identity mismatch."
}
$workerByRank = @{}
foreach($rank in 1..20) {
   $attempts = @($workerRows | Where-Object { [int]$_.QueueRank -eq $rank })
   $valid = @($attempts | Where-Object Status -eq "REPORT_FOUND" | Sort-Object Finished)
   if($valid.Count -ne 1) { throw "Rank $rank does not have exactly one valid final report." }
   $workerByRank[[string]$rank] = $valid[0]
}
if(@($workerRows | Where-Object Status -eq "ERROR").Count -ne 2) {
   throw "Expected exactly two preserved identity-only refusals."
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
      QueueRank = [int]$item.QueueRank
      Candidate = $item.Candidate
      Role = $item.Role
      RewardQualityEnabled = $item.RewardQualityEnabled
      MinimumAdjustedRiskReward = [double]$item.StrongSignalMinimumAdjustedRiskReward
      Window = $item.Window
      From = $item.From
      To = $item.To
      Model = [int]$item.Model
      ProfileSha256 = $item.ProfileSha256
      SourceSha256 = $item.SourceSha256
      BinarySha256 = $run.PortableBinarySha256
      Status = $parsed.Status
      NetProfit = [math]::Round([double]$parsed.NetProfit,2)
      TotalReturnPercent = [math]::Round([double]$parsed.TotalReturnPercent,2)
      CagrPercent = [math]::Round([double]$parsed.CagrPercent,2)
      ProfitFactor = [math]::Round([double]$parsed.ProfitFactor,2)
      TotalTrades = [int]$parsed.TotalTrades
      WinRatePercent = [math]::Round([double]$parsed.WinRatePercent,2)
      MaxDrawdownMoney = [math]::Round([double]$parsed.MaxDrawdownMoney,2)
      MaxDrawdownPercent = [math]::Round([double]$parsed.MaxDrawdownPercent,2)
      RecoveryFactor = [math]::Round([double]$parsed.RecoveryFactor,4)
      ReturnDrawdown = [math]::Round($returnDrawdown,4)
      SharpeRatio = [math]::Round([double]$parsed.SharpeRatio,2)
      MaxConsecutiveLosses = [int]$parsed.MaxConsecutiveLosses
      ReportSha256 = $run.ReportSha256
   }) | Out-Null
   $attestation.Add([pscustomobject][ordered]@{
      QueueRank = [int]$item.QueueRank
      Candidate = $item.Candidate
      Window = $item.Window
      Status = $run.Status
      Attempts = @($workerRows | Where-Object { [int]$_.QueueRank -eq [int]$item.QueueRank }).Count
      IdentityRetries = @($workerRows | Where-Object { [int]$_.QueueRank -eq [int]$item.QueueRank -and $_.Status -eq 'ERROR' }).Count
      SourceSha256 = $run.PackageSourceSha256
      BinarySha256 = $run.PortableBinarySha256
      ConfigSha256 = $run.PackageConfigSha256
      ReportSha256 = $run.ReportSha256
      IdentitySidecarPresent = $true
      PortableExpertRecompiled = $false
      Started = $run.Started
      Finished = $run.Finished
   }) | Out-Null
}

$results | Export-Csv -LiteralPath (Resolve-RepoPath $ResultsPath) -NoTypeInformation -Encoding ASCII
$attestation | Export-Csv -LiteralPath (Resolve-RepoPath $RunAttestationPath) -NoTypeInformation -Encoding ASCII

$byCandidateWindow = @{}
foreach($row in $results) { $byCandidateWindow["$($row.Candidate)|$($row.Window)"] = $row }
$control = $byCandidateWindow["$controlName|$continuousWindow"]
$diagnostic = $byCandidateWindow["$diagnosticName|$continuousWindow"]
$lower = $byCandidateWindow["$lowerName|$continuousWindow"]
$candidate = $byCandidateWindow["$candidateName|$continuousWindow"]
$upper = $byCandidateWindow["$upperName|$continuousWindow"]

$allWindowsPositive = @($results | Where-Object { [double]$_.NetProfit -le 0.0 }).Count -eq 0
$candidateNetAtLeastControlEveryWindow = @($windows | Where-Object {
   $window = $_
   @($lowerName,$candidateName,$upperName | Where-Object {
      [double]$byCandidateWindow["$_|$window"].NetProfit -lt [double]$byCandidateWindow["$controlName|$window"].NetProfit
   }).Count -gt 0
}).Count -eq 0
$continuousNetGate = [double]$candidate.NetProfit -ge 1.05 * [double]$control.NetProfit
$cagrGate = [double]$candidate.CagrPercent -ge [double]$control.CagrPercent + 0.10
$profitFactorGate = [double]$candidate.ProfitFactor -ge [double]$control.ProfitFactor
$drawdownGate = [double]$candidate.MaxDrawdownPercent -le 1.25 -and
   [double]$candidate.MaxDrawdownPercent -le [double]$control.MaxDrawdownPercent + 0.08
$recoveryGate = [double]$candidate.RecoveryFactor -ge [double]$control.RecoveryFactor
$returnDrawdownGate = [double]$candidate.ReturnDrawdown -ge [double]$control.ReturnDrawdown
$tradeCountGate = [int]$candidate.TotalTrades -ge 400
$lowerGate = [double]$lower.NetProfit -ge 1.03 * [double]$control.NetProfit -and
   [double]$lower.CagrPercent -ge [double]$control.CagrPercent + 0.05 -and
   [double]$lower.ProfitFactor -ge [double]$control.ProfitFactor -and
   [double]$lower.MaxDrawdownPercent -le 1.25 -and
   [double]$lower.RecoveryFactor -ge [double]$control.RecoveryFactor -and
   [double]$lower.ReturnDrawdown -ge [double]$control.ReturnDrawdown -and
   [int]$lower.TotalTrades -ge 400
$upperGate = [double]$upper.NetProfit -ge 1.03 * [double]$control.NetProfit -and
   [double]$upper.CagrPercent -ge [double]$control.CagrPercent + 0.05 -and
   [double]$upper.ProfitFactor -ge [double]$control.ProfitFactor -and
   [double]$upper.MaxDrawdownPercent -le 1.25 -and
   [double]$upper.RecoveryFactor -ge [double]$control.RecoveryFactor -and
   [double]$upper.ReturnDrawdown -ge [double]$control.ReturnDrawdown -and
   [int]$upper.TotalTrades -ge 400
$passed = $allWindowsPositive -and $candidateNetAtLeastControlEveryWindow -and $continuousNetGate -and
   $cagrGate -and $profitFactorGate -and $drawdownGate -and $recoveryGate -and
   $returnDrawdownGate -and $tradeCountGate -and $lowerGate -and $upperGate

$summary = foreach($name in @($controlName,$diagnosticName,$lowerName,$candidateName,$upperName)) {
   $continuous = $byCandidateWindow["$name|$continuousWindow"]
   [pscustomobject][ordered]@{
      Candidate = $name
      Role = $continuous.Role
      Enabled = $name -ne $controlName
      RewardQualityEnabled = $continuous.RewardQualityEnabled
      StrongSignalMinimumBodyRatio = 0.25
      StrongSignalRiskPercent = 0.70
      MinimumAdjustedRiskReward = $continuous.MinimumAdjustedRiskReward
      OlderNetProfit = $byCandidateWindow["$name|older_2015_2018"].NetProfit
      MiddleNetProfit = $byCandidateWindow["$name|middle_2019_2022"].NetProfit
      RecentNetProfit = $byCandidateWindow["$name|recent_2023_2026"].NetProfit
      ContinuousNetProfit = $continuous.NetProfit
      TotalReturnPercent = $continuous.TotalReturnPercent
      CagrPercent = $continuous.CagrPercent
      ProfitFactor = $continuous.ProfitFactor
      TotalTrades = $continuous.TotalTrades
      MaxDrawdownPercent = $continuous.MaxDrawdownPercent
      RecoveryFactor = $continuous.RecoveryFactor
      ReturnDrawdown = $continuous.ReturnDrawdown
      GatePass = if($name -eq $controlName) { $true } elseif($name -eq $candidateName) { $passed } elseif($name -eq $lowerName) { $lowerGate } elseif($name -eq $upperName) { $upperGate } else { 'DIAGNOSTIC_ONLY' }
   }
}
$summary | Export-Csv -LiteralPath (Resolve-RepoPath $SummaryPath) -NoTypeInformation -Encoding ASCII

$decision = [pscustomobject][ordered]@{
   Status = if($passed) { "MODEL1_GATE_PASSED" } else { "REJECTED_IN_MODEL1" }
   ReportsParsed = $results.Count
   IdentityValidReports = $attestation.Count
   TotalAttempts = $workerRows.Count
   IdentityRetries = @($workerRows | Where-Object Status -eq 'ERROR').Count
   AllWindowsPositive = $allWindowsPositive
   CandidateNetAtLeastControlEveryWindow = $candidateNetAtLeastControlEveryWindow
   ContinuousNetAtLeastControlPlusFivePercent = $continuousNetGate
   CagrAtLeastControlPlusPointTen = $cagrGate
   ProfitFactorAtLeastControl = $profitFactorGate
   DrawdownWithinFrozenLimits = $drawdownGate
   RecoveryAtLeastControl = $recoveryGate
   ReturnDrawdownAtLeastControl = $returnDrawdownGate
   ContinuousTradesAtLeast400 = $tradeCountGate
   LowerNeighborGate = $lowerGate
   UpperNeighborGate = $upperGate
   Model4ValidationPermitted = $passed
   ResearchPromotionPermitted = $false
   ForwardCandidateChanged = $false
   RealAccountTradingAllowed = $false
   ControlNetProfit = $control.NetProfit
   CandidateNetProfit = $candidate.NetProfit
   LowerNeighborNetProfit = $lower.NetProfit
   UpperNeighborNetProfit = $upper.NetProfit
   ControlRecoveryFactor = $control.RecoveryFactor
   CandidateRecoveryFactor = $candidate.RecoveryFactor
   LowerNeighborRecoveryFactor = $lower.RecoveryFactor
   UpperNeighborRecoveryFactor = $upper.RecoveryFactor
   SourceSha256 = $expectedSourceSha256
   BinarySha256 = $expectedBinarySha256
   CandidateProfileSha256 = $candidate.ProfileSha256
}
$decision | Export-Csv -LiteralPath (Resolve-RepoPath $DecisionCsvPath) -NoTypeInformation -Encoding ASCII

$netImprovementPercent = 100.0 * ([double]$candidate.NetProfit / [double]$control.NetProfit - 1.0)
$recoveryDifference = [double]$candidate.RecoveryFactor - [double]$control.RecoveryFactor
$lines = [Collections.Generic.List[string]]::new()
$lines.Add("# Three-Lane Reversion Strong-Reward Quality Model 1 Decision")
$lines.Add("")
$lines.Add($(if($passed) {
   "**Decision: MODEL 1 GATE PASSED. The fixed center and neighbors may open Model 4 real-tick validation; no promotion or forward change is authorized.**"
} else {
   "**Decision: REJECTED IN MODEL 1. No Model 4, promotion, forward change, or live approval is permitted.**"
}))
$lines.Add("")
$lines.Add("- Reports: ``20 / 20`` parsed and exact source/binary identity valid")
$lines.Add("- Attempts: ``22``; identity-only retries: ``2``")
$lines.Add("- Exact source SHA-256: ``$expectedSourceSha256``")
$lines.Add("- Exact EX5 SHA-256: ``$expectedBinarySha256``")
$lines.Add("- Candidate profile SHA-256: ``$($candidate.ProfileSha256)``")
$lines.Add("- Fixed allocation: completed H1 body ratio ``0.25`` and requested risk ``0.70%``")
$lines.Add("- Fixed adjusted reward/risk neighborhood: ``1.35 / 1.50 / 1.65``")
$lines.Add("- Real-account trading: disabled")
$lines.Add("")
$lines.Add("| Profile | 2015-18 | 2019-22 | 2023-26 | Continuous | Return | CAGR | PF | Trades | DD | Recovery | Return/DD |")
$lines.Add("|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|")
foreach($row in $summary) {
   $label = switch($row.Candidate) {
      $controlName { "Disabled-feature control" }
      $diagnosticName { "Body-only unfiltered diagnostic" }
      $lowerName { "Lower neighbor RR 1.35" }
      $candidateName { "Center RR 1.50" }
      $upperName { "Upper neighbor RR 1.65" }
   }
   $lines.Add("| $label | $(Money ([double]$row.OlderNetProfit)) | $(Money ([double]$row.MiddleNetProfit)) | $(Money ([double]$row.RecentNetProfit)) | $(Money ([double]$row.ContinuousNetProfit)) | $($row.TotalReturnPercent)% | $($row.CagrPercent)%/yr | $($row.ProfitFactor) | $($row.TotalTrades) | $($row.MaxDrawdownPercent)% | $($row.RecoveryFactor) | $($row.ReturnDrawdown) |")
}
$lines.Add("")
$lines.Add("## Frozen Gate")
$lines.Add("")
$lines.Add("| Requirement | Result | Status |")
$lines.Add("|---|---|---|")
$lines.Add("| Every tested era profitable | ``$allWindowsPositive`` | $(BoolText $allWindowsPositive) |")
$lines.Add("| Center and both neighbors no worse in every era | ``$candidateNetAtLeastControlEveryWindow`` | $(BoolText $candidateNetAtLeastControlEveryWindow) |")
$lines.Add("| Continuous net at least control +5% | ``$('{0:N2}' -f $netImprovementPercent)%`` | $(BoolText $continuousNetGate) |")
$lines.Add("| CAGR at least control +0.10 point | ``$($candidate.CagrPercent - $control.CagrPercent)`` point | $(BoolText $cagrGate) |")
$lines.Add("| PF no worse than control | ``$($candidate.ProfitFactor)`` vs ``$($control.ProfitFactor)`` | $(BoolText $profitFactorGate) |")
$lines.Add("| DD <=1.25% and <=control +0.08 point | ``$($candidate.MaxDrawdownPercent)%`` vs ``$($control.MaxDrawdownPercent)%`` | $(BoolText $drawdownGate) |")
$lines.Add("| Recovery no worse than control | ``$($candidate.RecoveryFactor)`` vs ``$($control.RecoveryFactor)`` | $(BoolText $recoveryGate) |")
$lines.Add("| Return/DD no worse than control | ``$($candidate.ReturnDrawdown)`` vs ``$($control.ReturnDrawdown)`` | $(BoolText $returnDrawdownGate) |")
$lines.Add("| At least 400 continuous trades | ``$($candidate.TotalTrades)`` | $(BoolText $tradeCountGate) |")
$lines.Add("| RR 1.35 lower neighbor independently passes | net ``$(Money ([double]$lower.NetProfit))``; CAGR ``$($lower.CagrPercent)%``; recovery ``$($lower.RecoveryFactor)`` | $(BoolText $lowerGate) |")
$lines.Add("| RR 1.65 upper neighbor independently passes | net ``$(Money ([double]$upper.NetProfit))``; CAGR ``$($upper.CagrPercent)%``; recovery ``$($upper.RecoveryFactor)`` | $(BoolText $upperGate) |")
$lines.Add("")
$lines.Add("## Interpretation")
$lines.Add("")
$lines.Add("The center changes no entry or exit rule. It allocates extra risk only when the already-valid completed-bar reversion also has spread-adjusted reward/risk of at least 1.50. Continuous Model 1 net improved by ``$('{0:N2}' -f $netImprovementPercent)%`` and CAGR by ``$($candidate.CagrPercent - $control.CagrPercent)`` point while both efficiency measures improved.")
$lines.Add("")
$lines.Add($(if($passed) {
   "The center and both reward-quality neighbors passed the preregistered Model 1 growth and efficiency gates. A fixed Model 4 real-tick comparison may open, but this is not a promotion and the forward candidate remains unchanged."
} else {
   "At least one preregistered center or neighbor gate failed. The gate is not relaxed after observation; Model 4 stays closed and ATB150 remains the historical champion. Center recovery difference versus control: ``$('{0:F4}' -f $recoveryDifference)``."
}))
$lines.Add("")
$lines.Add("The registered forward candidate, invalid-account boundary, evidence logs, and real-account lock remain unchanged.")
$lines | Set-Content -LiteralPath (Resolve-RepoPath $DecisionMarkdownPath) -Encoding ASCII

Remove-Item -LiteralPath (Resolve-RepoPath $rawResults),(Resolve-RepoPath $rawSummary),(Resolve-RepoPath $rawMetrics) -Force -ErrorAction SilentlyContinue
$decision
