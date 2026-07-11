param(
   [string]$PackageDir = "work\local_mt5_current_best_fsd_lane_package",
   [string]$ReportRoot = "outputs",
   [string]$BaseSetPath = "outputs\CANDIDATE_PRIMARY_AUG40_REVERSE_OFF_MICRO_JULOCT_PROFILE.set",
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
   [pscustomobject]@{ Window = "2025_01"; Phase = "flat"; Set = "flat"; From = "2025.01.01"; To = "2025.01.31" },
   [pscustomobject]@{ Window = "2025_04"; Phase = "flat"; Set = "flat"; From = "2025.04.01"; To = "2025.04.30" },
   [pscustomobject]@{ Window = "2025_06"; Phase = "flat"; Set = "flat"; From = "2025.06.01"; To = "2025.06.30" },
   [pscustomobject]@{ Window = "2026_01"; Phase = "flat"; Set = "flat"; From = "2026.01.01"; To = "2026.01.31" }
)

if(Test-Path -LiteralPath $PackageDir) { Remove-Item -LiteralPath $PackageDir -Recurse -Force }
New-Item -ItemType Directory -Path (Join-Path $PackageDir "configs") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $PackageDir "reports_here") -Force | Out-Null

$flatOpportunity = @{
   InpUseAdaptiveReverse = "false"
   InpUseFlatMonthOpportunityMode = "true"
   InpFlatMonthOpportunityOnlyOutsideMonthFilter = "true"
   InpAllowFlatMonthOpportunityOutsideMonthFilter = "true"
   InpFlatMonthOpportunityBypassMinQualityScore = "8"
   InpFlatMonthOpportunityBypassMinPriceActionScore = "0"
   InpFlatMonthOpportunityBypassRequireLiquidSession = "true"
   InpFlatMonthTargetPercent = "2.00"
   InpFlatMonthMinDayOfMonth = "4"
   InpFlatMonthMaxEntryCount = "5"
   InpFlatMonthMaxProfitPercent = "0.75"
   InpFlatMonthRequireNoMonthlyLoss = "true"
   InpUseFlatMonthProbeLaneSpacing = "true"
   InpUseMediocreSetupRiskThrottle = "true"
   InpMediocreSetupRiskMultiplier = "0.30"
   InpUseSpreadAdjustedRRFilter = "true"
}

function New-FsdProfile {
   param(
      [string]$Risk = "0.25",
      [string]$MaxEntries = "3",
      [string]$Spacing = "480",
      [string]$MinScore = "8",
      [string]$MinRangeATR = "0.75",
      [string]$MinBody = "52.0",
      [string]$MaxOppWick = "30.0",
      [string]$Lookback = "24",
      [string]$RequireOrderFlow = "true",
      [string]$RequireSweepOrRetest = "true",
      [string]$MinClearanceATR = "1.05",
      [string]$TakeProfitATR = "1.35",
      [string]$MinRR = "0.95"
   )

   return Merge-Overrides @($flatOpportunity, @{
      InpUseFlatMonthStructuralDisplacementLane = "true"
      InpFlatMonthStructuralDisplacementRiskMultiplier = $Risk
      InpFlatMonthStructuralDisplacementMaxMonthlyEntries = $MaxEntries
      InpFlatMonthStructuralDisplacementSpacingMinutes = $Spacing
      InpFlatMonthStructuralDisplacementMinScore = $MinScore
      InpFlatMonthStructuralDisplacementRequireLiquidSession = "true"
      InpFlatMonthStructuralDisplacementRequireADX = "true"
      InpFlatMonthStructuralDisplacementMinADX = "18.0"
      InpFlatMonthStructuralDisplacementMaxADX = "34.0"
      InpFlatMonthStructuralDisplacementMinRangeATR = $MinRangeATR
      InpFlatMonthStructuralDisplacementMinBodyPercent = $MinBody
      InpFlatMonthStructuralDisplacementMaxOppositeWickPercent = $MaxOppWick
      InpFlatMonthStructuralDisplacementLookbackBars = $Lookback
      InpFlatMonthStructuralDisplacementRequireSweepOrRetest = $RequireSweepOrRetest
      InpFlatMonthStructuralDisplacementRequireOrderFlow = $RequireOrderFlow
      InpFlatMonthStructuralDisplacementStopBufferATR = "0.16"
      InpFlatMonthStructuralDisplacementStopBufferPoints = "35.0"
      InpFlatMonthStructuralDisplacementTakeProfitATR = $TakeProfitATR
      InpFlatMonthStructuralDisplacementMinRR = $MinRR
      InpFlatMonthStructuralDisplacementRequireForwardClearance = "true"
      InpFlatMonthStructuralDisplacementMinClearanceATR = $MinClearanceATR
      InpFlatMonthStructuralDisplacementUseEqualLevels = "true"
      InpFlatMonthStructuralDisplacementUsePreviousDay = "true"
      InpFlatMonthStructuralDisplacementUsePreviousWeek = "false"
   })
}

$profiles = @(
   [pscustomobject]@{ Name = "base"; Overrides = @{ InpUseAdaptiveReverse = "false" } },
   [pscustomobject]@{ Name = "fsd_strict"; Overrides = New-FsdProfile },
   [pscustomobject]@{ Name = "fsd_balanced"; Overrides = New-FsdProfile -Risk "0.30" -MaxEntries "4" -Spacing "360" -MinScore "7" -MinRangeATR "0.65" -MinBody "48.0" -MaxOppWick "34.0" -MinClearanceATR "0.95" },
   [pscustomobject]@{ Name = "fsd_wide_tp"; Overrides = New-FsdProfile -Risk "0.25" -MaxEntries "3" -Spacing "480" -MinScore "8" -TakeProfitATR "1.65" -MinRR "1.05" -MinClearanceATR "1.10" },
   [pscustomobject]@{ Name = "fsd_no_of"; Overrides = New-FsdProfile -Risk "0.20" -MaxEntries "3" -Spacing "480" -MinScore "8" -RequireOrderFlow "false" -MinClearanceATR "1.20" }
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
      $reportName = "current_best_fsd_lane_{0}_{1}" -f $profile.Name, $window.Window
      Write-SeasonalTesterConfig -Path (Join-Path $PackageDir "configs\$configName") -ReportRoot $ReportRoot -ReportName $reportName -From $window.From -To $window.To -Inputs $inputs -Model $Model
      $expected.Add([pscustomobject]@{
         Rank = $rank; Profile = $profile.Name; Phase = $window.Phase; Set = $window.Set; Window = $window.Window;
         From = $window.From; To = $window.To; Config = "configs\$configName"; ExpectedReportName = $reportName
      }) | Out-Null
   }
}

$expected | Export-Csv -LiteralPath (Join-Path $PackageDir "EXPECTED_REPORTS.csv") -NoTypeInformation
$expected | Export-Csv -LiteralPath "outputs\CURRENT_BEST_FSD_LANE_MANIFEST.csv" -NoTypeInformation
"Built $rank current-best FSD lane configs in $PackageDir"
