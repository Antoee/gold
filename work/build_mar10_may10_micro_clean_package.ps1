param(
   [string]$PackageDir = "work\local_mt5_mar10_may10_micro_clean_package",
   [string]$ReportRoot = "outputs",
   [string]$BaseSetPath = "outputs\CANDIDATE_MAR10_MAY10_CONTINUOUS_PROFILE.set",
   [int]$Model = 0,
   [string[]]$ProfileNames = @(),
   [switch]$Monthly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "seasonal_gate_helpers.ps1")

if($Monthly) {
   $windows = @()
   foreach($year in 2024..2026) {
      foreach($month in 1..12) {
         if($year -eq 2026 -and $month -gt 6) { continue }
         $from = "{0}.{1:00}.01" -f $year, $month
         $to = "{0}.{1:00}.{2:00}" -f $year, $month, [DateTime]::DaysInMonth($year, $month)
         $windows += [pscustomobject]@{ Window = "{0}_{1:00}" -f $year, $month; Phase = "monthly"; Set = "monthly"; From = $from; To = $to }
      }
   }
}
else {
   $windows = @(
      [pscustomobject]@{ Window = "2024_to_2026"; Phase = "full"; Set = "full"; From = "2024.01.01"; To = "2026.07.02" },
      [pscustomobject]@{ Window = "2026_ytd"; Phase = "recent"; Set = "recent"; From = "2026.01.01"; To = "2026.07.02" },
      [pscustomobject]@{ Window = "2025_full"; Phase = "oos"; Set = "oos"; From = "2025.01.01"; To = "2025.12.31" },
      [pscustomobject]@{ Window = "2024_full"; Phase = "train"; Set = "train"; From = "2024.01.01"; To = "2024.12.31" },
      [pscustomobject]@{ Window = "2025_07_10"; Phase = "target"; Set = "target"; From = "2025.07.01"; To = "2025.10.31" },
      [pscustomobject]@{ Window = "2024_07_10"; Phase = "target"; Set = "target"; From = "2024.07.01"; To = "2024.10.31" },
      [pscustomobject]@{ Window = "2025_08_09"; Phase = "target"; Set = "target"; From = "2025.08.01"; To = "2025.09.30" },
      [pscustomobject]@{ Window = "2024_08_09"; Phase = "target"; Set = "target"; From = "2024.08.01"; To = "2024.09.30" },
      [pscustomobject]@{ Window = "2026_01"; Phase = "target"; Set = "target"; From = "2026.01.01"; To = "2026.01.31" }
   )
}

if(Test-Path -LiteralPath $PackageDir) { Remove-Item -LiteralPath $PackageDir -Recurse -Force }
New-Item -ItemType Directory -Path (Join-Path $PackageDir "configs") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $PackageDir "reports_here") -Force | Out-Null

$microClean = @{
   InpAllowFlatMonthProbesOutsideMonthFilter = "true"
   InpUseFlatMonthMicroReversionLane = "true"
   InpFlatMonthMicroReversionRiskMultiplier = "0.25"
   InpFlatMonthMicroReversionMaxMonthlyEntries = "4"
   InpFlatMonthMicroReversionSpacingMinutes = "180"
   InpFlatMonthMicroReversionMaxADX = "21.0"
   InpFlatMonthMicroReversionMinWickPercent = "34.0"
   InpFlatMonthMicroReversionRequireLiquidity = "true"
   InpFlatMonthMicroReversionRequireVWAP = "true"
   InpUseFlatMonthOpportunityMode = "true"
   InpFlatMonthMaxEntryCount = "5"
   InpFlatMonthMaxProfitPercent = "0.75"
   InpFlatMonthMinDayOfMonth = "5"
   InpFlatMonthRequireNoMonthlyLoss = "true"
   InpFlatMonthTargetPercent = "2.00"
   InpUseFlatMonthProbeFailureExit = "true"
   InpFlatMonthProbeFailureBars = "4"
   InpFlatMonthProbeFailureMaxCurrentR = "-0.06"
   InpFlatMonthProbeFailureMinMFER = "0.12"
}

$microCleanJulOct = Merge-Overrides @($microClean, @{
   InpUseFlatMonthProbeMonthFilter = "true"
   InpFlatProbeTradeJanuary = "false"
   InpFlatProbeTradeFebruary = "false"
   InpFlatProbeTradeMarch = "false"
   InpFlatProbeTradeApril = "false"
   InpFlatProbeTradeMay = "false"
   InpFlatProbeTradeJune = "false"
   InpFlatProbeTradeJuly = "true"
   InpFlatProbeTradeAugust = "false"
   InpFlatProbeTradeSeptember = "false"
   InpFlatProbeTradeOctober = "true"
   InpFlatProbeTradeNovember = "false"
   InpFlatProbeTradeDecember = "false"
})

$microCleanCoreJulOct = Merge-Overrides @($microCleanJulOct, @{
   InpFlatProbeTradeMarch = "true"
   InpFlatProbeTradeMay = "true"
})

$microDedicatedJulOct = Merge-Overrides @($microClean, @{
   InpUseFlatMonthOpportunityMode = "false"
   InpFlatMonthMicroReversionStandaloneActive = "true"
   InpUseFlatMonthMicroReversionMonthFilter = "true"
   InpFlatMicroRevTradeJanuary = "false"
   InpFlatMicroRevTradeFebruary = "false"
   InpFlatMicroRevTradeMarch = "false"
   InpFlatMicroRevTradeApril = "false"
   InpFlatMicroRevTradeMay = "false"
   InpFlatMicroRevTradeJune = "false"
   InpFlatMicroRevTradeJuly = "true"
   InpFlatMicroRevTradeAugust = "false"
   InpFlatMicroRevTradeSeptember = "false"
   InpFlatMicroRevTradeOctober = "true"
   InpFlatMicroRevTradeNovember = "false"
   InpFlatMicroRevTradeDecember = "false"
})

$microDedicatedAugSep = Merge-Overrides @($microClean, @{
   InpUseFlatMonthOpportunityMode = "false"
   InpFlatMonthMicroReversionStandaloneActive = "true"
   InpUseFlatMonthMicroReversionMonthFilter = "true"
   InpFlatMicroRevTradeJanuary = "false"
   InpFlatMicroRevTradeFebruary = "false"
   InpFlatMicroRevTradeMarch = "false"
   InpFlatMicroRevTradeApril = "false"
   InpFlatMicroRevTradeMay = "false"
   InpFlatMicroRevTradeJune = "false"
   InpFlatMicroRevTradeJuly = "false"
   InpFlatMicroRevTradeAugust = "true"
   InpFlatMicroRevTradeSeptember = "true"
   InpFlatMicroRevTradeOctober = "false"
   InpFlatMicroRevTradeNovember = "false"
   InpFlatMicroRevTradeDecember = "false"
})

$microDedicatedAugSepJulOct = Merge-Overrides @($microDedicatedAugSep, @{
   InpFlatMicroRevTradeJuly = "true"
   InpFlatMicroRevTradeOctober = "true"
})

$microDedicatedSepJulOct = Merge-Overrides @($microDedicatedJulOct, @{
   InpFlatMicroRevTradeSeptember = "true"
})

$profiles = @(
   [pscustomobject]@{ Name = "base_mar10_may10"; Overrides = @{} },
   [pscustomobject]@{ Name = "micro_clean"; Overrides = $microClean },
   [pscustomobject]@{ Name = "micro_clean_jul_oct"; Overrides = $microCleanJulOct },
   [pscustomobject]@{ Name = "micro_clean_core_jul_oct"; Overrides = $microCleanCoreJulOct },
   [pscustomobject]@{ Name = "micro_dedicated_jul_oct"; Overrides = $microDedicatedJulOct },
   [pscustomobject]@{ Name = "micro_dedicated_aug_sep"; Overrides = $microDedicatedAugSep },
   [pscustomobject]@{ Name = "micro_dedicated_sep_jul_oct"; Overrides = $microDedicatedSepJulOct },
   [pscustomobject]@{ Name = "micro_dedicated_aug_sep_jul_oct"; Overrides = $microDedicatedAugSepJulOct }
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
      $reportName = "mar10_may10_micro_clean_{0}_{1}" -f $profile.Name, $window.Window
      Write-SeasonalTesterConfig -Path (Join-Path $PackageDir "configs\$configName") -ReportRoot $ReportRoot -ReportName $reportName -From $window.From -To $window.To -Inputs $inputs -Model $Model
      $expected.Add([pscustomobject]@{
         Rank = $rank; Profile = $profile.Name; Phase = $window.Phase; Set = $window.Set; Window = $window.Window;
         From = $window.From; To = $window.To; Config = "configs\$configName"; ExpectedReportName = $reportName
      }) | Out-Null
   }
}

$expected | Export-Csv -LiteralPath (Join-Path $PackageDir "EXPECTED_REPORTS.csv") -NoTypeInformation
$manifest = if($Monthly) { "outputs\MAR10_MAY10_MICRO_CLEAN_MONTHLY_MANIFEST.csv" } else { "outputs\MAR10_MAY10_MICRO_CLEAN_MANIFEST.csv" }
$expected | Export-Csv -LiteralPath $manifest -NoTypeInformation
"Built $rank mar10/may10 clean micro add-on configs in $PackageDir"
