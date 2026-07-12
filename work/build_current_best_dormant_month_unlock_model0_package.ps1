param(
   [string]$PackageDir = "work\local_mt5_current_best_dormant_month_unlock_model0_package",
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
   [pscustomobject]@{ Window = "2025_01"; Phase = "dormant"; Set = "dormant"; From = "2025.01.01"; To = "2025.01.31" },
   [pscustomobject]@{ Window = "2025_04"; Phase = "dormant"; Set = "dormant"; From = "2025.04.01"; To = "2025.04.30" },
   [pscustomobject]@{ Window = "2025_06"; Phase = "dormant"; Set = "dormant"; From = "2025.06.01"; To = "2025.06.30" },
   [pscustomobject]@{ Window = "2026_01"; Phase = "dormant"; Set = "dormant"; From = "2026.01.01"; To = "2026.01.31" },
   [pscustomobject]@{ Window = "2024_04"; Phase = "guard"; Set = "guard"; From = "2024.04.01"; To = "2024.04.30" }
)

function New-TargetMonthUnlockOverrides {
   param([string]$RiskMultiplier)

   return @{
      InpUseMonthFilter = "true"
      InpTradeJanuary = "true"
      InpTradeApril = "true"
      InpTradeJune = "true"
      InpUseMonthRiskMultipliers = "true"
      InpJanuaryRiskMultiplier = $RiskMultiplier
      InpAprilRiskMultiplier = $RiskMultiplier
      InpJuneRiskMultiplier = $RiskMultiplier
      InpJanuaryDayRiskMultiplier = $RiskMultiplier
      InpAprilDayRiskMultiplier = $RiskMultiplier
      InpJuneDayRiskMultiplier = $RiskMultiplier
   }
}

function New-SingleTargetMonthUnlockOverrides {
   param([int]$Month, [string]$RiskMultiplier)

   $overrides = @{
      InpUseMonthFilter = "true"
      InpUseMonthRiskMultipliers = "true"
   }

   switch($Month) {
      1 {
         $overrides.InpTradeJanuary = "true"
         $overrides.InpJanuaryRiskMultiplier = $RiskMultiplier
         $overrides.InpJanuaryDayRiskMultiplier = $RiskMultiplier
      }
      4 {
         $overrides.InpTradeApril = "true"
         $overrides.InpAprilRiskMultiplier = $RiskMultiplier
         $overrides.InpAprilDayRiskMultiplier = $RiskMultiplier
      }
      6 {
         $overrides.InpTradeJune = "true"
         $overrides.InpJuneRiskMultiplier = $RiskMultiplier
         $overrides.InpJuneDayRiskMultiplier = $RiskMultiplier
      }
      default { throw "Unsupported single target month: $Month" }
   }

   return $overrides
}

function New-AllMonthLowRiskOverrides {
   param([string]$RiskMultiplier)

   return @{
      InpUseMonthFilter = "false"
      InpUseMonthRiskMultipliers = "true"
      InpJanuaryRiskMultiplier = $RiskMultiplier
      InpFebruaryRiskMultiplier = $RiskMultiplier
      InpAprilRiskMultiplier = $RiskMultiplier
      InpJuneRiskMultiplier = $RiskMultiplier
      InpJulyRiskMultiplier = $RiskMultiplier
      InpSeptemberRiskMultiplier = $RiskMultiplier
      InpOctoberRiskMultiplier = $RiskMultiplier
      InpNovemberRiskMultiplier = $RiskMultiplier
      InpDecemberRiskMultiplier = $RiskMultiplier
      InpJanuaryDayRiskMultiplier = $RiskMultiplier
      InpFebruaryDayRiskMultiplier = $RiskMultiplier
      InpAprilDayRiskMultiplier = $RiskMultiplier
      InpJuneDayRiskMultiplier = $RiskMultiplier
      InpJulyDayRiskMultiplier = $RiskMultiplier
      InpSeptemberDayRiskMultiplier = $RiskMultiplier
      InpOctoberDayRiskMultiplier = $RiskMultiplier
      InpNovemberDayRiskMultiplier = $RiskMultiplier
      InpDecemberDayRiskMultiplier = $RiskMultiplier
   }
}

$breakoutProbe = @{
   InpUseFlatMonthBreakoutProbe = "true"
   InpFlatMonthBreakoutProbeMinHours = "36"
   InpFlatMonthBreakoutProbeMaxMonthlyEntries = "5"
   InpFlatMonthBreakoutProbeMinScore = "8"
   InpFlatMonthBreakoutProbeRiskMultiplier = "0.22"
   InpFlatMonthBreakoutProbeRequireLiquidSession = "true"
   InpFlatMonthBreakoutProbeRequireADX = "true"
   InpFlatMonthBreakoutProbeMinADX = "19.0"
   InpFlatMonthBreakoutProbeMaxADX = "33.0"
   InpFlatMonthBreakoutProbeRequireExecution = "true"
   InpFlatMonthBreakoutProbeRequireRangeExpansion = "true"
   InpFlatMonthBreakoutProbeMinRangeATR = "0.50"
   InpFlatMonthBreakoutProbeMaxOppositeWickPercent = "34.0"
}

$profiles = @(
   [pscustomobject]@{ Name = "base_mfe_aug"; Overrides = @{} },
   [pscustomobject]@{ Name = "jan_only_r010"; Overrides = New-SingleTargetMonthUnlockOverrides 1 "0.10" },
   [pscustomobject]@{ Name = "jan_only_r025"; Overrides = New-SingleTargetMonthUnlockOverrides 1 "0.25" },
   [pscustomobject]@{ Name = "apr_only_r010"; Overrides = New-SingleTargetMonthUnlockOverrides 4 "0.10" },
   [pscustomobject]@{ Name = "jun_only_r010"; Overrides = New-SingleTargetMonthUnlockOverrides 6 "0.10" },
   [pscustomobject]@{ Name = "unlock_jan_apr_jun_r025"; Overrides = New-TargetMonthUnlockOverrides "0.25" },
   [pscustomobject]@{ Name = "unlock_jan_apr_jun_r050"; Overrides = New-TargetMonthUnlockOverrides "0.50" },
   [pscustomobject]@{ Name = "unlock_jan_apr_jun_breakout"; Overrides = Merge-Overrides @((New-TargetMonthUnlockOverrides "0.25"), $breakoutProbe) },
   [pscustomobject]@{ Name = "month_filter_off_r020"; Overrides = New-AllMonthLowRiskOverrides "0.20" }
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
      $reportName = "current_best_dormant_month_unlock_model0_{0}_{1}" -f $profile.Name, $window.Window
      Write-SeasonalTesterConfig -Path (Join-Path $PackageDir "configs\$configName") -ReportRoot $ReportRoot -ReportName $reportName -From $window.From -To $window.To -Inputs $inputs -Model 0
      $expected.Add([pscustomobject]@{
         Rank = $rank; Profile = $profile.Name; Phase = $window.Phase; Set = $window.Set; Window = $window.Window;
         From = $window.From; To = $window.To; Config = "configs\$configName"; ExpectedReportName = $reportName
      }) | Out-Null
   }
}

$expected | Export-Csv -LiteralPath (Join-Path $PackageDir "EXPECTED_REPORTS.csv") -NoTypeInformation
$expected | Export-Csv -LiteralPath "outputs\CURRENT_BEST_DORMANT_MONTH_UNLOCK_MODEL0_MANIFEST.csv" -NoTypeInformation
"Built $rank current-best dormant-month unlock Model 0 configs in $PackageDir"
