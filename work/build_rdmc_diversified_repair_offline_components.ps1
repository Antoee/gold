param(
   [string]$R20OutPath = "outputs\RDMC_DIVERSIFIED_REPAIR_R20_ANNUAL_TRADES.csv",
   [string]$DdbOutPath = "outputs\RDMC_DIVERSIFIED_REPAIR_DDB_ANNUAL_TRADES.csv"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$workspaceRoot = [IO.Path]::GetFullPath((Join-Path $repo '..\..'))
$parser = Join-Path $repo 'work\analyze_mt5_report_trade_segments.ps1'
$r20Out = Join-Path $repo $R20OutPath
$ddbOut = Join-Path $repo $DdbOutPath
$tempRoot = [IO.Path]::GetFullPath($env:TEMP)
$tempDir = [IO.Path]::GetFullPath((Join-Path $tempRoot 'rdmc_diversified_repair_components'))

if(!$tempDir.StartsWith($tempRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
   throw 'Temporary extraction directory escaped the system temporary directory.'
}
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

function Sum-Profit([object[]]$Rows) {
   return [math]::Round([double](($Rows | Measure-Object -Property Profit -Sum).Sum), 2)
}

function Add-ReportTrades {
   param(
      [Collections.Generic.List[object]]$Destination,
      [string]$Window,
      [string]$ReportPath,
      [scriptblock]$Selector
   )

   if(!(Test-Path -LiteralPath $ReportPath -PathType Leaf)) {
      throw "Required report is missing: $ReportPath"
   }
   $reportHash = (Get-FileHash -LiteralPath $ReportPath -Algorithm SHA256).Hash
   $slug = [IO.Path]::GetFileNameWithoutExtension($ReportPath)
   $tradesPath = Join-Path $tempDir ($slug + '_trades.csv')
   $summaryPath = Join-Path $tempDir ($slug + '_summary.csv')
   $markdownPath = Join-Path $tempDir ($slug + '.md')
   & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $parser `
      -ReportPath $ReportPath -OutTrades $tradesPath -OutSummary $summaryPath -OutMarkdown $markdownPath | Out-Null
   if($LASTEXITCODE -ne 0) { throw "Trade extraction failed for $ReportPath" }

   foreach($trade in @((Import-Csv -LiteralPath $tradesPath) | Where-Object $Selector)) {
      $Destination.Add([pscustomobject]@{
         TestWindow = $Window
         ReportSha256 = $reportHash
         EntryTime = $trade.EntryTime
         ExitTime = $trade.ExitTime
         EntryYear = $trade.EntryYear
         Symbol = $trade.Symbol
         Side = $trade.Side
         Volume = $trade.Volume
         EntryPrice = $trade.EntryPrice
         ExitPrice = $trade.ExitPrice
         InitialStop = $trade.InitialStop
         InitialTarget = $trade.InitialTarget
         InitialRiskMoney = $trade.InitialRiskMoney
         RiskR = $trade.RiskR
         HoldMinutes = $trade.HoldMinutes
         Profit = $trade.Profit
         EntryComment = $trade.EntryComment
         ExitComment = $trade.ExitComment
      }) | Out-Null
   }
}

$r20 = [Collections.Generic.List[object]]::new()
$r20ReportRoot = Join-Path $repo 'outputs\peak_r20_regime_combo_model4_yearly_package\reports_here'
foreach($window in @('2019','2020','2021','2022','2023','2024','2025')) {
   $report = Join-Path $r20ReportRoot "peak_r20_oos_r10_pg40_atr085_adapt7_$($window)_full_m4.htm"
   Add-ReportTrades -Destination $r20 -Window $window -ReportPath $report -Selector { $true }
}

if($r20.Count -ne 22 -or (Sum-Profit @($r20)) -ne 263.72) {
   throw "Unexpected R20 component evidence: trades=$($r20.Count), net=$(Sum-Profit @($r20))"
}
if((Sum-Profit @($r20 | Where-Object TestWindow -eq '2019')) -ne 44.30 -or
   (Sum-Profit @($r20 | Where-Object TestWindow -eq '2020')) -ne -22.92 -or
   (Sum-Profit @($r20 | Where-Object TestWindow -eq '2022')) -ne 37.31) {
   throw 'R20 annual component values changed.'
}
$r20 | Export-Csv -LiteralPath $r20Out -NoTypeInformation -Encoding ASCII

$ddb = [Collections.Generic.List[object]]::new()
$ddbReportRoot = Join-Path $workspaceRoot 'outputs\returned_mt5_reports\first_pass_inbox'
foreach($window in @('2015','2018','2019')) {
   $report = Join-Path $ddbReportRoot "three_lane_ddb045_$($window)_m4.htm"
   Add-ReportTrades -Destination $ddb -Window $window -ReportPath $report -Selector { $_.EntryComment -like 'DDB;*' }
}

if($ddb.Count -ne 3 -or (Sum-Profit @($ddb)) -ne 19.36) {
   throw "Unexpected DDB component evidence: trades=$($ddb.Count), net=$(Sum-Profit @($ddb))"
}
foreach($expected in @(
   @{ Window='2015'; Net=33.19 },
   @{ Window='2018'; Net=-18.71 },
   @{ Window='2019'; Net=4.88 }
)) {
   $actual = Sum-Profit @($ddb | Where-Object TestWindow -eq $expected.Window)
   if($actual -ne $expected.Net) { throw "DDB $($expected.Window) changed: $actual" }
}
$ddb | Export-Csv -LiteralPath $ddbOut -NoTypeInformation -Encoding ASCII

[pscustomobject]@{
   R20Trades = $r20.Count
   R20Net = Sum-Profit @($r20)
   DDBTrades = $ddb.Count
   DDBNet = Sum-Profit @($ddb)
   R20Out = $R20OutPath
   DDBOut = $DdbOutPath
}
