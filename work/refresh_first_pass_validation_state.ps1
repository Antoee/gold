param(
   [string]$QueueRoot = "outputs\first_pass_validation_queue",
   [string]$QueueManifestPath = "outputs\FIRST_PASS_VALIDATION_QUEUE.csv",
   [string]$OutResults = "outputs\FIRST_PASS_VALIDATION_QUEUE_RESULTS.csv",
   [string]$OutReportSummary = "outputs\FIRST_PASS_VALIDATION_QUEUE_REPORT_SUMMARY.csv",
   [string]$OutReportMarkdown = "outputs\FIRST_PASS_VALIDATION_QUEUE_REPORT_METRICS.md",
   [string]$OutDecisionCsv = "outputs\FIRST_PASS_VALIDATION_QUEUE_DECISION.csv",
   [string]$OutDecisionMarkdown = "outputs\FIRST_PASS_VALIDATION_QUEUE_DECISION.md",
   [string]$OutDecisionSummary = "outputs\FIRST_PASS_VALIDATION_QUEUE_DECISION_SUMMARY.csv",
   [string]$OutCandidateRanking = "outputs\FIRST_PASS_VALIDATION_QUEUE_CANDIDATE_RANKING.csv",
   [string]$OutIntegrityCsv = "outputs\FIRST_PASS_EVIDENCE_INTEGRITY.csv",
   [string]$OutIntegrityMarkdown = "outputs\FIRST_PASS_EVIDENCE_INTEGRITY.md",
   [string]$OutTrustedDecisionCsv = "outputs\FIRST_PASS_TRUSTED_DECISION.csv",
   [string]$OutTrustedDecisionMarkdown = "outputs\FIRST_PASS_TRUSTED_DECISION.md",
   [string]$OutNextBatchCsv = "outputs\FIRST_PASS_NEXT_RUN_BATCH.csv",
   [string]$OutNextStatusCsv = "outputs\FIRST_PASS_NEXT_RUN_STATUS.csv",
   [string]$OutNextBatchMarkdown = "outputs\FIRST_PASS_NEXT_RUN_BATCH.md",
   [string]$PackageDir = "outputs\first_pass_next_run_package",
   [string]$OutPackageManifest = "outputs\FIRST_PASS_NEXT_RUN_PACKAGE_MANIFEST.csv",
   [string]$OutPackageMarkdown = "outputs\FIRST_PASS_NEXT_RUN_PACKAGE.md",
   [string]$OutParallelLaneDir = "outputs\first_pass_parallel_lanes",
   [string]$OutParallelLaneManifest = "outputs\FIRST_PASS_PARALLEL_LANE_MANIFEST.csv",
   [string]$OutParallelRunManifest = "outputs\FIRST_PASS_PARALLEL_LANE_RUN_MANIFEST.csv",
   [string]$OutParallelLaneMarkdown = "outputs\FIRST_PASS_PARALLEL_LANES.md",
   [string]$OutParallelLaneZip = "outputs\first_pass_parallel_lanes.zip",
   [string]$HiddenRunCsv = "",
   [string[]]$HiddenTesterLogPath = @(),
   [int]$HiddenLogTailLines = 200000,
   [string]$OutRefreshCsv = "outputs\FIRST_PASS_REFRESH_STATUS.csv",
   [string]$OutRefreshMarkdown = "outputs\FIRST_PASS_REFRESH_STATUS.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

function Resolve-RepoPath {
   param([string]$Path)
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}

function Read-CsvSafe {
   param([string]$Path)
   $resolved = Resolve-RepoPath $Path
   if(Test-Path -LiteralPath $resolved) { return @(Import-Csv -LiteralPath $resolved) }
   return @()
}

function Write-CsvRows {
   param([object[]]$Rows, [string]$Path)
   $resolved = Resolve-RepoPath $Path
   $parent = Split-Path -Parent $resolved
   if($parent -and !(Test-Path -LiteralPath $parent)) {
      New-Item -ItemType Directory -Path $parent -Force | Out-Null
   }
   $Rows | Export-Csv -LiteralPath $resolved -NoTypeInformation -Encoding ASCII
}

function Write-TextLines {
   param([string[]]$Lines, [string]$Path)
   $resolved = Resolve-RepoPath $Path
   $parent = Split-Path -Parent $resolved
   if($parent -and !(Test-Path -LiteralPath $parent)) {
      New-Item -ItemType Directory -Path $parent -Force | Out-Null
   }
   $Lines | Set-Content -LiteralPath $resolved -Encoding ASCII
}

function Write-CsvHeader {
   param([string[]]$Headers, [string]$Path)
   $escaped = @($Headers | ForEach-Object { '"' + ($_ -replace '"', '""') + '"' })
   Write-TextLines -Lines @(($escaped -join ",")) -Path $Path
}

function Clear-PackageDirIfSafe {
   param([string]$Path)

   $resolved = Resolve-RepoPath $Path
   if(Test-Path -LiteralPath $resolved) {
      $actualPackage = (Resolve-Path -LiteralPath $resolved).Path
      $actualOutputs = (Resolve-Path -LiteralPath (Resolve-RepoPath "outputs")).Path
      if($actualPackage.StartsWith($actualOutputs, [System.StringComparison]::OrdinalIgnoreCase)) {
         Remove-Item -LiteralPath $actualPackage -Recurse -Force
      }
   }

   if(!(Test-Path -LiteralPath $resolved)) {
      New-Item -ItemType Directory -Path $resolved -Force | Out-Null
   }
}

function Write-TrustBlockedNextRunArtifacts {
   param(
      [object[]]$TrustedRows,
      [string]$Reason
   )

   Write-CsvHeader -Headers @(
      "QueueRank", "Candidate", "CandidateRank", "SourceType", "Phase", "PhaseLabel",
      "Set", "Window", "From", "To", "Model", "Config", "ExpectedReportName",
      "ProfileSnapshot", "ProfileSha256", "StopRule"
   ) -Path $OutNextBatchCsv

   $blockedStatusRows = [System.Collections.Generic.List[object]]::new()
   $trustedSourceRows = @($TrustedRows)
   if($trustedSourceRows.Count -eq 0) {
      $trustedSourceRows = @([pscustomobject]@{
         Candidate = "all_candidates"
         Parsed = 0
         Expected = 0
         Reason = $Reason
      })
   }

   foreach($row in $trustedSourceRows) {
      $blockedStatusRows.Add([pscustomobject]@{
         Candidate = $row.Candidate
         State = "BLOCKED_BY_TRUSTED_DECISION"
         NextPhase = ""
         NextPhaseLabel = ""
         Parsed = $row.Parsed
         Expected = $row.Expected
         BatchRows = 0
         Reason = if("$($row.Reason)" -ne "") { $row.Reason } else { $Reason }
      }) | Out-Null
   }
   Write-CsvRows -Rows @($blockedStatusRows) -Path $OutNextStatusCsv

   $batchMd = @(
      "# First-Pass Next Run Batch",
      "",
      "Offline selector only. This does not launch MT5.",
      "",
      "- Status: **BLOCKED_BY_TRUSTED_DECISION**",
      "- Selected configs: ``0``",
      "- Reason: $Reason",
      "",
      "No next-run MT5 configs were selected because the trusted evidence gate failed. Fix the evidence-integrity issue, then run the refresh again."
   )
   Write-TextLines -Lines $batchMd -Path $OutNextBatchMarkdown

   Clear-PackageDirIfSafe -Path $PackageDir
   Write-CsvHeader -Headers @(
      "QueueRank", "Candidate", "Phase", "PhaseLabel", "Window", "Model",
      "PackageConfig", "SourceConfig", "ExpectedReportName", "ReportDestination",
      "ProfileSha256", "StopRule"
   ) -Path $OutPackageManifest

   $packageMd = @(
      "# First-Pass Next-Run Package",
      "",
      "Offline package only. This does not launch MT5.",
      "",
      "- Status: **BLOCKED_BY_TRUSTED_DECISION**",
      "- Package folder: ``$PackageDir``",
      "- Packaged configs: ``0``",
      "- Reason: $Reason",
      "",
      "The package was not built because the trusted evidence gate failed. Do not run stale first-pass configs until the integrity issue is fixed and the refresh returns `READY`."
   )
   Write-TextLines -Lines $packageMd -Path $OutPackageMarkdown
}

$preImportResultsPath = Join-Path ([IO.Path]::GetTempPath()) ("first_pass_results_pre_import_{0}.csv" -f $PID)
$resolvedExistingResults = Resolve-RepoPath $OutResults
if(Test-Path -LiteralPath $resolvedExistingResults -PathType Leaf) {
   Copy-Item -LiteralPath $resolvedExistingResults -Destination $preImportResultsPath -Force
}

& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "import_first_pass_validation_queue_reports.ps1") `
   -QueueRoot $QueueRoot `
   -QueueManifestPath $QueueManifestPath `
   -OutResults $OutResults `
   -OutSummary $OutReportSummary `
   -OutMarkdown $OutReportMarkdown `
   -OutDecisionCsv $OutDecisionCsv `
   -OutDecisionMarkdown $OutDecisionMarkdown `
   -OutDecisionSummary $OutDecisionSummary `
   -OutCandidateRanking $OutCandidateRanking | Out-Null

if($HiddenRunCsv -ne "") {
   $resolvedHiddenRunCsv = Resolve-RepoPath $HiddenRunCsv
   if(Test-Path -LiteralPath $resolvedHiddenRunCsv) {
      $hiddenArgs = @(
         "-NoProfile", "-ExecutionPolicy", "Bypass",
         "-File", (Join-Path $PSScriptRoot "import_first_pass_hidden_log_results.ps1"),
         "-RunCsv", $HiddenRunCsv,
         "-QueueManifestPath", $QueueManifestPath,
         "-ExistingResultsPath", ($(if(Test-Path -LiteralPath $preImportResultsPath -PathType Leaf) { $preImportResultsPath } else { $OutResults })),
         "-OutResults", $OutResults,
         "-OutSummary", $OutReportSummary,
         "-OutMarkdown", $OutReportMarkdown,
         "-TailLines", ([string]$HiddenLogTailLines)
      )
      if($HiddenTesterLogPath.Count -gt 0) {
         $hiddenArgs += "-TesterLogPath"
         $hiddenArgs += $HiddenTesterLogPath
      }
      & powershell @hiddenArgs | Out-Null
   }
}

Remove-Item -LiteralPath $preImportResultsPath -Force -ErrorAction SilentlyContinue

& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "analyze_first_pass_validation_queue.ps1") `
   -ManifestPath $QueueManifestPath `
   -ResultsPath $OutResults `
   -OutDecisionCsv $OutDecisionCsv `
   -OutDecisionMarkdown $OutDecisionMarkdown `
   -OutSummaryCsv $OutDecisionSummary `
   -OutRankingCsv $OutCandidateRanking | Out-Null

& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "audit_first_pass_evidence_integrity.ps1") `
   -QueueManifestPath $QueueManifestPath `
   -ResultsPath $OutResults `
   -QueueRoot $QueueRoot `
   -OutCsv $OutIntegrityCsv `
   -OutMarkdown $OutIntegrityMarkdown | Out-Null

& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "build_first_pass_trusted_decision.ps1") `
   -RankingPath $OutCandidateRanking `
   -IntegrityPath $OutIntegrityCsv `
   -OutCsv $OutTrustedDecisionCsv `
   -OutMarkdown $OutTrustedDecisionMarkdown | Out-Null

$trustedRowsPre = @(Read-CsvSafe $OutTrustedDecisionCsv)
$integrityRowsPre = @(Read-CsvSafe $OutIntegrityCsv)
$integrityFailuresPre = @($integrityRowsPre | Where-Object Status -eq "FAIL")
$trustedIntegrityFailuresPre = @($trustedRowsPre | Where-Object TrustedRecommendation -eq "EVIDENCE_INTEGRITY_FAIL")
$nextRunBlockedReason = ""

if($integrityFailuresPre.Count -gt 0 -or $trustedIntegrityFailuresPre.Count -gt 0) {
   $nextRunBlockedReason = "Evidence integrity failed; next-run selection and packaging are blocked until the audit passes."
   Write-TrustBlockedNextRunArtifacts -TrustedRows $trustedRowsPre -Reason $nextRunBlockedReason
} else {
   & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "select_first_pass_next_run_batch.ps1") `
      -QueueManifestPath $QueueManifestPath `
      -ResultsPath $OutResults `
      -OutBatchCsv $OutNextBatchCsv `
      -OutStatusCsv $OutNextStatusCsv `
      -OutMarkdown $OutNextBatchMarkdown | Out-Null

   $nextBatchRowsPre = @(Read-CsvSafe $OutNextBatchCsv)
   if($nextBatchRowsPre.Count -gt 0) {
      & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "build_first_pass_next_run_package.ps1") `
         -BatchPath $OutNextBatchCsv `
         -QueueRoot $QueueRoot `
         -PackageDir $PackageDir `
         -OutManifest $OutPackageManifest `
         -OutMarkdown $OutPackageMarkdown | Out-Null
   } else {
      Clear-PackageDirIfSafe -Path $PackageDir
      Write-CsvHeader -Headers @(
         "QueueRank", "Candidate", "Phase", "PhaseLabel", "Window", "Model",
         "PackageConfig", "SourceConfig", "ExpectedReportName", "ReportDestination",
         "ProfileSha256", "StopRule"
      ) -Path $OutPackageManifest

      $packageMd = @(
         "# First-Pass Next-Run Package",
         "",
         "Offline package only. This does not launch MT5.",
         "",
         "- Status: **EMPTY**",
         "- Package folder: ``$PackageDir``",
         "- Packaged configs: ``0``",
         "- Reason: no next-run configs were selected. The remaining active candidates either completed first-pass or hit an early-stop failure.",
         "",
         "Do not run stale first-pass configs; this package was intentionally cleared."
      )
      Write-TextLines -Lines $packageMd -Path $OutPackageMarkdown
   }
}

& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "build_first_pass_parallel_lanes.ps1") `
   -PackageManifest $OutPackageManifest `
   -PackageDir $PackageDir `
   -OutDir $OutParallelLaneDir `
   -OutLaneManifest $OutParallelLaneManifest `
   -OutRunManifest $OutParallelRunManifest `
   -OutMarkdown $OutParallelLaneMarkdown `
   -ZipPath $OutParallelLaneZip | Out-Null

$resultRows = @(Read-CsvSafe $OutResults)
$decisionRows = @(Read-CsvSafe $OutDecisionCsv)
$rankingRows = @(Read-CsvSafe $OutCandidateRanking)
$integrityRows = @(Read-CsvSafe $OutIntegrityCsv)
$trustedRows = @(Read-CsvSafe $OutTrustedDecisionCsv)
$nextBatchRows = @(Read-CsvSafe $OutNextBatchCsv)
$nextStatusRows = @(Read-CsvSafe $OutNextStatusCsv)
$packageRows = @(Read-CsvSafe $OutPackageManifest)
$parallelLaneRows = @(Read-CsvSafe $OutParallelLaneManifest)
$parallelRunRows = @(Read-CsvSafe $OutParallelRunManifest)

$parsedReports = @($resultRows | Where-Object Status -eq "PARSED").Count
$parsedLogs = @($resultRows | Where-Object Status -eq "PARSED_FROM_LOG").Count
$parsed = $parsedReports + $parsedLogs
$missing = @($resultRows | Where-Object Status -eq "MISSING_REPORT").Count
$unparsed = @($resultRows | Where-Object Status -eq "UNPARSED").Count
$decisionFail = @($decisionRows | Where-Object Status -eq "FAIL").Count
$decisionPending = @($decisionRows | Where-Object Status -eq "PENDING").Count
$decisionPass = @($decisionRows | Where-Object Status -eq "PASS").Count
$integrityFail = @($integrityRows | Where-Object Status -eq "FAIL").Count
$integrityPending = @($integrityRows | Where-Object Status -eq "PENDING").Count
$integrityPass = @($integrityRows | Where-Object Status -eq "PASS").Count
$integrityOverall = if($integrityFail -gt 0) { "FAIL" } elseif($integrityPending -gt 0) { "PENDING" } elseif($integrityRows.Count -gt 0) { "PASS" } else { "MISSING" }
$trustedFail = @($trustedRows | Where-Object { $_.TrustedRecommendation -in @("EVIDENCE_INTEGRITY_FAIL", "REJECT_FIRST_PASS") }).Count
$trustedPending = @($trustedRows | Where-Object { $_.TrustedRecommendation -like "WAIT_*" }).Count
$trustedPromote = @($trustedRows | Where-Object TrustedRecommendation -eq "PROMOTE_TO_FULL_VALIDATION").Count
$trustedOverall = if($trustedFail -gt 0) { "FAIL" } elseif($trustedRows.Count -gt 0 -and $trustedPromote -eq $trustedRows.Count) { "PASS" } else { "PENDING" }
$overall = if($decisionFail -gt 0) { "FAIL" } elseif($decisionPending -gt 0) { "PENDING" } else { "PASS" }

$statusRows = [System.Collections.Generic.List[object]]::new()
$statusRows.Add([pscustomobject]@{
   Area = "first_pass_reports"
   Status = if($parsedReports -eq $resultRows.Count -and $resultRows.Count -gt 0) { "COMPLETE" } else { "WAIT_FOR_REPORTS" }
   Actual = "parsedReports=$parsedReports; parsedLogs=$parsedLogs; missing=$missing; unparsed=$unparsed; expected=$($resultRows.Count)"
   Evidence = $OutResults
}) | Out-Null
$statusRows.Add([pscustomobject]@{
   Area = "first_pass_decision"
   Status = $overall
   Actual = "pass=$decisionPass; pending=$decisionPending; fail=$decisionFail"
   Evidence = $OutDecisionMarkdown
}) | Out-Null
$statusRows.Add([pscustomobject]@{
   Area = "first_pass_integrity"
   Status = $integrityOverall
   Actual = "pass=$integrityPass; pending=$integrityPending; fail=$integrityFail"
   Evidence = $OutIntegrityMarkdown
}) | Out-Null
$statusRows.Add([pscustomobject]@{
   Area = "first_pass_trusted_decision"
   Status = $trustedOverall
   Actual = "promote=$trustedPromote; wait=$trustedPending; fail=$trustedFail"
   Evidence = $OutTrustedDecisionMarkdown
}) | Out-Null
$statusRows.Add([pscustomobject]@{
   Area = "next_run_batch"
   Status = if($nextRunBlockedReason -ne "") { "BLOCKED_BY_TRUSTED_DECISION" } elseif($nextBatchRows.Count -gt 0) { "READY" } else { "EMPTY" }
   Actual = "selectedConfigs=$($nextBatchRows.Count)"
   Evidence = $OutNextBatchMarkdown
}) | Out-Null
$statusRows.Add([pscustomobject]@{
   Area = "next_run_package"
   Status = if($nextRunBlockedReason -ne "") { "BLOCKED_BY_TRUSTED_DECISION" } elseif($nextBatchRows.Count -gt 0 -and $packageRows.Count -eq $nextBatchRows.Count) { "READY" } elseif($nextBatchRows.Count -eq 0) { "NOT_NEEDED" } else { "CHECK" }
   Actual = "packagedConfigs=$($packageRows.Count); selectedConfigs=$($nextBatchRows.Count)"
   Evidence = $OutPackageMarkdown
}) | Out-Null
$statusRows.Add([pscustomobject]@{
   Area = "first_pass_parallel_lanes"
   Status = if($nextRunBlockedReason -ne "") { "BLOCKED_BY_TRUSTED_DECISION" } elseif($parallelRunRows.Count -gt 0 -and $parallelRunRows.Count -eq $packageRows.Count) { "READY" } elseif($packageRows.Count -eq 0) { "NOT_NEEDED" } else { "CHECK" }
   Actual = "lanes=$($parallelLaneRows.Count); laneConfigs=$($parallelRunRows.Count); packagedConfigs=$($packageRows.Count)"
   Evidence = $OutParallelLaneMarkdown
}) | Out-Null

foreach($row in $rankingRows) {
   $trusted = $trustedRows | Where-Object Candidate -eq $row.Candidate | Select-Object -First 1
   $trustedRecommendation = if($trusted) { $trusted.TrustedRecommendation } else { "MISSING_TRUSTED_DECISION" }
   $statusRows.Add([pscustomobject]@{
      Area = "candidate:$($row.Candidate)"
      Status = $trustedRecommendation
      Actual = "raw=$($row.Recommendation); evidence=$($row.EvidenceStatus); parsed=$($row.Parsed)/$($row.Expected); failGates=$($row.CandidateFailGates); pendingGates=$($row.CandidatePendingGates)"
      Evidence = $OutTrustedDecisionMarkdown
   }) | Out-Null
}

Write-CsvRows -Rows @($statusRows) -Path $OutRefreshCsv

$md = [System.Collections.Generic.List[string]]::new()
$md.Add("# First-Pass Refresh Status")
$md.Add("")
$md.Add("Offline refresh only. This does not launch MT5.")
$md.Add("")
$md.Add("- Overall first-pass decision: **$overall**")
$md.Add("- Parsed exported reports: ``$parsedReports / $($resultRows.Count)``")
$md.Add("- Parsed tester-log rows: ``$parsedLogs / $($resultRows.Count)``")
$md.Add("- Missing reports: ``$missing``")
$md.Add("- Unparsed reports: ``$unparsed``")
$md.Add("- Evidence integrity: **$integrityOverall**")
$md.Add("- Trusted decision: **$trustedOverall**")
$md.Add("- Next selected configs: ``$($nextBatchRows.Count)``")
$md.Add("- Packaged configs: ``$($packageRows.Count)``")
$md.Add("- Parallel lanes: ``$($parallelLaneRows.Count)``")
$md.Add("- Parallel lane configs: ``$($parallelRunRows.Count)``")
if($nextRunBlockedReason -ne "") {
   $md.Add("- Next-run gate: **BLOCKED_BY_TRUSTED_DECISION**")
   $md.Add("- Block reason: $nextRunBlockedReason")
}
$md.Add("")
$md.Add("## Candidate Recommendations")
$md.Add("")
$md.Add("| Candidate | Evidence | Raw Recommendation | Trusted Recommendation | Parsed | Fail Gates | Pending Gates |")
$md.Add("| --- | --- | --- | --- | ---: | ---: | ---: |")
foreach($row in ($rankingRows | Sort-Object Rank)) {
   $trusted = $trustedRows | Where-Object Candidate -eq $row.Candidate | Select-Object -First 1
   $trustedRecommendation = if($trusted) { $trusted.TrustedRecommendation } else { "MISSING_TRUSTED_DECISION" }
   $md.Add("| ``$($row.Candidate)`` | $($row.EvidenceStatus) | $($row.Recommendation) | $trustedRecommendation | $($row.Parsed)/$($row.Expected) | $($row.CandidateFailGates) | $($row.CandidatePendingGates) |")
}
$md.Add("")
$md.Add("## Next Batch")
$md.Add("")
if($nextStatusRows.Count -eq 0) {
   $md.Add("No next-batch status rows were generated.")
} else {
   $md.Add("| Candidate | State | Parsed/Expected | Next Phase | Batch Rows |")
   $md.Add("| --- | --- | ---: | --- | ---: |")
   foreach($row in ($nextStatusRows | Sort-Object Candidate)) {
      $md.Add("| ``$($row.Candidate)`` | $($row.State) | $($row.Parsed)/$($row.Expected) | $($row.NextPhaseLabel) | $($row.BatchRows) |")
   }
}
$md.Add("")
$md.Add("## Files")
$md.Add("")
$md.Add("- Decision: ``$OutDecisionMarkdown``")
$md.Add("- Candidate ranking: ``$OutCandidateRanking``")
$md.Add("- Evidence integrity: ``$OutIntegrityMarkdown``")
$md.Add("- Trusted decision: ``$OutTrustedDecisionMarkdown``")
$md.Add("- Next batch: ``$OutNextBatchMarkdown``")
$md.Add("- Next package: ``$OutPackageMarkdown``")
Write-TextLines -Lines $md -Path $OutRefreshMarkdown

[pscustomobject]@{
   Overall = $overall
   Parsed = $parsed
   ParsedReports = $parsedReports
   ParsedFromLog = $parsedLogs
   Expected = $resultRows.Count
   Missing = $missing
   EvidenceIntegrity = $integrityOverall
   TrustedDecision = $trustedOverall
   NextSelectedConfigs = $nextBatchRows.Count
   PackagedConfigs = $packageRows.Count
   OutRefreshCsv = $OutRefreshCsv
   OutRefreshMarkdown = $OutRefreshMarkdown
}
