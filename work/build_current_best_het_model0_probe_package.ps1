param(
   [string]$PackageDir = "work\local_mt5_current_best_het_model0_probe_package",
   [string]$ReportRoot = "outputs",
   [string]$BaseSetPath = "outputs\CANDIDATE_PRIMARY_AUG40_REVERSE_OFF_FSD_STRICT_MICRO_JULOCT_PROFILE.set"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "seasonal_gate_helpers.ps1")

$windows = @(
   [pscustomobject]@{ Window = "2024_to_2026"; Phase = "full"; Set = "full"; From = "2024.01.01"; To = "2026.07.02" },
   [pscustomobject]@{ Window = "2024_03"; Phase = "engine"; Set = "engine"; From = "2024.03.01"; To = "2024.03.31" },
   [pscustomobject]@{ Window = "2025_03"; Phase = "engine"; Set = "engine"; From = "2025.03.01"; To = "2025.03.31" },
   [pscustomobject]@{ Window = "2026_03"; Phase = "engine"; Set = "engine"; From = "2026.03.01"; To = "2026.03.31" },
   [pscustomobject]@{ Window = "2024_05"; Phase = "engine"; Set = "engine"; From = "2024.05.01"; To = "2024.05.31" },
   [pscustomobject]@{ Window = "2026_05"; Phase = "engine"; Set = "engine"; From = "2026.05.01"; To = "2026.05.31" },
   [pscustomobject]@{ Window = "2025_04"; Phase = "flat_guard"; Set = "guard"; From = "2025.04.01"; To = "2025.04.30" },
   [pscustomobject]@{ Window = "2026_01"; Phase = "flat_guard"; Set = "guard"; From = "2026.01.01"; To = "2026.01.31" }
)

if(Test-Path -LiteralPath $PackageDir) { Remove-Item -LiteralPath $PackageDir -Recurse -Force }
New-Item -ItemType Directory -Path (Join-Path $PackageDir "configs") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $PackageDir "reports_here") -Force | Out-Null

function New-HetProfile {
   param(
      [string]$Mode = "1",
      [string]$MinScore = "8",
      [string]$Risk = "0.30",
      [string]$MaxEntries = "3",
      [string]$Spacing = "360",
      [string]$StopATR = "1.15",
      [string]$TakeProfitATR = "2.60",
      [string]$MinRR = "1.40",
      [string]$AllowFlatBypass = "false"
   )

   return @{
      InpUseHighEfficiencyTrendLane = "true"
      InpHighEfficiencyTrendMode = $Mode
      InpHighEfficiencyTrendMinScore = $MinScore
      InpHighEfficiencyTrendRiskMultiplier = $Risk
      InpHighEfficiencyTrendMaxMonthlyEntries = $MaxEntries
      InpHighEfficiencyTrendSpacingMinutes = $Spacing
      InpHighEfficiencyTrendStopATRMultiplier = $StopATR
      InpHighEfficiencyTrendTakeProfitATRMultiplier = $TakeProfitATR
      InpHighEfficiencyTrendMinRR = $MinRR
      InpAllowFlatMonthMomentumOutsideMonthFilter = $AllowFlatBypass
   }
}

$profiles = @(
   [pscustomobject]@{ Name = "het_engine_strict"; Overrides = New-HetProfile -Mode "3" -MinScore "8" -Risk "0.25" -MaxEntries "2" -Spacing "480" -StopATR "1.10" -TakeProfitATR "2.80" -MinRR "1.55" },
   [pscustomobject]@{ Name = "het_engine_mid"; Overrides = New-HetProfile -Mode "1" -MinScore "7" -Risk "0.35" -MaxEntries "3" -Spacing "360" -StopATR "1.15" -TakeProfitATR "2.60" -MinRR "1.40" },
   [pscustomobject]@{ Name = "het_flat_strict"; Overrides = New-HetProfile -Mode "3" -MinScore "8" -Risk "0.20" -MaxEntries "2" -Spacing "720" -StopATR "1.10" -TakeProfitATR "2.80" -MinRR "1.55" -AllowFlatBypass "true" },
   [pscustomobject]@{ Name = "base"; Overrides = @{} }
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
      $reportName = "current_best_het_model0_probe_{0}_{1}" -f $profile.Name, $window.Window
      Write-SeasonalTesterConfig -Path (Join-Path $PackageDir "configs\$configName") -ReportRoot $ReportRoot -ReportName $reportName -From $window.From -To $window.To -Inputs $inputs -Model 0
      $expected.Add([pscustomobject]@{
         Rank = $rank; Profile = $profile.Name; Phase = $window.Phase; Set = $window.Set; Window = $window.Window;
         From = $window.From; To = $window.To; Config = "configs\$configName"; ExpectedReportName = $reportName
      }) | Out-Null
   }
}

$expected | Export-Csv -LiteralPath (Join-Path $PackageDir "EXPECTED_REPORTS.csv") -NoTypeInformation
$expected | Export-Csv -LiteralPath "outputs\CURRENT_BEST_HET_MODEL0_PROBE_MANIFEST.csv" -NoTypeInformation
"Built $rank HET Model 0 probe configs in $PackageDir"
