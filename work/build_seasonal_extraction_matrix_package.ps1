param(
   [string]$PackageDir = "work\local_mt5_seasonal_extraction_matrix_package",
   [string]$ReportRoot = "outputs",
   [string]$BaseSetPath = "outputs\CANDIDATE_SEASONAL_MAR1_MAY225_PROFILE.set",
   [int]$Model = 2
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

if(Test-Path -LiteralPath $PackageDir) { Remove-Item -LiteralPath $PackageDir -Recurse -Force }
New-Item -ItemType Directory -Path (Join-Path $PackageDir "configs") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $PackageDir "reports_here") -Force | Out-Null

$stable = New-StableSeasonalBase

$profiles = @(
   [pscustomobject]@{ Name = "stable_mar1_may225"; Overrides = $stable },
   [pscustomobject]@{ Name = "march2_may225"; Overrides = (Merge-Overrides @($stable, @{ InpMarchRiskMultiplier = "2.00" })) },
   [pscustomobject]@{ Name = "may265_guarded"; Overrides = (Merge-Overrides @($stable, @{ InpMayRiskMultiplier = "2.65" })) },
   [pscustomobject]@{ Name = "equity_peak_lock"; Overrides = (Merge-Overrides @($stable, @{
      InpUseEquityProfitLock = "true"
      InpEquityProfitLockStartPercent = "2.00"
      InpEquityProfitLockPercent = "65.0"
      InpUseEquityProfitPeakTrail = "true"
      InpEquityProfitPeakTrailMinProfitPercent = "3.00"
      InpEquityProfitPeakTrailGivebackPercent = "22.0"
   })) },
   [pscustomobject]@{ Name = "mfe_runner_lock"; Overrides = (Merge-Overrides @($stable, @{
      InpUseMFEProfitLockStop = "true"
      InpMFEProfitLockStartR = "1.15"
      InpMFEProfitLockMinR = "0.25"
      InpMFEProfitLockGivebackR = "0.55"
      InpUseStructureTrailing = "true"
   })) },
   [pscustomobject]@{ Name = "house_money_scale"; Overrides = (Merge-Overrides @($stable, @{
      InpUseWinnerScaleIn = "true"
      InpWinnerScaleInMinProfitR = "0.90"
      InpWinnerScaleInRequireProtectedStop = "true"
      InpWinnerScaleInRiskMultiplier = "0.35"
      InpUseHouseMoneyScaleInRiskRamp = "true"
      InpHouseMoneyScaleInRiskStartCushionPercent = "2.0"
      InpHouseMoneyScaleInRiskFullCushionPercent = "8.0"
      InpMaxHouseMoneyScaleInRiskMultiplier = "0.65"
   })) },
   [pscustomobject]@{ Name = "profit_boost_guarded"; Overrides = (Merge-Overrides @($stable, @{
      InpUseProfitOnlyRiskBoost = "true"
      InpProfitBoostStartPercent = "1.00"
      InpProfitBoostFullPercent = "6.00"
      InpMaxProfitBoostMultiplier = "1.75"
      InpGrowthBoostRequiresClosedProfit = "true"
      InpUseEquityProfitPeakTrail = "true"
      InpEquityProfitPeakTrailMinProfitPercent = "3.00"
      InpEquityProfitPeakTrailGivebackPercent = "20.0"
   })) }
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
      $reportName = "seasonal_extraction_matrix_{0}_{1}" -f $profile.Name, $window.Window
      Write-SeasonalTesterConfig -Path (Join-Path $PackageDir "configs\$configName") -ReportRoot $ReportRoot -ReportName $reportName -From $window.From -To $window.To -Inputs $inputs -Model $Model
      $expected.Add([pscustomobject]@{
         Rank = $rank; Profile = $profile.Name; Phase = $window.Phase; Set = $window.Set; Window = $window.Window;
         From = $window.From; To = $window.To; Config = "configs\$configName"; ExpectedReportName = $reportName
      }) | Out-Null
   }
}

$expected | Export-Csv -LiteralPath (Join-Path $PackageDir "EXPECTED_REPORTS.csv") -NoTypeInformation
$expected | Export-Csv -LiteralPath "outputs\SEASONAL_EXTRACTION_MATRIX_MANIFEST.csv" -NoTypeInformation
"Built $rank seasonal extraction matrix configs in $PackageDir"
