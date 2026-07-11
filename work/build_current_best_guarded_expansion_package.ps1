param(
   [string]$PackageDir = "work\local_mt5_current_best_guarded_expansion_package",
   [string]$ReportRoot = "outputs",
   [string]$BaseSetPath = "outputs\CANDIDATE_PRIMARY_AUG40_MICRO_JULOCT_PROFILE.set",
   [int]$Model = 2,
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
   [pscustomobject]@{ Window = "2024_05"; Phase = "target"; Set = "target"; From = "2024.05.01"; To = "2024.05.31" },
   [pscustomobject]@{ Window = "2025_05"; Phase = "target"; Set = "target"; From = "2025.05.01"; To = "2025.05.31" },
   [pscustomobject]@{ Window = "2026_05"; Phase = "target"; Set = "target"; From = "2026.05.01"; To = "2026.05.31" },
   [pscustomobject]@{ Window = "2026_06"; Phase = "guard"; Set = "guard"; From = "2026.06.01"; To = "2026.06.30" },
   [pscustomobject]@{ Window = "2025_01"; Phase = "flat"; Set = "flat"; From = "2025.01.01"; To = "2025.01.31" },
   [pscustomobject]@{ Window = "2025_04"; Phase = "flat"; Set = "flat"; From = "2025.04.01"; To = "2025.04.30" },
   [pscustomobject]@{ Window = "2025_06"; Phase = "flat"; Set = "flat"; From = "2025.06.01"; To = "2025.06.30" },
   [pscustomobject]@{ Window = "2026_01"; Phase = "flat"; Set = "flat"; From = "2026.01.01"; To = "2026.01.31" }
)

if(Test-Path -LiteralPath $PackageDir) { Remove-Item -LiteralPath $PackageDir -Recurse -Force }
New-Item -ItemType Directory -Path (Join-Path $PackageDir "configs") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $PackageDir "reports_here") -Force | Out-Null

$mayAggressive = @{
   InpUseMonthRiskMultipliers = "true"
   InpTradeMay = "true"
   InpMayMaxDay = "20"
   InpMayRiskMultiplier = "3.20"
}

$reverseGuard = @{
   InpUseAdaptiveReverseWhipsawGuard = "true"
   InpAdaptiveReverseBlockOriginalOnGuard = "true"
   InpUseAdaptiveReverseRecentFlipCooldown = "true"
   InpAdaptiveReverseRecentFlipCooldownMinutes = "240"
   InpAdaptiveReverseRecentFlipMinQualityScore = "14"
   InpUseAdaptiveReversePostStopLockout = "true"
   InpAdaptiveReversePostStopLockoutMinutes = "360"
   InpAdaptiveReversePostStopMinQualityScore = "15"
   InpAdaptiveReverseBlockRangePhase = "true"
   InpAdaptiveReverseRequireTrendPhase = "true"
   InpUseAdaptiveReverseLiquidityTrapGuard = "true"
   InpUseAdaptiveReverseLiquidityClearance = "true"
   InpUseAdaptiveReverseFollowThroughClose = "true"
}

$liquidityStop = @{
   InpUseLiquidityAwareStructureStop = "true"
   InpLiquidityStopUseLastSweep = "true"
   InpLiquidityStopUseEqualLevels = "true"
   InpLiquidityStopUsePreviousDay = "true"
   InpLiquidityStopLookbackBars = "24"
   InpLiquidityStopBufferATR = "0.22"
   InpLiquidityStopBufferPoints = "45.0"
   InpLiquidityStopMaxATRMultiplier = "5.50"
   InpUseLiquidityClusterStopExtension = "true"
   InpLiquidityClusterMinTouches = "3"
   InpLiquidityClusterProximityATR = "0.18"
   InpLiquidityClusterProximityPoints = "55.0"
   InpLiquidityClusterExtraBufferATR = "0.10"
   InpLiquidityClusterExtraBufferPoints = "30.0"
}

$flatOpportunity = @{
   InpUseFlatMonthOpportunityMode = "true"
   InpFlatMonthOpportunityOnlyOutsideMonthFilter = "true"
   InpFlatMonthTargetPercent = "2.00"
   InpFlatMonthMinDayOfMonth = "4"
   InpFlatMonthMaxEntryCount = "4"
   InpFlatMonthMaxProfitPercent = "0.65"
   InpFlatMonthRequireNoMonthlyLoss = "true"
   InpUseFlatMonthProbeLaneSpacing = "true"
   InpFlatMonthProbeLaneSpacingMinutes = "240"
   InpUseMediocreSetupRiskThrottle = "true"
   InpMediocreSetupRiskMultiplier = "0.30"
   InpUseSpreadAdjustedRRFilter = "true"
}

$flatBreakout = Merge-Overrides @($flatOpportunity, @{
   InpAllowFlatMonthProbesOutsideMonthFilter = "true"
   InpUseFlatMonthProbeMode = "true"
   InpFlatMonthProbeMaxEntryCount = "3"
   InpFlatMonthProbeRiskMultiplier = "0.12"
   InpFlatMonthProbeAllowBreakoutContinuation = "true"
   InpFlatMonthProbeBreakoutRiskMultiplier = "0.12"
   InpUseFlatMonthBreakoutProbe = "true"
   InpFlatMonthBreakoutProbeMinHours = "48"
   InpFlatMonthBreakoutProbeMaxMonthlyEntries = "3"
   InpFlatMonthBreakoutProbeMinScore = "9"
   InpFlatMonthBreakoutProbeRequireLiquidSession = "true"
   InpFlatMonthBreakoutProbeRequireADX = "true"
   InpFlatMonthBreakoutProbeMinADX = "22.0"
   InpFlatMonthBreakoutProbeMaxADX = "32.0"
   InpFlatMonthBreakoutProbeRequireExecution = "true"
   InpFlatMonthBreakoutProbeRequireRangeExpansion = "true"
   InpFlatMonthBreakoutProbeMinRangeATR = "0.65"
   InpFlatMonthBreakoutProbeMaxOppositeWickPercent = "28.0"
})

$missedMove = Merge-Overrides @($flatOpportunity, @{
   InpAllowFlatMonthMomentumOutsideMonthFilter = "true"
   InpUseFlatMonthMissedMoveWakeUp = "true"
   InpFlatMonthMissedMoveMinHours = "36"
   InpFlatMonthMissedMoveMaxMonthlyEntries = "4"
   InpFlatMonthMissedMoveMinATR = "1.25"
   InpFlatMonthMissedMoveScoreDiscount = "1"
   InpFlatMonthMissedMoveRRDiscount = "0.03"
   InpFlatMonthMissedMoveRequireLiquidSession = "true"
   InpFlatMonthMissedMoveAllowBreakout = "true"
   InpFlatMonthMissedMoveAllowSessionImpulse = "true"
   InpFlatMonthMissedMoveAllowPowerTrend = "true"
   InpUseFlatMonthMissedMoveTPExpansion = "true"
   InpFlatMonthMissedMoveTPMinQualityScore = "12"
   InpFlatMonthMissedMoveTPMinPriceActionScore = "10"
   InpFlatMonthMissedMoveTPMultiplier = "1.20"
   InpFlatMonthMissedMoveTPRequireTrailing = "true"
})

$profiles = @(
   [pscustomobject]@{ Name = "base"; Overrides = @{} },
   [pscustomobject]@{ Name = "may320_guard"; Overrides = Merge-Overrides @($mayAggressive, $reverseGuard) },
   [pscustomobject]@{ Name = "may320_liqstop"; Overrides = Merge-Overrides @($mayAggressive, $liquidityStop) },
   [pscustomobject]@{ Name = "may320_guard_liqstop"; Overrides = Merge-Overrides @($mayAggressive, $reverseGuard, $liquidityStop) },
   [pscustomobject]@{ Name = "flat_breakout_guard"; Overrides = Merge-Overrides @($flatBreakout, $reverseGuard, $liquidityStop) },
   [pscustomobject]@{ Name = "missed_move_guard"; Overrides = Merge-Overrides @($missedMove, $reverseGuard, $liquidityStop) },
   [pscustomobject]@{ Name = "may320_flat_breakout_guard"; Overrides = Merge-Overrides @($mayAggressive, $flatBreakout, $reverseGuard, $liquidityStop) },
   [pscustomobject]@{ Name = "may320_missed_move_guard"; Overrides = Merge-Overrides @($mayAggressive, $missedMove, $reverseGuard, $liquidityStop) }
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
      $reportName = "current_best_guarded_expansion_{0}_{1}" -f $profile.Name, $window.Window
      Write-SeasonalTesterConfig -Path (Join-Path $PackageDir "configs\$configName") -ReportRoot $ReportRoot -ReportName $reportName -From $window.From -To $window.To -Inputs $inputs -Model $Model
      $expected.Add([pscustomobject]@{
         Rank = $rank; Profile = $profile.Name; Phase = $window.Phase; Set = $window.Set; Window = $window.Window;
         From = $window.From; To = $window.To; Config = "configs\$configName"; ExpectedReportName = $reportName
      }) | Out-Null
   }
}

$expected | Export-Csv -LiteralPath (Join-Path $PackageDir "EXPECTED_REPORTS.csv") -NoTypeInformation
$expected | Export-Csv -LiteralPath "outputs\CURRENT_BEST_GUARDED_EXPANSION_MANIFEST.csv" -NoTypeInformation
"Built $rank current-best guarded expansion configs in $PackageDir"
