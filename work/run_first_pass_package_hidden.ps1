param(
   [string]$ManifestPath = "outputs\FIRST_PASS_NEXT_RUN_PACKAGE_MANIFEST.csv",
   [string]$TerminalPath = "C:\Program Files\MetaTrader 5\terminal64.exe",
   [int]$TimeoutMinutesPerConfig = 15,
   [ValidateRange(1,100)][int]$MaxCpuPercent = 80,
   [switch]$Run,
   [string]$OutCsv = "outputs\FIRST_PASS_HIDDEN_RUN_PLAN.csv",
   [string]$OutMarkdown = "outputs\FIRST_PASS_HIDDEN_RUN_PLAN.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$firstPassInbox = Join-Path $repo "outputs\returned_mt5_reports\first_pass_inbox"
$hardLockFile = Join-Path $PSScriptRoot "MT5_LOCAL_LAUNCH_DISABLED.lock"
$terminalDataRoot = Join-Path $env:APPDATA "MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075"

function Resolve-RepoPath {
   param([string]$Path)
   if([string]::IsNullOrWhiteSpace($Path)) { return $Path }
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

function Escape-MarkdownCell {
   param([string]$Text)
   if($null -eq $Text) { return "" }
   return ([string]$Text) -replace '\|', '\|'
}

function Get-ReportCandidates {
   param([object]$Row)

   $baseName = [System.IO.Path]::GetFileName([string]$Row.ExpectedReportName)
   $destinationBase = [string]$Row.ReportDestination
   $candidates = [System.Collections.Generic.List[string]]::new()
   foreach($extension in @(".htm", ".html", ".xml")) {
      if(![string]::IsNullOrWhiteSpace($destinationBase)) {
         $candidates.Add((Resolve-RepoPath ($destinationBase + $extension))) | Out-Null
      }
      $candidates.Add((Join-Path $firstPassInbox ($baseName + $extension))) | Out-Null
      $candidates.Add((Join-Path $repo ("outputs\{0}{1}" -f $baseName, $extension))) | Out-Null
      $candidates.Add((Join-Path $terminalDataRoot ($baseName + $extension))) | Out-Null
   }
   return @($candidates | Select-Object -Unique)
}

function Copy-FoundReportsToInbox {
   param([object]$Row)

   New-Item -ItemType Directory -Path $firstPassInbox -Force | Out-Null
   $copied = [System.Collections.Generic.List[string]]::new()
   foreach($candidate in (Get-ReportCandidates $Row)) {
      if(!(Test-Path -LiteralPath $candidate)) { continue }
      $target = Join-Path $firstPassInbox ([System.IO.Path]::GetFileName($candidate))
      $sourceFull = (Resolve-Path -LiteralPath $candidate).Path
      $targetFull = if(Test-Path -LiteralPath $target) { (Resolve-Path -LiteralPath $target).Path } else { $target }
      if($sourceFull -ne $targetFull) {
         Copy-Item -LiteralPath $candidate -Destination $target -Force
      }
      $copied.Add($target) | Out-Null
   }
   return @($copied | Select-Object -Unique)
}

$manifestFull = Resolve-RepoPath $ManifestPath
if(!(Test-Path -LiteralPath $manifestFull)) {
   throw "First-pass manifest not found: $manifestFull"
}

$manifestRows = @(Import-Csv -LiteralPath $manifestFull)
$hardLocked = Test-Path -LiteralPath $hardLockFile
$terminalExists = Test-Path -LiteralPath $TerminalPath

if($Run) {
   . (Join-Path $PSScriptRoot "assert_mt5_launch_allowed.ps1")
   . (Join-Path $PSScriptRoot "mt5_background_helpers.ps1")
   if(!$terminalExists) { throw "MT5 terminal not found: $TerminalPath" }
   New-Item -ItemType Directory -Path $firstPassInbox -Force | Out-Null
}

$rows = [System.Collections.Generic.List[object]]::new()
foreach($item in ($manifestRows | Sort-Object { [int]$_.QueueRank })) {
   $configFull = Resolve-RepoPath ([string]$item.PackageConfig)
   $configExists = Test-Path -LiteralPath $configFull
   $started = ""
   $finished = ""
   $reports = @()
   $evidence = ""
   $status = if($configExists) { "READY" } else { "FAIL" }
   $action = if($configExists) { "WOULD_RUN_HIDDEN" } else { "MISSING_CONFIG" }

   if($status -eq "READY" -and $hardLocked -and !$Run) {
      $status = "LOCKED"
      $action = "UNLOCK_REQUIRED"
      $evidence = "Plan only. MT5 hard lock is present, so no local tester run can start."
   }
   elseif($status -eq "READY" -and !$Run) {
      $evidence = "Plan only. Rerun with -Run after confirming hidden MT5 execution is allowed."
   }
   elseif($Run) {
      $started = (Get-Date).ToString("s")
      $status = "RUNNING"
      $action = "RUN_HIDDEN"
      try {
         foreach($candidate in (Get-ReportCandidates $item)) {
            Remove-Item -LiteralPath $candidate -Force -ErrorAction SilentlyContinue
         }
         Stop-MT5TesterProcesses
         Start-Sleep -Seconds 1

         Start-MT5Hidden -TerminalPath $TerminalPath -ConfigPath $configFull -MaxCpuPercent $MaxCpuPercent | Out-Null
         $deadline = (Get-Date).AddMinutes($TimeoutMinutesPerConfig)
         do {
            Start-Sleep -Seconds 2
            Set-MT5BackgroundSafe -MaxCpuPercent $MaxCpuPercent
            $reports = @(Copy-FoundReportsToInbox $item)
            if($reports.Count -gt 0) {
               $status = "REPORT_FOUND"
               $evidence = "Copied $($reports.Count) report file(s) into the first-pass inbox."
               break
            }
             $running = @(Get-Process -Name (Get-MT5TesterProcessNames) -ErrorAction SilentlyContinue)
            if($running.Count -eq 0) {
               Start-Sleep -Seconds 2
               $reports = @(Copy-FoundReportsToInbox $item)
               if($reports.Count -gt 0) {
                  $status = "REPORT_FOUND"
                  $evidence = "Terminal exited; copied $($reports.Count) report file(s) into the first-pass inbox."
               }
               else {
                  $status = "NO_REPORT"
                  $evidence = "Terminal exited but no report file was found."
               }
               break
            }
         } while((Get-Date) -lt $deadline)

         if($status -eq "RUNNING") {
            $status = "TIMEOUT"
            $evidence = "Timed out after $TimeoutMinutesPerConfig minute(s)."
         }
      }
      catch {
         $status = "ERROR"
         $evidence = $_.Exception.Message
      }
      finally {
          Stop-MT5TesterProcesses
         $finished = (Get-Date).ToString("s")
      }
   }

   $rows.Add([pscustomobject]@{
      QueueRank = $item.QueueRank
      Candidate = $item.Candidate
      Window = $item.Window
      Model = $item.Model
      Status = $status
      Action = $action
      Config = $item.PackageConfig
      ConfigExists = [string]$configExists
      ExpectedReportName = $item.ExpectedReportName
      FirstPassInbox = "outputs\returned_mt5_reports\first_pass_inbox"
      MaxCpuPercent = $MaxCpuPercent
      Reports = (@($reports) -join ";")
      Evidence = $evidence
      Started = $started
      Finished = $finished
   }) | Out-Null
}

$outCsvFull = Resolve-RepoPath $OutCsv
$outMarkdownFull = Resolve-RepoPath $OutMarkdown
Ensure-ParentDir $outCsvFull
Ensure-ParentDir $outMarkdownFull
if($rows.Count -eq 0) {
   @('"QueueRank","Candidate","Window","Model","Status","Action","Config","ConfigExists","ExpectedReportName","FirstPassInbox","MaxCpuPercent","Reports","Evidence","Started","Finished"') |
      Set-Content -LiteralPath $outCsvFull -Encoding ASCII
} else {
   $rows | Export-Csv -LiteralPath $outCsvFull -NoTypeInformation -Encoding ASCII
}

$fail = @($rows | Where-Object { $_.Status -in @("FAIL", "ERROR", "TIMEOUT", "NO_REPORT") }).Count
$locked = @($rows | Where-Object Status -eq "LOCKED").Count
$reportFound = @($rows | Where-Object Status -eq "REPORT_FOUND").Count
$ready = @($rows | Where-Object Status -eq "READY").Count
$overall = if($fail -gt 0) {
   "FAIL"
} elseif($reportFound -gt 0 -and $reportFound -eq $rows.Count) {
   "REPORTS_RETURNED"
} elseif($rows.Count -eq 0) {
   "EMPTY"
} elseif($locked -gt 0) {
   "LOCKED"
} elseif($ready -gt 0) {
   "READY"
} else {
   "PENDING"
}

$md = [System.Collections.Generic.List[string]]::new()
$md.Add("# First-Pass Hidden Run Plan")
$md.Add("")
$md.Add("Generated offline unless `-Run` is supplied. Plan mode does not launch MT5, MetaEditor, Git, GitHub CLI, or GitHub Actions.")
$md.Add("")
$md.Add(("- Overall: **{0}**" -f $overall))
$md.Add(('- Run requested: `{0}`' -f ([bool]$Run)))
$md.Add(('- MT5 hard lock present: `{0}`' -f $hardLocked))
$md.Add(('- Terminal path exists: `{0}`' -f $terminalExists))
$md.Add(('- Resource budget: max `{0}%` logical-processor affinity plus below-normal process priority' -f $MaxCpuPercent))
$md.Add(('- Config rows: `{0}`' -f $rows.Count))
$md.Add(('- Reports found: `{0}`' -f $reportFound))
$md.Add("")
if($overall -eq "LOCKED") {
   $md.Add("No tester run was started. The workspace MT5 hard lock is still present, which is the correct no-popup/no-focus state.")
   $md.Add("")
   $md.Add("When local MT5 testing is explicitly allowed again, remove the hard lock, create the required unlock acknowledgements, set the required environment variables, then rerun this script with `-Run`.")
} elseif($overall -eq "READY") {
   $md.Add("The first-pass package is ready to run hidden. Use `-Run` only after local MT5 execution is explicitly allowed.")
} elseif($overall -eq "REPORTS_RETURNED") {
   $md.Add("Reports were found for every configured row. Run `work\route_first_pass_returned_reports.ps1` and `work\refresh_first_pass_validation_state.ps1` next.")
} elseif($overall -eq "EMPTY") {
   $md.Add("No first-pass configs are currently selected. This usually means the active candidate hit an early-stop failure or first-pass is complete.")
}
$md.Add("")
$md.Add("## Rows")
$md.Add("")
$md.Add("| Rank | Candidate | Window | Model | Status | Action | Max CPU % | Expected Report | Evidence |")
$md.Add("| ---: | --- | --- | --- | --- | --- | ---: | --- | --- |")
foreach($row in $rows) {
   $md.Add(("| {0} | {1} | {2} | {3} | {4} | {5} | {6} | {7} | {8} |" -f
      (Escape-MarkdownCell $row.QueueRank),
      (Escape-MarkdownCell $row.Candidate),
      (Escape-MarkdownCell $row.Window),
      (Escape-MarkdownCell $row.Model),
      (Escape-MarkdownCell $row.Status),
      (Escape-MarkdownCell $row.Action),
      (Escape-MarkdownCell $row.MaxCpuPercent),
      (Escape-MarkdownCell $row.ExpectedReportName),
      (Escape-MarkdownCell $row.Evidence)))
}
$md | Set-Content -LiteralPath $outMarkdownFull -Encoding ASCII

[pscustomobject]@{
   Overall = $overall
   Rows = $rows.Count
   Ready = $ready
   Locked = $locked
   ReportsFound = $reportFound
   Fail = $fail
   OutCsv = $OutCsv
   OutMarkdown = $OutMarkdown
}
