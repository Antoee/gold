param(
   [string]$TerminalPath = "C:\Program Files\MetaTrader 5\terminal64.exe",
   [int]$TimeoutMinutesPerConfig = 3,
   [ValidateRange(1,100)][int]$MaxCpuPercent = 80,
   [string]$OutCsv = "outputs\MT5_REPORT_EXPORT_SMOKE.csv",
   [string]$OutMarkdown = "outputs\MT5_REPORT_EXPORT_SMOKE.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$outDir = Join-Path $repo "outputs\mt5_report_export_smoke"
$configDir = Join-Path $outDir "configs"
$reportDir = Join-Path $outDir "reports"
$lockFile = Join-Path $PSScriptRoot "MT5_LOCAL_LAUNCH_DISABLED.lock"
$unlockFile = Join-Path $PSScriptRoot "ALLOW_MT5_LOCAL_LAUNCH.unlock"
$hiddenAckFile = Join-Path $PSScriptRoot "ALLOW_MT5_HIDDEN_DESKTOP_ACK.unlock"

function Ensure-Dir {
   param([string]$Path)
   if(!(Test-Path -LiteralPath $Path)) {
      New-Item -ItemType Directory -Path $Path -Force | Out-Null
   }
}

function Stop-MT5LocalProcesses {
   foreach($name in @("terminal", "terminal64", "metatester", "metatester64", "MetaEditor", "metaeditor64")) {
      Get-Process -Name $name -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
   }
}

function Find-SmokeReports {
   param([string]$BaseName)

   $roots = @(
      $repo,
      (Join-Path $env:APPDATA "MetaQuotes")
   )
   $matches = [System.Collections.Generic.List[string]]::new()
   foreach($root in $roots) {
      if(!(Test-Path -LiteralPath $root)) { continue }
      foreach($extension in @(".htm", ".html", ".xml")) {
         Get-ChildItem -LiteralPath $root -Recurse -File -Filter "$BaseName*$extension" -ErrorAction SilentlyContinue |
            ForEach-Object { $matches.Add($_.FullName) | Out-Null }
      }
   }
   return @($matches | Select-Object -Unique)
}

function Write-SmokeConfig {
   param(
      [string]$Path,
      [string]$ReportValue
   )

   $lines = @(
      "[Tester]",
      "Expert=Professional_XAUUSD_EA.ex5",
      "Symbol=XAUUSD",
      "Period=15",
      "Optimization=0",
      "Model=1",
      "FromDate=2026.01.01",
      "ToDate=2026.01.15",
      "ForwardMode=0",
      "Deposit=1000",
      "Currency=USD",
      "ProfitInPips=0",
      "Leverage=100",
      "ExecutionMode=0",
      "OptimizationCriterion=6",
      "Visual=0",
      "Report=$ReportValue",
      "ReplaceReport=1",
      "ShutdownTerminal=1",
      "[TesterInputs]",
      "InpAllowedSymbol=XAUUSD",
      "InpUseSymbolSafetyLock=true||true||0||0||N",
      "InpUseRealAccountSafetyLock=true||true||0||0||N",
      "InpAllowRealAccountTrading=false||false||0||0||N",
      "InpShowDashboard=false||false||0||0||N",
      "InpDashboardInTester=false||false||0||0||N",
      "InpLogLevel=0||0||0||0||N",
      "InpEvidenceProfileId=report_export_smoke",
      "InpEvidenceRunLabel=report_export_smoke",
      "InpRealAccountApprovalCode=DISABLED",
      "InpRealAccountApprovalProfileId=DISABLED",
      "InpRealAccountApprovalSourceHash=DISABLED"
   )
   Set-Content -LiteralPath $Path -Value $lines -Encoding ASCII
}

Ensure-Dir $configDir
Ensure-Dir $reportDir

$variants = @(
   [pscustomobject]@{ Name = "abs_no_ext"; BaseName = "mt5_report_smoke_abs_no_ext"; ReportValue = (Join-Path $reportDir "mt5_report_smoke_abs_no_ext") },
   [pscustomobject]@{ Name = "abs_htm"; BaseName = "mt5_report_smoke_abs_htm"; ReportValue = (Join-Path $reportDir "mt5_report_smoke_abs_htm.htm") },
   [pscustomobject]@{ Name = "plain_no_ext"; BaseName = "mt5_report_smoke_plain_no_ext"; ReportValue = "mt5_report_smoke_plain_no_ext" },
   [pscustomobject]@{ Name = "plain_htm"; BaseName = "mt5_report_smoke_plain_htm"; ReportValue = "mt5_report_smoke_plain_htm.htm" }
)

$rows = [System.Collections.Generic.List[object]]::new()

try {
   if(!(Test-Path -LiteralPath $TerminalPath)) {
      throw "MT5 terminal not found: $TerminalPath"
   }
   Stop-MT5LocalProcesses
   Remove-Item -LiteralPath $lockFile -Force -ErrorAction SilentlyContinue
   New-Item -ItemType File -Path $unlockFile -Force | Out-Null
   New-Item -ItemType File -Path $hiddenAckFile -Force | Out-Null
   $env:ALLOW_MT5_FOCUS_RISK = "1"
   $env:ALLOW_MT5_HIDDEN_DESKTOP_ACK = "1"
   . (Join-Path $PSScriptRoot "assert_mt5_launch_allowed.ps1")
   . (Join-Path $PSScriptRoot "mt5_background_helpers.ps1")

   foreach($variant in $variants) {
      $configPath = Join-Path $configDir ("{0}.ini" -f $variant.Name)
      Write-SmokeConfig -Path $configPath -ReportValue $variant.ReportValue
      foreach($existing in (Find-SmokeReports -BaseName $variant.BaseName)) {
         Remove-Item -LiteralPath $existing -Force -ErrorAction SilentlyContinue
      }

      $started = (Get-Date).ToString("s")
      $status = "RUNNING"
      $evidence = ""
      $reports = @()
      try {
         Stop-MT5LocalProcesses
         Start-Sleep -Seconds 1
         Start-MT5Hidden -TerminalPath $TerminalPath -ConfigPath $configPath -MaxCpuPercent $MaxCpuPercent | Out-Null
         $deadline = (Get-Date).AddMinutes($TimeoutMinutesPerConfig)
         do {
            Start-Sleep -Seconds 2
            Set-MT5BackgroundSafe -MaxCpuPercent $MaxCpuPercent
            $reports = @(Find-SmokeReports -BaseName $variant.BaseName)
            if($reports.Count -gt 0) {
               $status = "REPORT_FOUND"
               $evidence = "Found $($reports.Count) matching report file(s)."
               break
            }

            $running = @(Get-Process -Name (Get-MT5TesterProcessNames) -ErrorAction SilentlyContinue)
            if($running.Count -eq 0) {
               Start-Sleep -Seconds 2
               $reports = @(Find-SmokeReports -BaseName $variant.BaseName)
               if($reports.Count -gt 0) {
                  $status = "REPORT_FOUND"
                  $evidence = "Terminal exited; found $($reports.Count) matching report file(s)."
               }
               else {
                  $status = "NO_REPORT"
                  $evidence = "Terminal exited but no matching report file was found."
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
         Stop-MT5LocalProcesses
      }

      $rows.Add([pscustomobject]@{
         Variant = $variant.Name
         Status = $status
         ReportValue = $variant.ReportValue
         BaseName = $variant.BaseName
         Reports = (@($reports) -join ";")
         Evidence = $evidence
         Started = $started
         Finished = (Get-Date).ToString("s")
      }) | Out-Null
   }
}
finally {
   Stop-MT5LocalProcesses
   Remove-Item -LiteralPath $unlockFile -Force -ErrorAction SilentlyContinue
   Remove-Item -LiteralPath $hiddenAckFile -Force -ErrorAction SilentlyContinue
   New-Item -ItemType File -Path $lockFile -Force | Out-Null
   Remove-Item Env:\ALLOW_MT5_FOCUS_RISK -ErrorAction SilentlyContinue
   Remove-Item Env:\ALLOW_MT5_HIDDEN_DESKTOP_ACK -ErrorAction SilentlyContinue
}

$outCsvFull = Join-Path $repo $OutCsv
$outMarkdownFull = Join-Path $repo $OutMarkdown
Ensure-Dir (Split-Path -Parent $outCsvFull)
$rows | Export-Csv -LiteralPath $outCsvFull -NoTypeInformation -Encoding ASCII

$found = @($rows | Where-Object Status -eq "REPORT_FOUND").Count
$md = [System.Collections.Generic.List[string]]::new()
$md.Add("# MT5 Report Export Smoke Test") | Out-Null
$md.Add("") | Out-Null
$md.Add(("- Generated: {0}" -f (Get-Date).ToString("s"))) | Out-Null
$md.Add(("- Variants: {0}" -f $rows.Count)) | Out-Null
$md.Add(("- Reports found: {0}" -f $found)) | Out-Null
$md.Add("") | Out-Null
$md.Add("| Variant | Status | Report value | Reports | Evidence |") | Out-Null
$md.Add("| --- | --- | --- | --- | --- |") | Out-Null
foreach($row in $rows) {
   $md.Add(("| {0} | {1} | {2} | {3} | {4} |" -f
      $row.Variant,
      $row.Status,
      (($row.ReportValue -replace '\|','\|')),
      (($row.Reports -replace '\|','\|')),
      (($row.Evidence -replace '\|','\|')))) | Out-Null
}
$md | Set-Content -LiteralPath $outMarkdownFull -Encoding ASCII

[pscustomobject]@{
   Variants = $rows.Count
   ReportsFound = $found
   OutCsv = $OutCsv
   OutMarkdown = $OutMarkdown
}
