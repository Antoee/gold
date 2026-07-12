param(
   [string]$PackageDir = "work\local_mt5_current_best_exit_maycap_model0_package",
   [string]$ReportRoot = "outputs",
   [string]$BaseSetPath = "outputs\CANDIDATE_PRIMARY_AUG40_REVERSE_OFF_FSD_STRICT_MFE_AUGUST_ONLY_MICRO_R035_RANGE_ELITE_PROFILE.set"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "seasonal_gate_helpers.ps1")

$windows = @(
   [pscustomobject]@{ Window = "2024_to_2026"; Phase = "full"; Set = "full"; From = "2024.01.01"; To = "2026.07.02" },
   [pscustomobject]@{ Window = "2026_ytd"; Phase = "recent"; Set = "recent"; From = "2026.01.01"; To = "2026.07.02" },
   [pscustomobject]@{ Window = "2025_full"; Phase = "oos"; Set = "oos"; From = "2025.01.01"; To = "2025.12.31" },
   [pscustomobject]@{ Window = "2024_full"; Phase = "train"; Set = "train"; From = "2024.01.01"; To = "2024.12.31" },
   [pscustomobject]@{ Window = "2024_H2"; Phase = "walk"; Set = "walk"; From = "2024.07.01"; To = "2024.12.31" },
   [pscustomobject]@{ Window = "2025_H2"; Phase = "walk"; Set = "walk"; From = "2025.07.01"; To = "2025.12.31" },
   [pscustomobject]@{ Window = "2024_Q3"; Phase = "walk"; Set = "walk"; From = "2024.07.01"; To = "2024.09.30" },
   [pscustomobject]@{ Window = "2024_Q4"; Phase = "walk"; Set = "walk"; From = "2024.10.01"; To = "2024.12.31" },
   [pscustomobject]@{ Window = "2025_Q3"; Phase = "walk"; Set = "walk"; From = "2025.07.01"; To = "2025.09.30" },
   [pscustomobject]@{ Window = "2025_Q4"; Phase = "walk"; Set = "walk"; From = "2025.10.01"; To = "2025.12.31" },
   [pscustomobject]@{ Window = "2024_03"; Phase = "engine"; Set = "engine"; From = "2024.03.01"; To = "2024.03.31" },
   [pscustomobject]@{ Window = "2025_03"; Phase = "engine"; Set = "engine"; From = "2025.03.01"; To = "2025.03.31" },
   [pscustomobject]@{ Window = "2026_03"; Phase = "engine"; Set = "engine"; From = "2026.03.01"; To = "2026.03.31" },
   [pscustomobject]@{ Window = "2024_05"; Phase = "engine"; Set = "engine"; From = "2024.05.01"; To = "2024.05.31" },
   [pscustomobject]@{ Window = "2026_05"; Phase = "engine"; Set = "engine"; From = "2026.05.01"; To = "2026.05.31" },
   [pscustomobject]@{ Window = "2025_04"; Phase = "flat_guard"; Set = "guard"; From = "2025.04.01"; To = "2025.04.30" },
   [pscustomobject]@{ Window = "2026_01"; Phase = "flat_guard"; Set = "guard"; From = "2026.01.01"; To = "2026.01.31" }
)

$mayCap042 = @{ InpMayRiskMultiplier = "3.25"; InpMaxPositionLots = "0.42"; InpUseAdaptiveReverse = "false" }
$mayCap045 = @{ InpMayRiskMultiplier = "3.25"; InpMaxPositionLots = "0.45"; InpUseAdaptiveReverse = "false" }
$qualityTpConservative = @{ InpUseQualityTakeProfitScaling = "true"; InpQualityTPMinScore = "11"; InpQualityTPFullScore = "16"; InpMinQualityTPMultiplier = "1.00"; InpMaxQualityTPMultiplier = "1.25"; InpUseAdaptiveReverse = "false" }
$runnerConservative = @{ InpUseRunnerTakeProfitExpansion = "true"; InpRunnerMinQualityScore = "14"; InpRunnerMinPriceActionScore = "16"; InpRunnerTakeProfitMultiplier = "1.30"; InpRunnerRequireTrailing = "false"; InpUseAdaptiveReverse = "false" }
$mayCapRunner = Merge-Overrides @($mayCap042, $runnerConservative)

$profiles = @(
   [pscustomobject]@{ Name = "base_range_elite"; Overrides = @{} },
   [pscustomobject]@{ Name = "may325_lot042"; Overrides = $mayCap042 },
   [pscustomobject]@{ Name = "may325_lot045"; Overrides = $mayCap045 },
   [pscustomobject]@{ Name = "qtp_conservative"; Overrides = $qualityTpConservative },
   [pscustomobject]@{ Name = "runner_conservative"; Overrides = $runnerConservative },
   [pscustomobject]@{ Name = "may325_lot042_runner"; Overrides = $mayCapRunner }
)

if(Test-Path -LiteralPath $PackageDir) { Remove-Item -LiteralPath $PackageDir -Recurse -Force }
New-Item -ItemType Directory -Path (Join-Path $PackageDir "configs") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $PackageDir "reports_here") -Force | Out-Null

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
      foreach($entry in $profile.Overrides.GetEnumerator()) { Set-InputLine -Inputs $inputs -Name $entry.Key -Value ([string]$entry.Value) }
      $configName = "{0:000}_{1}_{2}.ini" -f $rank, $profile.Name, $window.Window
      $reportName = "current_best_exit_maycap_model0_{0}_{1}" -f $profile.Name, $window.Window
      Write-SeasonalTesterConfig -Path (Join-Path $PackageDir "configs\$configName") -ReportRoot $ReportRoot -ReportName $reportName -From $window.From -To $window.To -Inputs $inputs -Model 0
      $expected.Add([pscustomobject]@{ Rank = $rank; Profile = $profile.Name; Phase = $window.Phase; Set = $window.Set; Window = $window.Window; From = $window.From; To = $window.To; Config = "configs\$configName"; ExpectedReportName = $reportName }) | Out-Null
   }
}

$expected | Export-Csv -LiteralPath (Join-Path $PackageDir "EXPECTED_REPORTS.csv") -NoTypeInformation
$expected | Export-Csv -LiteralPath "outputs\CURRENT_BEST_EXIT_MAYCAP_MODEL0_MANIFEST.csv" -NoTypeInformation
"Built $rank current-best exit/May-cap Model 0 configs in $PackageDir"
