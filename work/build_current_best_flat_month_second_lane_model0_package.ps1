param(
   [string]$PackageDir = "work\local_mt5_current_best_flat_month_second_lane_model0_package",
   [string]$ReportRoot = "outputs",
   [string]$BaseSetPath = "outputs\CANDIDATE_PRIMARY_AUG40_REVERSE_OFF_FSD_STRICT_MFE_AUGUST_ONLY_PROFILE.set",
   [string[]]$ProfileNames = @()
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "seasonal_gate_helpers.ps1")

$windows = @(
   [pscustomobject]@{ Window = "2024_to_2026"; Phase = "full"; Set = "full"; From = "2024.01.01"; To = "2026.07.02" },
   [pscustomobject]@{ Window = "2026_ytd"; Phase = "recent"; Set = "recent"; From = "2026.01.01"; To = "2026.07.02" },
   [pscustomobject]@{ Window = "2025_full"; Phase = "oos"; Set = "oos"; From = "2025.01.01"; To = "2025.12.31" },
   [pscustomobject]@{ Window = "2024_full"; Phase = "train"; Set = "train"; From = "2024.01.01"; To = "2024.12.31" },
   [pscustomobject]@{ Window = "2025_01"; Phase = "dormant"; Set = "dormant"; From = "2025.01.01"; To = "2025.01.31" },
   [pscustomobject]@{ Window = "2025_04"; Phase = "dormant"; Set = "dormant"; From = "2025.04.01"; To = "2025.04.30" },
   [pscustomobject]@{ Window = "2025_06"; Phase = "dormant"; Set = "dormant"; From = "2025.06.01"; To = "2025.06.30" },
   [pscustomobject]@{ Window = "2026_01"; Phase = "dormant"; Set = "dormant"; From = "2026.01.01"; To = "2026.01.31" },
   [pscustomobject]@{ Window = "2024_04"; Phase = "guard"; Set = "guard"; From = "2024.04.01"; To = "2024.04.30" }
)

if(Test-Path -LiteralPath $PackageDir) { Remove-Item -LiteralPath $PackageDir -Recurse -Force }
New-Item -ItemType Directory -Path (Join-Path $PackageDir "configs") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $PackageDir "reports_here") -Force | Out-Null

$fsdRelaxed = @{
   InpUseFlatMonthStructuralDisplacementLane = "true"
   InpFlatMonthStructuralDisplacementRiskMultiplier = "0.18"
   InpFlatMonthStructuralDisplacementMaxMonthlyEntries = "6"
   InpFlatMonthStructuralDisplacementSpacingMinutes = "240"
   InpFlatMonthStructuralDisplacementMinScore = "7"
   InpFlatMonthStructuralDisplacementMinADX = "17.0"
   InpFlatMonthStructuralDisplacementMaxADX = "36.0"
   InpFlatMonthStructuralDisplacementMinRangeATR = "0.62"
   InpFlatMonthStructuralDisplacementMinBodyPercent = "46.0"
   InpFlatMonthStructuralDisplacementMaxOppositeWickPercent = "34.0"
   InpFlatMonthStructuralDisplacementRequireSweepOrRetest = "true"
   InpFlatMonthStructuralDisplacementRequireOrderFlow = "false"
   InpFlatMonthStructuralDisplacementRequireForwardClearance = "true"
   InpFlatMonthStructuralDisplacementMinClearanceATR = "0.90"
   InpFlatMonthStructuralDisplacementTakeProfitATR = "1.25"
   InpFlatMonthStructuralDisplacementMinRR = "0.90"
}

$breakoutProbe = @{
   InpUseFlatMonthBreakoutProbe = "true"
   InpFlatMonthBreakoutProbeMinHours = "36"
   InpFlatMonthBreakoutProbeMaxMonthlyEntries = "5"
   InpFlatMonthBreakoutProbeMinScore = "8"
   InpFlatMonthBreakoutProbeRiskMultiplier = "0.22"
   InpFlatMonthBreakoutProbeRequireLiquidSession = "true"
   InpFlatMonthBreakoutProbeRequireADX = "true"
   InpFlatMonthBreakoutProbeMinADX = "19.0"
   InpFlatMonthBreakoutProbeMaxADX = "33.0"
   InpFlatMonthBreakoutProbeRequireExecution = "true"
   InpFlatMonthBreakoutProbeRequireRangeExpansion = "true"
   InpFlatMonthBreakoutProbeMinRangeATR = "0.50"
   InpFlatMonthBreakoutProbeMaxOppositeWickPercent = "34.0"
}

$missedMoveWake = @{
   InpUseFlatMonthMissedMoveWakeUp = "true"
   InpFlatMonthMissedMoveMinHours = "30"
   InpFlatMonthMissedMoveMaxMonthlyEntries = "6"
   InpFlatMonthMissedMoveMinATR = "1.45"
   InpFlatMonthMissedMoveScoreDiscount = "1"
   InpFlatMonthMissedMoveRRDiscount = "0.03"
   InpFlatMonthMissedMoveRequireLiquidSession = "true"
   InpFlatMonthMissedMoveAllowBreakout = "true"
   InpFlatMonthMissedMoveAllowSessionImpulse = "true"
   InpFlatMonthMissedMoveAllowPowerTrend = "true"
}

$eliteFallback = @{
   InpUseFlatMonthEliteFallback = "true"
   InpFlatMonthEliteFallbackMinHours = "48"
   InpFlatMonthEliteFallbackMaxMonthlyEntries = "4"
   InpFlatMonthEliteFallbackMaxConfirmationShortfall = "1"
   InpFlatMonthEliteFallbackMinQualityScore = "13"
   InpFlatMonthEliteFallbackMinPriceActionScore = "8"
   InpFlatMonthEliteFallbackRequireLiquidSession = "true"
}

$profiles = @(
   [pscustomobject]@{ Name = "base_mfe_aug"; Overrides = @{} },
   [pscustomobject]@{ Name = "fsd_relaxed"; Overrides = $fsdRelaxed },
   [pscustomobject]@{ Name = "breakout_probe"; Overrides = $breakoutProbe },
   [pscustomobject]@{ Name = "missed_move_wake"; Overrides = $missedMoveWake },
   [pscustomobject]@{ Name = "elite_fallback"; Overrides = $eliteFallback },
   [pscustomobject]@{ Name = "guarded_combo"; Overrides = Merge-Overrides @($fsdRelaxed, $breakoutProbe, $missedMoveWake, $eliteFallback) }
)

if($ProfileNames.Count -gt 0) {
   $wanted = @{}
   foreach($name in $ProfileNames) { $wanted[$name] = $true }
   $profiles = @($profiles | Where-Object { $wanted.ContainsKey($_.Name) })
   if($profiles.Count -le 0) { throw "No matching profiles selected: $($ProfileNames -join ', ')" }
}

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
      $reportName = "current_best_flat_month_second_lane_model0_{0}_{1}" -f $profile.Name, $window.Window
      Write-SeasonalTesterConfig -Path (Join-Path $PackageDir "configs\$configName") -ReportRoot $ReportRoot -ReportName $reportName -From $window.From -To $window.To -Inputs $inputs -Model 0
      $expected.Add([pscustomobject]@{
         Rank = $rank; Profile = $profile.Name; Phase = $window.Phase; Set = $window.Set; Window = $window.Window;
         From = $window.From; To = $window.To; Config = "configs\$configName"; ExpectedReportName = $reportName
      }) | Out-Null
   }
}

$expected | Export-Csv -LiteralPath (Join-Path $PackageDir "EXPECTED_REPORTS.csv") -NoTypeInformation
$expected | Export-Csv -LiteralPath "outputs\CURRENT_BEST_FLAT_MONTH_SECOND_LANE_MODEL0_MANIFEST.csv" -NoTypeInformation
"Built $rank current-best flat-month second-lane Model 0 configs in $PackageDir"
