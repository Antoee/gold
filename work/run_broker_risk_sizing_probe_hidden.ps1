param(
   [int]$TimeoutMinutesPerConfig = 8,
   [ValidateRange(1,100)][int]$MaxCpuPercent = 80,
   [ValidateSet("RiskSizing", "DgfActivity", "StabilityRebase", "StabilityRealtick")][string]$ProbeMode = "RiskSizing",
   [string]$BaseSetPath = "outputs\CANDIDATE_RANGE_ELITE_HIGHPROFIT_PEAKTRAIL_OFF_CONTINUOUS_PROFILE.set",
   [ValidateRange(100,100000000)][int]$Deposit = 1000,
   [ValidateRange(0,4)][int]$Model = 1,
   [string]$OutCsv = "outputs\BROKER_RISK_SIZING_PROBE_CURRENT_SOURCE_STATUS.csv",
   [string]$OutMarkdown = "outputs\BROKER_RISK_SIZING_PROBE_CURRENT_SOURCE_STATUS.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$artifactStem = if($ProbeMode -eq "DgfActivity") { "DGF_ACTIVITY_PROBE" } elseif($ProbeMode -eq "StabilityRebase") { "STABILITY_REBASE_PROBE" } elseif($ProbeMode -eq "StabilityRealtick") { "STABILITY_REALTICK_PROBE" } else { "BROKER_RISK_SIZING_PROBE" }
$packageLeaf = if($ProbeMode -eq "DgfActivity") { "dgf_activity_probe_package" } elseif($ProbeMode -eq "StabilityRebase") { "stability_rebase_probe_package" } elseif($ProbeMode -eq "StabilityRealtick") { "stability_realtick_probe_package" } else { "broker_risk_sizing_probe_package" }
$packageDir = "outputs\$packageLeaf"
$queueManifest = "outputs\$($artifactStem)_QUEUE.csv"
$packageManifest = "outputs\$($artifactStem)_PACKAGE_MANIFEST.csv"
$packageMarkdown = "outputs\$($artifactStem)_PACKAGE.md"
$runCsv = "outputs\$($artifactStem)_RUN.csv"
$runMarkdown = "outputs\$($artifactStem)_RUN.md"
$resultsCsv = "outputs\$($artifactStem)_RESULTS.csv"
$summaryCsv = "outputs\$($artifactStem)_SUMMARY.csv"
$metricsMarkdown = "outputs\$($artifactStem)_METRICS.md"
if($ProbeMode -ne "RiskSizing") {
   if($OutCsv -eq "outputs\BROKER_RISK_SIZING_PROBE_CURRENT_SOURCE_STATUS.csv") {
      $OutCsv = "outputs\$($artifactStem)_CURRENT_SOURCE_STATUS.csv"
   }
   if($OutMarkdown -eq "outputs\BROKER_RISK_SIZING_PROBE_CURRENT_SOURCE_STATUS.md") {
      $OutMarkdown = "outputs\$($artifactStem)_CURRENT_SOURCE_STATUS.md"
   }
}
$hardLockFile = Join-Path $PSScriptRoot "MT5_LOCAL_LAUNCH_DISABLED.lock"
$unlockFile = Join-Path $PSScriptRoot "ALLOW_MT5_LOCAL_LAUNCH.unlock"
$hiddenAckFile = Join-Path $PSScriptRoot "ALLOW_MT5_HIDDEN_DESKTOP_ACK.unlock"

function Resolve-RepoPath {
   param([string]$Path)
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}

function Stop-MT5LocalFamily {
   $stopHelper = Join-Path $PSScriptRoot "stop_mt5_stray_processes.ps1"
   if(Test-Path -LiteralPath $stopHelper) {
      & $stopHelper | Out-Null
      return
   }
   foreach($name in @("terminal", "terminal64", "metatester", "metatester64", "MetaEditor", "metaeditor64")) {
      Get-Process -Name $name -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
   }
}

$started = Get-Date
$status = "RUNNING"
$errorText = ""
$sourceHash = (Get-FileHash -LiteralPath (Join-Path $repo "Professional_XAUUSD_EA.mq5") -Algorithm SHA256).Hash
$oldFocusRisk = $env:ALLOW_MT5_FOCUS_RISK
$oldHiddenAck = $env:ALLOW_MT5_HIDDEN_DESKTOP_ACK

try {
   Remove-Item -LiteralPath $hardLockFile -Force -ErrorAction SilentlyContinue
   $env:ALLOW_MT5_FOCUS_RISK = "1"
   $env:ALLOW_MT5_HIDDEN_DESKTOP_ACK = "1"
   Set-Content -LiteralPath $unlockFile -Value "Controlled broker-risk sizing probe allowed at $($started.ToString('s'))." -Encoding ASCII
   Set-Content -LiteralPath $hiddenAckFile -Value "Hidden desktop/focus risk acknowledged for controlled local tester run." -Encoding ASCII

   & (Join-Path $PSScriptRoot "build_broker_risk_sizing_probe_package.ps1") `
      -BaseSetPath $BaseSetPath `
      -ProbeMode $ProbeMode `
      -Deposit $Deposit `
      -Model $Model `
      -PackageDir $packageDir `
      -OutQueueManifest $queueManifest `
      -OutPackageManifest $packageManifest `
      -OutMarkdown $packageMarkdown
   & (Join-Path $PSScriptRoot "run_first_pass_package_hidden.ps1") `
      -ManifestPath $packageManifest `
      -TimeoutMinutesPerConfig $TimeoutMinutesPerConfig `
      -MaxCpuPercent $MaxCpuPercent `
      -Run `
      -OutCsv $runCsv `
      -OutMarkdown $runMarkdown

   & (Join-Path $PSScriptRoot "import_first_pass_hidden_log_results.ps1") `
      -RunCsv $runCsv `
      -QueueManifestPath $queueManifest `
      -InitialDeposit $Deposit `
      -OutResults $resultsCsv `
      -OutSummary $summaryCsv `
      -OutMarkdown $metricsMarkdown

   $status = "PASS"
}
catch {
   $status = "FAIL"
   $errorText = $_.Exception.Message
   throw
}
finally {
   Stop-MT5LocalFamily
   Remove-Item -LiteralPath $unlockFile -Force -ErrorAction SilentlyContinue
   Remove-Item -LiteralPath $hiddenAckFile -Force -ErrorAction SilentlyContinue
   if([string]::IsNullOrWhiteSpace($oldFocusRisk)) { Remove-Item Env:\ALLOW_MT5_FOCUS_RISK -ErrorAction SilentlyContinue }
   else { $env:ALLOW_MT5_FOCUS_RISK = $oldFocusRisk }
   if([string]::IsNullOrWhiteSpace($oldHiddenAck)) { Remove-Item Env:\ALLOW_MT5_HIDDEN_DESKTOP_ACK -ErrorAction SilentlyContinue }
   else { $env:ALLOW_MT5_HIDDEN_DESKTOP_ACK = $oldHiddenAck }
   Set-Content -LiteralPath $hardLockFile -Value "Restored after controlled broker-risk sizing probe." -Encoding ASCII
}

$finished = Get-Date
$runRows = @()
if(Test-Path -LiteralPath (Resolve-RepoPath $runCsv)) {
   $runRows = @(Import-Csv -LiteralPath (Resolve-RepoPath $runCsv))
}
$reportRows = @($runRows | Where-Object { $_.Status -eq "REPORT_FOUND" })
$failedRows = @($runRows | Where-Object { $_.Status -in @("FAIL", "ERROR", "TIMEOUT", "NO_REPORT") })
$overall = if($status -eq "PASS" -and $failedRows.Count -eq 0 -and $runRows.Count -gt 0 -and $reportRows.Count -eq $runRows.Count) { "PASS" } elseif($status -eq "PASS") { "PARTIAL" } else { "FAIL" }

$statusRow = [pscustomobject]@{
   Status = $overall
   ProbeMode = $ProbeMode
   InitialDeposit = $Deposit
   Model = $Model
   SourceHash = $sourceHash
   Started = $started.ToString("s")
   Finished = $finished.ToString("s")
   ConfigRows = $runRows.Count
   ReportsFound = $reportRows.Count
   FailedRows = $failedRows.Count
   TimeoutMinutesPerConfig = $TimeoutMinutesPerConfig
   MaxCpuPercent = $MaxCpuPercent
   Error = $errorText
}
$statusRow | Export-Csv -LiteralPath (Resolve-RepoPath $OutCsv) -NoTypeInformation -Encoding ASCII

$md = @(
   "# Broker-Accurate Risk Sizing Current-Source Status",
   "",
   "Controlled local hidden MT5 run. The wrapper restores the hard launch lock in finally.",
   "",
   ("- Status: **{0}**" -f $overall),
   ("- Probe mode: {0}" -f $ProbeMode),
   ("- Initial deposit: {0}" -f $Deposit),
   ("- Model: {0}" -f $Model),
   ("- Source hash: {0}" -f $sourceHash),
   ("- Started: {0}" -f $started.ToString("s")),
   ("- Finished: {0}" -f $finished.ToString("s")),
   ("- Config rows: {0}" -f $runRows.Count),
   ("- Reports found: {0}" -f $reportRows.Count),
   ("- Failed rows: {0}" -f $failedRows.Count),
   ("- Error: {0}" -f $(if([string]::IsNullOrWhiteSpace($errorText)) { "none" } else { $errorText }))
)
$md | Set-Content -LiteralPath (Resolve-RepoPath $OutMarkdown) -Encoding ASCII
