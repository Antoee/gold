param(
   [string]$OutputDirectory = "outputs\rdmc_diversified_repair_executable_gate_package"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$package = Join-Path $repo $OutputDirectory
$sourceOrigin = Join-Path $repo "outputs\rdmc_diversified_repair_restart_safe_model1_package\source\Professional_XAUUSD_EA.mq5"
$profileOrigin = Join-Path $repo "outputs\rdmc_diversified_repair_restart_safe_model1_package\profiles\rdmc_diversified_repair_restart_safe_v2.set"
$source = Join-Path $package "source\Professional_XAUUSD_EA.mq5"
$profile = Join-Path $package "profiles\rdmc_diversified_repair_restart_safe_v2.set"
$configs = Join-Path $package "configs"
$reports = Join-Path $package "reports_here"
$manifestPath = Join-Path $repo "outputs\RDMC_DIVERSIFIED_REPAIR_EXECUTABLE_GATE_MANIFEST.csv"
$contractPath = Join-Path $repo "outputs\RDMC_DIVERSIFIED_REPAIR_EXECUTABLE_GATE_CONTRACT.md"
$repoLock = Join-Path $repo "work\MT5_LOCAL_LAUNCH_DISABLED.lock"
$outerLock = Join-Path (Split-Path -Parent $repo) "MT5_LOCAL_LAUNCH_DISABLED.lock"
$repoUnlock = Join-Path $repo "work\ALLOW_MT5_LOCAL_LAUNCH.unlock"
$outerUnlock = Join-Path (Split-Path -Parent $repo) "ALLOW_MT5_LOCAL_LAUNCH.unlock"

$expectedSourceHash = "EC6F866B8F7786169F7B2ECE5553CF3A4DC6E6073D0B25389C16381B71FEF51F"
$expectedProfileHash = "746798EF260A375F8F8921DBC6D03CD3968ED38F5C105818598CA57572A0B883"
$candidate = "rdmc_diversified_repair_restart_safe_v2"
$dataCutoff = "2026.07.12"

foreach($required in @($sourceOrigin, $profileOrigin, $repoLock, $outerLock)) {
   if(!(Test-Path -LiteralPath $required -PathType Leaf)) {
      throw "Required frozen input or launch lock is missing: $required"
   }
}
foreach($unexpected in @($repoUnlock, $outerUnlock)) {
   if(Test-Path -LiteralPath $unexpected) {
      throw "Unexpected MT5 launch unlock is present: $unexpected"
   }
}

$sourceHash = (Get-FileHash -LiteralPath $sourceOrigin -Algorithm SHA256).Hash.ToUpperInvariant()
$profileHash = (Get-FileHash -LiteralPath $profileOrigin -Algorithm SHA256).Hash.ToUpperInvariant()
if($sourceHash -ne $expectedSourceHash) { throw "Frozen source identity changed." }
if($profileHash -ne $expectedProfileHash) { throw "Frozen profile identity changed." }

$sourceText = Get-Content -LiteralPath $sourceOrigin -Raw
$sourceInputs = @([regex]::Matches($sourceText, '(?m)^input\s+\S+\s+(Inp[A-Za-z0-9_]+)\s*=') |
   ForEach-Object { $_.Groups[1].Value })
$profileLines = @(Get-Content -LiteralPath $profileOrigin)
$profileInputs = @($profileLines | ForEach-Object {
   if($_ -match '^([^;=]+)=') { $matches[1] }
})
if($sourceInputs.Count -ne 589 -or $profileInputs.Count -ne 589) {
   throw "Expected 589 source/profile inputs; found source=$($sourceInputs.Count) profile=$($profileInputs.Count)."
}
if(@($sourceInputs | Group-Object | Where-Object Count -gt 1).Count -gt 0 -or
   @($profileInputs | Group-Object | Where-Object Count -gt 1).Count -gt 0 -or
   @($sourceInputs | Where-Object { $_ -notin $profileInputs }).Count -gt 0 -or
   @($profileInputs | Where-Object { $_ -notin $sourceInputs }).Count -gt 0) {
   throw "The frozen profile does not exactly cover the source input surface."
}

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $source), (Split-Path -Parent $profile), $configs, $reports | Out-Null
Copy-Item -LiteralPath $sourceOrigin -Destination $source -Force
Copy-Item -LiteralPath $profileOrigin -Destination $profile -Force
Get-ChildItem -LiteralPath $configs -Filter "*.ini" -File -ErrorAction SilentlyContinue | Remove-Item -Force

$rows = [System.Collections.Generic.List[object]]::new()
$rank = 0

function Add-GateRow {
   param(
      [int]$Wave,
      [string]$Phase,
      [string]$Role,
      [string]$Window,
      [string]$From,
      [string]$To,
      [int]$Model,
      [double]$MinNetProfit,
      [double]$MinProfitFactor,
      [int]$MinTrades,
      [double]$MaxDrawdownPercent,
      [double]$MinRecoveryFactor,
      [double]$MinCagrPercent,
      [int]$MaxParallelism,
      [string]$StopRule
   )

   $script:rank++
   $modelName = "m$Model"
   $reportName = "rdmc_exec_w{0:D2}_{1}_{2}_{3}" -f $Wave, $modelName, $Role, $Window
   $configName = "{0:D3}_{1}.ini" -f $script:rank, $reportName
   $configPath = Join-Path $configs $configName
   $configLines = [System.Collections.Generic.List[string]]::new()
   foreach($line in @(
      "[Tester]", "Expert=Professional_XAUUSD_EA.ex5", "Symbol=XAUUSD", "Period=15",
      "Optimization=0", "Model=$Model", "FromDate=$From", "ToDate=$To", "ForwardMode=0",
      "Deposit=10000", "Currency=USD", "ProfitInPips=0", "Leverage=100", "ExecutionMode=0",
      "OptimizationCriterion=6", "Visual=0", "Report=$reportName", "ReplaceReport=1",
      "ShutdownTerminal=1", "[TesterInputs]"
   )) { $configLines.Add($line) }
   foreach($line in $profileLines) { $configLines.Add($line) }
   [IO.File]::WriteAllLines($configPath, $configLines.ToArray(), [Text.Encoding]::ASCII)
   $configHash = (Get-FileHash -LiteralPath $configPath -Algorithm SHA256).Hash.ToUpperInvariant()
   $relativeConfig = "$OutputDirectory\configs\$configName"
   $relativeReport = "$OutputDirectory\reports_here\$reportName"

   $rows.Add([pscustomobject]@{
      QueueRank = $script:rank
      Rank = $script:rank
      Wave = $Wave
      Phase = $Phase
      Role = $Role
      Candidate = $candidate
      Profile = $candidate
      Set = "frozen"
      Window = $Window
      From = $From
      To = $To
      Model = $Model
      Deposit = 10000
      InitialDeposit = 10000
      PackageConfig = $relativeConfig
      SourceConfig = $relativeConfig
      ExpectedReportName = $reportName
      ReportDestination = $relativeReport
      ProfileSha256 = $profileHash
      SourceSha256 = $sourceHash
      ConfigSha256 = $configHash
      MinNetProfit = $MinNetProfit
      MinProfitFactor = $MinProfitFactor
      MinTrades = $MinTrades
      MaxDrawdownPercent = $MaxDrawdownPercent
      MinRecoveryFactor = $MinRecoveryFactor
      MinCagrPercent = $MinCagrPercent
      MaxParallelism = $MaxParallelism
      StopRule = $StopRule
      Status = "LOCKED_LOCAL_LAUNCH_DISABLED"
   })
}

$criticalRule = "Reject immediately unless net>0, PF>=1.05, trades meet the frozen floor, and equity drawdown<=3%."
$broadRule = "Reject unless every disjoint broad era is profitable with PF>=1.20, sufficient activity, and equity drawdown<=5%."
$continuousM1Rule = "Model1 is triage only: require net>0, PF>=1.25, >=250 trades, <=5% drawdown, >=2 recovery, and >=0.75% CAGR."
$continuousM4Rule = "Require net>0, PF>=1.30, >=250 trades, <=5% drawdown, >=3 recovery, and >=1.00% CAGR."
$annualRule = "Require all 12 annual/YTD real-tick rows profitable, within the activity and 3% drawdown floors, then enforce annual-sum/continuous-net consistency of 0.75x to 1.25x."

Add-GateRow 1 "wave_01_m1_critical" "critical" "2019" "2019.01.01" "2019.12.31" 1 0.01 1.05 15 3.0 0.0 0.0 2 $criticalRule
Add-GateRow 1 "wave_01_m1_critical" "critical" "2022" "2022.01.01" "2022.12.31" 1 0.01 1.05 20 3.0 0.0 0.0 2 $criticalRule

Add-GateRow 2 "wave_02_m1_broad" "broad" "older_2015_2018" "2015.01.01" "2018.12.31" 1 0.01 1.20 80 5.0 0.0 0.0 4 $broadRule
Add-GateRow 2 "wave_02_m1_broad" "broad" "middle_2019_2022" "2019.01.01" "2022.12.31" 1 0.01 1.20 80 5.0 0.0 0.0 4 $broadRule
Add-GateRow 2 "wave_02_m1_broad" "broad" "recent_2023_2026" "2023.01.01" $dataCutoff 1 0.01 1.20 30 5.0 0.0 0.0 4 $broadRule
Add-GateRow 2 "wave_02_m1_broad" "continuous" "continuous_2015_2026" "2015.01.01" $dataCutoff 1 0.01 1.25 250 5.0 2.0 0.75 4 $continuousM1Rule

Add-GateRow 3 "wave_03_m4_critical" "critical" "2019" "2019.01.01" "2019.12.31" 4 0.01 1.05 15 3.0 0.0 0.0 2 $criticalRule
Add-GateRow 3 "wave_03_m4_critical" "critical" "2022" "2022.01.01" "2022.12.31" 4 0.01 1.05 20 3.0 0.0 0.0 2 $criticalRule

Add-GateRow 4 "wave_04_m4_broad" "broad" "older_2015_2018" "2015.01.01" "2018.12.31" 4 0.01 1.20 80 5.0 0.0 0.0 4 $broadRule
Add-GateRow 4 "wave_04_m4_broad" "broad" "middle_2019_2022" "2019.01.01" "2022.12.31" 4 0.01 1.20 80 5.0 0.0 0.0 4 $broadRule
Add-GateRow 4 "wave_04_m4_broad" "broad" "recent_2023_2026" "2023.01.01" $dataCutoff 4 0.01 1.20 30 5.0 0.0 0.0 4 $broadRule
Add-GateRow 4 "wave_04_m4_broad" "continuous" "continuous_2015_2026" "2015.01.01" $dataCutoff 4 0.01 1.30 250 5.0 3.0 1.00 4 $continuousM4Rule

$annualMinimumTrades = @{
   "2015"=8; "2016"=15; "2017"=20; "2018"=20; "2019"=15; "2020"=12
   "2021"=15; "2022"=20; "2023"=20; "2024"=15; "2025"=1; "2026_ytd"=1
}
for($year = 2015; $year -le 2025; $year++) {
   $label = [string]$year
   Add-GateRow 5 "wave_05_m4_annual" "annual" $label "$year.01.01" "$year.12.31" 4 0.01 1.00 $annualMinimumTrades[$label] 3.0 0.0 0.0 6 $annualRule
}
Add-GateRow 5 "wave_05_m4_annual" "annual" "2026_ytd" "2026.01.01" $dataCutoff 4 0.01 1.00 $annualMinimumTrades["2026_ytd"] 3.0 0.0 0.0 6 $annualRule

if($rows.Count -ne 24) { throw "Expected 24 frozen gate rows; found $($rows.Count)." }
$rows | Export-Csv -LiteralPath $manifestPath -NoTypeInformation -Encoding ASCII
for($wave = 1; $wave -le 5; $wave++) {
   $wavePath = Join-Path $repo ("outputs\RDMC_DIVERSIFIED_REPAIR_EXECUTABLE_GATE_WAVE_{0:D2}_MANIFEST.csv" -f $wave)
   @($rows | Where-Object Wave -eq $wave) | Export-Csv -LiteralPath $wavePath -NoTypeInformation -Encoding ASCII
}

$lines = [System.Collections.Generic.List[string]]::new()
foreach($line in @(
   "# RDMC Diversified Repair Executable Gate Contract",
   "",
   "Status: **FROZEN / LOCKED / ZERO MT5 REPORTS / NOT PROMOTED**",
   "",
   "This contract replaces chronological all-at-once testing with early rejection. It preserves the exact source and profile while spending real-tick time only after cheaper evidence passes.",
   "",
   "## Frozen Identity",
   "",
   "- Source SHA-256: ``$sourceHash``",
   "- Profile SHA-256: ``$profileHash``",
   "- Starting capital: ``10,000 USD``",
   "- Symbol/timeframe: ``XAUUSD M15``",
   "- Data cutoff: ``$dataCutoff``",
   "- Configs: ``$($rows.Count)`` with each config SHA-256 pinned in the combined manifest",
   "",
   "## Efficient Waves",
   "",
   "| Wave | Model | Runs | Maximum workers | Admission purpose |",
   "|---:|---|---:|---:|---|",
   "| 1 | Model1 | 2 | 2 | Reject immediately on the known 2019 or 2022 failure year |",
   "| 2 | Model1 | 4 | 4 | Check three disjoint broad eras plus the continuous path |",
   "| 3 | Model4 real ticks | 2 | 2 | Recheck 2019 and 2022 before broad real-tick cost |",
   "| 4 | Model4 real ticks | 4 | 4 | Check broad eras and continuous risk-adjusted return |",
   "| 5 | Model4 real ticks | 12 | 6 | Prove annual restart stability only after all earlier gates pass |",
   "",
   "A failed or incomplete wave never admits later waves. At most two tests are spent before the first rejection decision and only eight tests are spent before real-tick testing begins.",
   "",
   "## Frozen Gates",
   "",
   "- Critical 2019/2022 rows: positive net, PF at least ``1.05``, frozen activity floor, and drawdown no higher than ``3%``.",
   "- Broad eras: every disjoint era positive, PF at least ``1.20``, frozen activity floor, and drawdown no higher than ``5%``.",
   "- Continuous Model1 triage: PF at least ``1.25``, at least ``250`` trades, drawdown no higher than ``5%``, recovery at least ``2``, and CAGR at least ``0.75%``.",
   "- Continuous Model4: PF at least ``1.30``, at least ``250`` trades, drawdown no higher than ``5%``, recovery at least ``3``, and CAGR at least ``1.00%``.",
   "- Annual Model4: all 12 annual/YTD rows profitable with frozen activity floors and drawdown no higher than ``3%``; summed annual net must remain within ``0.75x`` to ``1.25x`` of continuous Model4 net.",
   "",
   "## Hard Boundary",
   "",
   "- Both MT5 launch locks are present. No terminal, MetaEditor, tester, or worker was launched to build this package.",
   "- Model1 only rejects cheaply; it can never promote the candidate.",
   "- Passing wave 5 still requires an executable trade ledger, deterministic cost stress, order-aware Monte Carlo, broker variation, and a valid forward demo.",
   "- The post-hoc ``+`$2,067.64`` collision score is not attributed to this source. The registered forward candidate and real-account lock remain unchanged."
)) { $lines.Add($line) }
[IO.File]::WriteAllLines($contractPath, $lines.ToArray(), [Text.Encoding]::ASCII)

[pscustomobject]@{
   Status = "FROZEN_LOCKED"
   Rows = $rows.Count
   Waves = 5
   Model1Runs = @($rows | Where-Object Model -eq 1).Count
   Model4Runs = @($rows | Where-Object Model -eq 4).Count
   SourceSha256 = $sourceHash
   ProfileSha256 = $profileHash
}
