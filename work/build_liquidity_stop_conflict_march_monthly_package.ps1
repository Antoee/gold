param(
   [string]$PackageDir = "work\local_mt5_liquidity_stop_conflict_march_monthly_package",
   [string]$ReportRoot = "outputs",
   [string]$BaseSetPath = "outputs\CANDIDATE_SEASONAL_MAR1_MAY225_PROFILE.set",
   [int]$Model = 4
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "seasonal_gate_helpers.ps1")

function New-MonthWindows {
   $items = New-Object System.Collections.Generic.List[object]
   for($year = 2024; $year -le 2026; $year++) {
      $lastMonth = if($year -eq 2026) { 6 } else { 12 }
      for($month = 1; $month -le $lastMonth; $month++) {
         $from = Get-Date -Year $year -Month $month -Day 1
         $to = $from.AddMonths(1).AddDays(-1)
         $items.Add([pscustomobject]@{
            Window = ("{0:D4}_{1:D2}" -f $year, $month)
            Phase = "month"
            Set = "month"
            From = $from.ToString("yyyy.MM.dd")
            To = $to.ToString("yyyy.MM.dd")
         }) | Out-Null
      }
   }
   return $items
}

function New-StableSeasonalBase {
   return Merge-Overrides @(
      (New-MonthGate @(3,5)),
      @{
         InpRiskPercent = "1.00"
         InpUseMonthRiskMultipliers = "true"
         InpMarchRiskMultiplier = "1.00"
         InpMayRiskMultiplier = "2.25"
      }
   )
}

function New-MarchConflictGuard {
   return @{
      InpUseLiquidityStopConflictGuard = "true"
      InpLiquidityStopConflictLookbackBars = "24"
      InpLiquidityStopConflictMinTouches = "3"
      InpLiquidityStopConflictProximityATR = "0.16"
      InpLiquidityStopConflictProximityPoints = "45.0"
      InpLiquidityStopConflictBypassQualityScore = "15"
      InpUseLiquidityStopConflictMonthFilter = "true"
      InpLiquidityStopConflictTradeJanuary = "false"
      InpLiquidityStopConflictTradeFebruary = "false"
      InpLiquidityStopConflictTradeMarch = "true"
      InpLiquidityStopConflictTradeApril = "false"
      InpLiquidityStopConflictTradeMay = "false"
      InpLiquidityStopConflictTradeJune = "false"
      InpLiquidityStopConflictTradeJuly = "false"
      InpLiquidityStopConflictTradeAugust = "false"
      InpLiquidityStopConflictTradeSeptember = "false"
      InpLiquidityStopConflictTradeOctober = "false"
      InpLiquidityStopConflictTradeNovember = "false"
      InpLiquidityStopConflictTradeDecember = "false"
   }
}

if(Test-Path -LiteralPath $PackageDir) { Remove-Item -LiteralPath $PackageDir -Recurse -Force }
New-Item -ItemType Directory -Path (Join-Path $PackageDir "configs") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $PackageDir "reports_here") -Force | Out-Null

$stable = New-StableSeasonalBase
$profiles = @(
   [pscustomobject]@{ Name = "stable"; Overrides = $stable },
   [pscustomobject]@{ Name = "conflict_march_only"; Overrides = (Merge-Overrides @($stable, (New-MarchConflictGuard))) }
)

$expected = New-Object System.Collections.Generic.List[object]
$rank = 0
foreach($profile in $profiles) {
   foreach($window in New-MonthWindows) {
      $rank++
      $inputs = Import-SetInputs $BaseSetPath
      Set-InputLine -Inputs $inputs -Name "InpAllowedSymbol" -Value "XAUUSD"
      Set-InputLine -Inputs $inputs -Name "InpSignalTimeframe" -Value "15"
      Set-InputLine -Inputs $inputs -Name "InpShowDashboard" -Value "false"
      Set-InputLine -Inputs $inputs -Name "InpDashboardInTester" -Value "false"
      Set-InputLine -Inputs $inputs -Name "InpLogLevel" -Value "0"
      foreach($entry in $profile.Overrides.GetEnumerator()) {
         Set-InputLine -Inputs $inputs -Name $entry.Key -Value ([string]$entry.Value)
      }
      $configName = "{0:000}_{1}_{2}.ini" -f $rank, $profile.Name, $window.Window
      $reportName = "liquidity_stop_conflict_march_monthly_{0}_{1}" -f $profile.Name, $window.Window
      Write-SeasonalTesterConfig -Path (Join-Path $PackageDir "configs\$configName") -ReportRoot $ReportRoot -ReportName $reportName -From $window.From -To $window.To -Inputs $inputs -Model $Model
      $expected.Add([pscustomobject]@{
         Rank = $rank; Profile = $profile.Name; Phase = $window.Phase; Set = $window.Set; Window = $window.Window;
         From = $window.From; To = $window.To; Config = "configs\$configName"; ExpectedReportName = $reportName
      }) | Out-Null
   }
}

$expected | Export-Csv -LiteralPath (Join-Path $PackageDir "EXPECTED_REPORTS.csv") -NoTypeInformation
$expected | Export-Csv -LiteralPath "outputs\LIQUIDITY_STOP_CONFLICT_MARCH_MONTHLY_MANIFEST.csv" -NoTypeInformation
"Built $rank liquidity stop conflict March monthly configs in $PackageDir"
