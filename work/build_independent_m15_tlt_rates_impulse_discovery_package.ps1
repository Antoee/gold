param(
   [string]$SourcePath = "work\Independent_XAUUSD_M15_TLT_Rates_Impulse.mq5",
   [string]$PackageDir = "outputs\independent_m15_tlt_rates_impulse_discovery_model1_package",
   [string]$QueueManifestPath = "outputs\INDEPENDENT_M15_TLT_RATES_IMPULSE_DISCOVERY_MODEL1_QUEUE.csv",
   [string]$PackageManifestPath = "outputs\INDEPENDENT_M15_TLT_RATES_IMPULSE_DISCOVERY_MODEL1_PACKAGE_MANIFEST.csv",
   [string]$MarkdownPath = "outputs\INDEPENDENT_M15_TLT_RATES_IMPULSE_DISCOVERY_MODEL1_PACKAGE.md"
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
      InpAllowedSymbol = "XAUUSD"; InpTLTSymbol = "TLT"
      InpMagicNumber = "26072013"; InpUseSymbolSafetyLock = "true"; InpUseRealAccountSafetyLock = "true"
      InpAllowRealAccountTrading = "false"; InpRealAccountApprovalCode = "DISABLED"
      InpEnforceInitialBalanceContract = "true"; InpExpectedInitialBalance = "10000.0"; InpInitialBalanceTolerance = "1.0"
      InpEnforceAccountCurrency = "true"; InpExpectedAccountCurrency = "USD"
      InpSignalTimeframe = "15"; InpReferenceTimeframe = "16408"; InpReferenceLookbackBars = "1"
      InpReferenceATRPeriod = "14"; InpReferenceTrendBars = "10"; InpMaximumAlignmentSeconds = "259200"
      InpMinimumReferenceMoveATR = "0.20"; InpRequireReferenceTrend = "true"
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
      InpLogTrades = "false"; InpLogFileName = "Independent_XAUUSD_M15_TLT_Rates_Impulse_Trades.csv"
      InpEvidenceProfileId = ""; InpEvidenceSourceHash = ""; InpEvidenceRunLabel = ""
   }
   foreach($entry in $defaults.GetEnumerator()) { Set-InputLine -Inputs $inputs -Name $entry.Key -Value ([string]$entry.Value) }
   return $inputs
}

& (Join-Path $PSScriptRoot "test_independent_m15_tlt_rates_impulse_source.ps1") | Out-Null
$sourceFull = (Resolve-Path -LiteralPath (Resolve-RepoPath $SourcePath)).Path
$sourceHash = (Get-FileHash -LiteralPath $sourceFull -Algorithm SHA256).Hash
$variants = @(
   [pscustomobject]@{ Name="tltri_center"; ReferenceLookback="1"; MinimumMove="0.20"; Trend="true"; TrendBars="10"; Breakout="4"; Buffer="0.05"; TPR="1.75"; SessionStart="6" },
   [pscustomobject]@{ Name="tltri_move10"; ReferenceLookback="1"; MinimumMove="0.10"; Trend="true"; TrendBars="10"; Breakout="4"; Buffer="0.05"; TPR="1.75"; SessionStart="6" },
   [pscustomobject]@{ Name="tltri_move30"; ReferenceLookback="1"; MinimumMove="0.30"; Trend="true"; TrendBars="10"; Breakout="4"; Buffer="0.05"; TPR="1.75"; SessionStart="6" },
   [pscustomobject]@{ Name="tltri_ref2"; ReferenceLookback="2"; MinimumMove="0.20"; Trend="true"; TrendBars="10"; Breakout="4"; Buffer="0.05"; TPR="1.75"; SessionStart="6" },
   [pscustomobject]@{ Name="tltri_ref3"; ReferenceLookback="3"; MinimumMove="0.20"; Trend="true"; TrendBars="10"; Breakout="4"; Buffer="0.05"; TPR="1.75"; SessionStart="6" },
   [pscustomobject]@{ Name="tltri_notrend"; ReferenceLookback="1"; MinimumMove="0.20"; Trend="false"; TrendBars="10"; Breakout="4"; Buffer="0.05"; TPR="1.75"; SessionStart="6" },
   [pscustomobject]@{ Name="tltri_trend5"; ReferenceLookback="1"; MinimumMove="0.20"; Trend="true"; TrendBars="5"; Breakout="4"; Buffer="0.05"; TPR="1.75"; SessionStart="6" },
   [pscustomobject]@{ Name="tltri_trend20"; ReferenceLookback="1"; MinimumMove="0.20"; Trend="true"; TrendBars="20"; Breakout="4"; Buffer="0.05"; TPR="1.75"; SessionStart="6" },
   [pscustomobject]@{ Name="tltri_break2"; ReferenceLookback="1"; MinimumMove="0.20"; Trend="true"; TrendBars="10"; Breakout="2"; Buffer="0.05"; TPR="1.75"; SessionStart="6" },
   [pscustomobject]@{ Name="tltri_break6"; ReferenceLookback="1"; MinimumMove="0.20"; Trend="true"; TrendBars="10"; Breakout="6"; Buffer="0.05"; TPR="1.75"; SessionStart="6" },
   [pscustomobject]@{ Name="tltri_buffer00"; ReferenceLookback="1"; MinimumMove="0.20"; Trend="true"; TrendBars="10"; Breakout="4"; Buffer="0.00"; TPR="1.75"; SessionStart="6" },
   [pscustomobject]@{ Name="tltri_buffer10"; ReferenceLookback="1"; MinimumMove="0.20"; Trend="true"; TrendBars="10"; Breakout="4"; Buffer="0.10"; TPR="1.75"; SessionStart="6" },
   [pscustomobject]@{ Name="tltri_tp150"; ReferenceLookback="1"; MinimumMove="0.20"; Trend="true"; TrendBars="10"; Breakout="4"; Buffer="0.05"; TPR="1.50"; SessionStart="6" },
   [pscustomobject]@{ Name="tltri_tp200"; ReferenceLookback="1"; MinimumMove="0.20"; Trend="true"; TrendBars="10"; Breakout="4"; Buffer="0.05"; TPR="2.00"; SessionStart="6" },
   [pscustomobject]@{ Name="tltri_start8"; ReferenceLookback="1"; MinimumMove="0.20"; Trend="true"; TrendBars="10"; Breakout="4"; Buffer="0.05"; TPR="1.75"; SessionStart="8" }
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
$stopRule = "Discovery only: require both disjoint eras positive, continuous PF at least 1.20, at least 100 continuous trades, DD at or below 3%, positive payoff and return/DD at least 1.0, plus adjacent one-factor support before opening 2021-2026."
foreach($variant in $variants) {
   $candidateRank++
   $inputs = New-BaseInputs
   Set-InputLine $inputs "InpReferenceLookbackBars" $variant.ReferenceLookback
   Set-InputLine $inputs "InpMinimumReferenceMoveATR" $variant.MinimumMove
   Set-InputLine $inputs "InpRequireReferenceTrend" $variant.Trend
   Set-InputLine $inputs "InpReferenceTrendBars" $variant.TrendBars
   Set-InputLine $inputs "InpBreakoutLookbackBars" $variant.Breakout
   Set-InputLine $inputs "InpBreakoutBufferATR" $variant.Buffer
   Set-InputLine $inputs "InpTakeProfitR" $variant.TPR
   Set-InputLine $inputs "InpSessionStartHour" $variant.SessionStart
   Set-InputLine $inputs "InpEvidenceProfileId" $variant.Name
   Set-InputLine $inputs "InpEvidenceSourceHash" $sourceHash
   Set-InputLine $inputs "InpEvidenceRunLabel" "independent_m15_tlt_rates_impulse_discovery_model1"
   Set-InputLine $inputs "InpLogFileName" "$($variant.Name)_trades.csv"
   $profileName = "$($variant.Name).set"
   $profilePath = Join-Path $profileDir $profileName
   @($inputs.Keys | Sort-Object | ForEach-Object { $inputs[$_] }) | Set-Content -LiteralPath $profilePath -Encoding ASCII
   $profileText = Get-Content -LiteralPath $profilePath -Raw
   if($profileText -notmatch '(?m)^InpTLTSymbol=TLT\r?$' -or
      $profileText -notmatch '(?m)^InpReferenceTimeframe=16408(?:\|\|16408\|\|0\|\|0\|\|N)?\r?$') {
      throw "TLT reference inputs were not serialized as fixed values: $profilePath"
   }
   $profileHash = (Get-FileHash -LiteralPath $profilePath -Algorithm SHA256).Hash
   foreach($window in $windows) {
      $ordinal++
      $queueRank = $ordinal
      $configName = "{0:000}_{1}_{2}_m1.ini" -f $ordinal,$variant.Name,$window.Name
      $reportName = "$($variant.Name)_$($window.Name)_m1"
      Write-SeasonalTesterConfig -Path (Join-Path $configDir $configName) -ReportRoot $reportDir -ReportName $reportName `
         -From $window.From -To $window.To -Inputs $inputs -Model 1 -Deposit 10000 -Period 15
      $queueRows.Add([pscustomobject]@{
         QueueRank=$queueRank; Candidate=$variant.Name; CandidateRank=$candidateRank; SourceType="independent_m15_tlt_rates_impulse"
         SourceRank=1; Phase="discovery_model1"; Set=$profileName; Window=$window.Name; From=$window.From; To=$window.To
         Model=1; Deposit=10000; Config="configs\$configName"; ExpectedReportName=$reportName; ProfileSnapshot="profiles\$profileName"
         ProfileSha256=$profileHash; SourceSha256=$sourceHash; SignalTimeframe="15"; ReferenceSymbol="TLT"
         ReferenceTimeframe="D1"; ReferenceLookbackBars=$variant.ReferenceLookback; MinimumReferenceMoveATR=$variant.MinimumMove
         RequireReferenceTrend=$variant.Trend; ReferenceTrendBars=$variant.TrendBars; BreakoutLookbackBars=$variant.Breakout
         BreakoutBufferATR=$variant.Buffer; TakeProfitR=$variant.TPR; SessionStartHour=$variant.SessionStart; StopRule=$stopRule
      }) | Out-Null
      $runRows.Add([pscustomobject]@{
         QueueRank=$queueRank; Candidate=$variant.Name; Phase="discovery_model1"; PhaseLabel="Independent M15 TLT rates-impulse discovery Model1"
         Window=$window.Name; Model=1; Deposit=10000; PackageConfig="$PackageDir\configs\$configName"; SourceConfig="$PackageDir\configs\$configName"
         ExpectedReportName=$reportName; ReportDestination="$PackageDir\reports_here\$reportName"; ProfileSha256=$profileHash; StopRule=$stopRule
      }) | Out-Null
   }
}

$queueRows | Export-Csv -LiteralPath (Resolve-RepoPath $QueueManifestPath) -NoTypeInformation -Encoding ASCII
$runRows | Export-Csv -LiteralPath (Resolve-RepoPath $PackageManifestPath) -NoTypeInformation -Encoding ASCII
$md = @(
   "# Independent M15 TLT Rates-Impulse Discovery Package", "",
   "Standalone cross-market rates-proxy research family. No configuration includes data after 2020.", "",
   "- Source SHA-256: ``$sourceHash``", "- Variants: ``$($variants.Count)``",
   "- Discovery windows: ``$($windows.Name -join ', ')``", "- Configurations: ``$ordinal``", "",
   'All profiles use only provably completed TLT D1 context and completed XAUUSD M15 breakout confirmation. Risk is fixed at `0.10%` with minimum-lot refusal, a `$10,000` initial-balance contract, account-wide exposure protection, daily and equity loss caps, one trade per day, and real-account trading disabled.'
)
$md | Set-Content -LiteralPath (Resolve-RepoPath $MarkdownPath) -Encoding ASCII
[pscustomobject]@{ Status="READY"; SourceHash=$sourceHash; Variants=$variants.Count; Windows=$windows.Count; Configurations=$ordinal; PackageDir=$PackageDir }
