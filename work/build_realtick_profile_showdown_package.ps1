param(
   [string]$PackageDir = "outputs\realtick_profile_showdown_package",
   [string]$ReportRoot = "outputs",
   [string[]]$ProfileNames = @()
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "seasonal_gate_helpers.ps1")

$windows = @(
   [pscustomobject]@{ Window = "continuous_2024_2026"; Phase = "full"; Set = "full"; From = "2024.01.01"; To = "2026.07.12" },
   [pscustomobject]@{ Window = "full2024"; Phase = "train"; Set = "train"; From = "2024.01.01"; To = "2024.12.31" },
   [pscustomobject]@{ Window = "full2025"; Phase = "oos"; Set = "oos"; From = "2025.01.01"; To = "2025.12.31" },
   [pscustomobject]@{ Window = "ytd2026"; Phase = "recent"; Set = "recent"; From = "2026.01.01"; To = "2026.07.12" },
   [pscustomobject]@{ Window = "q4_2024"; Phase = "weak"; Set = "weak"; From = "2024.10.01"; To = "2024.12.31" },
   [pscustomobject]@{ Window = "q4_2025"; Phase = "weak"; Set = "weak"; From = "2025.10.01"; To = "2025.12.31" }
)

$profiles = @(
   [pscustomobject]@{
      Name = "no_m1shock"
      SetPath = "outputs\CANDIDATE_PRIMARY_RANGE_ELITE_MFE_FAILURE_MARCH_ISLP_JUN_OCTDEC_SCORE7_REGIME_NO_M1SHOCK_PROFILE.set"
   },
   [pscustomobject]@{
      Name = "may235"
      SetPath = "outputs\CANDIDATE_LIQUIDITY_STOP_CONFLICT_MARCH_MAY235_PROFILE.set"
   },
   [pscustomobject]@{
      Name = "conflict_march"
      SetPath = "outputs\CANDIDATE_LIQUIDITY_STOP_CONFLICT_MARCH_PROFILE.set"
   },
   [pscustomobject]@{
      Name = "stable_mar1_may225"
      SetPath = "outputs\CANDIDATE_SEASONAL_MAR1_MAY225_PROFILE.set"
   }
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
      $inputs = Import-SetInputs $profile.SetPath
      Set-InputLine -Inputs $inputs -Name "InpAllowedSymbol" -Value "XAUUSD"
      Set-InputLine -Inputs $inputs -Name "InpSignalTimeframe" -Value "15"
      Set-InputLine -Inputs $inputs -Name "InpShowDashboard" -Value "false"
      Set-InputLine -Inputs $inputs -Name "InpDashboardInTester" -Value "false"
      Set-InputLine -Inputs $inputs -Name "InpLogLevel" -Value "0"

      $configName = "{0:000}_{1}_{2}.ini" -f $rank, $profile.Name, $window.Window
      $reportName = "realtick_profile_showdown_{0}_{1}" -f $profile.Name, $window.Window
      Write-SeasonalTesterConfig -Path (Join-Path $PackageDir "configs\$configName") -ReportRoot $ReportRoot -ReportName $reportName -From $window.From -To $window.To -Inputs $inputs -Model 4

      $expected.Add([pscustomobject]@{
         Rank = $rank
         Profile = $profile.Name
         Phase = $window.Phase
         Set = $window.Set
         Window = $window.Window
         From = $window.From
         To = $window.To
         Config = "configs\$configName"
         ExpectedReportName = $reportName
         Model = 4
         SourceSet = $profile.SetPath
      }) | Out-Null
   }
}

$manifestPath = Join-Path $PackageDir "EXPECTED_REPORTS.csv"
$expected | Export-Csv -LiteralPath $manifestPath -NoTypeInformation
$expected | Export-Csv -LiteralPath "outputs\REALTICK_PROFILE_SHOWDOWN_MANIFEST.csv" -NoTypeInformation
"Built $rank real-tick profile showdown configs in $PackageDir"
