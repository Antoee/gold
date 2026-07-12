param(
   [string]$PackageDir = "work\local_mt5_current_best_engine_month_expansion_package",
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
   [pscustomobject]@{ Window = "2024_03"; Phase = "engine"; Set = "engine"; From = "2024.03.01"; To = "2024.03.31" },
   [pscustomobject]@{ Window = "2025_03"; Phase = "engine"; Set = "engine"; From = "2025.03.01"; To = "2025.03.31" },
   [pscustomobject]@{ Window = "2026_03"; Phase = "engine"; Set = "engine"; From = "2026.03.01"; To = "2026.03.31" },
   [pscustomobject]@{ Window = "2024_05"; Phase = "engine"; Set = "engine"; From = "2024.05.01"; To = "2024.05.31" },
   [pscustomobject]@{ Window = "2025_05"; Phase = "guard"; Set = "guard"; From = "2025.05.01"; To = "2025.05.31" },
   [pscustomobject]@{ Window = "2026_05"; Phase = "engine"; Set = "engine"; From = "2026.05.01"; To = "2026.05.31" },
   [pscustomobject]@{ Window = "2024_04"; Phase = "guard"; Set = "guard"; From = "2024.04.01"; To = "2024.04.30" },
   [pscustomobject]@{ Window = "2025_04"; Phase = "guard"; Set = "guard"; From = "2025.04.01"; To = "2025.04.30" }
)

if(Test-Path -LiteralPath $PackageDir) { Remove-Item -LiteralPath $PackageDir -Recurse -Force }
New-Item -ItemType Directory -Path (Join-Path $PackageDir "configs") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $PackageDir "reports_here") -Force | Out-Null

function New-MonthRisk {
   param(
      [string]$MarchRisk = "1.00",
      [string]$MayRisk = "2.80",
      [hashtable]$Extra = @{}
   )

   $base = @{
      InpUseMonthFilter = "true"
      InpUseMonthRiskMultipliers = "true"
      InpTradeMarch = "true"
      InpTradeMay = "true"
      InpTradeAugust = "true"
      InpMarchRiskMultiplier = $MarchRisk
      InpMayRiskMultiplier = $MayRisk
      InpAugustRiskMultiplier = "0.40"
   }

   foreach($entry in $Extra.GetEnumerator()) { $base[$entry.Key] = $entry.Value }
   return $base
}

$tpMarchMay = @{
   InpUseQualityTakeProfitScaling = "true"
   InpUseQualityTPMonthFilter = "true"
   InpQualityTPTradeJanuary = "false"
   InpQualityTPTradeFebruary = "false"
   InpQualityTPTradeMarch = "true"
   InpQualityTPTradeApril = "false"
   InpQualityTPTradeMay = "true"
   InpQualityTPTradeJune = "false"
   InpQualityTPTradeJuly = "false"
   InpQualityTPTradeAugust = "false"
   InpQualityTPTradeSeptember = "false"
   InpQualityTPTradeOctober = "false"
   InpQualityTPTradeNovember = "false"
   InpQualityTPTradeDecember = "false"
   InpQualityTPMinScore = "10"
   InpQualityTPFullScore = "15"
   InpMinQualityTPMultiplier = "1.00"
   InpMaxQualityTPMultiplier = "1.20"
}

$tpMarchOnly = @{}
foreach($entry in $tpMarchMay.GetEnumerator()) { $tpMarchOnly[$entry.Key] = $entry.Value }
$tpMarchOnly["InpQualityTPTradeMay"] = "false"

$runnerStretch = @{
   InpUseHouseMoneyMFEGivebackStretch = "true"
   InpHouseMoneyMFEGivebackStartR = "1.10"
   InpHouseMoneyMFEGivebackMaxR = "1.10"
}

$profiles = @(
   [pscustomobject]@{ Name = "base"; Overrides = @{} },
   [pscustomobject]@{ Name = "march_r125"; Overrides = New-MonthRisk -MarchRisk "1.25" },
   [pscustomobject]@{ Name = "march_r150"; Overrides = New-MonthRisk -MarchRisk "1.50" },
   [pscustomobject]@{ Name = "may_r285"; Overrides = New-MonthRisk -MayRisk "2.85" },
   [pscustomobject]@{ Name = "may_r290"; Overrides = New-MonthRisk -MayRisk "2.90" },
   [pscustomobject]@{ Name = "may_r295"; Overrides = New-MonthRisk -MayRisk "2.95" },
   [pscustomobject]@{ Name = "may_r300"; Overrides = New-MonthRisk -MayRisk "3.00" },
   [pscustomobject]@{ Name = "may_r320"; Overrides = New-MonthRisk -MayRisk "3.20" },
   [pscustomobject]@{ Name = "march125_may300"; Overrides = New-MonthRisk -MarchRisk "1.25" -MayRisk "3.00" },
   [pscustomobject]@{ Name = "march_tp120"; Overrides = New-MonthRisk -Extra $tpMarchOnly },
   [pscustomobject]@{ Name = "march_may_tp120"; Overrides = New-MonthRisk -Extra $tpMarchMay },
   [pscustomobject]@{ Name = "march125_tp120"; Overrides = New-MonthRisk -MarchRisk "1.25" -Extra $tpMarchOnly },
   [pscustomobject]@{ Name = "runner_stretch"; Overrides = New-MonthRisk -Extra $runnerStretch }
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
      $reportName = "current_best_engine_month_expansion_{0}_{1}" -f $profile.Name, $window.Window
      Write-SeasonalTesterConfig -Path (Join-Path $PackageDir "configs\$configName") -ReportRoot $ReportRoot -ReportName $reportName -From $window.From -To $window.To -Inputs $inputs -Model $Model
      $expected.Add([pscustomobject]@{
         Rank = $rank; Profile = $profile.Name; Phase = $window.Phase; Set = $window.Set; Window = $window.Window;
         From = $window.From; To = $window.To; Config = "configs\$configName"; ExpectedReportName = $reportName
      }) | Out-Null
   }
}

$expected | Export-Csv -LiteralPath (Join-Path $PackageDir "EXPECTED_REPORTS.csv") -NoTypeInformation
$expected | Export-Csv -LiteralPath "outputs\CURRENT_BEST_ENGINE_MONTH_EXPANSION_MANIFEST.csv" -NoTypeInformation
"Built $rank current-best engine-month expansion configs in $PackageDir"
