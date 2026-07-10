param(
   [string]$PackageDir = "work\local_mt5_flat_session_impulse_strict_broad_package",
   [string]$ReportRoot = "outputs",
   [string]$BaseSetPath = "outputs\CANDIDATE_SEASONAL_MAR1_MAY225_PROFILE.set",
   [int]$Model = 2
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "seasonal_gate_helpers.ps1")

function New-SessionBase {
   return @{
      InpAllowFlatMonthMomentumOutsideMonthFilter = "true"
      InpUseFlatMonthProbeMonthFilter = "true"
      InpFlatProbeTradeMarch = "true"
      InpFlatProbeTradeMay = "true"
      InpUseFlatMonthOpportunityMode = "true"
      InpFlatMonthMinDayOfMonth = "5"
      InpFlatMonthTargetPercent = "2.00"
      InpFlatMonthMaxProfitPercent = "0.75"
      InpFlatMonthRequireNoMonthlyLoss = "true"
      InpFlatMonthMaxEntryCount = "2"
      InpUseSessionImpulseLane = "true"
      InpSessionImpulseRequireLiquidSession = "true"
      InpSessionImpulseRequireSessionBreak = "true"
      InpSessionImpulseRequireExecution = "true"
      InpSessionImpulseRequireOrderFlow = "true"
      InpSessionImpulseStandaloneEntry = "true"
      InpSessionImpulseRiskMultiplier = "0.12"
      InpSessionImpulseTPMultiplier = "1.25"
      InpUseSessionImpulseFailureExit = "true"
      InpSessionImpulseFailureBars = "3"
      InpSessionImpulseFailureMinMFER = "0.18"
      InpSessionImpulseFailureMaxCurrentR = "-0.04"
      InpSessionImpulseFailureRequireOppositeCandle = "true"
      InpSessionImpulseFailureOppositeRangeATR = "0.35"
      InpSessionImpulseFailureOppositeBodyPercent = "35.0"
      InpUseMonthlyLossRiskScaling = "true"
      InpMonthlyLossRiskStartFraction = "0.10"
      InpMinMonthlyLossRiskMultiplier = "0.15"
      InpUseDirectionalLossCooldown = "true"
      InpDirectionalLossCooldownMinutes = "720"
      InpCooldownMinutesAfterLoss = "720"
   }
}

$windows = @(
   [pscustomobject]@{ Window = "2024_to_2026"; Phase = "full"; Set = "full"; From = "2024.01.01"; To = "2026.07.02" },
   [pscustomobject]@{ Window = "2026_ytd"; Phase = "recent"; Set = "recent"; From = "2026.01.01"; To = "2026.07.02" },
   [pscustomobject]@{ Window = "2025_full"; Phase = "oos"; Set = "oos"; From = "2025.01.01"; To = "2025.12.31" },
   [pscustomobject]@{ Window = "2024_full"; Phase = "train"; Set = "train"; From = "2024.01.01"; To = "2024.12.31" },
   [pscustomobject]@{ Window = "2024_02"; Phase = "loss_probe"; Set = "loss_probe"; From = "2024.02.01"; To = "2024.02.29" },
   [pscustomobject]@{ Window = "2024_08"; Phase = "loss_probe"; Set = "loss_probe"; From = "2024.08.01"; To = "2024.08.31" },
   [pscustomobject]@{ Window = "2025_08"; Phase = "loss_probe"; Set = "loss_probe"; From = "2025.08.01"; To = "2025.08.31" },
   [pscustomobject]@{ Window = "2026_02"; Phase = "loss_probe"; Set = "loss_probe"; From = "2026.02.01"; To = "2026.02.28" },
   [pscustomobject]@{ Window = "2026_06"; Phase = "guard"; Set = "guard"; From = "2026.06.01"; To = "2026.06.30" }
)

if(Test-Path -LiteralPath $PackageDir) { Remove-Item -LiteralPath $PackageDir -Recurse -Force }
New-Item -ItemType Directory -Path (Join-Path $PackageDir "configs") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $PackageDir "reports_here") -Force | Out-Null

$strict = Merge-Overrides @((New-SessionBase), @{
   InpSessionImpulseMinScore = "12"
   InpSessionImpulseStandaloneMinScore = "13"
   InpSessionImpulseMinADX = "25.0"
   InpSessionImpulseMinBodyPercent = "48.0"
   InpSessionImpulseMinRangeATR = "0.65"
   InpSessionImpulseMinCloseLocation = "0.72"
})

$ultra = Merge-Overrides @((New-SessionBase), @{
   InpSessionImpulseMinScore = "14"
   InpSessionImpulseStandaloneMinScore = "15"
   InpSessionImpulseMinADX = "28.0"
   InpSessionImpulseMinBodyPercent = "55.0"
   InpSessionImpulseMinRangeATR = "0.85"
   InpSessionImpulseMinCloseLocation = "0.78"
   InpFlatMonthMaxEntryCount = "1"
})

$profiles = @(
   [pscustomobject]@{ Name = "session_anatomy_strict"; Overrides = $strict },
   [pscustomobject]@{ Name = "session_anatomy_ultra"; Overrides = $ultra }
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
      $reportName = "flat_session_impulse_strict_broad_{0}_{1}" -f $profile.Name, $window.Window
      Write-SeasonalTesterConfig -Path (Join-Path $PackageDir "configs\$configName") -ReportRoot $ReportRoot -ReportName $reportName -From $window.From -To $window.To -Inputs $inputs -Model $Model
      $expected.Add([pscustomobject]@{
         Rank = $rank; Profile = $profile.Name; Phase = $window.Phase; Set = $window.Set; Window = $window.Window;
         From = $window.From; To = $window.To; Config = "configs\$configName"; ExpectedReportName = $reportName
      }) | Out-Null
   }
}

$expected | Export-Csv -LiteralPath (Join-Path $PackageDir "EXPECTED_REPORTS.csv") -NoTypeInformation
$expected | Export-Csv -LiteralPath "outputs\FLAT_SESSION_IMPULSE_STRICT_BROAD_MANIFEST.csv" -NoTypeInformation
"Built $rank strict session impulse broad configs in $PackageDir"
