param(
   [string]$SourcePath = "work\Independent_XAUUSD_M15_USD_Consensus_Lead_Lag.mq5",
   [string]$PackageDir = "outputs\independent_m15_usd_consensus_lead_lag_discovery_model1_package",
   [string]$QueueManifestPath = "outputs\INDEPENDENT_M15_USD_CONSENSUS_LEAD_LAG_DISCOVERY_MODEL1_QUEUE.csv",
   [string]$PackageManifestPath = "outputs\INDEPENDENT_M15_USD_CONSENSUS_LEAD_LAG_DISCOVERY_MODEL1_PACKAGE_MANIFEST.csv",
   [string]$MarkdownPath = "outputs\INDEPENDENT_M15_USD_CONSENSUS_LEAD_LAG_DISCOVERY_MODEL1_PACKAGE.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "seasonal_gate_helpers.ps1")
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$outputsRoot = (Resolve-Path (Join-Path $repo "outputs")).Path
function Resolve-RepoPath([string]$Path) { if([IO.Path]::IsPathRooted($Path)) { return $Path }; return Join-Path $repo $Path }
function Clear-OutputDirSafe([string]$Path) {
   if(Test-Path -LiteralPath $Path) {
      $resolved = (Resolve-Path -LiteralPath $Path).Path
      if(!$resolved.StartsWith($outputsRoot, [StringComparison]::OrdinalIgnoreCase)) { throw "Refusing to clear non-outputs directory: $resolved" }
      Remove-Item -LiteralPath $resolved -Recurse -Force
   }
   New-Item -ItemType Directory -Path $Path -Force | Out-Null
}
function New-BaseInputs {
   $inputs = [ordered]@{}
   $defaults = [ordered]@{
      InpAllowedSymbol = "XAUUSD"; InpEURUSDSymbol = "EURUSD"; InpUSDJPYSymbol = "USDJPY"
      InpMagicNumber = "26072011"; InpUseSymbolSafetyLock = "true"; InpUseRealAccountSafetyLock = "true"
      InpAllowRealAccountTrading = "false"; InpRealAccountApprovalCode = "DISABLED"
      InpEnforceInitialBalanceContract = "true"; InpExpectedInitialBalance = "10000.0"; InpInitialBalanceTolerance = "1.0"
      InpEnforceAccountCurrency = "true"; InpExpectedAccountCurrency = "USD"
      InpSignalTimeframe = "15"; InpProxyTimeframe = "16385"; InpProxyLookbackBars = "4"; InpProxyATRPeriod = "14"
      InpMaximumAlignmentSeconds = "3600"; InpMinimumProxyComponentATR = "0.10"; InpMinimumConsensusATR = "0.25"
      InpMinimumAlignedGoldMoveATR = "-0.25"; InpMaximumGoldExtensionATR = "0.35"
      InpBreakoutLookbackBars = "4"; InpBreakoutBufferATR = "0.05"; InpMinimumSignalBodyPercent = "30.0"
      InpRequireFreshBreakout = "true"; InpAllowBuy = "true"; InpAllowSell = "true"
      InpATRPeriod = "20"; InpStopLookbackBars = "6"; InpStopBufferATR = "0.15"; InpMinimumStopATR = "0.50"
      InpMaximumStopATR = "2.50"; InpMaximumStopPriceDistance = "8.00"; InpTakeProfitR = "1.75"
      InpMaximumHoldBars = "32"; InpExitHour = "20"; InpUseBreakEven = "true"
      InpBreakEvenTriggerR = "1.00"; InpBreakEvenLockR = "0.05"
      InpSessionStartHour = "6"; InpSessionEndHour = "18"; InpDisableFridayAfterHour = "true"; InpFridayEntryCutoffHour = "16"
      InpRiskPercent = "0.10"; InpMaximumPositionLots = "1.00"; InpMaximumDailyLossPercent = "0.75"
      InpMaximumEquityDrawdownPercent = "5.00"; InpMaximumConsecutiveLosses = "3"; InpLossCooldownHours = "24"
      InpMaximumSpreadPoints = "50.0"; InpDeviationPoints = "20"; InpRequireEmptyAccountAtEntry = "true"
      InpAccountWideMaxOpenRiskPercent = "1.00"; InpAccountWideBlockUnprotectedExposure = "true"
      InpLogTrades = "false"; InpLogFileName = "Independent_XAUUSD_M15_USD_Consensus_Lead_Lag_Trades.csv"
      InpEvidenceProfileId = ""; InpEvidenceSourceHash = ""; InpEvidenceRunLabel = ""
   }
   foreach($entry in $defaults.GetEnumerator()) { Set-InputLine -Inputs $inputs -Name $entry.Key -Value ([string]$entry.Value) }
   return $inputs
}

& (Join-Path $PSScriptRoot "test_independent_m15_usd_consensus_lead_lag_source.ps1") | Out-Null
$sourceFull = (Resolve-Path -LiteralPath (Resolve-RepoPath $SourcePath)).Path
$sourceHash = (Get-FileHash -LiteralPath $sourceFull -Algorithm SHA256).Hash
$variants = @(
   [pscustomobject]@{ Name="usdcll_center"; ProxyLookback="4"; Component="0.10"; Consensus="0.25"; GoldMax="0.35"; Breakout="4"; Buffer="0.05"; TPR="1.75" },
   [pscustomobject]@{ Name="usdcll_proxy3"; ProxyLookback="3"; Component="0.10"; Consensus="0.25"; GoldMax="0.35"; Breakout="4"; Buffer="0.05"; TPR="1.75" },
   [pscustomobject]@{ Name="usdcll_proxy6"; ProxyLookback="6"; Component="0.10"; Consensus="0.25"; GoldMax="0.35"; Breakout="4"; Buffer="0.05"; TPR="1.75" },
   [pscustomobject]@{ Name="usdcll_component05"; ProxyLookback="4"; Component="0.05"; Consensus="0.25"; GoldMax="0.35"; Breakout="4"; Buffer="0.05"; TPR="1.75" },
   [pscustomobject]@{ Name="usdcll_component15"; ProxyLookback="4"; Component="0.15"; Consensus="0.25"; GoldMax="0.35"; Breakout="4"; Buffer="0.05"; TPR="1.75" },
   [pscustomobject]@{ Name="usdcll_consensus15"; ProxyLookback="4"; Component="0.10"; Consensus="0.15"; GoldMax="0.35"; Breakout="4"; Buffer="0.05"; TPR="1.75" },
   [pscustomobject]@{ Name="usdcll_consensus35"; ProxyLookback="4"; Component="0.10"; Consensus="0.35"; GoldMax="0.35"; Breakout="4"; Buffer="0.05"; TPR="1.75" },
   [pscustomobject]@{ Name="usdcll_goldmax20"; ProxyLookback="4"; Component="0.10"; Consensus="0.25"; GoldMax="0.20"; Breakout="4"; Buffer="0.05"; TPR="1.75" },
   [pscustomobject]@{ Name="usdcll_goldmax50"; ProxyLookback="4"; Component="0.10"; Consensus="0.25"; GoldMax="0.50"; Breakout="4"; Buffer="0.05"; TPR="1.75" },
   [pscustomobject]@{ Name="usdcll_breakout3"; ProxyLookback="4"; Component="0.10"; Consensus="0.25"; GoldMax="0.35"; Breakout="3"; Buffer="0.05"; TPR="1.75" },
   [pscustomobject]@{ Name="usdcll_breakout6"; ProxyLookback="4"; Component="0.10"; Consensus="0.25"; GoldMax="0.35"; Breakout="6"; Buffer="0.05"; TPR="1.75" },
   [pscustomobject]@{ Name="usdcll_buffer00"; ProxyLookback="4"; Component="0.10"; Consensus="0.25"; GoldMax="0.35"; Breakout="4"; Buffer="0.00"; TPR="1.75" },
   [pscustomobject]@{ Name="usdcll_buffer10"; ProxyLookback="4"; Component="0.10"; Consensus="0.25"; GoldMax="0.35"; Breakout="4"; Buffer="0.10"; TPR="1.75" },
   [pscustomobject]@{ Name="usdcll_tp150"; ProxyLookback="4"; Component="0.10"; Consensus="0.25"; GoldMax="0.35"; Breakout="4"; Buffer="0.05"; TPR="1.50" },
   [pscustomobject]@{ Name="usdcll_tp200"; ProxyLookback="4"; Component="0.10"; Consensus="0.25"; GoldMax="0.35"; Breakout="4"; Buffer="0.05"; TPR="2.00" }
)
$windows = @(
   [pscustomobject]@{ Name="older_2015_2018"; From="2015.01.01"; To="2018.12.31" },
   [pscustomobject]@{ Name="discovery_2019_2020"; From="2019.01.01"; To="2020.12.31" },
   [pscustomobject]@{ Name="continuous_2015_2020"; From="2015.01.01"; To="2020.12.31" }
)

$packageFull = Resolve-RepoPath $PackageDir
Clear-OutputDirSafe $packageFull
$configDir = Join-Path $packageFull "configs"
$profileDir = Join-Path $packageFull "profiles"
$reportDir = Join-Path $packageFull "reports_here"
$sourceDir = Join-Path $packageFull "source"
New-Item -ItemType Directory -Path $configDir,$profileDir,$reportDir,$sourceDir -Force | Out-Null
Copy-Item -LiteralPath $sourceFull -Destination (Join-Path $sourceDir "Professional_XAUUSD_EA.mq5") -Force

$queueRows = [Collections.Generic.List[object]]::new()
$runRows = [Collections.Generic.List[object]]::new()
$ordinal = 0
$candidateRank = 0
$stopRule = "Discovery only: require both disjoint eras positive, continuous PF at least 1.20, at least 80 continuous trades, DD at or below 3%, positive payoff and return/DD at least 1.0, plus adjacent one-factor support before opening 2021-2026."
foreach($variant in $variants) {
   $candidateRank++
   $inputs = New-BaseInputs
   Set-InputLine $inputs "InpProxyLookbackBars" $variant.ProxyLookback
   Set-InputLine $inputs "InpMinimumProxyComponentATR" $variant.Component
   Set-InputLine $inputs "InpMinimumConsensusATR" $variant.Consensus
   Set-InputLine $inputs "InpMaximumGoldExtensionATR" $variant.GoldMax
   Set-InputLine $inputs "InpBreakoutLookbackBars" $variant.Breakout
   Set-InputLine $inputs "InpBreakoutBufferATR" $variant.Buffer
   Set-InputLine $inputs "InpTakeProfitR" $variant.TPR
   Set-InputLine $inputs "InpEvidenceProfileId" $variant.Name
   Set-InputLine $inputs "InpEvidenceSourceHash" $sourceHash
   Set-InputLine $inputs "InpEvidenceRunLabel" "independent_m15_usd_consensus_lead_lag_discovery_model1"
   Set-InputLine $inputs "InpLogFileName" "$($variant.Name)_trades.csv"
   $profileName = "$($variant.Name).set"
   $profilePath = Join-Path $profileDir $profileName
   @($inputs.Keys | Sort-Object | ForEach-Object { $inputs[$_] }) | Set-Content -LiteralPath $profilePath -Encoding ASCII
   $profileText = Get-Content -LiteralPath $profilePath -Raw
   if($profileText -notmatch '(?m)^InpEURUSDSymbol=EURUSD\r?$' -or
      $profileText -notmatch '(?m)^InpUSDJPYSymbol=USDJPY\r?$') {
      throw "Proxy symbol inputs were not serialized as literal strings: $profilePath"
   }
   $profileHash = (Get-FileHash -LiteralPath $profilePath -Algorithm SHA256).Hash
   foreach($window in $windows) {
      $ordinal++
      $pairIndex = [int][Math]::Floor(($ordinal - 1) / 2)
      $queueRank = 3 * $pairIndex + $(if(($ordinal % 2) -eq 1) { 1 } else { 3 })
      $configName = "{0:000}_{1}_{2}_m1.ini" -f $ordinal,$variant.Name,$window.Name
      $reportName = "$($variant.Name)_$($window.Name)_m1"
      Write-SeasonalTesterConfig -Path (Join-Path $configDir $configName) -ReportRoot $reportDir -ReportName $reportName `
         -From $window.From -To $window.To -Inputs $inputs -Model 1 -Deposit 10000 -Period 15
      $queueRows.Add([pscustomobject]@{
         QueueRank=$queueRank; Candidate=$variant.Name; CandidateRank=$candidateRank; SourceType="independent_m15_usd_consensus_lead_lag"
         SourceRank=1; Phase="discovery_model1"; Set=$profileName; Window=$window.Name; From=$window.From; To=$window.To
         Model=1; Deposit=10000; Config="configs\$configName"; ExpectedReportName=$reportName; ProfileSnapshot="profiles\$profileName"
         ProfileSha256=$profileHash; SourceSha256=$sourceHash; SignalTimeframe="15"; ProxyLookbackBars=$variant.ProxyLookback
         MinimumProxyComponentATR=$variant.Component; MinimumConsensusATR=$variant.Consensus; MaximumGoldExtensionATR=$variant.GoldMax
         BreakoutLookbackBars=$variant.Breakout; BreakoutBufferATR=$variant.Buffer; TakeProfitR=$variant.TPR; StopRule=$stopRule
      }) | Out-Null
      $runRows.Add([pscustomobject]@{
         QueueRank=$queueRank; Candidate=$variant.Name; Phase="discovery_model1"; PhaseLabel="Independent M15 USD-consensus lead-lag discovery Model1"
         Window=$window.Name; Model=1; Deposit=10000; PackageConfig="$PackageDir\configs\$configName"; SourceConfig="$PackageDir\configs\$configName"
         ExpectedReportName=$reportName; ReportDestination="$PackageDir\reports_here\$reportName"; ProfileSha256=$profileHash; StopRule=$stopRule
      }) | Out-Null
   }
}

$queueRows | Export-Csv -LiteralPath (Resolve-RepoPath $QueueManifestPath) -NoTypeInformation -Encoding ASCII
$runRows | Export-Csv -LiteralPath (Resolve-RepoPath $PackageManifestPath) -NoTypeInformation -Encoding ASCII
$md = @(
   "# Independent M15 USD-Consensus Lead-Lag Discovery Package", "",
   "Standalone cross-market research family. No configuration includes data after 2020.", "",
   "- Source SHA-256: ``$sourceHash``", "- Variants: ``$($variants.Count)``",
   "- Discovery windows: ``$($windows.Name -join ', ')``", "- Configurations: ``$ordinal``", "",
   'All profiles use completed H1 EURUSD/USDJPY/XAUUSD context and completed M15 breakout confirmation. Risk is fixed at `0.10%` with minimum-lot refusal, a `$10,000` initial-balance contract, account-wide exposure protection, daily and equity loss caps, one trade per day, and real-account trading disabled.'
)
$md | Set-Content -LiteralPath (Resolve-RepoPath $MarkdownPath) -Encoding ASCII
[pscustomobject]@{ Status="READY"; SourceHash=$sourceHash; Variants=$variants.Count; Windows=$windows.Count; Configurations=$ordinal; PackageDir=$PackageDir }
