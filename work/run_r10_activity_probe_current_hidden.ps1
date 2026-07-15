param(
   [int]$TimeoutMinutesPerConfig = 5,
   [ValidateRange(1,100)][int]$MaxCpuPercent = 80,
   [string]$OutCsv = "outputs\R10_ACTIVITY_PROBE_CURRENT_SOURCE_STATUS.csv",
   [string]$OutMarkdown = "outputs\R10_ACTIVITY_PROBE_CURRENT_SOURCE_STATUS.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$hardLockFile = Join-Path $PSScriptRoot "MT5_LOCAL_LAUNCH_DISABLED.lock"
$unlockFile = Join-Path $PSScriptRoot "ALLOW_MT5_LOCAL_LAUNCH.unlock"
$hiddenAckFile = Join-Path $PSScriptRoot "ALLOW_MT5_HIDDEN_DESKTOP_ACK.unlock"

function Resolve-RepoPath {
   param([string]$Path)
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}

function Ensure-ParentDir {
   param([string]$Path)
   $parent = Split-Path -Parent $Path
   if($parent -and !(Test-Path -LiteralPath $parent)) {
      New-Item -ItemType Directory -Path $parent -Force | Out-Null
   }
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

$started = (Get-Date)
$status = "RUNNING"
$errorText = ""
$sourceHash = (Get-FileHash -LiteralPath (Join-Path $repo "Professional_XAUUSD_EA.mq5") -Algorithm SHA256).Hash
$oldFocusRisk = $env:ALLOW_MT5_FOCUS_RISK
$oldHiddenAck = $env:ALLOW_MT5_HIDDEN_DESKTOP_ACK

try {
   if(Test-Path -LiteralPath $hardLockFile) {
      Remove-Item -LiteralPath $hardLockFile -Force
   }

   $env:ALLOW_MT5_FOCUS_RISK = "1"
   $env:ALLOW_MT5_HIDDEN_DESKTOP_ACK = "1"
   Set-Content -LiteralPath $unlockFile -Value "Controlled current-source R10 activity probe allowed at $($started.ToString('s'))." -Encoding ASCII
   Set-Content -LiteralPath $hiddenAckFile -Value "Hidden desktop/focus risk acknowledged for controlled local tester run." -Encoding ASCII

   & (Join-Path $PSScriptRoot "build_r10_activity_probe_package.ps1")

   & (Join-Path $PSScriptRoot "run_first_pass_package_hidden.ps1") `
      -ManifestPath "outputs\R10_ACTIVITY_PROBE_PACKAGE_MANIFEST.csv" `
      -TimeoutMinutesPerConfig $TimeoutMinutesPerConfig `
      -MaxCpuPercent $MaxCpuPercent `
      -Run `
      -OutCsv "outputs\R10_ACTIVITY_PROBE_RUN.csv" `
      -OutMarkdown "outputs\R10_ACTIVITY_PROBE_RUN.md"

   & (Join-Path $PSScriptRoot "import_first_pass_hidden_log_results.ps1") `
      -RunCsv "outputs\R10_ACTIVITY_PROBE_RUN.csv" `
      -QueueManifestPath "outputs\R10_ACTIVITY_PROBE_QUEUE.csv" `
      -OutResults "outputs\R10_ACTIVITY_PROBE_RESULTS.csv" `
      -OutSummary "outputs\R10_ACTIVITY_PROBE_SUMMARY.csv" `
      -OutMarkdown "outputs\R10_ACTIVITY_PROBE_METRICS.md"

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

   if([string]::IsNullOrWhiteSpace($oldFocusRisk)) {
      Remove-Item Env:\ALLOW_MT5_FOCUS_RISK -ErrorAction SilentlyContinue
   } else {
      $env:ALLOW_MT5_FOCUS_RISK = $oldFocusRisk
   }

   if([string]::IsNullOrWhiteSpace($oldHiddenAck)) {
      Remove-Item Env:\ALLOW_MT5_HIDDEN_DESKTOP_ACK -ErrorAction SilentlyContinue
   } else {
      $env:ALLOW_MT5_HIDDEN_DESKTOP_ACK = $oldHiddenAck
   }

   Set-Content -LiteralPath $hardLockFile -Value "Restored after controlled current-source R10 activity probe." -Encoding ASCII
}

$finished = Get-Date
$runRows = @()
if(Test-Path -LiteralPath (Resolve-RepoPath "outputs\R10_ACTIVITY_PROBE_RUN.csv")) {
   $runRows = @(Import-Csv -LiteralPath (Resolve-RepoPath "outputs\R10_ACTIVITY_PROBE_RUN.csv"))
}
$reportRows = @($runRows | Where-Object { $_.Status -eq "REPORT_FOUND" })
$failedRows = @($runRows | Where-Object { $_.Status -in @("FAIL", "ERROR", "TIMEOUT", "NO_REPORT") })
$overall = if($status -eq "PASS" -and $failedRows.Count -eq 0 -and $runRows.Count -gt 0 -and $reportRows.Count -eq $runRows.Count) { "PASS" } elseif($status -eq "PASS") { "PARTIAL" } else { "FAIL" }

$outCsvFull = Resolve-RepoPath $OutCsv
$outMarkdownFull = Resolve-RepoPath $OutMarkdown
Ensure-ParentDir $outCsvFull
Ensure-ParentDir $outMarkdownFull

$statusRow = [pscustomobject]@{
   Status = $overall
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
$statusRow | Export-Csv -LiteralPath $outCsvFull -NoTypeInformation -Encoding ASCII

$md = [System.Collections.Generic.List[string]]::new()
$md.Add("# R10 Activity Probe Current-Source Status")
$md.Add("")
$md.Add("Controlled local hidden MT5 run. The wrapper restores the hard local MT5 launch lock and removes unlock files in finally.")
$md.Add("")
$md.Add(("- Status: **{0}**" -f $overall))
$md.Add(("- Source hash: {0}" -f $sourceHash))
$md.Add(("- Started: {0}" -f $started.ToString("s")))
$md.Add(("- Finished: {0}" -f $finished.ToString("s")))
$md.Add(("- Config rows: {0}" -f $runRows.Count))
$md.Add(("- Reports found: {0}" -f $reportRows.Count))
$md.Add(("- Failed rows: {0}" -f $failedRows.Count))
if($errorText -ne "") {
   $md.Add(("- Error: {0}" -f ($errorText -replace "\|", "/")))
}
$md | Set-Content -LiteralPath $outMarkdownFull -Encoding ASCII
