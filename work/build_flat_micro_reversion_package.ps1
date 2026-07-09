param(
   [string]$PackageDir = "work\local_mt5_flat_micro_reversion_package",
   [string]$ReportRoot = "outputs",
   [string]$PrimarySetPath = "outputs\CANDIDATE_PEAK15_LIQUIDITY_STOP_CHOP_PROFILE.set",
   [string]$RiskCalendarSetPath = "outputs\CANDIDATE_PEAK15_BLOCK_MAY_JUN_PROFILE.set"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Import-SetInputs {
   param([string]$Path)
   if(!(Test-Path -LiteralPath $Path)) { throw "Set file missing: $Path" }
   $map = @{}
   foreach($line in Get-Content -LiteralPath $Path) {
      if([string]::IsNullOrWhiteSpace($line)) { continue }
      $idx = $line.IndexOf("=")
      if($idx -lt 1) { continue }
      $map[$line.Substring(0, $idx)] = $line
   }
   return $map
}

function Set-InputLine {
   param($Inputs, [string]$Name, [string]$Value)
   $Inputs[$Name] = "$Name=$Value||$Value||0||0||N"
}

function Write-Config {
   param([string]$Path, [string]$ReportName, [string]$From, [string]$To, $Inputs)
   $reportPath = Join-Path (Resolve-Path $ReportRoot).Path $ReportName
   $lines = @(
      "[Tester]",
      "Expert=Professional_XAUUSD_EA.ex5",
      "Symbol=XAUUSD",
      "Period=15",
      "Optimization=0",
      "Model=2",
      "FromDate=$From",
      "ToDate=$To",
      "ForwardMode=0",
      "Deposit=1000",
      "Currency=USD",
      "ProfitInPips=0",
      "Leverage=100",
      "ExecutionMode=0",
      "OptimizationCriterion=6",
      "Visual=0",
      "Report=$reportPath",
      "ReplaceReport=1",
      "ShutdownTerminal=1",
      "[TesterInputs]"
   )
   foreach($key in ($Inputs.Keys | Sort-Object)) { $lines += $Inputs[$key] }
   Set-Content -LiteralPath $Path -Value $lines -Encoding ASCII
}

$windows = @(
   [pscustomobject]@{ Window = "2024_to_2026"; Phase = "full"; From = "2024.01.01"; To = "2026.07.02" },
   [pscustomobject]@{ Window = "2026_ytd"; Phase = "recent"; From = "2026.01.01"; To = "2026.07.02" },
   [pscustomobject]@{ Window = "2025_full"; Phase = "oos"; From = "2025.01.01"; To = "2025.12.31" },
   [pscustomobject]@{ Window = "2024_full"; Phase = "train"; From = "2024.01.01"; To = "2024.12.31" },
   [pscustomobject]@{ Window = "2026_03"; Phase = "weak"; From = "2026.03.01"; To = "2026.03.31" },
   [pscustomobject]@{ Window = "2026_05"; Phase = "weak"; From = "2026.05.01"; To = "2026.05.31" },
   [pscustomobject]@{ Window = "2026_06"; Phase = "weak"; From = "2026.06.01"; To = "2026.06.30" }
)

$microStrict = @{
   InpUseFlatMonthMicroReversionLane = "true"
   InpUseFlatMonthOpportunityMode = "true"
   InpFlatMonthRequireNoMonthlyLoss = "false"
   InpFlatMonthMicroReversionRiskMultiplier = "0.35"
   InpFlatMonthMicroReversionMaxMonthlyEntries = "10"
   InpFlatMonthMicroReversionSpacingMinutes = "90"
   InpFlatMonthMicroReversionMaxADX = "22.0"
   InpFlatMonthMicroReversionMinWickPercent = "30.0"
   InpFlatMonthMicroReversionMinCloseLocation = "0.56"
   InpFlatMonthMicroReversionMinRangeATR = "0.28"
   InpFlatMonthMicroReversionRequireLiquidity = "true"
   InpFlatMonthMicroReversionRequireVWAP = "false"
   InpFlatMonthMicroReversionMinRR = "0.75"
   InpRangeReversionEliteMinConfirmations = "1"
   InpRangeReversionEliteMinQualityScore = "4"
   InpRangeReversionEliteMinPriceActionScore = "0"
}

$microLoose = $microStrict.Clone()
$microLoose["InpFlatMonthMicroReversionRequireLiquidity"] = "false"
$microLoose["InpFlatMonthMicroReversionRiskMultiplier"] = "0.25"
$microLoose["InpFlatMonthMicroReversionMinRR"] = "0.65"

$microVwap = $microStrict.Clone()
$microVwap["InpFlatMonthMicroReversionRequireVWAP"] = "true"
$microVwap["InpFlatMonthMicroReversionRiskMultiplier"] = "0.45"

$noAdaptive = @{
   InpUseAdaptiveReverse = "false"
   InpUseAdaptiveReverseWhipsawGuard = "true"
}

$profiles = @(
   [pscustomobject]@{ Name = "base"; SetPath = $PrimarySetPath; Overrides = @{} },
   [pscustomobject]@{ Name = "block_may_jun"; SetPath = $RiskCalendarSetPath; Overrides = @{} },
   [pscustomobject]@{ Name = "base_fmr_strict"; SetPath = $PrimarySetPath; Overrides = $microStrict },
   [pscustomobject]@{ Name = "base_fmr_loose"; SetPath = $PrimarySetPath; Overrides = $microLoose },
   [pscustomobject]@{ Name = "base_fmr_vwap"; SetPath = $PrimarySetPath; Overrides = $microVwap },
   [pscustomobject]@{ Name = "base_fmr_strict_no_adapt"; SetPath = $PrimarySetPath; Overrides = $microStrict + $noAdaptive },
   [pscustomobject]@{ Name = "block_fmr_strict"; SetPath = $RiskCalendarSetPath; Overrides = $microStrict },
   [pscustomobject]@{ Name = "block_fmr_loose"; SetPath = $RiskCalendarSetPath; Overrides = $microLoose },
   [pscustomobject]@{ Name = "block_no_adapt"; SetPath = $RiskCalendarSetPath; Overrides = $noAdaptive },
   [pscustomobject]@{ Name = "block_fmr_strict_no_adapt"; SetPath = $RiskCalendarSetPath; Overrides = $microStrict + $noAdaptive }
)

if(Test-Path -LiteralPath $PackageDir) { Remove-Item -LiteralPath $PackageDir -Recurse -Force }
New-Item -ItemType Directory -Path (Join-Path $PackageDir "configs") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $PackageDir "reports_here") -Force | Out-Null

$expected = New-Object System.Collections.Generic.List[object]
$rank = 0
foreach($profile in $profiles) {
   foreach($window in $windows) {
      $rank++
      $inputs = Import-SetInputs $profile.SetPath
      Set-InputLine -Inputs $inputs -Name "InpAllowedSymbol" -Value "XAUUSD"
      Set-InputLine -Inputs $inputs -Name "InpSignalTimeframe" -Value "15"
      Set-InputLine -Inputs $inputs -Name "InpShowDashboard" -Value "false"
      Set-InputLine -Inputs $inputs -Name "InpDashboardInTester" -Value "false"
      Set-InputLine -Inputs $inputs -Name "InpLogLevel" -Value "0"
      foreach($entry in $profile.Overrides.GetEnumerator()) {
         Set-InputLine -Inputs $inputs -Name $entry.Key -Value ([string]$entry.Value)
      }
      $configName = "{0:000}_{1}_{2}.ini" -f $rank, $profile.Name, $window.Window
      $reportName = "flat_micro_{0}_{1}" -f $profile.Name, $window.Window
      Write-Config -Path (Join-Path $PackageDir "configs\$configName") -ReportName $reportName -From $window.From -To $window.To -Inputs $inputs
      $expected.Add([pscustomobject]@{
         Rank = $rank; Profile = $profile.Name; Phase = $window.Phase; Set = $window.Phase; Window = $window.Window;
         From = $window.From; To = $window.To; Config = "configs\$configName"; ExpectedReportName = $reportName
      }) | Out-Null
   }
}

$expected | Export-Csv -LiteralPath (Join-Path $PackageDir "EXPECTED_REPORTS.csv") -NoTypeInformation
$expected | Export-Csv -LiteralPath "outputs\FLAT_MICRO_REVERSION_MANIFEST.csv" -NoTypeInformation
"Built $rank flat micro reversion configs in $PackageDir"
