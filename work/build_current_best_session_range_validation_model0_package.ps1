param(
   [string]$PackageDir = "work\local_mt5_current_best_session_range_validation_model0_package",
   [string]$ReportRoot = "outputs",
   [string]$BaseSetPath = "outputs\CANDIDATE_PRIMARY_AUG40_REVERSE_OFF_FSD_STRICT_MFE_AUGUST_ONLY_MICRO_R035_PROFILE.set"
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

$sessionStrictMicro = @{
   InpUseSessionImpulseLane = "true"
   InpSessionImpulseMinScore = "12"
   InpSessionImpulseStandaloneMinScore = "13"
   InpSessionImpulseMinADX = "27.0"
   InpSessionImpulseRequireLiquidSession = "true"
   InpSessionImpulseRequireSessionBreak = "true"
   InpSessionImpulseRequireExecution = "true"
   InpSessionImpulseRequireOrderFlow = "true"
   InpSessionImpulseRiskMultiplier = "0.15"
   InpSessionImpulseTPMultiplier = "1.25"
   InpSessionImpulseMinBodyPercent = "52.0"
   InpSessionImpulseMinRangeATR = "0.75"
   InpSessionImpulseMinCloseLocation = "0.76"
   InpAllowFlatMonthMomentumOutsideMonthFilter = "false"
   InpUseSessionImpulseFailureExit = "true"
   InpSessionImpulseFailureBars = "3"
   InpSessionImpulseFailureMinMFER = "0.18"
   InpSessionImpulseFailureMaxCurrentR = "-0.04"
}

$sessionStrictNoOrderFlow = @{
   InpUseSessionImpulseLane = "true"
   InpSessionImpulseMinScore = "12"
   InpSessionImpulseStandaloneMinScore = "13"
   InpSessionImpulseMinADX = "29.0"
   InpSessionImpulseRequireLiquidSession = "true"
   InpSessionImpulseRequireSessionBreak = "true"
   InpSessionImpulseRequireExecution = "true"
   InpSessionImpulseRequireOrderFlow = "false"
   InpSessionImpulseRiskMultiplier = "0.12"
   InpSessionImpulseTPMultiplier = "1.20"
   InpSessionImpulseMinBodyPercent = "56.0"
   InpSessionImpulseMinRangeATR = "0.85"
   InpSessionImpulseMinCloseLocation = "0.78"
   InpAllowFlatMonthMomentumOutsideMonthFilter = "false"
   InpUseSessionImpulseFailureExit = "true"
   InpSessionImpulseFailureBars = "3"
   InpSessionImpulseFailureMinMFER = "0.16"
   InpSessionImpulseFailureMaxCurrentR = "-0.04"
}

$rangeEliteMicro = @{
   InpUseRangeReversionOpportunity = "true"
   InpRangeReversionMinScore = "9"
   InpWeightRangeReversionOpportunity = "2"
   InpRangeReversionStandaloneEntry = "true"
   InpRangeReversionMaxADX = "20.0"
   InpRangeReversionMinWickPercent = "42.0"
   InpRangeReversionMinCloseLocation = "0.66"
   InpRangeReversionMinRangeATR = "0.42"
   InpRangeReversionRequireVWAPMagnet = "true"
   InpRangeReversionMaxVWAPDistanceATR = "1.05"
   InpRangeReversionRequireOrderFlow = "true"
   InpRangeReversionUseStructuralStop = "true"
   InpRangeReversionStopBufferATR = "0.08"
   InpRangeReversionStopBufferPoints = "18.0"
   InpRangeReversionUseMeanTarget = "true"
   InpRangeReversionFallbackTPATR = "0.85"
   InpRangeReversionMinRR = "0.85"
   InpRangeReversionUseCustomEliteGate = "true"
   InpRangeReversionEliteMinConfirmations = "3"
   InpRangeReversionEliteMinQualityScore = "7"
}

$profiles = @(
   [pscustomobject]@{ Name = "base_micro_r035"; Overrides = @{} },
   [pscustomobject]@{ Name = "session_strict_micro"; Overrides = $sessionStrictMicro },
   [pscustomobject]@{ Name = "session_no_of_micro"; Overrides = $sessionStrictNoOrderFlow },
   [pscustomobject]@{ Name = "range_elite_micro"; Overrides = $rangeEliteMicro }
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
      foreach($entry in $profile.Overrides.GetEnumerator()) {
         Set-InputLine -Inputs $inputs -Name $entry.Key -Value ([string]$entry.Value)
      }

      $configName = "{0:000}_{1}_{2}.ini" -f $rank, $profile.Name, $window.Window
      $reportName = "current_best_session_range_validation_model0_{0}_{1}" -f $profile.Name, $window.Window
      Write-SeasonalTesterConfig -Path (Join-Path $PackageDir "configs\$configName") -ReportRoot $ReportRoot -ReportName $reportName -From $window.From -To $window.To -Inputs $inputs -Model 0
      $expected.Add([pscustomobject]@{
         Rank = $rank; Profile = $profile.Name; Phase = $window.Phase; Set = $window.Set; Window = $window.Window;
         From = $window.From; To = $window.To; Config = "configs\$configName"; ExpectedReportName = $reportName
      }) | Out-Null
   }
}

$expected | Export-Csv -LiteralPath (Join-Path $PackageDir "EXPECTED_REPORTS.csv") -NoTypeInformation
$expected | Export-Csv -LiteralPath "outputs\CURRENT_BEST_SESSION_RANGE_VALIDATION_MODEL0_MANIFEST.csv" -NoTypeInformation
"Built $rank current-best session/range validation Model 0 configs in $PackageDir"
