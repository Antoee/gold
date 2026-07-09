param(
   [string]$BaseSetPath = "outputs\CANDIDATE_PEAK15_LIQUIDITY_STOP_CHOP_PROFILE.set",
   [string]$PackageDir = "work\local_mt5_m5_secondary_package",
   [string]$ReportRoot = "outputs"
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
   [pscustomobject]@{ Window = "2024_to_2026"; Phase = "full";   From = "2024.01.01"; To = "2026.07.02" },
   [pscustomobject]@{ Window = "2026_ytd";     Phase = "recent"; From = "2026.01.01"; To = "2026.07.02" },
   [pscustomobject]@{ Window = "2025_full";    Phase = "oos";    From = "2025.01.01"; To = "2025.12.31" },
   [pscustomobject]@{ Window = "2024_full";    Phase = "train";  From = "2024.01.01"; To = "2024.12.31" },
   [pscustomobject]@{ Window = "2026_03";      Phase = "weak";   From = "2026.03.01"; To = "2026.03.31" },
   [pscustomobject]@{ Window = "2026_05";      Phase = "weak";   From = "2026.05.01"; To = "2026.05.31" },
   [pscustomobject]@{ Window = "2026_06";      Phase = "weak";   From = "2026.06.01"; To = "2026.06.30" }
)

$common = @{
   InpUseM5TightLiquiditySecondaryLane = "true"
   InpM5TightLiquidityTimeframe = "5"
   InpM5TightLiquidityMinADX = "22.0"
   InpM5TightLiquidityADXStrengthLookback = "4"
   InpM5TightLiquidityADXMinIncrease = "1.0"
   InpM5TightLiquidityTrendEMAPeriod = "200"
   InpM5TightLiquidityTrendSlopeLookback = "8"
   InpM5TightLiquidityMinSlopePoints = "20.0"
   InpM5TightLiquidityBOSLookbackBars = "20"
   InpM5TightLiquiditySweepLookbackBars = "10"
   InpM5TightLiquidityStopLookbackBars = "10"
   InpM5TightLiquidityStopBufferATR = "0.08"
   InpM5TightLiquidityStopBufferPoints = "15.0"
   InpM5TightLiquidityStopATRMultiplier = "1.10"
   InpM5TightLiquidityTakeProfitATRMultiplier = "2.40"
   InpM5TightLiquidityMinRR = "1.25"
}

$profiles = @(
   [pscustomobject]@{ Name = "m15_peak_plus_m5_r100_cap4_align"; Overrides = @{
      InpM5TightLiquidityRiskMultiplier = "1.00"; InpM5TightLiquidityMaxMonthlyEntries = "4"; InpM5TightLiquidityRequireM15Alignment = "true"
   }},
   [pscustomobject]@{ Name = "m15_peak_plus_m5_r100_cap8_align"; Overrides = @{
      InpM5TightLiquidityRiskMultiplier = "1.00"; InpM5TightLiquidityMaxMonthlyEntries = "8"; InpM5TightLiquidityRequireM15Alignment = "true"
   }},
   [pscustomobject]@{ Name = "m15_peak_plus_m5_r150_cap8_align"; Overrides = @{
      InpM5TightLiquidityRiskMultiplier = "1.50"; InpM5TightLiquidityMaxMonthlyEntries = "8"; InpM5TightLiquidityRequireM15Alignment = "true"
   }},
   [pscustomobject]@{ Name = "m15_peak_plus_m5_r150_cap12_align"; Overrides = @{
      InpM5TightLiquidityRiskMultiplier = "1.50"; InpM5TightLiquidityMaxMonthlyEntries = "12"; InpM5TightLiquidityRequireM15Alignment = "true"
   }},
   [pscustomobject]@{ Name = "m15_peak_plus_m5_r150_cap8_free"; Overrides = @{
      InpM5TightLiquidityRiskMultiplier = "1.50"; InpM5TightLiquidityMaxMonthlyEntries = "8"; InpM5TightLiquidityRequireM15Alignment = "false"
   }},
   [pscustomobject]@{ Name = "m15_peak_plus_m5_r200_cap8_align"; Overrides = @{
      InpM5TightLiquidityRiskMultiplier = "2.00"; InpM5TightLiquidityMaxMonthlyEntries = "8"; InpM5TightLiquidityRequireM15Alignment = "true"
   }},
   [pscustomobject]@{ Name = "m15_peak_m5_override_r100_q6"; Overrides = @{
      InpM5TightLiquidityRiskMultiplier = "1.00"; InpM5TightLiquidityMaxMonthlyEntries = "8"; InpM5TightLiquidityRequireM15Alignment = "true";
      InpM5TightLiquidityAllowPrimaryOverride = "true"; InpM5TightLiquidityOverrideMaxPrimaryQuality = "6"; InpM5TightLiquidityOverrideRequireSameBias = "true"
   }},
   [pscustomobject]@{ Name = "m15_peak_m5_override_r150_q6"; Overrides = @{
      InpM5TightLiquidityRiskMultiplier = "1.50"; InpM5TightLiquidityMaxMonthlyEntries = "8"; InpM5TightLiquidityRequireM15Alignment = "true";
      InpM5TightLiquidityAllowPrimaryOverride = "true"; InpM5TightLiquidityOverrideMaxPrimaryQuality = "6"; InpM5TightLiquidityOverrideRequireSameBias = "true"
   }},
   [pscustomobject]@{ Name = "m15_peak_m5_override_r100_q8"; Overrides = @{
      InpM5TightLiquidityRiskMultiplier = "1.00"; InpM5TightLiquidityMaxMonthlyEntries = "12"; InpM5TightLiquidityRequireM15Alignment = "true";
      InpM5TightLiquidityAllowPrimaryOverride = "true"; InpM5TightLiquidityOverrideMaxPrimaryQuality = "8"; InpM5TightLiquidityOverrideRequireSameBias = "true"
   }},
   [pscustomobject]@{ Name = "m15_peak_m5_override_r150_q8"; Overrides = @{
      InpM5TightLiquidityRiskMultiplier = "1.50"; InpM5TightLiquidityMaxMonthlyEntries = "12"; InpM5TightLiquidityRequireM15Alignment = "true";
      InpM5TightLiquidityAllowPrimaryOverride = "true"; InpM5TightLiquidityOverrideMaxPrimaryQuality = "8"; InpM5TightLiquidityOverrideRequireSameBias = "true"
   }}
)

if(Test-Path -LiteralPath $PackageDir) { Remove-Item -LiteralPath $PackageDir -Recurse -Force }
New-Item -ItemType Directory -Path (Join-Path $PackageDir "configs") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $PackageDir "reports_here") -Force | Out-Null

$rank = 0
$expected = @()
foreach($profile in $profiles) {
   foreach($window in $windows) {
      $rank++
      $inputs = Import-SetInputs $BaseSetPath
      Set-InputLine -Inputs $inputs -Name "InpAllowedSymbol" -Value "XAUUSD"
      Set-InputLine -Inputs $inputs -Name "InpSignalTimeframe" -Value "15"
      Set-InputLine -Inputs $inputs -Name "InpShowDashboard" -Value "false"
      Set-InputLine -Inputs $inputs -Name "InpDashboardInTester" -Value "false"
      Set-InputLine -Inputs $inputs -Name "InpLogLevel" -Value "0"
      foreach($entry in $common.GetEnumerator()) {
         Set-InputLine -Inputs $inputs -Name $entry.Key -Value ([string]$entry.Value)
      }
      foreach($entry in $profile.Overrides.GetEnumerator()) {
         Set-InputLine -Inputs $inputs -Name $entry.Key -Value ([string]$entry.Value)
      }
      $configName = "{0:000}_{1}_{2}.ini" -f $rank, $profile.Name, $window.Window
      $reportName = "m5_secondary_{0}_{1}" -f $profile.Name, $window.Window
      Write-Config -Path (Join-Path $PackageDir "configs\$configName") -ReportName $reportName -From $window.From -To $window.To -Inputs $inputs
      $expected += [pscustomobject]@{
         Rank = $rank; Profile = $profile.Name; Phase = $window.Phase; Window = $window.Window;
         From = $window.From; To = $window.To; Config = "configs\$configName"; ExpectedReportName = $reportName
      }
   }
}

$expected | Export-Csv -LiteralPath (Join-Path $PackageDir "EXPECTED_REPORTS.csv") -NoTypeInformation
"Built $rank M5 secondary configs in $PackageDir"
