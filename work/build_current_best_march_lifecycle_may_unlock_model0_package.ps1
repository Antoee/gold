param(
   [string]$PackageDir = "work\local_mt5_current_best_march_lifecycle_may_unlock_model0_package",
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
   [pscustomobject]@{ Window = "2025_mar_to_may"; Phase = "path"; Set = "path"; From = "2025.03.01"; To = "2025.05.31" },
   [pscustomobject]@{ Window = "2025_may"; Phase = "target"; Set = "target"; From = "2025.05.01"; To = "2025.05.31" },
   [pscustomobject]@{ Window = "2024_03"; Phase = "engine"; Set = "engine"; From = "2024.03.01"; To = "2024.03.31" },
   [pscustomobject]@{ Window = "2025_03"; Phase = "engine"; Set = "engine"; From = "2025.03.01"; To = "2025.03.31" },
   [pscustomobject]@{ Window = "2026_03"; Phase = "engine"; Set = "engine"; From = "2026.03.01"; To = "2026.03.31" },
   [pscustomobject]@{ Window = "2024_05"; Phase = "engine"; Set = "engine"; From = "2024.05.01"; To = "2024.05.31" },
   [pscustomobject]@{ Window = "2026_05"; Phase = "engine"; Set = "engine"; From = "2026.05.01"; To = "2026.05.31" }
)

$mayWindowR280 = @{
   InpUseMonthDayWindowFilter = "true"
   InpMayMinDay = "1"
   InpMayMaxDay = "31"
   InpUseMonthRiskMultipliers = "true"
   InpMayRiskMultiplier = "2.80"
   InpMayDayRiskMultiplier = "2.80"
}

$marchMfeLock = @{
   InpUseMFEProfitLockStop = "true"
   InpUseMFEProfitLockMonthFilter = "true"
   InpMFEProfitLockTradeMarch = "true"
   InpMFEProfitLockTradeMay = "false"
   InpMFEProfitLockTradeAugust = "true"
   InpMFEProfitLockStartR = "1.35"
   InpMFEProfitLockGivebackR = "0.75"
   InpMFEProfitLockMinR = "0.25"
}

$marchMfeLockLoose = @{
   InpUseMFEProfitLockStop = "true"
   InpUseMFEProfitLockMonthFilter = "true"
   InpMFEProfitLockTradeMarch = "true"
   InpMFEProfitLockTradeMay = "false"
   InpMFEProfitLockTradeAugust = "true"
   InpMFEProfitLockStartR = "1.60"
   InpMFEProfitLockGivebackR = "1.10"
   InpMFEProfitLockMinR = "0.25"
}

$marchRPartial = @{
   InpUseRPartialProfitLock = "true"
   InpUseRPartialProfitLockMonthFilter = "true"
   InpRPartialProfitLockTradeMarch = "true"
   InpRPartialProfitLockTradeMay = "false"
   InpRPartialProfitLockTradeAugust = "false"
   InpRPartialProfitLockAtR = "1.00"
   InpRPartialProfitLockPercent = "25.0"
   InpRPartialProfitLockMoveStop = "true"
   InpRPartialProfitLockStopR = "0.10"
}

$stagnationExit = @{
   InpUseStagnationExit = "true"
   InpStagnationExitBars = "48"
   InpStagnationExitMaxR = "0.20"
}

$noFollowExit = @{
   InpUseNoFollowThroughExit = "true"
   InpNoFollowThroughBars = "6"
   InpNoFollowThroughMinMFER = "0.25"
}

$profiles = @(
   [pscustomobject]@{ Name = "base_mfe_aug"; Overrides = @{} },
   [pscustomobject]@{ Name = "may_window_r280"; Overrides = $mayWindowR280 },
   [pscustomobject]@{ Name = "may_march_mfe_lock"; Overrides = Merge-Overrides @($mayWindowR280, $marchMfeLock) },
   [pscustomobject]@{ Name = "may_march_mfe_lock_loose"; Overrides = Merge-Overrides @($mayWindowR280, $marchMfeLockLoose) },
   [pscustomobject]@{ Name = "may_march_rpartial"; Overrides = Merge-Overrides @($mayWindowR280, $marchRPartial) },
   [pscustomobject]@{ Name = "may_stagnation_exit"; Overrides = Merge-Overrides @($mayWindowR280, $stagnationExit) },
   [pscustomobject]@{ Name = "may_no_follow_exit"; Overrides = Merge-Overrides @($mayWindowR280, $noFollowExit) }
)

if($ProfileNames.Count -gt 0) {
   $wanted = @{}
   foreach($name in $ProfileNames) { $wanted[$name] = $true }
   $profiles = @($profiles | Where-Object { $wanted.ContainsKey($_.Name) })
   if($profiles.Count -le 0) { throw "No matching profiles selected: $($ProfileNames -join ', ')" }
}

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
      foreach($entry in $profile.Overrides.GetEnumerator()) {
         Set-InputLine -Inputs $inputs -Name $entry.Key -Value ([string]$entry.Value)
      }

      $configName = "{0:000}_{1}_{2}.ini" -f $rank, $profile.Name, $window.Window
      $reportName = "current_best_march_lifecycle_may_unlock_model0_{0}_{1}" -f $profile.Name, $window.Window
      Write-SeasonalTesterConfig -Path (Join-Path $PackageDir "configs\$configName") -ReportRoot $ReportRoot -ReportName $reportName -From $window.From -To $window.To -Inputs $inputs -Model 0
      $expected.Add([pscustomobject]@{
         Rank = $rank; Profile = $profile.Name; Phase = $window.Phase; Set = $window.Set; Window = $window.Window;
         From = $window.From; To = $window.To; Config = "configs\$configName"; ExpectedReportName = $reportName
      }) | Out-Null
   }
}

$expected | Export-Csv -LiteralPath (Join-Path $PackageDir "EXPECTED_REPORTS.csv") -NoTypeInformation
$expected | Export-Csv -LiteralPath "outputs\CURRENT_BEST_MARCH_LIFECYCLE_MAY_UNLOCK_MODEL0_MANIFEST.csv" -NoTypeInformation
"Built $rank current-best March lifecycle May-unlock Model 0 configs in $PackageDir"
