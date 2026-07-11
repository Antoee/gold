param(
   [string]$PackageDir = "work\local_mt5_current_best_primary_unlock_package",
   [string]$ReportRoot = "outputs",
   [string]$BaseSetPath = "outputs\CANDIDATE_MICRO_DEDICATED_JULOCT_PROFILE.set",
   [int]$Model = 2,
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
      [pscustomobject]@{ Window = "2025_08_09"; Phase = "target"; Set = "target"; From = "2025.08.01"; To = "2025.09.30" },
      [pscustomobject]@{ Window = "2024_08_09"; Phase = "target"; Set = "target"; From = "2024.08.01"; To = "2024.09.30" },
      [pscustomobject]@{ Window = "2026_06"; Phase = "guard"; Set = "guard"; From = "2026.06.01"; To = "2026.06.30" }
   )
}

if(Test-Path -LiteralPath $PackageDir) { Remove-Item -LiteralPath $PackageDir -Recurse -Force }
New-Item -ItemType Directory -Path (Join-Path $PackageDir "configs") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $PackageDir "reports_here") -Force | Out-Null

function New-PrimaryUnlock {
   param(
      [int[]]$Months,
      [string]$RiskMultiplier = "0.20"
   )

   $map = @{
      InpUseMonthFilter = "true"
      InpUseMonthRiskMultipliers = "true"
      InpTradeMarch = "true"
      InpTradeMay = "true"
      InpMarchRiskMultiplier = "1.00"
      InpMayRiskMultiplier = "2.80"
   }

   foreach($month in $Months) {
      switch($month) {
         8 {
            $map.InpTradeAugust = "true"
            $map.InpAugustRiskMultiplier = $RiskMultiplier
         }
         9 {
            $map.InpTradeSeptember = "true"
            $map.InpSeptemberRiskMultiplier = $RiskMultiplier
         }
      }
   }
   return $map
}

$profiles = @(
   [pscustomobject]@{ Name = "base_current_best"; Overrides = @{} },
   [pscustomobject]@{ Name = "primary_aug20"; Overrides = New-PrimaryUnlock @(8) },
   [pscustomobject]@{ Name = "primary_sep20"; Overrides = New-PrimaryUnlock @(9) },
   [pscustomobject]@{ Name = "primary_aug20_sep20"; Overrides = New-PrimaryUnlock @(8, 9) }
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
      $reportName = "current_best_primary_unlock_{0}_{1}" -f $profile.Name, $window.Window
      Write-SeasonalTesterConfig -Path (Join-Path $PackageDir "configs\$configName") -ReportRoot $ReportRoot -ReportName $reportName -From $window.From -To $window.To -Inputs $inputs -Model $Model
      $expected.Add([pscustomobject]@{
         Rank = $rank; Profile = $profile.Name; Phase = $window.Phase; Set = $window.Set; Window = $window.Window;
         From = $window.From; To = $window.To; Config = "configs\$configName"; ExpectedReportName = $reportName
      }) | Out-Null
   }
}

$expected | Export-Csv -LiteralPath (Join-Path $PackageDir "EXPECTED_REPORTS.csv") -NoTypeInformation
$manifest = if($Monthly) { "outputs\CURRENT_BEST_PRIMARY_UNLOCK_MONTHLY_MANIFEST.csv" } else { "outputs\CURRENT_BEST_PRIMARY_UNLOCK_MANIFEST.csv" }
$expected | Export-Csv -LiteralPath $manifest -NoTypeInformation
"Built $rank current-best primary unlock configs in $PackageDir"
