param(
   [string]$PackageDir = "work\local_mt5_current_best_spread_stress_package",
   [string]$ReportRoot = "outputs",
   [string]$BaseSetPath = "outputs\CANDIDATE_PRIMARY_AUG20_MICRO_JULOCT_PROFILE.set",
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
   [pscustomobject]@{ Window = "2025_08_09"; Phase = "target"; Set = "target"; From = "2025.08.01"; To = "2025.09.30" },
   [pscustomobject]@{ Window = "2024_08_09"; Phase = "target"; Set = "target"; From = "2024.08.01"; To = "2024.09.30" },
   [pscustomobject]@{ Window = "2026_06"; Phase = "guard"; Set = "guard"; From = "2026.06.01"; To = "2026.06.30" }
)

if(Test-Path -LiteralPath $PackageDir) { Remove-Item -LiteralPath $PackageDir -Recurse -Force }
New-Item -ItemType Directory -Path (Join-Path $PackageDir "configs") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $PackageDir "reports_here") -Force | Out-Null

$strictMaxSpread = @{
   InpMaxSpreadPoints = "220"
   InpMaxSpreadATRPercent = "12.0"
   InpUseMonthSpreadCaps = "true"
   InpMarchMaxSpreadPoints = "170.0"
   InpMayMaxSpreadPoints = "17.0"
   InpJulyMaxSpreadPoints = "170.0"
   InpAugustMaxSpreadPoints = "170.0"
   InpOctoberMaxSpreadPoints = "170.0"
}

$regimeGuard = Merge-Overrides @($strictMaxSpread, @{
   InpUseSpreadRegimeGuard = "true"
   InpSpreadRegimeLookbackBars = "24"
   InpMaxSpreadRegimeRatio = "1.55"
   InpMinSpreadRegimePoints = "35.0"
})

$shockGuard = Merge-Overrides @($strictMaxSpread, @{
   InpUseM1SpreadShockGuard = "true"
   InpM1SpreadShockLookbackBars = "30"
   InpM1SpreadShockMaxRatio = "1.80"
   InpM1SpreadShockMinPoints = "35.0"
})

$rrGuard = Merge-Overrides @($strictMaxSpread, @{
   InpUseSpreadAdjustedRRFilter = "true"
   InpMinSpreadAdjustedRR = "1.25"
})

$profiles = @(
   [pscustomobject]@{ Name = "primary_aug20"; Overrides = @{} },
   [pscustomobject]@{ Name = "aug20_maxspread220"; Overrides = $strictMaxSpread },
   [pscustomobject]@{ Name = "aug20_regime155"; Overrides = $regimeGuard },
   [pscustomobject]@{ Name = "aug20_shock180"; Overrides = $shockGuard },
   [pscustomobject]@{ Name = "aug20_spread_rr125"; Overrides = $rrGuard }
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
      $reportName = "current_best_spread_stress_{0}_{1}" -f $profile.Name, $window.Window
      Write-SeasonalTesterConfig -Path (Join-Path $PackageDir "configs\$configName") -ReportRoot $ReportRoot -ReportName $reportName -From $window.From -To $window.To -Inputs $inputs -Model $Model
      $expected.Add([pscustomobject]@{
         Rank = $rank; Profile = $profile.Name; Phase = $window.Phase; Set = $window.Set; Window = $window.Window;
         From = $window.From; To = $window.To; Config = "configs\$configName"; ExpectedReportName = $reportName
      }) | Out-Null
   }
}

$expected | Export-Csv -LiteralPath (Join-Path $PackageDir "EXPECTED_REPORTS.csv") -NoTypeInformation
$expected | Export-Csv -LiteralPath "outputs\CURRENT_BEST_SPREAD_STRESS_MANIFEST.csv" -NoTypeInformation
"Built $rank current-best spread stress configs in $PackageDir"
