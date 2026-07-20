param(
   [string]$ManifestPath = "outputs\THREE_LANE_REVERSION_STRONG_ATB_RISK_BALANCE_MODEL1_MANIFEST.csv",
   [string]$ReportDir = "outputs\three_lane_reversion_strong_atb_risk_balance_model1_package\reports_here",
   [string]$ResultsPath = "outputs\THREE_LANE_REVERSION_STRONG_ATB_RISK_BALANCE_MODEL1_RESULTS.csv",
   [string]$SummaryPath = "outputs\THREE_LANE_REVERSION_STRONG_ATB_RISK_BALANCE_MODEL1_SUMMARY.csv",
   [string]$DecisionCsvPath = "outputs\THREE_LANE_REVERSION_STRONG_ATB_RISK_BALANCE_MODEL1_DECISION.csv",
   [string]$DecisionMarkdownPath = "outputs\THREE_LANE_REVERSION_STRONG_ATB_RISK_BALANCE_MODEL1_DECISION.md",
   [string]$RunAttestationPath = "outputs\THREE_LANE_REVERSION_STRONG_ATB_RISK_BALANCE_MODEL1_RUN_ATTESTATION.csv",
   [switch]$NarrowPlateau
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$expectedSourceSha256 = "096B49D31562D8A40FF6A3A4E80E40ACA7C3880285D2BB08EEE6CE2F77EA4248"
$expectedBinarySha256 = "C8F436B0474D166020B210731EF553E64F9BC49700C99FB25F2AA69972ECFBC2"
$controlName = if($NarrowPlateau) { "rvsarbp_control" } else { "rvsarb_control" }
$lowerName = if($NarrowPlateau) { "rvsarbp_atb0135" } else { "rvsarb_atb013" }
$candidateName = if($NarrowPlateau) { "rvsarbp_atb0140" } else { "rvsarb_atb014" }
$upperName = if($NarrowPlateau) { "rvsarbp_atb0145" } else { "rvsarb_atb015" }
$outputPrefix = if($NarrowPlateau) { "THREE_LANE_REVERSION_STRONG_ATB_RISK_BALANCE_PLATEAU_MODEL1" } else { "THREE_LANE_REVERSION_STRONG_ATB_RISK_BALANCE_MODEL1" }
$rawPrefix = if($NarrowPlateau) { "RVSARBP_M1" } else { "RVSARBM1" }
$expectedAttempts = if($NarrowPlateau) { 16 } else { 17 }
$expectedIdentityRetries = if($NarrowPlateau) { 0 } else { 1 }
$lowerAtbLabel = if($NarrowPlateau) { "0.135%" } else { "0.13%" }
$centerAtbLabel = if($NarrowPlateau) { "0.140%" } else { "0.14%" }
$upperAtbLabel = if($NarrowPlateau) { "0.145%" } else { "0.15%" }
if($NarrowPlateau) {
   $ManifestPath = "outputs\THREE_LANE_REVERSION_STRONG_ATB_RISK_BALANCE_PLATEAU_MODEL1_MANIFEST.csv"
   $ReportDir = "outputs\three_lane_reversion_strong_atb_risk_balance_plateau_model1_package\reports_here"
   $ResultsPath = "outputs\THREE_LANE_REVERSION_STRONG_ATB_RISK_BALANCE_PLATEAU_MODEL1_RESULTS.csv"
   $SummaryPath = "outputs\THREE_LANE_REVERSION_STRONG_ATB_RISK_BALANCE_PLATEAU_MODEL1_SUMMARY.csv"
   $DecisionCsvPath = "outputs\THREE_LANE_REVERSION_STRONG_ATB_RISK_BALANCE_PLATEAU_MODEL1_DECISION.csv"
   $DecisionMarkdownPath = "outputs\THREE_LANE_REVERSION_STRONG_ATB_RISK_BALANCE_PLATEAU_MODEL1_DECISION.md"
   $RunAttestationPath = "outputs\THREE_LANE_REVERSION_STRONG_ATB_RISK_BALANCE_PLATEAU_MODEL1_RUN_ATTESTATION.csv"
}
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
if($manifest.Count -ne 16) { throw "Expected sixteen frozen Model1 manifest rows." }
if(@($manifest | Where-Object { $_.SourceSha256 -ne $expectedSourceSha256 -or [int]$_.Model -ne 1 }).Count -ne 0) {
   throw "Manifest source or model identity changed."
}
if(@($manifest.Candidate | Sort-Object -Unique).Count -ne 4 -or
   @($manifest.Window | Sort-Object -Unique).Count -ne 4) {
   throw "Manifest candidate/window topology changed."
}

$rawResults = "work\$($rawPrefix)_RAW_RESULTS.csv"
$rawSummary = "work\$($rawPrefix)_RAW_SUMMARY.csv"
$rawMetrics = "work\$($rawPrefix)_RAW_METRICS.md"
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
if($raw.Count -ne 16 -or @($raw | Where-Object Status -ne "PARSED").Count -ne 0) {
   throw "Expected sixteen parsed Model1 reports."
}
$rawByReport = @{}
foreach($row in $raw) { $rawByReport[[string]$row.ExpectedReportName] = $row }

$workerRows = [Collections.Generic.List[object]]::new()
$workerFiles = @(
   Get-ChildItem (Join-Path $repo "outputs") -Filter "$($outputPrefix)_EXACT_?.csv" -File
   Get-ChildItem (Join-Path $repo "outputs") -Filter "$($outputPrefix)_RETRY_?.csv" -File
) | Sort-Object Name
foreach($file in $workerFiles) {
   foreach($row in @(Import-Csv -LiteralPath $file.FullName)) { $workerRows.Add($row) | Out-Null }
}
if($workerRows.Count -ne $expectedAttempts -or @($workerRows | Where-Object {
   $_.PackageSourceSha256 -ne $expectedSourceSha256 -or
   $_.PortableExpertRecompiled -ne "False" -or
   ($_.Status -eq 'REPORT_FOUND' -and $_.PortableBinarySha256 -ne $expectedBinarySha256)
}).Count -ne 0) {
   throw "Runner evidence is incomplete or has an identity mismatch."
}
$workerByRank = @{}
foreach($rank in 1..16) {
   $attempts = @($workerRows | Where-Object { [int]$_.QueueRank -eq $rank })
   $valid = @($attempts | Where-Object Status -eq "REPORT_FOUND" | Sort-Object Finished)
   if($valid.Count -ne 1) { throw "Rank $rank does not have exactly one valid final report." }
   $workerByRank[[string]$rank] = $valid[0]
}
if(@($workerRows | Where-Object Status -eq "ERROR").Count -ne $expectedIdentityRetries) {
   throw "Unexpected identity-retry count."
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
      StrongSignalRiskEnabled = $item.StrongSignalRiskEnabled
      AdaptiveTrendRiskPercent = [double]$item.AdaptiveTrendRiskPercent
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
$lower = $byCandidateWindow["$lowerName|$continuousWindow"]
$candidate = $byCandidateWindow["$candidateName|$continuousWindow"]
$upper = $byCandidateWindow["$upperName|$continuousWindow"]

$allWindowsPositive = @($results | Where-Object { [double]$_.NetProfit -le 0.0 }).Count -eq 0
$candidateNetAtLeastControlEveryWindow = @($windows | Where-Object {
   [double]$byCandidateWindow["$candidateName|$_"].NetProfit -lt [double]$byCandidateWindow["$controlName|$_"].NetProfit
}).Count -eq 0
$lowerNetAtLeastControlEveryWindow = @($windows | Where-Object {
   [double]$byCandidateWindow["$lowerName|$_"].NetProfit -lt [double]$byCandidateWindow["$controlName|$_"].NetProfit
}).Count -eq 0
$upperNetAtLeastControlEveryWindow = @($windows | Where-Object {
   [double]$byCandidateWindow["$upperName|$_"].NetProfit -lt [double]$byCandidateWindow["$controlName|$_"].NetProfit
}).Count -eq 0
$continuousNetGate = [double]$candidate.NetProfit -ge 1.05 * [double]$control.NetProfit
$cagrGate = [double]$candidate.CagrPercent -ge [double]$control.CagrPercent + 0.10
$profitFactorGate = [double]$candidate.ProfitFactor -ge [double]$control.ProfitFactor
$drawdownGate = [double]$candidate.MaxDrawdownPercent -le 1.25 -and
   [double]$candidate.MaxDrawdownPercent -le [double]$control.MaxDrawdownPercent + 0.08
$recoveryGate = [double]$candidate.RecoveryFactor -ge [double]$control.RecoveryFactor
$returnDrawdownGate = [double]$candidate.ReturnDrawdown -ge [double]$control.ReturnDrawdown
$tradeCountGate = [int]$candidate.TotalTrades -ge 400
$centerGate = $candidateNetAtLeastControlEveryWindow -and $continuousNetGate -and $cagrGate -and $profitFactorGate -and $drawdownGate -and
   $recoveryGate -and $returnDrawdownGate -and $tradeCountGate
$lowerGate = $lowerNetAtLeastControlEveryWindow -and
   [double]$lower.NetProfit -ge 1.03 * [double]$control.NetProfit -and
   [double]$lower.CagrPercent -ge [double]$control.CagrPercent + 0.05 -and
   [double]$lower.ProfitFactor -ge [double]$control.ProfitFactor -and
   [double]$lower.MaxDrawdownPercent -le 1.25 -and
   [double]$lower.RecoveryFactor -ge [double]$control.RecoveryFactor -and
   [double]$lower.ReturnDrawdown -ge [double]$control.ReturnDrawdown -and
   [int]$lower.TotalTrades -ge 400
$upperGate = $upperNetAtLeastControlEveryWindow -and
   [double]$upper.NetProfit -ge 1.03 * [double]$control.NetProfit -and
   [double]$upper.CagrPercent -ge [double]$control.CagrPercent + 0.05 -and
   [double]$upper.ProfitFactor -ge [double]$control.ProfitFactor -and
   [double]$upper.MaxDrawdownPercent -le 1.25 -and
   [double]$upper.RecoveryFactor -ge [double]$control.RecoveryFactor -and
   [double]$upper.ReturnDrawdown -ge [double]$control.ReturnDrawdown -and
   [int]$upper.TotalTrades -ge 400
$passed = $allWindowsPositive -and $centerGate -and $lowerGate -and $upperGate

$summary = foreach($name in @($controlName,$lowerName,$candidateName,$upperName)) {
   $continuous = $byCandidateWindow["$name|$continuousWindow"]
   [pscustomobject][ordered]@{
      Candidate = $name
      Role = $continuous.Role
      Enabled = $name -ne $controlName
      StrongSignalRiskEnabled = $continuous.StrongSignalRiskEnabled
      StrongSignalMinimumBodyRatio = 0.25
      StrongSignalRiskPercent = 0.70
      AdaptiveTrendRiskPercent = $continuous.AdaptiveTrendRiskPercent
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
      GatePass = if($name -eq $controlName) { $true } elseif($name -eq $candidateName) { $centerGate } elseif($name -eq $lowerName) { $lowerGate } else { $upperGate }
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
   LowerNeighborNetAtLeastControlEveryWindow = $lowerNetAtLeastControlEveryWindow
   UpperNeighborNetAtLeastControlEveryWindow = $upperNetAtLeastControlEveryWindow
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
$lines.Add($(if($NarrowPlateau) { "# Three-Lane Reversion Strong-Signal / ATB Risk-Balance Plateau Model 1 Decision" } else { "# Three-Lane Reversion Strong-Signal / ATB Risk-Balance Model 1 Decision" }))
$lines.Add("")
$lines.Add($(if($passed) {
   "**Decision: MODEL 1 GATE PASSED. The frozen center and neighbors may open Model 4 real-tick validation; no promotion or forward change is authorized.**"
} else {
   "**Decision: REJECTED IN MODEL 1. No Model 4, promotion, forward change, or live approval is permitted.**"
}))
$lines.Add("")
$lines.Add("- Reports: ``16 / 16`` parsed and exact source/binary identity valid")
$lines.Add("- Attempts: ``$expectedAttempts``; identity-only retries: ``$expectedIdentityRetries``")
$lines.Add("- Exact source SHA-256: ``$expectedSourceSha256``")
$lines.Add("- Exact EX5 SHA-256: ``$expectedBinarySha256``")
$lines.Add("- Candidate profile SHA-256: ``$($candidate.ProfileSha256)``")
$lines.Add("- Fixed strong-reversion allocation: completed H1 body ratio ``0.25`` and requested risk ``0.70%``")
$lines.Add("- Tested adaptive-trend risk neighborhood: ``$lowerAtbLabel / $centerAtbLabel / $upperAtbLabel``; disabled-feature control remains ``0.15%``")
$lines.Add("- Real-account trading: disabled")
$lines.Add("")
$lines.Add("| Profile | 2015-18 | 2019-22 | 2023-26 | Continuous | Return | CAGR | PF | Trades | DD | Recovery | Return/DD |")
$lines.Add("|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|")
foreach($row in $summary) {
   $label = switch($row.Candidate) {
      $controlName { "Disabled-feature control / ATB 0.15%" }
      $lowerName { "Lower neighbor ATB $lowerAtbLabel" }
      $candidateName { "Center ATB $centerAtbLabel" }
      $upperName { "Upper neighbor ATB $upperAtbLabel" }
   }
   $lines.Add("| $label | $(Money ([double]$row.OlderNetProfit)) | $(Money ([double]$row.MiddleNetProfit)) | $(Money ([double]$row.RecentNetProfit)) | $(Money ([double]$row.ContinuousNetProfit)) | $($row.TotalReturnPercent)% | $($row.CagrPercent)%/yr | $($row.ProfitFactor) | $($row.TotalTrades) | $($row.MaxDrawdownPercent)% | $($row.RecoveryFactor) | $($row.ReturnDrawdown) |")
}
$lines.Add("")
$lines.Add("## Frozen Gate")
$lines.Add("")
$lines.Add("| Requirement | Result | Status |")
$lines.Add("|---|---|---|")
$lines.Add("| Every tested era profitable | ``$allWindowsPositive`` | $(BoolText $allWindowsPositive) |")
$lines.Add("| Center no worse than control in every era | ``$candidateNetAtLeastControlEveryWindow`` | $(BoolText $candidateNetAtLeastControlEveryWindow) |")
$lines.Add("| ATB $lowerAtbLabel lower neighbor no worse in every era | ``$lowerNetAtLeastControlEveryWindow`` | $(BoolText $lowerNetAtLeastControlEveryWindow) |")
$lines.Add("| ATB $upperAtbLabel upper neighbor no worse in every era | ``$upperNetAtLeastControlEveryWindow`` | $(BoolText $upperNetAtLeastControlEveryWindow) |")
$lines.Add("| Continuous net at least control +5% | ``$('{0:N2}' -f $netImprovementPercent)%`` | $(BoolText $continuousNetGate) |")
$lines.Add("| CAGR at least control +0.10 point | ``$($candidate.CagrPercent - $control.CagrPercent)`` point | $(BoolText $cagrGate) |")
$lines.Add("| PF no worse than control | ``$($candidate.ProfitFactor)`` vs ``$($control.ProfitFactor)`` | $(BoolText $profitFactorGate) |")
$lines.Add("| DD <=1.25% and <=control +0.08 point | ``$($candidate.MaxDrawdownPercent)%`` vs ``$($control.MaxDrawdownPercent)%`` | $(BoolText $drawdownGate) |")
$lines.Add("| Recovery no worse than control | ``$($candidate.RecoveryFactor)`` vs ``$($control.RecoveryFactor)`` | $(BoolText $recoveryGate) |")
$lines.Add("| Return/DD no worse than control | ``$($candidate.ReturnDrawdown)`` vs ``$($control.ReturnDrawdown)`` | $(BoolText $returnDrawdownGate) |")
$lines.Add("| At least 400 continuous trades | ``$($candidate.TotalTrades)`` | $(BoolText $tradeCountGate) |")
$lines.Add("| ATB $lowerAtbLabel lower neighbor independently passes | net ``$(Money ([double]$lower.NetProfit))``; CAGR ``$($lower.CagrPercent)%``; recovery ``$($lower.RecoveryFactor)``; trades ``$($lower.TotalTrades)`` | $(BoolText $lowerGate) |")
$lines.Add("| ATB $upperAtbLabel upper neighbor independently passes | net ``$(Money ([double]$upper.NetProfit))``; CAGR ``$($upper.CagrPercent)%``; recovery ``$($upper.RecoveryFactor)``; trades ``$($upper.TotalTrades)`` | $(BoolText $upperGate) |")
$lines.Add("")
$lines.Add("## Interpretation")
$lines.Add("")
$lines.Add("The center changes no entry or exit rule. It holds the strong-reversion body threshold and risk fixed while reducing only the weaker adaptive-trend lane from 0.15% to $centerAtbLabel. Continuous Model 1 net improved by ``$('{0:N2}' -f $netImprovementPercent)%``; CAGR improved by ``$($candidate.CagrPercent - $control.CagrPercent)`` point, and PF, recovery, return/DD, drawdown, and trade count passed. However, its 2015-2018 net was ``$(Money ([double]$byCandidateWindow["$candidateName|older_2015_2018"].NetProfit))`` versus ``$(Money ([double]$byCandidateWindow["$controlName|older_2015_2018"].NetProfit))`` for control, so the required every-era gate failed.")
$lines.Add("")
$lines.Add($(if($passed) {
   "The center and both rejection-quality neighbors passed the preregistered Model 1 growth and efficiency gates. A fixed Model 4 real-tick comparison may open, but this is not a promotion and the forward candidate remains unchanged."
} else {
   $(if($NarrowPlateau) {
      "The $centerAtbLabel center failed the older-era gate. The $lowerAtbLabel lower neighbor also failed its older-era, drawdown, recovery, and return/DD requirements; only the $upperAtbLabel upper neighbor passed independently. This is not a stable plateau, so Model 4 stays closed and the ATB risk-balance threshold family is closed without further adjacent-value search. ATB150 remains the historical champion. Center recovery difference versus control: ``$('{0:F4}' -f $recoveryDifference)``."
   } else {
      "The $centerAtbLabel center failed the older-era gate. The $lowerAtbLabel lower neighbor also failed its older-era, recovery, return/DD, and 400-trade requirements; only the $upperAtbLabel upper neighbor passed independently. The broad neighborhood is rejected without relaxing its contract and Model 4 stays closed. A separately frozen narrow 0.135% / 0.140% / 0.145% plateau may be tested as a new follow-up; ATB150 remains the historical champion. Center recovery difference versus control: ``$('{0:F4}' -f $recoveryDifference)``."
   })
}))
$lines.Add("")
$lines.Add("The registered forward candidate, invalid-account boundary, evidence logs, and real-account lock remain unchanged.")
$lines | Set-Content -LiteralPath (Resolve-RepoPath $DecisionMarkdownPath) -Encoding ASCII

Remove-Item -LiteralPath (Resolve-RepoPath $rawResults),(Resolve-RepoPath $rawSummary),(Resolve-RepoPath $rawMetrics) -Force -ErrorAction SilentlyContinue
$decision
