param(
   [string]$PackageDir = "work\local_mt5_current_best_adaptive_reverse_ablation_package",
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
   [pscustomobject]@{ Window = "2025_01"; Phase = "flat"; Set = "flat"; From = "2025.01.01"; To = "2025.01.31" },
   [pscustomobject]@{ Window = "2025_04"; Phase = "flat"; Set = "flat"; From = "2025.04.01"; To = "2025.04.30" },
   [pscustomobject]@{ Window = "2025_06"; Phase = "flat"; Set = "flat"; From = "2025.06.01"; To = "2025.06.30" },
   [pscustomobject]@{ Window = "2026_01"; Phase = "flat"; Set = "flat"; From = "2026.01.01"; To = "2026.01.31" }
)

if(Test-Path -LiteralPath $PackageDir) { Remove-Item -LiteralPath $PackageDir -Recurse -Force }
New-Item -ItemType Directory -Path (Join-Path $PackageDir "configs") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $PackageDir "reports_here") -Force | Out-Null

$reverseOff = @{
   InpUseAdaptiveReverse = "false"
}

$rangeTrapGuard = @{
   InpUseAdaptiveReverseWhipsawGuard = "true"
   InpAdaptiveReverseBlockOriginalOnGuard = "true"
   InpAdaptiveReverseBlockRangePhase = "true"
   InpAdaptiveReverseRequireTrendPhase = "true"
   InpUseAdaptiveReverseLiquidityTrapGuard = "true"
   InpAdaptiveReverseTrapLookbackBars = "30"
   InpAdaptiveReverseTrapMaxDistanceATR = "1.00"
   InpAdaptiveReverseTrapUseEqualLevels = "true"
   InpAdaptiveReverseTrapUsePreviousDay = "true"
   InpUseAdaptiveReverseLiquidityClearance = "true"
   InpAdaptiveReverseClearanceLookbackBars = "42"
   InpAdaptiveReverseMinLiquidityClearanceATR = "1.25"
}

$followThrough = @{
   InpUseAdaptiveReverseWhipsawGuard = "true"
   InpAdaptiveReverseBlockOriginalOnGuard = "true"
   InpUseAdaptiveReverseFollowThroughClose = "true"
   InpAdaptiveReverseFollowThroughLookbackBars = "12"
   InpAdaptiveReverseFollowThroughBufferATR = "0.12"
   InpAdaptiveReverseFollowThroughBufferPoints = "25.0"
   InpUseAdaptiveReverseRecentFlipCooldown = "true"
   InpAdaptiveReverseRecentFlipCooldownMinutes = "240"
   InpAdaptiveReverseRecentFlipMinQualityScore = "15"
   InpUseAdaptiveReversePostStopLockout = "true"
   InpAdaptiveReversePostStopLockoutMinutes = "360"
   InpAdaptiveReversePostStopMinQualityScore = "16"
}

$qualityOnly = @{
   InpUseAdaptiveReverseWhipsawGuard = "true"
   InpAdaptiveReverseBlockOriginalOnGuard = "false"
   InpUseAdaptiveReverseLossCooldown = "true"
   InpAdaptiveReverseLossLookbackTrades = "8"
   InpAdaptiveReverseLossThreshold = "2"
   InpAdaptiveReverseLossCooldownMinutes = "480"
   InpAdaptiveReverseLossMinQualityScore = "16"
   InpAdaptiveReversePhaseBypassQualityScore = "18"
   InpAdaptiveReverseTrapBypassQualityScore = "18"
   InpAdaptiveReverseClearanceBypassQualityScore = "18"
   InpAdaptiveReverseFollowThroughBypassQualityScore = "18"
}

$profiles = @(
   [pscustomobject]@{ Name = "base"; Overrides = @{} },
   [pscustomobject]@{ Name = "reverse_off"; Overrides = $reverseOff },
   [pscustomobject]@{ Name = "range_trap_guard"; Overrides = $rangeTrapGuard },
   [pscustomobject]@{ Name = "followthrough_guard"; Overrides = $followThrough },
   [pscustomobject]@{ Name = "quality18_guard"; Overrides = $qualityOnly },
   [pscustomobject]@{ Name = "full_reverse_guard"; Overrides = Merge-Overrides @($rangeTrapGuard, $followThrough, $qualityOnly) }
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
      $reportName = "current_best_adaptive_reverse_ablation_{0}_{1}" -f $profile.Name, $window.Window
      Write-SeasonalTesterConfig -Path (Join-Path $PackageDir "configs\$configName") -ReportRoot $ReportRoot -ReportName $reportName -From $window.From -To $window.To -Inputs $inputs -Model $Model
      $expected.Add([pscustomobject]@{
         Rank = $rank; Profile = $profile.Name; Phase = $window.Phase; Set = $window.Set; Window = $window.Window;
         From = $window.From; To = $window.To; Config = "configs\$configName"; ExpectedReportName = $reportName
      }) | Out-Null
   }
}

$expected | Export-Csv -LiteralPath (Join-Path $PackageDir "EXPECTED_REPORTS.csv") -NoTypeInformation
$expected | Export-Csv -LiteralPath "outputs\CURRENT_BEST_ADAPTIVE_REVERSE_ABLATION_MANIFEST.csv" -NoTypeInformation
"Built $rank adaptive-reverse ablation configs in $PackageDir"
