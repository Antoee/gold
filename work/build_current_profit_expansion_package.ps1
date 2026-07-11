param(
   [string]$PackageDir = "work\local_mt5_current_profit_expansion_package",
   [string]$ReportRoot = "outputs",
   [string]$BaseSetPath = "outputs\CANDIDATE_MARCH110_MAY325_MAYCAP17_LOT040_PROFILE.set",
   [int]$Model = 0,
   [switch]$Monthly,
   [string[]]$ProfileNames = @()
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
      [pscustomobject]@{ Window = "2026_03"; Phase = "target"; Set = "target"; From = "2026.03.01"; To = "2026.03.31" },
      [pscustomobject]@{ Window = "2026_05"; Phase = "target"; Set = "target"; From = "2026.05.01"; To = "2026.05.31" },
      [pscustomobject]@{ Window = "2026_06"; Phase = "guard"; Set = "guard"; From = "2026.06.01"; To = "2026.06.30" }
   )
}

if(Test-Path -LiteralPath $PackageDir) { Remove-Item -LiteralPath $PackageDir -Recurse -Force }
New-Item -ItemType Directory -Path (Join-Path $PackageDir "configs") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $PackageDir "reports_here") -Force | Out-Null

$mfeLock = @{
   InpUseMFEProfitLockStop = "true"
   InpMFEProfitLockStartR = "1.35"
   InpMFEProfitLockGivebackR = "0.85"
   InpMFEProfitLockMinR = "0.25"
}

$runnerPatience = @{
   InpUseMFEGivebackExit = "true"
   InpMFEGivebackStartR = "1.40"
   InpMFEGivebackMaxGivebackR = "0.90"
   InpMFEGivebackMinCloseR = "0.25"
   InpUseRunnerExitPatience = "true"
   InpRunnerExitPatienceMinR = "0.35"
   InpRunnerExitPatienceMinMFER = "0.80"
   InpRunnerExitPatienceRequireHouseMoney = "false"
   InpRunnerExitPatienceRequireProtectedStop = "true"
   InpRunnerExitPatienceRequireTrendRegime = "false"
   InpRunnerExitPatienceRequireContinuation = "false"
   InpRunnerExitPatienceMFEGivebackMultiplier = "1.35"
}

$profiles = @(
   [pscustomobject]@{ Name = "base_current"; Overrides = @{} },
   [pscustomobject]@{ Name = "tp40"; Overrides = @{
      InpTakeProfitATRMultiplier = "4.00"
   }},
   [pscustomobject]@{ Name = "tp45"; Overrides = @{
      InpTakeProfitATRMultiplier = "4.50"
   }},
   [pscustomobject]@{ Name = "quality_tp"; Overrides = @{
      InpUseQualityTakeProfitScaling = "true"
      InpQualityTPMinScore = "8"
      InpQualityTPFullScore = "13"
      InpMinQualityTPMultiplier = "0.95"
      InpMaxQualityTPMultiplier = "1.30"
   }},
   [pscustomobject]@{ Name = "quality_tp_march_only"; Overrides = @{
      InpUseQualityTakeProfitScaling = "true"
      InpQualityTPMinScore = "8"
      InpQualityTPFullScore = "13"
      InpMinQualityTPMultiplier = "0.95"
      InpMaxQualityTPMultiplier = "1.30"
      InpUseQualityTPMonthFilter = "true"
      InpQualityTPTradeJanuary = "false"
      InpQualityTPTradeFebruary = "false"
      InpQualityTPTradeMarch = "true"
      InpQualityTPTradeApril = "false"
      InpQualityTPTradeMay = "false"
      InpQualityTPTradeJune = "false"
      InpQualityTPTradeJuly = "false"
      InpQualityTPTradeAugust = "false"
      InpQualityTPTradeSeptember = "false"
      InpQualityTPTradeOctober = "false"
      InpQualityTPTradeNovember = "false"
      InpQualityTPTradeDecember = "false"
   }},
   [pscustomobject]@{ Name = "runner_tp"; Overrides = @{
      InpUseRunnerTakeProfitExpansion = "true"
      InpRunnerMinQualityScore = "11"
      InpRunnerMinPriceActionScore = "12"
      InpRunnerTakeProfitMultiplier = "1.35"
      InpRunnerRequireTrailing = "true"
   }},
   [pscustomobject]@{ Name = "trend_tp"; Overrides = @{
      InpUseTrendRegimeTakeProfitExpansion = "true"
      InpTrendRegimeTPMinQualityScore = "11"
      InpTrendRegimeTPMinPriceActionScore = "12"
      InpTrendRegimeTPMultiplier = "1.30"
      InpTrendRegimeTPRequireTrailing = "true"
      InpTrendRegimeTPRequiresEquityProfit = "false"
   }},
   [pscustomobject]@{ Name = "mfe_patience"; Overrides = $runnerPatience },
   [pscustomobject]@{ Name = "tp40_mfe_lock"; Overrides = Merge-Overrides @(@{
      InpTakeProfitATRMultiplier = "4.00"
   }, $mfeLock) },
   [pscustomobject]@{ Name = "runner_mfe_patience"; Overrides = Merge-Overrides @(@{
      InpUseRunnerTakeProfitExpansion = "true"
      InpRunnerMinQualityScore = "11"
      InpRunnerMinPriceActionScore = "12"
      InpRunnerTakeProfitMultiplier = "1.30"
      InpRunnerRequireTrailing = "true"
   }, $runnerPatience, $mfeLock) }
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
      $reportName = "current_profit_expansion_{0}_{1}" -f $profile.Name, $window.Window
      Write-SeasonalTesterConfig -Path (Join-Path $PackageDir "configs\$configName") -ReportRoot $ReportRoot -ReportName $reportName -From $window.From -To $window.To -Inputs $inputs -Model $Model
      $expected.Add([pscustomobject]@{
         Rank = $rank; Profile = $profile.Name; Phase = $window.Phase; Set = $window.Set; Window = $window.Window;
         From = $window.From; To = $window.To; Config = "configs\$configName"; ExpectedReportName = $reportName
      }) | Out-Null
   }
}

$expected | Export-Csv -LiteralPath (Join-Path $PackageDir "EXPECTED_REPORTS.csv") -NoTypeInformation
$manifest = if($Monthly) { "outputs\CURRENT_PROFIT_EXPANSION_MONTHLY_MANIFEST.csv" } else { "outputs\CURRENT_PROFIT_EXPANSION_BROAD_MANIFEST.csv" }
$expected | Export-Csv -LiteralPath $manifest -NoTypeInformation
"Built $rank current profit-expansion configs in $PackageDir"
