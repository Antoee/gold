param(
   [string]$OutCsv = "outputs\MONEY_READY_REFRESH_STATUS.csv",
   [string]$OutMarkdown = "outputs\MONEY_READY_REFRESH_STATUS.md",
   [switch]$MoveReturnedReports
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

function Resolve-RepoPath {
   param([string]$Path)
   if([string]::IsNullOrWhiteSpace($Path)) { return $Path }
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}

function Read-CsvSafe {
   param([string]$Path)
   $resolved = Resolve-RepoPath $Path
   if(Test-Path -LiteralPath $resolved) { return @(Import-Csv -LiteralPath $resolved) }
   return @()
}

function Get-Value {
   param([object]$Row, [string]$Name, [object]$Default = "")
   if($null -eq $Row) { return $Default }
   $property = $Row.PSObject.Properties[$Name]
   if($null -eq $property) { return $Default }
   return $property.Value
}

function Escape-MarkdownCell {
   param([string]$Text)
   if($null -eq $Text) { return "" }
   return ([string]$Text) -replace '\|', '\|'
}

function Ensure-ParentDir {
   param([string]$Path)
   $parent = Split-Path -Parent $Path
   if($parent -and !(Test-Path -LiteralPath $parent)) {
      New-Item -ItemType Directory -Path $parent -Force | Out-Null
   }
}

function Invoke-QuietPowerShell {
   param(
      [Parameter(Mandatory = $true)]
      [string[]]$Arguments
   )

   $logRoot = Join-Path $repo "outputs\money_ready_refresh_logs"
   New-Item -ItemType Directory -Path $logRoot -Force | Out-Null

   $stamp = Get-Date -Format "yyyyMMdd_HHmmss_fff"
   $safeName = (($Arguments -join "_") -replace '[^A-Za-z0-9_.-]', '_')
   if($safeName.Length -gt 96) { $safeName = $safeName.Substring(0, 96) }
   $stdoutPath = Join-Path $logRoot "$stamp`_$safeName.out.log"
   $stderrPath = Join-Path $logRoot "$stamp`_$safeName.err.log"

   $allArguments = @("-NoLogo", "-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass") + $Arguments
   $quotedArguments = @($allArguments | ForEach-Object {
      '"' + (([string]$_) -replace '"', '\"') + '"'
   })

   $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
   $startInfo.FileName = "powershell.exe"
   $startInfo.Arguments = ($quotedArguments -join " ")
   $startInfo.WorkingDirectory = $repo
   $startInfo.UseShellExecute = $false
   $startInfo.CreateNoWindow = $true
   $startInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
   $startInfo.RedirectStandardOutput = $true
   $startInfo.RedirectStandardError = $true

   $process = [System.Diagnostics.Process]::new()
   $process.StartInfo = $startInfo
   [void]$process.Start()
   $stdoutText = $process.StandardOutput.ReadToEnd()
   $stderrText = $process.StandardError.ReadToEnd()
   $process.WaitForExit()

   $stdoutText | Set-Content -LiteralPath $stdoutPath -Encoding ASCII
   $stderrText | Set-Content -LiteralPath $stderrPath -Encoding ASCII

   if($process.ExitCode -ne 0) {
      $errorText = $stderrText
      if([string]::IsNullOrWhiteSpace($errorText)) { $errorText = $stdoutText }
      if($errorText.Length -gt 1200) { $errorText = $errorText.Substring(0, 1200) }
      throw "Hidden PowerShell step failed with exit code $($process.ExitCode). Log: $stderrPath. $errorText"
   }
}

function Add-StatusRow {
   param(
      [System.Collections.Generic.List[object]]$Rows,
      [string]$Area,
      [string]$Status,
      [string]$Actual,
      [string]$Evidence,
      [string]$NextAction
   )

   $Rows.Add([pscustomobject]@{
      Area = $Area
      Status = $Status
      Actual = $Actual
      Evidence = $Evidence
      NextAction = $NextAction
   }) | Out-Null
}

function Get-StatusSummary {
   param([object[]]$Rows)
   $fail = @($Rows | Where-Object { [string](Get-Value $_ "Status") -eq "FAIL" }).Count
   $pending = @($Rows | Where-Object { [string](Get-Value $_ "Status") -eq "PENDING" }).Count
   $pass = @($Rows | Where-Object { [string](Get-Value $_ "Status") -eq "PASS" }).Count
   $ready = @($Rows | Where-Object { [string](Get-Value $_ "Status") -eq "READY" }).Count
   return [pscustomobject]@{
      Rows = $Rows.Count
      Pass = $pass
      Pending = $pending
      Fail = $fail
      Ready = $ready
   }
}

function Get-MarkdownValue {
   param([string]$Path, [string]$Label)
   $resolved = Resolve-RepoPath $Path
   if(!(Test-Path -LiteralPath $resolved)) { return "" }
   $text = Get-Content -LiteralPath $resolved -Raw
   $pattern = "(?m)^- " + [regex]::Escape($Label) + ":\s+`?([^`\r\n]+)`?"
   $match = [regex]::Match($text, $pattern)
   if(!$match.Success) { return "" }
   $value = $match.Groups[1].Value.Trim()
   return (($value -replace '^\*+', '') -replace '\*+$', '')
}

$routeArgs = @("-File", (Join-Path $PSScriptRoot "route_first_pass_returned_reports.ps1"))
if($MoveReturnedReports) {
   $routeArgs += "-Move"
}
Invoke-QuietPowerShell $routeArgs

$liveRouteArgs = @("-File", (Join-Path $PSScriptRoot "route_trade_ready_live_evidence.ps1"))
if($MoveReturnedReports) {
   $liveRouteArgs += "-Move"
}
Invoke-QuietPowerShell $liveRouteArgs
Invoke-QuietPowerShell @("-File", (Join-Path $PSScriptRoot "route_mt5_compile_evidence.ps1"))
Invoke-QuietPowerShell @("-File", (Join-Path $PSScriptRoot "route_trade_ready_conservative_validation_reports.ps1"))

$firstPassRefreshArgs = @("-File", (Join-Path $PSScriptRoot "refresh_first_pass_validation_state.ps1"))
if(Test-Path -LiteralPath (Resolve-RepoPath "outputs\FIRST_PASS_HIDDEN_RUN_PLAN.csv")) {
   $firstPassRefreshArgs += @("-HiddenRunCsv", "outputs\FIRST_PASS_HIDDEN_RUN_PLAN.csv")
}
Invoke-QuietPowerShell $firstPassRefreshArgs
Invoke-QuietPowerShell @("-File", (Join-Path $PSScriptRoot "import_trade_ready_conservative_validation_reports.ps1"))
Invoke-QuietPowerShell @("-File", (Join-Path $PSScriptRoot "audit_mt5_local_safety.ps1"))
Invoke-QuietPowerShell @("-File", (Join-Path $PSScriptRoot "analyze_trade_ready_conservative_trade_quality.ps1"))
Invoke-QuietPowerShell @("-File", (Join-Path $PSScriptRoot "analyze_trade_ready_conservative_monte_carlo.ps1"))
Invoke-QuietPowerShell @("-File", (Join-Path $PSScriptRoot "analyze_trade_ready_conservative_forward_test.ps1"))
Invoke-QuietPowerShell @("-File", (Join-Path $PSScriptRoot "analyze_trade_ready_conservative_second_broker.ps1"))
Invoke-QuietPowerShell @("-File", (Join-Path $PSScriptRoot "build_money_ready_efficiency_audit.ps1"))
Invoke-QuietPowerShell @("-File", (Join-Path $PSScriptRoot "build_github_required_artifact_sync_package.ps1"))
Invoke-QuietPowerShell @("-File", (Join-Path $PSScriptRoot "upload_github_required_source_artifacts.ps1"), "-PlanOnly")
Invoke-QuietPowerShell @("-File", (Join-Path $PSScriptRoot "audit_github_publication_sync.ps1"))
Invoke-QuietPowerShell @("-File", (Join-Path $PSScriptRoot "write_validation_package_shape_gate.ps1"))
Invoke-QuietPowerShell @("-File", (Join-Path $PSScriptRoot "build_trade_ready_reproducibility_bundle.ps1"))
Invoke-QuietPowerShell @("-File", (Join-Path $PSScriptRoot "analyze_trade_ready_live_readiness.ps1"))
Invoke-QuietPowerShell @("-File", (Join-Path $PSScriptRoot "build_money_ready_status_scorecard.ps1"))
Invoke-QuietPowerShell @("-File", (Join-Path $PSScriptRoot "build_trade_ready_release_candidate.ps1"))
Invoke-QuietPowerShell @("-File", (Join-Path $PSScriptRoot "run_first_pass_package_hidden.ps1"))
Invoke-QuietPowerShell @("-File", (Join-Path $PSScriptRoot "build_money_ready_proof_runway.ps1"))
Invoke-QuietPowerShell @("-File", (Join-Path $PSScriptRoot "build_money_ready_evidence_handoff.ps1"))
Invoke-QuietPowerShell @("-File", (Join-Path $PSScriptRoot "build_trade_ready_reproducibility_bundle.ps1"))

$routingRows = @(Read-CsvSafe "outputs\FIRST_PASS_RETURNED_REPORT_ROUTING.csv")
$liveRoutingRows = @(Read-CsvSafe "outputs\TRADE_READY_LIVE_EVIDENCE_ROUTING.csv")
$compileRoutingRows = @(Read-CsvSafe "outputs\MT5_COMPILE_EVIDENCE_ROUTING.csv")
$conservativeRoutingRows = @(Read-CsvSafe "outputs\TRADE_READY_CONSERVATIVE_RETURNED_REPORT_ROUTING.csv")
$firstPassRows = @(Read-CsvSafe "outputs\FIRST_PASS_REFRESH_STATUS.csv")
$firstPassPackageRows = @(Read-CsvSafe "outputs\FIRST_PASS_NEXT_RUN_PACKAGE_MANIFEST.csv")
$firstPassLaneRows = @(Read-CsvSafe "outputs\FIRST_PASS_PARALLEL_LANE_MANIFEST.csv")
$firstPassLaneRunRows = @(Read-CsvSafe "outputs\FIRST_PASS_PARALLEL_LANE_RUN_MANIFEST.csv")
$safetyRows = @(Read-CsvSafe "outputs\MT5_LOCAL_SAFETY_AUDIT.csv")
$efficiencyRows = @(Read-CsvSafe "outputs\MONEY_READY_EFFICIENCY_AUDIT.csv")
$liveRows = @(Read-CsvSafe "outputs\TRADE_READY_LIVE_READINESS_DECISION.csv")
$scoreRows = @(Read-CsvSafe "outputs\MONEY_READY_STATUS_SCORECARD.csv")
$releaseRows = @(Read-CsvSafe "outputs\TRADE_READY_RELEASE_CANDIDATE_DECISION.csv")
$runwayRows = @(Read-CsvSafe "outputs\MONEY_READY_PROOF_RUNWAY.csv")
$reproRows = @(Read-CsvSafe "outputs\TRADE_READY_REPRODUCIBILITY_BUNDLE_MANIFEST.csv")
$githubRequiredArtifactRows = @(Read-CsvSafe "outputs\GITHUB_REQUIRED_ARTIFACT_SYNC_MANIFEST.csv")
$githubPublicationRows = @(Read-CsvSafe "outputs\GITHUB_PUBLICATION_SYNC.csv")
$handoffRunRows = @(Read-CsvSafe "outputs\money_ready_evidence_handoff\FIRST_PASS_RUN_LIST.csv")
$handoffLaneRows = @(Read-CsvSafe "outputs\money_ready_evidence_handoff\FIRST_PASS_PARALLEL_LANES.csv")
$handoffLaneRunRows = @(Read-CsvSafe "outputs\money_ready_evidence_handoff\FIRST_PASS_PARALLEL_RUN_LIST.csv")
$handoffFullRows = @(Read-CsvSafe "outputs\money_ready_evidence_handoff\FULL_VALIDATION_RUN_LIST.csv")
$handoffCompileRows = @(Read-CsvSafe "outputs\money_ready_evidence_handoff\COMPILE_EVIDENCE_FILES.csv")
$handoffLiveRows = @(Read-CsvSafe "outputs\money_ready_evidence_handoff\LIVE_EVIDENCE_FILES.csv")

$statusRows = [System.Collections.Generic.List[object]]::new()

$routed = @($routingRows | Where-Object Status -eq "ROUTED").Count
$missing = @($routingRows | Where-Object Status -eq "MISSING_IN_INBOX").Count
$duplicates = @($routingRows | Where-Object Status -eq "DUPLICATE_IN_INBOX").Count
$invalid = @($routingRows | Where-Object Status -eq "INVALID_REPORT").Count
$unmatched = @($routingRows | Where-Object Status -eq "UNMATCHED_IN_INBOX").Count
$routingStatus = if($firstPassPackageRows.Count -eq 0 -and $missing -eq 0 -and $duplicates -eq 0 -and $invalid -eq 0 -and $unmatched -eq 0) { "PASS" } elseif($duplicates -gt 0 -or $invalid -gt 0 -or $unmatched -gt 0) { "FAIL" } elseif($missing -gt 0 -or $routingRows.Count -eq 0) { "PENDING" } else { "PASS" }
$routingNextAction = if($firstPassPackageRows.Count -eq 0) {
   "No first-pass reports are expected because the current next-run package is empty."
} else {
   "Drop the $($firstPassPackageRows.Count) current first-pass MT5 reports into outputs\returned_mt5_reports\first_pass_inbox with exact ExpectedReportName base names."
}
Add-StatusRow $statusRows "first-pass-report-routing" $routingStatus `
   "routed=$routed; missing=$missing; duplicates=$duplicates; invalid=$invalid; unmatched=$unmatched" `
   "outputs\FIRST_PASS_RETURNED_REPORT_ROUTING.md" `
   $routingNextAction

$liveRouted = @($liveRoutingRows | Where-Object Status -eq "ROUTED").Count
$liveMissing = @($liveRoutingRows | Where-Object Status -eq "MISSING_IN_INBOX").Count
$liveDuplicates = @($liveRoutingRows | Where-Object Status -eq "DUPLICATE_IN_INBOX").Count
$liveInvalid = @($liveRoutingRows | Where-Object Status -eq "INVALID_EVIDENCE").Count
$liveUnmatched = @($liveRoutingRows | Where-Object Status -eq "UNMATCHED_IN_INBOX").Count
$liveRoutingStatus = if($liveDuplicates -gt 0 -or $liveInvalid -gt 0 -or $liveUnmatched -gt 0) { "FAIL" } elseif($liveMissing -gt 0 -or $liveRoutingRows.Count -eq 0) { "PENDING" } else { "PASS" }
Add-StatusRow $statusRows "live-evidence-routing" $liveRoutingStatus `
   "routed=$liveRouted; missing=$liveMissing; duplicates=$liveDuplicates; invalid=$liveInvalid; unmatched=$liveUnmatched" `
   "outputs\TRADE_READY_LIVE_EVIDENCE_ROUTING.md" `
   "Drop trade log, forward evidence, and second-broker evidence CSVs into outputs\returned_mt5_reports\live_evidence_inbox; external evidence must include expected payoff, Sharpe, and win-rate columns."

$compileRouted = @($compileRoutingRows | Where-Object Status -eq "ROUTED").Count
$compileMissing = @($compileRoutingRows | Where-Object Status -eq "MISSING_IN_INBOX").Count
$compileDuplicates = @($compileRoutingRows | Where-Object Status -eq "DUPLICATE_IN_INBOX").Count
$compileInvalid = @($compileRoutingRows | Where-Object { [string](Get-Value $_ "Status") -match "^INVALID_" }).Count
$compileImported = @($compileRoutingRows | Where-Object Status -eq "IMPORTED_PASS").Count
$compileWarn = @($compileRoutingRows | Where-Object Status -eq "IMPORT_WARN").Count
$compileFailed = @($compileRoutingRows | Where-Object Status -eq "IMPORT_FAILED").Count
$compileWaiting = @($compileRoutingRows | Where-Object Status -eq "WAITING_FOR_EVIDENCE").Count
$compileRoutingStatus = if($compileDuplicates -gt 0 -or $compileInvalid -gt 0 -or $compileWarn -gt 0 -or $compileFailed -gt 0) { "FAIL" } elseif($compileImported -gt 0 -and $compileMissing -eq 0 -and $compileWaiting -eq 0) { "PASS" } else { "PENDING" }
Add-StatusRow $statusRows "compile-evidence-routing" $compileRoutingStatus `
   "routed=$compileRouted; missing=$compileMissing; duplicates=$compileDuplicates; invalid=$compileInvalid; imported=$compileImported; warnings=$compileWarn; failed=$compileFailed; waiting=$compileWaiting" `
   "outputs\MT5_COMPILE_EVIDENCE_ROUTING.md" `
   "Drop one MetaEditor compile log plus the exact compiled .mq5 source copy into outputs\returned_mt5_reports\compile_inbox."

$conservativeRouted = @($conservativeRoutingRows | Where-Object Status -eq "ROUTED").Count
$conservativeMissing = @($conservativeRoutingRows | Where-Object Status -eq "MISSING_IN_INBOX").Count
$conservativeDuplicates = @($conservativeRoutingRows | Where-Object Status -eq "DUPLICATE_IN_INBOX").Count
$conservativeInvalid = @($conservativeRoutingRows | Where-Object Status -eq "INVALID_REPORT").Count
$conservativeUnmatched = @($conservativeRoutingRows | Where-Object Status -eq "UNMATCHED_IN_INBOX").Count
$conservativeValidationRouted = @($conservativeRoutingRows | Where-Object { [string](Get-Value $_ "ReportType") -eq "validation" -and [string](Get-Value $_ "Status") -eq "ROUTED" }).Count
$conservativeBrokerRouted = @($conservativeRoutingRows | Where-Object { [string](Get-Value $_ "ReportType") -eq "broker_proxy" -and [string](Get-Value $_ "Status") -eq "ROUTED" }).Count
$conservativeRoutingStatus = if($conservativeDuplicates -gt 0 -or $conservativeInvalid -gt 0 -or $conservativeUnmatched -gt 0) { "FAIL" } elseif($conservativeMissing -gt 0 -or $conservativeRoutingRows.Count -eq 0) { "PENDING" } else { "PASS" }
Add-StatusRow $statusRows "conservative-report-routing" $conservativeRoutingStatus `
   "routed=$conservativeRouted; validationRouted=$conservativeValidationRouted; brokerRouted=$conservativeBrokerRouted; missing=$conservativeMissing; duplicates=$conservativeDuplicates; invalid=$conservativeInvalid; unmatched=$conservativeUnmatched" `
   "outputs\TRADE_READY_CONSERVATIVE_RETURNED_REPORT_ROUTING.md" `
   "After first-pass passes, drop the 53 validation and 10 broker-proxy MT5 reports into outputs\returned_mt5_reports\trade_ready_conservative_validation_inbox."

$firstReports = $firstPassRows | Where-Object Area -eq "first_pass_reports" | Select-Object -First 1
$firstDecision = $firstPassRows | Where-Object Area -eq "first_pass_decision" | Select-Object -First 1
$firstTrusted = $firstPassRows | Where-Object Area -eq "first_pass_trusted_decision" | Select-Object -First 1
$nextPackage = $firstPassRows | Where-Object Area -eq "next_run_package" | Select-Object -First 1
Add-StatusRow $statusRows "first-pass-refresh" ([string](Get-Value $firstDecision "Status" "PENDING")) `
   ("reports={0}; decision={1}; trusted={2}; nextPackage={3}" -f
      (Get-Value $firstReports "Actual" "missing"),
      (Get-Value $firstDecision "Actual" "missing"),
      (Get-Value $firstTrusted "Actual" "missing"),
      (Get-Value $nextPackage "Actual" "missing")) `
   "outputs\FIRST_PASS_REFRESH_STATUS.md" `
   "Import routed reports and wait for trusted first-pass promotion before full validation."

$laneZipExists = Test-Path -LiteralPath (Resolve-RepoPath "outputs\first_pass_parallel_lanes.zip")
$laneStatus = if($firstPassPackageRows.Count -eq 0 -and $firstPassLaneRows.Count -eq 0 -and $firstPassLaneRunRows.Count -eq 0) { "PASS" } elseif($firstPassPackageRows.Count -gt 0 -and $firstPassLaneRows.Count -gt 0 -and $firstPassLaneRunRows.Count -eq $firstPassPackageRows.Count -and $laneZipExists) { "PASS" } elseif($firstPassLaneRows.Count -eq 0 -and $firstPassLaneRunRows.Count -eq 0) { "PENDING" } else { "CHECK" }
$laneNextAction = if($firstPassPackageRows.Count -eq 0) {
   "No lane folders are needed because there are 0 current first-pass configs."
} else {
   "Use the $($firstPassLaneRows.Count) first-pass lane folders when you want to run the current $($firstPassPackageRows.Count) fast checks in parallel chunks."
}
Add-StatusRow $statusRows "first-pass-parallel-lanes" $laneStatus `
   "lanes=$($firstPassLaneRows.Count); laneConfigs=$($firstPassLaneRunRows.Count); zipExists=$laneZipExists" `
   "outputs\FIRST_PASS_PARALLEL_LANES.md" `
   $laneNextAction

$safetyFailures = @($safetyRows | Where-Object { [string](Get-Value $_ "Status") -eq "FAIL" -or [string](Get-Value $_ "Passed") -eq "False" }).Count
$safetyStatus = if($safetyRows.Count -eq 0) { "PENDING" } elseif($safetyFailures -gt 0) { "FAIL" } else { "PASS" }
Add-StatusRow $statusRows "local-safety-audit" $safetyStatus `
   "rows=$($safetyRows.Count); failures=$safetyFailures" `
   "outputs\MT5_LOCAL_SAFETY_AUDIT.md" `
   "Fix local safety failures before running tester/live work."

$efficiencySummary = Get-StatusSummary $efficiencyRows
$efficiencyStatus = if($efficiencySummary.Fail -gt 0) { "FAIL" } elseif($efficiencySummary.Pending -gt 0 -or $efficiencySummary.Rows -eq 0) { "PENDING" } else { "PASS" }
Add-StatusRow $statusRows "money-ready-efficiency-audit" $efficiencyStatus `
   "rows=$($efficiencySummary.Rows); pass=$($efficiencySummary.Pass); pending=$($efficiencySummary.Pending); fail=$($efficiencySummary.Fail)" `
   "outputs\MONEY_READY_EFFICIENCY_AUDIT.md" `
   "Do not promote safe-but-small-profit profiles; require broad growth, return/drawdown, recent-data, and broker/stress efficiency targets."

$liveSummary = Get-StatusSummary $liveRows
$liveStatus = if($liveSummary.Fail -gt 0) { "FAIL" } elseif($liveSummary.Pending -gt 0 -or $liveSummary.Rows -eq 0) { "PENDING" } else { "PASS" }
Add-StatusRow $statusRows "live-readiness" $liveStatus `
   "rows=$($liveSummary.Rows); pass=$($liveSummary.Pass); pending=$($liveSummary.Pending); fail=$($liveSummary.Fail)" `
   "outputs\TRADE_READY_LIVE_READINESS_DECISION.md" `
   "Close compile, validation, trade-quality, Monte Carlo, forward, second-broker, and reproducibility gates."

$scoreSummary = Get-StatusSummary $scoreRows
$scoreStatus = if($scoreSummary.Fail -gt 0) { "FAIL" } elseif($scoreSummary.Pending -gt 0 -or $scoreSummary.Rows -eq 0) { "PENDING" } else { "PASS" }
$scoreVerdict = Get-MarkdownValue "outputs\MONEY_READY_STATUS_SCORECARD.md" "Verdict"
Add-StatusRow $statusRows "money-ready-scorecard" $scoreStatus `
   "verdict=$scoreVerdict; rows=$($scoreSummary.Rows); pass=$($scoreSummary.Pass); pending=$($scoreSummary.Pending); fail=$($scoreSummary.Fail)" `
   "outputs\MONEY_READY_STATUS_SCORECARD.md" `
   "Do not consider live review until scorecard has zero pending and zero fail rows."

$releaseSummary = Get-StatusSummary $releaseRows
$releaseStatus = if($releaseSummary.Fail -gt 0) { "FAIL" } elseif($releaseSummary.Pending -gt 0 -or $releaseSummary.Rows -eq 0) { "PENDING" } else { "PASS" }
$releaseVerdict = Get-MarkdownValue "outputs\TRADE_READY_RELEASE_CANDIDATE_DECISION.md" "Verdict"
Add-StatusRow $statusRows "release-candidate" $releaseStatus `
   "verdict=$releaseVerdict; rows=$($releaseSummary.Rows); pass=$($releaseSummary.Pass); pending=$($releaseSummary.Pending); fail=$($releaseSummary.Fail)" `
   "outputs\TRADE_READY_RELEASE_CANDIDATE_DECISION.md" `
   "Manual live-review profile remains blocked until evidence and explicit approval identity pass."

$readySteps = @($runwayRows | Where-Object Status -eq "READY").Count
$pendingSteps = @($runwayRows | Where-Object { [string](Get-Value $_ "Status") -match "PENDING|WAITING" }).Count
$failSteps = @($runwayRows | Where-Object { [string](Get-Value $_ "Status") -match "^FAIL" }).Count
Add-StatusRow $statusRows "proof-runway" ($(if($failSteps -gt 0) { "FAIL" } elseif($pendingSteps -gt 0) { "PENDING" } else { "PASS" })) `
   "rows=$($runwayRows.Count); ready=$readySteps; pendingOrWaiting=$pendingSteps; fail=$failSteps" `
   "outputs\MONEY_READY_PROOF_RUNWAY.md" `
   "Follow the first READY runway step."

$reproFail = @($reproRows | Where-Object Status -eq "FAIL").Count
$reproPending = @($reproRows | Where-Object Status -eq "PENDING").Count
$reproPass = @($reproRows | Where-Object Status -eq "PASS").Count
$reproZipExists = Test-Path -LiteralPath (Resolve-RepoPath "outputs\trade_ready_reproducibility_bundle.zip")
$reproStatus = if($reproFail -gt 0) { "FAIL" } elseif($reproRows.Count -eq 0 -or !$reproZipExists -or $reproPending -gt 0) { "PENDING" } else { "PASS" }
Add-StatusRow $statusRows "reproducibility-bundle" $reproStatus `
   "rows=$($reproRows.Count); pass=$reproPass; pending=$reproPending; fail=$reproFail; zipExists=$reproZipExists" `
   "outputs\TRADE_READY_REPRODUCIBILITY_BUNDLE.md" `
   "Use this local source/profile hash freeze for reproducibility; it does not replace the live-readiness GitHub sync gate."

$githubRequiredZipExists = Test-Path -LiteralPath (Resolve-RepoPath "outputs\github_required_artifact_sync_package.zip")
$githubRequiredUnsafe = @($githubRequiredArtifactRows | Where-Object {
   [string](Get-Value $_ "AllowRealAccountTrading") -notlike "false*" -and [string](Get-Value $_ "AllowRealAccountTrading") -ne ""
}).Count
$githubRequiredStatus = if($githubRequiredArtifactRows.Count -eq 5 -and $githubRequiredZipExists -and $githubRequiredUnsafe -eq 0) { "PASS" } else { "PENDING" }
Add-StatusRow $statusRows "github-required-artifact-sync-package" $githubRequiredStatus `
   "rows=$($githubRequiredArtifactRows.Count); zipExists=$githubRequiredZipExists; unsafeProfiles=$githubRequiredUnsafe" `
   "outputs\GITHUB_REQUIRED_ARTIFACT_SYNC_PACKAGE.md" `
   "Use this package as the exact local source for uploading the remaining required GitHub source/profile artifacts."

$githubRequiredRows = @($githubPublicationRows | Where-Object { [string](Get-Value $_ "Required") -eq "True" })
$githubRequiredPass = @($githubRequiredRows | Where-Object { [string](Get-Value $_ "Status") -eq "PASS" }).Count
$githubRequiredPending = @($githubRequiredRows | Where-Object { [string](Get-Value $_ "Status") -eq "PENDING" }).Count
$githubRequiredFail = @($githubRequiredRows | Where-Object { [string](Get-Value $_ "Status") -eq "FAIL" }).Count
$githubPublicationStatus = if($githubRequiredRows.Count -eq 0) { "PENDING" } elseif($githubRequiredFail -gt 0) { "FAIL" } elseif($githubRequiredPending -gt 0) { "PENDING" } else { "PASS" }
Add-StatusRow $statusRows "github-publication-sync" $githubPublicationStatus `
   "required=$($githubRequiredRows.Count); pass=$githubRequiredPass; pending=$githubRequiredPending; fail=$githubRequiredFail" `
   "outputs\GITHUB_PUBLICATION_SYNC.md" `
   "Publish exact source/profile artifacts to GitHub until required SHA-256 checks pass."

$handoffTemplates = @(
   "outputs\money_ready_evidence_handoff\templates\TRADE_READY_CONSERVATIVE_TRADE_LOG_TEMPLATE.csv",
   "outputs\money_ready_evidence_handoff\templates\TRADE_READY_CONSERVATIVE_FORWARD_TEST_EVIDENCE_TEMPLATE.csv",
   "outputs\money_ready_evidence_handoff\templates\TRADE_READY_CONSERVATIVE_SECOND_BROKER_EVIDENCE_TEMPLATE.csv"
)
$handoffRequiredFiles = @(
   "outputs\MONEY_READY_EVIDENCE_HANDOFF.md",
   "outputs\money_ready_evidence_handoff\README.md",
   "outputs\money_ready_evidence_handoff\FULL_VALIDATION_RUN_LIST.csv",
   "outputs\money_ready_evidence_handoff\FIRST_PASS_PARALLEL_LANES.csv",
   "outputs\money_ready_evidence_handoff\FIRST_PASS_PARALLEL_RUN_LIST.csv",
   "outputs\money_ready_evidence_handoff\COMPILE_EVIDENCE_FILES.csv",
   "outputs\money_ready_evidence_handoff.zip"
) + $handoffTemplates
$missingHandoffFiles = @($handoffRequiredFiles | Where-Object { !(Test-Path -LiteralPath (Resolve-RepoPath $_)) })
$handoffStatus = if($firstPassPackageRows.Count -gt 0 -and $handoffRunRows.Count -eq $firstPassPackageRows.Count -and $handoffLaneRows.Count -gt 0 -and $handoffLaneRunRows.Count -eq $firstPassPackageRows.Count -and $handoffFullRows.Count -eq 63 -and $handoffCompileRows.Count -eq 2 -and $handoffLiveRows.Count -eq 3 -and @($missingHandoffFiles).Count -eq 0) { "PASS" } else { "PENDING" }
Add-StatusRow $statusRows "evidence-handoff" $handoffStatus `
   "firstPassConfigs=$($handoffRunRows.Count); firstPassLanes=$($handoffLaneRows.Count); firstPassLaneConfigs=$($handoffLaneRunRows.Count); fullValidationConfigs=$($handoffFullRows.Count); compileEvidenceFiles=$($handoffCompileRows.Count); liveEvidenceFiles=$($handoffLiveRows.Count); missingFiles=$(@($missingHandoffFiles).Count)" `
   "outputs\MONEY_READY_EVIDENCE_HANDOFF.md" `
   "Use the handoff folder or zip when running/returning MT5 evidence outside this repo."

$failCount = @($statusRows | Where-Object Status -eq "FAIL").Count
$pendingCount = @($statusRows | Where-Object Status -eq "PENDING").Count
$passCount = @($statusRows | Where-Object Status -eq "PASS").Count
$overall = if($failCount -gt 0) { "FAIL" } elseif($pendingCount -gt 0) { "PENDING" } else { "PASS" }

$resolvedOutCsv = Resolve-RepoPath $OutCsv
$resolvedOutMarkdown = Resolve-RepoPath $OutMarkdown
Ensure-ParentDir $resolvedOutCsv
Ensure-ParentDir $resolvedOutMarkdown
$statusRows | Export-Csv -LiteralPath $resolvedOutCsv -NoTypeInformation -Encoding ASCII

$md = [System.Collections.Generic.List[string]]::new()
$md.Add("# Money-Ready Refresh Status")
$md.Add("")
$md.Add("Generated offline. This does not launch MT5, MetaEditor, Git, or GitHub Actions.")
$md.Add("")
$md.Add(("- Overall: **{0}**" -f $overall))
$md.Add(('- Passing areas: `{0}`' -f $passCount))
$md.Add(('- Pending areas: `{0}`' -f $pendingCount))
$md.Add(('- Failed areas: `{0}`' -f $failCount))
$md.Add("")
if($overall -eq "PASS") {
   $md.Add("All offline refresh areas are passing. Review the release-candidate decision before any live-profile step.")
} elseif($overall -eq "FAIL") {
   $md.Add("At least one offline refresh area failed. Fix failed rows before continuing.")
} else {
   $md.Add("The bot remains pending evidence. The next useful action is the first pending/ready evidence step below.")
}
$md.Add("")
$md.Add("## Areas")
$md.Add("")
$md.Add("| Area | Status | Actual | Evidence | Next Action |")
$md.Add("| --- | --- | --- | --- | --- |")
foreach($row in $statusRows) {
   $md.Add(("| {0} | {1} | {2} | {3} | {4} |" -f
      (Escape-MarkdownCell $row.Area),
      (Escape-MarkdownCell $row.Status),
      (Escape-MarkdownCell $row.Actual),
      (Escape-MarkdownCell $row.Evidence),
      (Escape-MarkdownCell $row.NextAction)))
}
$md | Set-Content -LiteralPath $resolvedOutMarkdown -Encoding ASCII

[pscustomobject]@{
   Overall = $overall
   Pass = $passCount
   Pending = $pendingCount
   Fail = $failCount
   OutCsv = $OutCsv
   OutMarkdown = $OutMarkdown
}
