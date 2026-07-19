param(
   [string]$ManifestPath = "outputs\THREE_LANE_REVERSION_STRICT_BODY_REAL_TICK_PLATEAU_MANIFEST.csv",
   [string]$ReportDir = "outputs\three_lane_reversion_strict_body_real_tick_plateau_package\reports_here",
   [string]$ResultsPath = "outputs\THREE_LANE_REVERSION_STRICT_BODY_REAL_TICK_PLATEAU_RESULTS.csv",
   [string]$SummaryPath = "outputs\THREE_LANE_REVERSION_STRICT_BODY_REAL_TICK_PLATEAU_SUMMARY.csv",
   [string]$DecisionCsvPath = "outputs\THREE_LANE_REVERSION_STRICT_BODY_REAL_TICK_PLATEAU_DECISION.csv",
   [string]$DecisionMarkdownPath = "outputs\THREE_LANE_REVERSION_STRICT_BODY_REAL_TICK_PLATEAU_DECISION.md",
   [string]$RunAttestationPath = "outputs\THREE_LANE_REVERSION_STRICT_BODY_REAL_TICK_PLATEAU_RUN_ATTESTATION.csv"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$expectedSourceSha256 = "36300BA97B4384C1860ED7754495C5EFC74D2C75603BF0CDCD24BC31D9EAB1DF"
$expectedBinarySha256 = "1B86001F62CE3AC4FDB29FF1E9D4DA34120FEFB37E1540A952186553E2D9845F"
$controlName = "rvsrp_control"
$candidateName = "rvsrp_b250_r065"
$neighborName = "rvsrp_b250_r0675"
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
if($manifest.Count -ne 12) { throw "Expected twelve frozen Model4 manifest rows." }
if(@($manifest | Where-Object { $_.SourceSha256 -ne $expectedSourceSha256 -or [int]$_.Model -ne 4 }).Count -ne 0) {
   throw "Manifest source or model identity changed."
}
if(@($manifest.Candidate | Sort-Object -Unique).Count -ne 3 -or
   @($manifest.Window | Sort-Object -Unique).Count -ne 4) {
   throw "Manifest candidate/window topology changed."
}

$rawResults = "work\RVSRP_RAW_RESULTS.csv"
$rawSummary = "work\RVSRP_RAW_SUMMARY.csv"
$rawMetrics = "work\RVSRP_RAW_METRICS.md"
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
if($raw.Count -ne 12 -or @($raw | Where-Object Status -ne "PARSED").Count -ne 0) {
   throw "Expected twelve parsed Model4 reports."
}
$rawByReport = @{}
foreach($row in $raw) { $rawByReport[[string]$row.ExpectedReportName] = $row }

$workerRows = [Collections.Generic.List[object]]::new()
$workerFiles = @(Get-ChildItem (Join-Path $repo "outputs") -Filter "THREE_LANE_REVERSION_STRICT_BODY_REAL_TICK_PLATEAU_EXACT_?.csv" -File | Sort-Object Name)
foreach($file in $workerFiles) {
   foreach($row in @(Import-Csv -LiteralPath $file.FullName)) { $workerRows.Add($row) | Out-Null }
}
if($workerRows.Count -ne 12 -or @($workerRows | Where-Object {
   $_.Status -ne "REPORT_FOUND" -or
   $_.PackageSourceSha256 -ne $expectedSourceSha256 -or
   $_.PortableBinarySha256 -ne $expectedBinarySha256 -or
   $_.PortableExpertRecompiled -ne "False"
}).Count -ne 0) {
   throw "Runner evidence is incomplete or has an identity mismatch."
}
$workerByRank = @{}
foreach($row in $workerRows) { $workerByRank[[string]$row.QueueRank] = $row }

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
$candidate = $byCandidateWindow["$candidateName|$continuousWindow"]
$neighbor = $byCandidateWindow["$neighborName|$continuousWindow"]

$allWindowsPositive = @($results | Where-Object { [double]$_.NetProfit -le 0.0 }).Count -eq 0
$candidateNetAtLeastControlEveryWindow = @($windows | Where-Object {
   $window = $_
   @($candidateName,$neighborName | Where-Object {
      [double]$byCandidateWindow["$_|$window"].NetProfit -lt [double]$byCandidateWindow["$controlName|$window"].NetProfit
   }).Count -gt 0
}).Count -eq 0
$continuousNetGate = [double]$candidate.NetProfit -ge 1.05 * [double]$control.NetProfit
$cagrGate = [double]$candidate.CagrPercent -ge [double]$control.CagrPercent + 0.10
$profitFactorGate = [double]$candidate.ProfitFactor -ge [double]$control.ProfitFactor
$drawdownGate = [double]$candidate.MaxDrawdownPercent -le 1.30 -and
   [double]$candidate.MaxDrawdownPercent -le [double]$control.MaxDrawdownPercent + 0.10
$recoveryGate = [double]$candidate.RecoveryFactor -ge [double]$control.RecoveryFactor
$returnDrawdownGate = [double]$candidate.ReturnDrawdown -ge [double]$control.ReturnDrawdown
$tradeCountGate = [int]$candidate.TotalTrades -ge 400
$neighborGate = [double]$neighbor.NetProfit -ge 1.05 * [double]$control.NetProfit -and
   [double]$neighbor.CagrPercent -ge [double]$control.CagrPercent + 0.10 -and
   [double]$neighbor.ProfitFactor -ge [double]$control.ProfitFactor -and
   [double]$neighbor.MaxDrawdownPercent -le 1.30 -and
   [double]$neighbor.MaxDrawdownPercent -le [double]$control.MaxDrawdownPercent + 0.10 -and
   [double]$neighbor.RecoveryFactor -ge [double]$control.RecoveryFactor -and
   [double]$neighbor.ReturnDrawdown -ge [double]$control.ReturnDrawdown -and
   [int]$neighbor.TotalTrades -ge 400
$passed = $allWindowsPositive -and $candidateNetAtLeastControlEveryWindow -and $continuousNetGate -and
   $cagrGate -and $profitFactorGate -and $drawdownGate -and $recoveryGate -and
   $returnDrawdownGate -and $tradeCountGate -and $neighborGate

$summary = foreach($name in @($controlName,$candidateName,$neighborName)) {
   $continuous = $byCandidateWindow["$name|$continuousWindow"]
   $risk = switch($name) {
      $candidateName { 0.65 }
      $neighborName { 0.675 }
      default { 0.60 }
   }
   [pscustomobject][ordered]@{
      Candidate = $name
      Enabled = $name -ne $controlName
      StrongSignalMinimumBodyRatio = 0.25
      StrongSignalRiskPercent = $risk
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
      GatePass = if($name -eq $controlName) { $true } elseif($name -eq $candidateName) { $passed } else { $neighborGate }
   }
}
$summary | Export-Csv -LiteralPath (Resolve-RepoPath $SummaryPath) -NoTypeInformation -Encoding ASCII

$decision = [pscustomobject][ordered]@{
   Status = if($passed) { "MODEL4_GATE_PASSED" } else { "REJECTED_IN_MODEL4" }
   ReportsParsed = $results.Count
   IdentityValidReports = $attestation.Count
   AllWindowsPositive = $allWindowsPositive
   CandidateNetAtLeastControlEveryWindow = $candidateNetAtLeastControlEveryWindow
   ContinuousNetAtLeastControlPlusFivePercent = $continuousNetGate
   CagrAtLeastControlPlusPointTen = $cagrGate
   ProfitFactorAtLeastControl = $profitFactorGate
   DrawdownWithinFrozenLimits = $drawdownGate
   RecoveryAtLeastControl = $recoveryGate
   ReturnDrawdownAtLeastControl = $returnDrawdownGate
   ContinuousTradesAtLeast400 = $tradeCountGate
   NeighborPlateauGate = $neighborGate
   ResearchPromotionPermitted = $passed
   AnnualCostMonteCarloGatePermitted = $passed
   ForwardCandidateChanged = $false
   RealAccountTradingAllowed = $false
   ControlNetProfit = $control.NetProfit
   CandidateNetProfit = $candidate.NetProfit
   NeighborNetProfit = $neighbor.NetProfit
   ControlRecoveryFactor = $control.RecoveryFactor
   CandidateRecoveryFactor = $candidate.RecoveryFactor
   NeighborRecoveryFactor = $neighbor.RecoveryFactor
   SourceSha256 = $expectedSourceSha256
   BinarySha256 = $expectedBinarySha256
   CandidateProfileSha256 = $candidate.ProfileSha256
}
$decision | Export-Csv -LiteralPath (Resolve-RepoPath $DecisionCsvPath) -NoTypeInformation -Encoding ASCII

$netImprovementPercent = 100.0 * ([double]$candidate.NetProfit / [double]$control.NetProfit - 1.0)
$recoveryDifference = [double]$candidate.RecoveryFactor - [double]$control.RecoveryFactor
$lines = [Collections.Generic.List[string]]::new()
$lines.Add("# Three-Lane Reversion Strict-Body Real-Tick Plateau Decision")
$lines.Add("")
$lines.Add($(if($passed) {
   "**Decision: MODEL4 GATE PASSED. Annual, cost, and Monte Carlo validation may open; the frozen forward candidate remains unchanged.**"
} else {
   "**Decision: REJECTED IN MODEL4. No research promotion, annual/stress expansion, forward change, or live approval is permitted.**"
}))
$lines.Add("")
$lines.Add("- Reports: ``12 / 12`` parsed and exact source/binary identity valid")
$lines.Add("- Exact source SHA-256: ``$expectedSourceSha256``")
$lines.Add("- Exact EX5 SHA-256: ``$expectedBinarySha256``")
$lines.Add("- Candidate profile SHA-256: ``$($candidate.ProfileSha256)``")
$lines.Add("- Fixed center: completed H1 body ratio ``0.25`` and strong-signal requested risk ``0.65%``")
$lines.Add("- Fixed upper neighbor: completed H1 body ratio ``0.25`` and requested risk ``0.675%``")
$lines.Add("- Real-account trading: disabled")
$lines.Add("")
$lines.Add("| Profile | 2015-18 | 2019-22 | 2023-26 | Continuous | Return | CAGR | PF | Trades | DD | Recovery | Return/DD |")
$lines.Add("|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|")
foreach($row in $summary) {
   $label = if($row.Candidate -eq $controlName) { "Disabled-feature control" } elseif($row.Candidate -eq $candidateName) { "Center body 0.25 / risk 0.65%" } else { "Neighbor body 0.25 / risk 0.675%" }
   $lines.Add("| $label | $(Money ([double]$row.OlderNetProfit)) | $(Money ([double]$row.MiddleNetProfit)) | $(Money ([double]$row.RecentNetProfit)) | $(Money ([double]$row.ContinuousNetProfit)) | $($row.TotalReturnPercent)% | $($row.CagrPercent)%/yr | $($row.ProfitFactor) | $($row.TotalTrades) | $($row.MaxDrawdownPercent)% | $($row.RecoveryFactor) | $($row.ReturnDrawdown) |")
}
$lines.Add("")
$lines.Add("## Frozen Gate")
$lines.Add("")
$lines.Add("| Requirement | Result | Status |")
$lines.Add("|---|---|---|")
$lines.Add("| Every control/center/neighbor era profitable | ``$allWindowsPositive`` | $(BoolText $allWindowsPositive) |")
$lines.Add("| Center and neighbor net no worse in every era | ``$candidateNetAtLeastControlEveryWindow`` | $(BoolText $candidateNetAtLeastControlEveryWindow) |")
$lines.Add("| Continuous net at least control +5% | ``$('{0:N2}' -f $netImprovementPercent)%`` | $(BoolText $continuousNetGate) |")
$lines.Add("| CAGR at least control +0.10 point | ``$($candidate.CagrPercent - $control.CagrPercent)`` point | $(BoolText $cagrGate) |")
$lines.Add("| PF no worse than control | ``$($candidate.ProfitFactor)`` vs ``$($control.ProfitFactor)`` | $(BoolText $profitFactorGate) |")
$lines.Add("| DD <=1.30% and <=control +0.10 point | ``$($candidate.MaxDrawdownPercent)%`` vs ``$($control.MaxDrawdownPercent)%`` | $(BoolText $drawdownGate) |")
$lines.Add("| Recovery no worse than control | ``$($candidate.RecoveryFactor)`` vs ``$($control.RecoveryFactor)`` | $(BoolText $recoveryGate) |")
$lines.Add("| Return/DD no worse than control | ``$($candidate.ReturnDrawdown)`` vs ``$($control.ReturnDrawdown)`` | $(BoolText $returnDrawdownGate) |")
$lines.Add("| At least 400 continuous trades | ``$($candidate.TotalTrades)`` | $(BoolText $tradeCountGate) |")
$lines.Add("| 0.675% upper neighbor independently passes | net ``$(Money ([double]$neighbor.NetProfit))``; CAGR ``$($neighbor.CagrPercent)%``; recovery ``$($neighbor.RecoveryFactor)`` | $(BoolText $neighborGate) |")
$lines.Add("")
$lines.Add("## Interpretation")
$lines.Add("")
$lines.Add("The center changed no entry or exit rule. It only applies the already-audited completed-bar strong-signal allocation and increased continuous real-tick net by ``$('{0:N2}' -f $netImprovementPercent)%`` with a CAGR change of ``$($candidate.CagrPercent - $control.CagrPercent)`` point.")
$lines.Add("")
$lines.Add($(if($passed) {
   "Both fixed risk rows passed the preregistered growth and efficiency gates. Annual restart, deterministic-cost, and Monte Carlo checks may open, but this is not yet a promotion and the forward candidate remains unchanged."
} else {
   "At least one preregistered center or plateau gate failed. The gate is not rounded away or relaxed after observing the result; annual/cost/Monte Carlo expansion stays closed and ATB150 remains the historical champion. Center recovery difference versus control: ``$('{0:F4}' -f $recoveryDifference)``."
}))
$lines.Add("")
$lines.Add("The registered forward candidate, invalid-account boundary, evidence logs, and real-account lock remain unchanged.")
$lines | Set-Content -LiteralPath (Resolve-RepoPath $DecisionMarkdownPath) -Encoding ASCII

Remove-Item -LiteralPath (Resolve-RepoPath $rawResults),(Resolve-RepoPath $rawSummary),(Resolve-RepoPath $rawMetrics) -Force -ErrorAction SilentlyContinue
$decision
