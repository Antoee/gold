param(
   [string]$PackageDir = "work\local_mt5_current_best_dormant_month_rescue_package",
   [string]$ReportRoot = "outputs",
   [string]$BaseSetPath = "outputs\CANDIDATE_PRIMARY_AUG40_REVERSE_OFF_FSD_STRICT_MICRO_JULOCT_PROFILE.set",
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
   [pscustomobject]@{ Window = "2025_01"; Phase = "target"; Set = "target"; From = "2025.01.01"; To = "2025.01.31" },
   [pscustomobject]@{ Window = "2025_04"; Phase = "target"; Set = "target"; From = "2025.04.01"; To = "2025.04.30" },
   [pscustomobject]@{ Window = "2025_06"; Phase = "target"; Set = "target"; From = "2025.06.01"; To = "2025.06.30" },
   [pscustomobject]@{ Window = "2026_01"; Phase = "target"; Set = "target"; From = "2026.01.01"; To = "2026.01.31" },
   [pscustomobject]@{ Window = "2024_01"; Phase = "guard"; Set = "guard"; From = "2024.01.01"; To = "2024.01.31" },
   [pscustomobject]@{ Window = "2024_04"; Phase = "guard"; Set = "guard"; From = "2024.04.01"; To = "2024.04.30" },
   [pscustomobject]@{ Window = "2024_06"; Phase = "guard"; Set = "guard"; From = "2024.06.01"; To = "2024.06.30" }
)

if(Test-Path -LiteralPath $PackageDir) { Remove-Item -LiteralPath $PackageDir -Recurse -Force }
New-Item -ItemType Directory -Path (Join-Path $PackageDir "configs") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $PackageDir "reports_here") -Force | Out-Null

$dormantMonthFilter = @{
   InpFlatMonthMicroReversionStandaloneActive = "true"
   InpUseFlatMonthMicroReversionMonthFilter = "true"
   InpFlatMicroRevTradeJanuary = "true"
   InpFlatMicroRevTradeFebruary = "false"
   InpFlatMicroRevTradeMarch = "false"
   InpFlatMicroRevTradeApril = "true"
   InpFlatMicroRevTradeMay = "false"
   InpFlatMicroRevTradeJune = "true"
   InpFlatMicroRevTradeJuly = "true"
   InpFlatMicroRevTradeAugust = "false"
   InpFlatMicroRevTradeSeptember = "false"
   InpFlatMicroRevTradeOctober = "true"
   InpFlatMicroRevTradeNovember = "false"
   InpFlatMicroRevTradeDecember = "false"
}

$fmrStrict = Merge-Overrides @($dormantMonthFilter, @{
   InpUseFlatMonthMicroReversionLane = "true"
   InpFlatMonthMicroReversionRiskMultiplier = "0.14"
   InpFlatMonthMicroReversionMaxMonthlyEntries = "2"
   InpFlatMonthMicroReversionSpacingMinutes = "360"
   InpFlatMonthMicroReversionMaxADX = "18.0"
   InpFlatMonthMicroReversionMinWickPercent = "42.0"
   InpFlatMonthMicroReversionMinCloseLocation = "0.64"
   InpFlatMonthMicroReversionMinRangeATR = "0.45"
   InpFlatMonthMicroReversionRequireLiquidity = "true"
   InpFlatMonthMicroReversionRequireVWAP = "true"
   InpFlatMonthMicroReversionMaxVWAPDistanceATR = "1.00"
   InpFlatMonthMicroReversionStopBufferATR = "0.16"
   InpFlatMonthMicroReversionStopBufferPoints = "35.0"
   InpFlatMonthMicroReversionFallbackTPATR = "0.85"
   InpFlatMonthMicroReversionMinRR = "0.90"
})

$fmrProbe = Merge-Overrides @($fmrStrict, @{
   InpFlatMonthMicroReversionRiskMultiplier = "0.10"
   InpFlatMonthMicroReversionMaxADX = "20.0"
   InpFlatMonthMicroReversionMinWickPercent = "36.0"
   InpFlatMonthMicroReversionMinCloseLocation = "0.60"
   InpFlatMonthMicroReversionMinRangeATR = "0.35"
   InpFlatMonthMicroReversionRequireVWAP = "true"
   InpFlatMonthMicroReversionMaxVWAPDistanceATR = "1.20"
   InpFlatMonthMicroReversionMinRR = "0.80"
})

$fmrProbeNoApril = Merge-Overrides @($fmrProbe, @{
   InpFlatMicroRevTradeApril = "false"
})

$fmrNoVwap = Merge-Overrides @($fmrStrict, @{
   InpFlatMonthMicroReversionRiskMultiplier = "0.08"
   InpFlatMonthMicroReversionRequireVWAP = "false"
   InpFlatMonthMicroReversionMaxADX = "16.0"
   InpFlatMonthMicroReversionMinWickPercent = "46.0"
   InpFlatMonthMicroReversionMinCloseLocation = "0.68"
})

$fsdRelaxed = @{
   InpFlatMonthStructuralDisplacementRiskMultiplier = "0.12"
   InpFlatMonthStructuralDisplacementMaxMonthlyEntries = "2"
   InpFlatMonthStructuralDisplacementSpacingMinutes = "720"
   InpFlatMonthStructuralDisplacementMinScore = "7"
   InpFlatMonthStructuralDisplacementMinRangeATR = "0.55"
   InpFlatMonthStructuralDisplacementMinBodyPercent = "46.0"
   InpFlatMonthStructuralDisplacementMaxOppositeWickPercent = "36.0"
   InpFlatMonthStructuralDisplacementRequireOrderFlow = "false"
   InpFlatMonthStructuralDisplacementMinClearanceATR = "1.25"
}

$combo = Merge-Overrides @($fmrProbe, $fsdRelaxed)

$profiles = @(
   [pscustomobject]@{ Name = "base"; Overrides = @{} },
   [pscustomobject]@{ Name = "dormant_fmr_strict"; Overrides = $fmrStrict },
   [pscustomobject]@{ Name = "dormant_fmr_probe"; Overrides = $fmrProbe },
   [pscustomobject]@{ Name = "dormant_fmr_probe_no_april"; Overrides = $fmrProbeNoApril },
   [pscustomobject]@{ Name = "dormant_fmr_no_vwap"; Overrides = $fmrNoVwap },
   [pscustomobject]@{ Name = "dormant_fsd_relaxed"; Overrides = $fsdRelaxed },
   [pscustomobject]@{ Name = "dormant_combo"; Overrides = $combo }
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
      $reportName = "current_best_dormant_rescue_{0}_{1}" -f $profile.Name, $window.Window
      Write-SeasonalTesterConfig -Path (Join-Path $PackageDir "configs\$configName") -ReportRoot $ReportRoot -ReportName $reportName -From $window.From -To $window.To -Inputs $inputs -Model $Model
      $expected.Add([pscustomobject]@{
         Rank = $rank; Profile = $profile.Name; Phase = $window.Phase; Set = $window.Set; Window = $window.Window;
         From = $window.From; To = $window.To; Config = "configs\$configName"; ExpectedReportName = $reportName
      }) | Out-Null
   }
}

$expected | Export-Csv -LiteralPath (Join-Path $PackageDir "EXPECTED_REPORTS.csv") -NoTypeInformation
$expected | Export-Csv -LiteralPath "outputs\CURRENT_BEST_DORMANT_MONTH_RESCUE_MANIFEST.csv" -NoTypeInformation
"Built $rank current-best dormant month rescue configs in $PackageDir"
