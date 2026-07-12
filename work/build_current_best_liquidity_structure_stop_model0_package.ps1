param(
   [string]$PackageDir = "work\local_mt5_current_best_liquidity_structure_stop_model0_package",
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
   [pscustomobject]@{ Window = "2024_08"; Phase = "target"; Set = "target"; From = "2024.08.01"; To = "2024.08.31" },
   [pscustomobject]@{ Window = "2025_08"; Phase = "target"; Set = "target"; From = "2025.08.01"; To = "2025.08.31" },
   [pscustomobject]@{ Window = "2026_06"; Phase = "guard"; Set = "guard"; From = "2026.06.01"; To = "2026.06.30" }
)

if(Test-Path -LiteralPath $PackageDir) { Remove-Item -LiteralPath $PackageDir -Recurse -Force }
New-Item -ItemType Directory -Path (Join-Path $PackageDir "configs") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $PackageDir "reports_here") -Force | Out-Null

$liquidityBalanced = @{
   InpUseLiquidityAwareStructureStop = "true"
   InpLiquidityStopLookbackBars = "22"
   InpLiquidityStopBufferATR = "0.18"
   InpLiquidityStopBufferPoints = "35.0"
   InpLiquidityStopUseEqualLevels = "true"
   InpLiquidityStopUseLastSweep = "true"
   InpLiquidityStopUsePreviousDay = "true"
   InpLiquidityStopUsePreviousWeek = "false"
   InpLiquidityStopUsePreviousMonth = "false"
   InpLiquidityStopAllowWiderMaxATR = "true"
   InpLiquidityStopMaxATRMultiplier = "5.20"
}

$liquidityClusterPocket = @{
   InpUseLiquidityClusterStopExtension = "true"
   InpLiquidityClusterMinTouches = "3"
   InpLiquidityClusterProximityATR = "0.22"
   InpLiquidityClusterProximityPoints = "60.0"
   InpLiquidityClusterExtraBufferATR = "0.12"
   InpLiquidityClusterExtraBufferPoints = "35.0"
   InpUseLiquidityPocketStopShift = "true"
   InpLiquidityPocketLookbackBars = "24"
   InpLiquidityPocketProximityATR = "0.18"
   InpLiquidityPocketProximityPoints = "45.0"
   InpLiquidityPocketBufferATR = "0.22"
   InpLiquidityPocketBufferPoints = "55.0"
}

$conflictGuard = @{
   InpUseLiquidityStopConflictGuard = "true"
   InpLiquidityStopConflictLookbackBars = "24"
   InpLiquidityStopConflictMinTouches = "3"
   InpLiquidityStopConflictProximityATR = "0.16"
   InpLiquidityStopConflictProximityPoints = "45.0"
   InpLiquidityStopConflictBypassQualityScore = "15"
}

$profiles = @(
   [pscustomobject]@{ Name = "base_mfe_aug"; Overrides = @{} },
   [pscustomobject]@{ Name = "liq_balanced"; Overrides = $liquidityBalanced },
   [pscustomobject]@{ Name = "liq_cluster_pocket"; Overrides = $liquidityClusterPocket },
   [pscustomobject]@{ Name = "liq_balanced_cluster"; Overrides = Merge-Overrides @($liquidityBalanced, $liquidityClusterPocket) },
   [pscustomobject]@{ Name = "liq_conflict_guard"; Overrides = $conflictGuard },
   [pscustomobject]@{ Name = "liq_full_guarded"; Overrides = Merge-Overrides @($liquidityBalanced, $liquidityClusterPocket, $conflictGuard) }
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
      $reportName = "current_best_liquidity_structure_stop_model0_{0}_{1}" -f $profile.Name, $window.Window
      Write-SeasonalTesterConfig -Path (Join-Path $PackageDir "configs\$configName") -ReportRoot $ReportRoot -ReportName $reportName -From $window.From -To $window.To -Inputs $inputs -Model 0
      $expected.Add([pscustomobject]@{
         Rank = $rank; Profile = $profile.Name; Phase = $window.Phase; Set = $window.Set; Window = $window.Window;
         From = $window.From; To = $window.To; Config = "configs\$configName"; ExpectedReportName = $reportName
      }) | Out-Null
   }
}

$expected | Export-Csv -LiteralPath (Join-Path $PackageDir "EXPECTED_REPORTS.csv") -NoTypeInformation
$expected | Export-Csv -LiteralPath "outputs\CURRENT_BEST_LIQUIDITY_STRUCTURE_STOP_MODEL0_MANIFEST.csv" -NoTypeInformation
"Built $rank current-best liquidity-structure-stop Model 0 configs in $PackageDir"
