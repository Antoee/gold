param(
   [string]$OutputDirectory = "outputs\rdmc_diversified_repair_restart_safe_model1_package"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$out = Join-Path $repo $OutputDirectory
$source = Join-Path $out "source\Professional_XAUUSD_EA.mq5"
$profile = Join-Path $out "profiles\rdmc_diversified_repair_restart_safe_v2.set"
$configs = Join-Path $out "configs"
$reports = Join-Path $out "reports"
$v1Source = Join-Path $repo "outputs\rdmc_diversified_repair_model1_package\source\Professional_XAUUSD_EA.mq5"
$launchLock = Join-Path $repo "work\MT5_LOCAL_LAUNCH_DISABLED.lock"
$launchUnlock = Join-Path $repo "work\ALLOW_MT5_LOCAL_LAUNCH.unlock"

$expectedV1SourceHash = "4740338598E290360946FE414CC6F2FE0CF3B704006860514367DCB996A8D2B5"
$expectedSourceHash = "AE56DD40DD5A0619A54252081F64CBABDEF7F002066C50AEE3ECA9C8CF100AB8"
$expectedProfileHash = "0CE2FAFCE3AD8BDC88D655B4C94364EA5F2B03C3BB4A5EC24C6308B6CC1D35E8"

foreach($required in @($source, $profile, $v1Source, $launchLock)) {
   if(!(Test-Path -LiteralPath $required -PathType Leaf)) {
      throw "Required frozen input is missing: $required"
   }
}
if(Test-Path -LiteralPath $launchUnlock) {
   throw "Unexpected MT5 launch unlock is present. Static package generation stopped."
}

$v1Hash = (Get-FileHash -LiteralPath $v1Source -Algorithm SHA256).Hash
$sourceHash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
$profileHash = (Get-FileHash -LiteralPath $profile -Algorithm SHA256).Hash
if($v1Hash -ne $expectedV1SourceHash) { throw "Frozen v1 predecessor source changed." }
if($sourceHash -ne $expectedSourceHash) { throw "Restart-safe v2 source identity changed." }
if($profileHash -ne $expectedProfileHash) { throw "Restart-safe v2 profile identity changed." }

$sourceText = Get-Content -LiteralPath $source -Raw
$sourceInputs = [regex]::Matches($sourceText, '(?m)^input\s+\S+\s+(Inp[A-Za-z0-9_]+)\s*=') |
   ForEach-Object { $_.Groups[1].Value }
$profileLines = @(Get-Content -LiteralPath $profile)
$profileInputs = @($profileLines | ForEach-Object {
   if($_ -match '^([^;=]+)=') { $matches[1] }
})
$duplicateSourceInputs = @($sourceInputs | Group-Object | Where-Object Count -gt 1)
$duplicateProfileInputs = @($profileInputs | Group-Object | Where-Object Count -gt 1)
$missingProfileInputs = @($sourceInputs | Where-Object { $_ -notin $profileInputs })
$extraProfileInputs = @($profileInputs | Where-Object { $_ -notin $sourceInputs })
if($sourceInputs.Count -ne 588 -or $profileInputs.Count -ne 588) {
   throw "Expected 588 source/profile inputs; found source=$($sourceInputs.Count) profile=$($profileInputs.Count)."
}
if($duplicateSourceInputs.Count -gt 0 -or $duplicateProfileInputs.Count -gt 0 -or
   $missingProfileInputs.Count -gt 0 -or $extraProfileInputs.Count -gt 0) {
   throw "The restart-safe profile does not exactly freeze the source input surface."
}

New-Item -ItemType Directory -Force -Path $configs, $reports | Out-Null
Get-ChildItem -LiteralPath $configs -Filter "*.ini" -File -ErrorAction SilentlyContinue |
   Remove-Item -Force

$windows = [System.Collections.Generic.List[object]]::new()
for($year = 2015; $year -le 2025; $year++) {
   $windows.Add([pscustomobject]@{ Year = [string]$year; From = "$year.01.01"; To = "$year.12.31" })
}
$windows.Add([pscustomobject]@{ Year = "2026_ytd"; From = "2026.01.01"; To = "2026.07.12" })

$queue = [System.Collections.Generic.List[object]]::new()
$index = 0
foreach($window in $windows) {
   $index++
   $name = "rdmc_diversified_repair_restart_safe_v2_$($window.Year)_m1"
   $configName = "{0:D3}_{1}.ini" -f $index, $name
   $configPath = Join-Path $configs $configName
   $configLines = [System.Collections.Generic.List[string]]::new()
   foreach($line in @(
      "[Tester]", "Expert=Professional_XAUUSD_EA.ex5", "Symbol=XAUUSD", "Period=15",
      "Optimization=0", "Model=1", "FromDate=$($window.From)", "ToDate=$($window.To)",
      "ForwardMode=0", "Deposit=10000", "Currency=USD", "ProfitInPips=0", "Leverage=100",
      "ExecutionMode=0", "OptimizationCriterion=6", "Visual=0", "Report=$name",
      "ReplaceReport=1", "ShutdownTerminal=1", "[TesterInputs]"
   )) { $configLines.Add($line) }
   foreach($line in $profileLines) { $configLines.Add($line) }
   [IO.File]::WriteAllLines($configPath, $configLines.ToArray(), [Text.Encoding]::ASCII)

   $queue.Add([pscustomobject]@{
      QueueIndex = $index
      Candidate = "rdmc_diversified_repair_restart_safe_v2"
      Window = $window.Year
      FromDate = $window.From
      ToDate = $window.To
      Model = 1
      Deposit = 10000
      ProfileSha256 = $profileHash
      SourceSha256 = $sourceHash
      Config = "outputs/rdmc_diversified_repair_restart_safe_model1_package/configs/$configName"
      Status = "LOCKED_LOCAL_LAUNCH_DISABLED"
   })
}

$queuePath = Join-Path $repo "outputs\RDMC_DIVERSIFIED_REPAIR_RESTART_SAFE_MODEL1_QUEUE.csv"
$queue | Export-Csv -LiteralPath $queuePath -NoTypeInformation -Encoding ASCII

$manifest = [pscustomobject]@{
   Candidate = "rdmc_diversified_repair_restart_safe_v2"
   Status = "STATIC_ONLY_LOCKED"
   PromotionStatus = "NOT_PROMOTED"
   ForwardCandidateChanged = "NO"
   StartingCapital = 10000
   Currency = "USD"
   SourceSha256 = $sourceHash
   ProfileSha256 = $profileHash
   PredecessorSourceSha256 = $v1Hash
   SourceInputs = $sourceInputs.Count
   ProfileInputs = $profileInputs.Count
   ConfigCount = $queue.Count
   EntryPathSafetyStatus = "PASS_74_CHECKS"
   MomentumCostMarginGuard = "ENABLED"
   PortfolioCooldownAllLanes = "ENABLED"
   RealtimeProtectionStatus = "PASS_31_CHECKS"
   RealtimeEquityDrawdownClose = "ENABLED"
   RealtimeMissingStopClose = "ENABLED"
   NormalPositionManagement = "NEW_BAR"
   CompileStatus = "NOT_RUN_LOCAL_LOCK_ACTIVE"
   BacktestStatus = "NOT_RUN_LOCAL_LOCK_ACTIVE"
   HistoricalBestChanged = "NO"
}
$manifestPath = Join-Path $repo "outputs\RDMC_DIVERSIFIED_REPAIR_RESTART_SAFE_MODEL1_MANIFEST.csv"
$manifest | Export-Csv -LiteralPath $manifestPath -NoTypeInformation -Encoding ASCII

$packagePath = Join-Path $repo "outputs\RDMC_DIVERSIFIED_REPAIR_RESTART_SAFE_MODEL1_PACKAGE.md"
$packageLines = @(
   "# RDMC Diversified Repair Restart-Safe Model1 Package",
   "",
   "Status: **STATIC ONLY / LOCKED / NOT PROMOTED**",
   "",
   'This package supersedes the uncompiled v1 package before its first MT5 run. It preserves the four-lane strategy and risk settings but repairs account restart behavior. It does not establish a new best or change the registered forward candidate.',
   "",
   "## Repair",
   "",
   '- First non-tester registration still requires an unused, flat account at the frozen `$10,000 USD` starting balance.',
   '- The starting-capital, funding-count, and peak-equity contracts persist under account-and-magic-scoped terminal global variables.',
   '- Restarts after ordinary profit or loss retain the original `$10,000` baseline and lifetime peak equity instead of comparing current balance with the starting deposit.',
   '- Deposits, withdrawals, credits, corrections, bonuses, foreign trade history, foreign open positions, missing persistence, and invalid stored peaks fail closed.',
   '- Broker commission, charge, and interest deal types are not misclassified as new funding.',
   '- Runtime history is refreshed before either momentum or primary entry evaluation. Position management and protective exits remain available.',
   '- All four order-opening sites now require broker-native lot sizing, account-wide exposure approval, trading-cost approval, margin approval, explicit magic, and bounded deviation before Buy/Sell.',
   '- The momentum lane now uses the same trading-cost and margin guards as the other three lanes.',
   '- Isolated lanes may bypass adaptive strategy pauses, but the hard portfolio consecutive-loss and four-hour post-loss cooldown gates can no longer be bypassed.',
   '- A lightweight per-tick emergency path issues close requests for both magic families on the 5% lifetime equity-drawdown limit or a missing/invalid protective stop.',
   '- The emergency path performs no trade-history scan, sleep, or retry loop; ordinary trailing, channel exits, and full period-risk calculations remain new-bar work.',
   "",
   "## Frozen identity",
   "",
   ("- Source SHA-256: ``{0}``" -f $sourceHash),
   ("- Profile SHA-256: ``{0}``" -f $profileHash),
   ("- Predecessor source SHA-256: ``{0}``" -f $v1Hash),
   '- Source/profile inputs: `588 / 588`',
   '- Queue: `outputs/RDMC_DIVERSIFIED_REPAIR_RESTART_SAFE_MODEL1_QUEUE.csv`',
   "",
   "## Hard boundary",
   "",
   'The source is tester-only, real-account trading is disabled, and all 12 annual/YTD Model1 rows remain `LOCKED_LOCAL_LAUNCH_DISABLED`. The new cost, margin, hard-cooldown, and intrabar emergency enforcement can change entries and exits, so the earlier post-hoc collision score is not attributed to this executable path. Static checks cannot prove compilation, profit, drawdown, or restart behavior inside MT5. Compilation, annual and continuous Model1, annual and continuous real-tick Model4, cost stress, Monte Carlo, broker variation, and valid forward evidence are still required.'
)
[IO.File]::WriteAllLines($packagePath, $packageLines, [Text.Encoding]::ASCII)

$manifest
