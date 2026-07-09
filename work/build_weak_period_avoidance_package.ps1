param(
   [string]$BaseSetPath = "outputs\CANDIDATE_PEAK15_LIQUIDITY_STOP_CHOP_PROFILE.set",
   [string]$PackageDir = "work\local_mt5_weak_period_avoidance_package",
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

$profiles = @(
   [pscustomobject]@{ Name = "block_mar_may_jun"; Overrides = @{
      InpUseMonthFilter = "true"; InpTradeMarch = "false"; InpTradeMay = "false"; InpTradeJune = "false"
   }},
   [pscustomobject]@{ Name = "block_may_jun"; Overrides = @{
      InpUseMonthFilter = "true"; InpTradeMay = "false"; InpTradeJune = "false"
   }},
   [pscustomobject]@{ Name = "block_march_only"; Overrides = @{
      InpUseMonthFilter = "true"; InpTradeMarch = "false"
   }},
   [pscustomobject]@{ Name = "block_may_only"; Overrides = @{
      InpUseMonthFilter = "true"; InpTradeMay = "false"
   }},
   [pscustomobject]@{ Name = "block_june_only"; Overrides = @{
      InpUseMonthFilter = "true"; InpTradeJune = "false"
   }},
   [pscustomobject]@{ Name = "month_start_day5"; Overrides = @{
      InpUseMonthStartFilter = "true"; InpMonthStartMinDay = "5"
   }},
   [pscustomobject]@{ Name = "month_start_day8"; Overrides = @{
      InpUseMonthStartFilter = "true"; InpMonthStartMinDay = "8"
   }},
   [pscustomobject]@{ Name = "weekday_no_monday_friday"; Overrides = @{
      InpUseDayOfWeekRiskScaling = "true"; InpMondayRiskMultiplier = "0.00"; InpFridayRiskMultiplier = "0.00"
   }},
   [pscustomobject]@{ Name = "weekday_no_tuesday"; Overrides = @{
      InpUseDayOfWeekRiskScaling = "true"; InpTuesdayRiskMultiplier = "0.00"
   }},
   [pscustomobject]@{ Name = "weekday_no_wednesday"; Overrides = @{
      InpUseDayOfWeekRiskScaling = "true"; InpWednesdayRiskMultiplier = "0.00"
   }},
   [pscustomobject]@{ Name = "weekday_no_thursday"; Overrides = @{
      InpUseDayOfWeekRiskScaling = "true"; InpThursdayRiskMultiplier = "0.00"
   }},
   [pscustomobject]@{ Name = "ny_only"; Overrides = @{
      InpUseLondonSession = "false"; InpUseNewYorkSession = "true"
   }},
   [pscustomobject]@{ Name = "london_only"; Overrides = @{
      InpUseLondonSession = "true"; InpUseNewYorkSession = "false"
   }},
   [pscustomobject]@{ Name = "block_may_jun_day5"; Overrides = @{
      InpUseMonthFilter = "true"; InpTradeMay = "false"; InpTradeJune = "false";
      InpUseMonthStartFilter = "true"; InpMonthStartMinDay = "5"
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
      foreach($entry in $profile.Overrides.GetEnumerator()) {
         Set-InputLine -Inputs $inputs -Name $entry.Key -Value ([string]$entry.Value)
      }
      $configName = "{0:000}_{1}_{2}.ini" -f $rank, $profile.Name, $window.Window
      $reportName = "weak_avoid_{0}_{1}" -f $profile.Name, $window.Window
      Write-Config -Path (Join-Path $PackageDir "configs\$configName") -ReportName $reportName -From $window.From -To $window.To -Inputs $inputs
      $expected += [pscustomobject]@{
         Rank = $rank; Profile = $profile.Name; Phase = $window.Phase; Window = $window.Window;
         From = $window.From; To = $window.To; Config = "configs\$configName"; ExpectedReportName = $reportName
      }
   }
}

$expected | Export-Csv -LiteralPath (Join-Path $PackageDir "EXPECTED_REPORTS.csv") -NoTypeInformation
"Built $rank weak-period avoidance configs in $PackageDir"
