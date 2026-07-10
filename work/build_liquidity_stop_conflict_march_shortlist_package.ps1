param(
   [string]$PackageDir = "work\local_mt5_liquidity_stop_conflict_march_shortlist_package",
   [string]$ReportRoot = "outputs",
   [string]$BaseSetPath = "outputs\CANDIDATE_SEASONAL_MAR1_MAY225_PROFILE.set",
   [int]$Model = 4
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "seasonal_gate_helpers.ps1")

$windows = @(
   [pscustomobject]@{ Window = "2024_to_2026"; Phase = "full"; Set = "full"; From = "2024.01.01"; To = "2026.07.02" },
   [pscustomobject]@{ Window = "2026_ytd"; Phase = "recent"; Set = "recent"; From = "2026.01.01"; To = "2026.07.02" },
   [pscustomobject]@{ Window = "2025_full"; Phase = "oos"; Set = "oos"; From = "2025.01.01"; To = "2025.12.31" },
   [pscustomobject]@{ Window = "2024_full"; Phase = "train"; Set = "train"; From = "2024.01.01"; To = "2024.12.31" },
   [pscustomobject]@{ Window = "2026_03"; Phase = "target"; Set = "target"; From = "2026.03.01"; To = "2026.03.31" },
   [pscustomobject]@{ Window = "2026_05"; Phase = "target"; Set = "target"; From = "2026.05.01"; To = "2026.05.31" },
   [pscustomobject]@{ Window = "2026_06"; Phase = "guard"; Set = "guard"; From = "2026.06.01"; To = "2026.06.30" }
)

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
   foreach($window in $windows) {
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
      $reportName = "liquidity_stop_conflict_march_shortlist_{0}_{1}" -f $profile.Name, $window.Window
      Write-SeasonalTesterConfig -Path (Join-Path $PackageDir "configs\$configName") -ReportRoot $ReportRoot -ReportName $reportName -From $window.From -To $window.To -Inputs $inputs -Model $Model
      $expected.Add([pscustomobject]@{
         Rank = $rank; Profile = $profile.Name; Phase = $window.Phase; Set = $window.Set; Window = $window.Window;
         From = $window.From; To = $window.To; Config = "configs\$configName"; ExpectedReportName = $reportName
      }) | Out-Null
   }
}

$expected | Export-Csv -LiteralPath (Join-Path $PackageDir "EXPECTED_REPORTS.csv") -NoTypeInformation
$expected | Export-Csv -LiteralPath "outputs\LIQUIDITY_STOP_CONFLICT_MARCH_SHORTLIST_MANIFEST.csv" -NoTypeInformation
"Built $rank liquidity stop conflict March shortlist configs in $PackageDir"
