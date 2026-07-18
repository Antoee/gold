param(
   [ValidateRange(0,5)][int]$Wave = 0,
   [string]$ManifestPath = "outputs\RDMC_DIVERSIFIED_REPAIR_EXECUTABLE_GATE_MANIFEST.csv",
   [string]$ReportDir = "outputs\rdmc_diversified_repair_executable_gate_package\reports_here",
   [string]$RunnerLedgerGlob = "",
   [string]$ResultsPath = "outputs\RDMC_DIVERSIFIED_REPAIR_EXECUTABLE_GATE_RESULTS.csv",
   [string]$RunAuditPath = "",
   [string]$RawResultsPath = "",
   [string]$SummaryPath = "",
   [string]$MetricsMarkdownPath = "",
   [switch]$SkipAdmissionRefresh
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "mt5_report_identity_helpers.ps1")
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$decisionPath = Join-Path $repo "outputs\RDMC_DIVERSIFIED_REPAIR_EXECUTABLE_GATE_DECISION.csv"
$evaluator = Join-Path $PSScriptRoot "evaluate_rdmc_diversified_repair_executable_gate.py"
$expectedManifestHash = "4DB75F81EB1BF82DD4516654E2070D75563D904B7A17367629911EE261B0E18A"
$expectedSourceHash = "EC6F866B8F7786169F7B2ECE5553CF3A4DC6E6073D0B25389C16381B71FEF51F"
$expectedProfileHash = "746798EF260A375F8F8921DBC6D03CD3968ED38F5C105818598CA57572A0B883"

function Resolve-RepoPath([string]$Path) {
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}

function Relative-RepoPath([string]$Path) {
   $full = [IO.Path]::GetFullPath($Path)
   if(!$full.StartsWith($repo + "\", [StringComparison]::OrdinalIgnoreCase)) {
      throw "Path is outside the repository: $full"
   }
   return $full.Substring($repo.Length + 1)
}

function Ensure-Parent([string]$Path) {
   $parent = Split-Path -Parent $Path
   if($parent -and !(Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
}

$manifestFull = Resolve-RepoPath $ManifestPath
$reportFull = Resolve-RepoPath $ReportDir
$resultsFull = Resolve-RepoPath $ResultsPath
if(!(Test-Path -LiteralPath $manifestFull -PathType Leaf)) { throw "Executable-gate manifest is missing." }
if(!(Test-Path -LiteralPath $decisionPath -PathType Leaf)) { throw "Executable-gate decision is missing." }
if((Get-FileHash -LiteralPath $manifestFull -Algorithm SHA256).Hash.ToUpperInvariant() -ne $expectedManifestHash) {
   throw "Executable-gate manifest identity changed."
}

$manifest = @(Import-Csv -LiteralPath $manifestFull)
$decision = @(Import-Csv -LiteralPath $decisionPath)
if($decision.Count -ne 1) { throw "Expected one executable-gate decision row." }
if($decision[0].TerminalRejection -eq "True") { throw "Executable gate is terminally rejected; no later wave is admissible." }
$currentWave = [int]$decision[0].CurrentWave
if($currentWave -lt 1 -or $currentWave -gt 5) { throw "No report-collection wave is currently admitted." }
if($Wave -eq 0) { $Wave = $currentWave }
if($Wave -ne $currentWave) { throw "Requested wave $Wave is not the currently admitted wave $currentWave." }

$waveRows = @($manifest | Where-Object Wave -eq ([string]$Wave) | Sort-Object { [int]$_.QueueRank })
if($waveRows.Count -lt 1) { throw "Wave $Wave has no manifest rows." }
if(@($waveRows | Where-Object { $_.SourceSha256 -ne $expectedSourceHash -or $_.ProfileSha256 -ne $expectedProfileHash }).Count -gt 0) {
   throw "Wave source/profile identity changed."
}
foreach($row in $waveRows) {
   $config = Resolve-RepoPath ([string]$row.PackageConfig)
   if(!(Test-Path -LiteralPath $config -PathType Leaf)) { throw "Missing wave config: $config" }
   if((Get-FileHash -LiteralPath $config -Algorithm SHA256).Hash.ToUpperInvariant() -ne $row.ConfigSha256) {
      throw "Wave config identity changed at queue rank $($row.QueueRank)."
   }
}

if([string]::IsNullOrWhiteSpace($RunnerLedgerGlob)) {
   $RunnerLedgerGlob = "outputs\RDMC_EXECUTABLE_GATE_WAVE_{0:D2}_WORKER_*.csv" -f $Wave
}
if([string]::IsNullOrWhiteSpace($RunAuditPath)) {
   $RunAuditPath = "outputs\RDMC_DIVERSIFIED_REPAIR_EXECUTABLE_GATE_WAVE_{0:D2}_RUN_AUDIT.csv" -f $Wave
}
if([string]::IsNullOrWhiteSpace($RawResultsPath)) {
   $RawResultsPath = "outputs\RDMC_DIVERSIFIED_REPAIR_EXECUTABLE_GATE_WAVE_{0:D2}_RAW_RESULTS.csv" -f $Wave
}
if([string]::IsNullOrWhiteSpace($SummaryPath)) {
   $SummaryPath = "outputs\RDMC_DIVERSIFIED_REPAIR_EXECUTABLE_GATE_WAVE_{0:D2}_SUMMARY.csv" -f $Wave
}
if([string]::IsNullOrWhiteSpace($MetricsMarkdownPath)) {
   $MetricsMarkdownPath = "outputs\RDMC_DIVERSIFIED_REPAIR_EXECUTABLE_GATE_WAVE_{0:D2}_METRICS.md" -f $Wave
}

$ledgerPattern = Resolve-RepoPath $RunnerLedgerGlob
$ledgerFiles = @(Get-ChildItem -Path $ledgerPattern -File -ErrorAction SilentlyContinue | Sort-Object FullName)
if($ledgerFiles.Count -lt 1) { throw "No runner ledger files found for admitted wave $Wave." }
$runnerRows = @($ledgerFiles | ForEach-Object { Import-Csv -LiteralPath $_.FullName })
$runAudit = [System.Collections.Generic.List[object]]::new()
$binaryHashes = [System.Collections.Generic.List[string]]::new()
foreach($row in $waveRows) {
   $matches = @($runnerRows | Where-Object { $_.QueueRank -eq $row.QueueRank -and $_.Candidate -eq $row.Candidate })
   if($matches.Count -ne 1) { throw "Expected one runner row for queue rank $($row.QueueRank); found $($matches.Count)." }
   $run = $matches[0]
   if($run.Status -ne "REPORT_FOUND") { throw "Runner did not return a report for queue rank $($row.QueueRank): $($run.Status)" }
   if($run.PackageSourceSha256 -ne $expectedSourceHash) { throw "Runner source mismatch at queue rank $($row.QueueRank)." }
   if($run.PackageConfigSha256 -ne $row.ConfigSha256) { throw "Runner config mismatch at queue rank $($row.QueueRank)." }
   if([string]::IsNullOrWhiteSpace([string]$run.PortableBinarySha256)) { throw "Runner binary identity is missing." }
   if([string]::IsNullOrWhiteSpace([string]$run.ReportSha256)) { throw "Runner report identity is missing." }
   $binaryHashes.Add(([string]$run.PortableBinarySha256).ToUpperInvariant()) | Out-Null

   $reportPath = Resolve-RepoPath ([string]$run.ReportPath)
   if(!(Test-Path -LiteralPath $reportPath -PathType Leaf)) { throw "Runner report is missing: $reportPath" }
   $reportRoot = [IO.Path]::GetFullPath($reportFull).TrimEnd('\')
   $reportResolved = (Resolve-Path -LiteralPath $reportPath).Path
   if(!$reportResolved.StartsWith($reportRoot + "\", [StringComparison]::OrdinalIgnoreCase)) {
      throw "Runner report is outside the admitted report directory."
   }
   if([IO.Path]::GetFileNameWithoutExtension($reportResolved) -ne $row.ExpectedReportName) {
      throw "Runner report name mismatch at queue rank $($row.QueueRank)."
   }
   $reportHash = (Get-FileHash -LiteralPath $reportResolved -Algorithm SHA256).Hash.ToUpperInvariant()
   if($reportHash -ne ([string]$run.ReportSha256).ToUpperInvariant()) {
      throw "Runner report hash mismatch at queue rank $($row.QueueRank)."
   }
   $identityPath = Resolve-RepoPath ([string]$run.ReportIdentityPath)
   $expectedIdentityPath = Join-Path $reportRoot ($row.ExpectedReportName + ".identity.json")
   if([IO.Path]::GetFullPath($identityPath) -ne [IO.Path]::GetFullPath($expectedIdentityPath)) {
      throw "Runner report identity path mismatch at queue rank $($row.QueueRank)."
   }
   $reportIdentity = Read-MT5ReportIdentityEvidence -ReportPath $reportResolved `
      -IdentityPath $identityPath -ExpectedReportName $row.ExpectedReportName `
      -ConfigSha256 $row.ConfigSha256 -SourceSha256 $expectedSourceHash
   if(!$reportIdentity -or $reportIdentity.PortableBinarySha256 -ne ([string]$run.PortableBinarySha256).ToUpperInvariant()) {
      throw "Runner report sidecar identity mismatch at queue rank $($row.QueueRank)."
   }
   $reportText = Get-Content -LiteralPath $reportResolved -Raw
   if($reportText.IndexOf($expectedSourceHash, [StringComparison]::OrdinalIgnoreCase) -lt 0) {
      throw "Runner report lacks the frozen source identity at queue rank $($row.QueueRank)."
   }
   $runAudit.Add([pscustomobject]@{
      QueueRank = $row.QueueRank
      Wave = $Wave
      ExpectedReportName = $row.ExpectedReportName
      ConfigSha256 = $row.ConfigSha256
      SourceSha256 = $expectedSourceHash
      PortableBinarySha256 = ([string]$run.PortableBinarySha256).ToUpperInvariant()
      ReportSha256 = $reportHash
      ReportPath = Relative-RepoPath $reportResolved
      ReportIdentityPath = Relative-RepoPath $identityPath
      ReportIdentityReused = ([string]$run.ReportIdentityReused -eq "True")
      IdentityPass = $true
   }) | Out-Null
}
if(@($binaryHashes | Sort-Object -Unique).Count -ne 1) { throw "Wave reports do not share one compiled binary identity." }

$runAuditFull = Resolve-RepoPath $RunAuditPath
Ensure-Parent $runAuditFull
$runAudit | Export-Csv -LiteralPath $runAuditFull -NoTypeInformation -Encoding ASCII

$waveManifestPath = "outputs\RDMC_DIVERSIFIED_REPAIR_EXECUTABLE_GATE_WAVE_{0:D2}_MANIFEST.csv" -f $Wave
& (Join-Path $PSScriptRoot "collect_validation_results.ps1") `
   -RepoRoot $repo -ManifestPath $waveManifestPath -ReportDir (Relative-RepoPath $reportFull) `
   -ReportNameTemplate "{ExpectedReportName}" -OutResults $RawResultsPath `
   -OutSummary $SummaryPath -OutMarkdown $MetricsMarkdownPath | Out-Null

$rawFull = Resolve-RepoPath $RawResultsPath
$raw = @(Import-Csv -LiteralPath $rawFull)
if($raw.Count -ne $waveRows.Count -or @($raw | Where-Object Status -ne "PARSED").Count -gt 0) {
   throw "Every admitted wave report must parse exactly once."
}

$existing = if(Test-Path -LiteralPath $resultsFull -PathType Leaf) { @(Import-Csv -LiteralPath $resultsFull) } else { @() }
$priorNames = @($manifest | Where-Object { [int]$_.Wave -lt $Wave } | Select-Object -ExpandProperty ExpectedReportName)
if(@($existing | Where-Object { $_.ExpectedReportName -notin $priorNames }).Count -gt 0) {
   throw "Existing canonical results contain current/future or unknown rows."
}
$canonical = [System.Collections.Generic.List[object]]::new()
foreach($item in $existing) { $canonical.Add($item) | Out-Null }
foreach($row in $waveRows) {
   $metric = @($raw | Where-Object ExpectedReportName -eq $row.ExpectedReportName)
   $audit = @($runAudit | Where-Object ExpectedReportName -eq $row.ExpectedReportName)
   if($metric.Count -ne 1 -or $audit.Count -ne 1) { throw "Canonical wave evidence is ambiguous." }
   $item = $metric[0]
   if([double]$item.InitialDeposit -ne 10000.0) { throw "Report starting capital mismatch at queue rank $($row.QueueRank)." }
   $canonical.Add([pscustomobject]@{
      QueueRank = $row.QueueRank
      Wave = $Wave
      Role = $row.Role
      Window = $row.Window
      Model = $row.Model
      ExpectedReportName = $row.ExpectedReportName
      Status = $item.Status
      ReportPath = $audit[0].ReportPath
      ReportIdentityPath = $audit[0].ReportIdentityPath
      ReportIdentityReused = $audit[0].ReportIdentityReused
      ReportSha256 = $audit[0].ReportSha256
      ConfigSha256 = $row.ConfigSha256
      SourceSha256 = $expectedSourceHash
      ProfileSha256 = $expectedProfileHash
      PortableBinarySha256 = $audit[0].PortableBinarySha256
      InitialDeposit = $item.InitialDeposit
      NetProfit = $item.NetProfit
      Balance = $item.Balance
      TotalReturnPercent = $item.TotalReturnPercent
      CagrPercent = $item.CagrPercent
      ProfitFactor = $item.ProfitFactor
      ExpectedPayoff = $item.ExpectedPayoff
      SharpeRatio = $item.SharpeRatio
      WinRatePercent = $item.WinRatePercent
      TotalTrades = $item.TotalTrades
      MaxConsecutiveLosses = $item.MaxConsecutiveLosses
      MaxDrawdownMoney = $item.MaxDrawdownMoney
      MaxDrawdownPercent = $item.MaxDrawdownPercent
      RecoveryFactor = $item.RecoveryFactor
   }) | Out-Null
}
Ensure-Parent $resultsFull
$canonical | Sort-Object { [int]$_.QueueRank } | Export-Csv -LiteralPath $resultsFull -NoTypeInformation -Encoding ASCII

if(!$SkipAdmissionRefresh) {
   if((Resolve-Path -LiteralPath $resultsFull).Path -ne (Join-Path $repo "outputs\RDMC_DIVERSIFIED_REPAIR_EXECUTABLE_GATE_RESULTS.csv")) {
      throw "Admission refresh requires the canonical results path."
   }
   & python $evaluator
   if($LASTEXITCODE -ne 0) { throw "Executable-gate admission evaluator failed." }
}

[pscustomobject]@{
   Status = "PARSED_IDENTITY_BOUND"
   Wave = $Wave
   Reports = $raw.Count
   PortableBinarySha256 = @($binaryHashes | Sort-Object -Unique)[0]
   AdmissionRefreshed = !$SkipAdmissionRefresh
}
