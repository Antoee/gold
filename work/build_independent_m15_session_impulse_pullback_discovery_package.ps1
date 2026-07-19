param(
   [string]$SourcePath = "work\Independent_XAUUSD_M15_Session_Impulse_Pullback.mq5",
   [string]$PackageDir = "outputs\independent_m15_session_impulse_pullback_discovery_model1_package",
   [string]$QueueManifestPath = "outputs\INDEPENDENT_M15_SESSION_IMPULSE_PULLBACK_DISCOVERY_MODEL1_QUEUE.csv",
   [string]$PackageManifestPath = "outputs\INDEPENDENT_M15_SESSION_IMPULSE_PULLBACK_DISCOVERY_MODEL1_PACKAGE_MANIFEST.csv",
   [string]$MarkdownPath = "outputs\INDEPENDENT_M15_SESSION_IMPULSE_PULLBACK_DISCOVERY_MODEL1_PACKAGE.md"
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
      InpAllowedSymbol = "XAUUSD"; InpMagicNumber = "26072012"
      InpUseSymbolSafetyLock = "true"; InpUseRealAccountSafetyLock = "true"
      InpAllowRealAccountTrading = "false"; InpRealAccountApprovalCode = "DISABLED"
      InpEnforceInitialBalanceContract = "true"; InpExpectedInitialBalance = "10000.0"; InpInitialBalanceTolerance = "1.0"
      InpEnforceAccountCurrency = "true"; InpExpectedAccountCurrency = "USD"
      InpSignalTimeframe = "15"; InpATRPeriod = "20"; InpObservationStartHour = "6"; InpObservationEndHour = "9"
      InpEntryEndHour = "14"; InpMinimumImpulseATR = "0.60"; InpMaximumImpulseATR = "2.00"
      InpMinimumEfficiency = "0.45"; InpMinimumDirectionalBarsPercent = "55.0"; InpMinimumImpulseCloseLocation = "0.65"
      InpPullbackLookbackBars = "6"; InpMinimumPullbackRetracement = "0.20"; InpMaximumPullbackRetracement = "0.60"
      InpMinimumSignalBodyPercent = "30.0"; InpMinimumSignalCloseLocation = "0.65"; InpRequireSignalBreak = "true"
      InpMaximumEntryExtensionATR = "0.30"; InpAllowBuy = "true"; InpAllowSell = "true"
      InpStopLookbackBars = "6"; InpStopBufferATR = "0.10"; InpMinimumStopATR = "0.40"
      InpMaximumStopATR = "1.80"; InpMaximumStopPriceDistance = "6.00"; InpTakeProfitR = "2.00"
      InpMaximumHoldBars = "32"; InpExitHour = "20"; InpUseBreakEven = "true"
      InpBreakEvenTriggerR = "1.00"; InpBreakEvenLockR = "0.05"
      InpDisableFridayAfterHour = "true"; InpFridayEntryCutoffHour = "14"
      InpRiskPercent = "0.10"; InpMaximumPositionLots = "1.00"; InpMaximumDailyLossPercent = "0.75"
      InpMaximumEquityDrawdownPercent = "5.00"; InpMaximumConsecutiveLosses = "3"; InpLossCooldownHours = "24"
      InpMaximumSpreadPoints = "50.0"; InpDeviationPoints = "20"; InpRequireEmptyAccountAtEntry = "true"
      InpAccountWideMaxOpenRiskPercent = "1.00"; InpAccountWideBlockUnprotectedExposure = "true"
      InpLogTrades = "false"; InpLogFileName = "Independent_XAUUSD_M15_Session_Impulse_Pullback_Trades.csv"
      InpEvidenceProfileId = ""; InpEvidenceSourceHash = ""; InpEvidenceRunLabel = ""
   }
   foreach($entry in $defaults.GetEnumerator()) { Set-InputLine -Inputs $inputs -Name $entry.Key -Value ([string]$entry.Value) }
   return $inputs
}

& (Join-Path $PSScriptRoot "test_independent_m15_session_impulse_pullback_source.ps1") | Out-Null
$sourceFull = (Resolve-Path -LiteralPath (Resolve-RepoPath $SourcePath)).Path
$sourceHash = (Get-FileHash -LiteralPath $sourceFull -Algorithm SHA256).Hash
$variants = @(
   [pscustomobject]@{ Name="sip_center"; End="9"; MinImpulse="0.60"; Efficiency="0.45"; Directional="55.0"; MinRetrace="0.20"; MaxRetrace="0.60"; Lookback="6" },
   [pscustomobject]@{ Name="sip_end8"; End="8"; MinImpulse="0.60"; Efficiency="0.45"; Directional="55.0"; MinRetrace="0.20"; MaxRetrace="0.60"; Lookback="6" },
   [pscustomobject]@{ Name="sip_end10"; End="10"; MinImpulse="0.60"; Efficiency="0.45"; Directional="55.0"; MinRetrace="0.20"; MaxRetrace="0.60"; Lookback="6" },
   [pscustomobject]@{ Name="sip_impulse40"; End="9"; MinImpulse="0.40"; Efficiency="0.45"; Directional="55.0"; MinRetrace="0.20"; MaxRetrace="0.60"; Lookback="6" },
   [pscustomobject]@{ Name="sip_impulse80"; End="9"; MinImpulse="0.80"; Efficiency="0.45"; Directional="55.0"; MinRetrace="0.20"; MaxRetrace="0.60"; Lookback="6" },
   [pscustomobject]@{ Name="sip_eff35"; End="9"; MinImpulse="0.60"; Efficiency="0.35"; Directional="55.0"; MinRetrace="0.20"; MaxRetrace="0.60"; Lookback="6" },
   [pscustomobject]@{ Name="sip_eff55"; End="9"; MinImpulse="0.60"; Efficiency="0.55"; Directional="55.0"; MinRetrace="0.20"; MaxRetrace="0.60"; Lookback="6" },
   [pscustomobject]@{ Name="sip_dir45"; End="9"; MinImpulse="0.60"; Efficiency="0.45"; Directional="45.0"; MinRetrace="0.20"; MaxRetrace="0.60"; Lookback="6" },
   [pscustomobject]@{ Name="sip_dir65"; End="9"; MinImpulse="0.60"; Efficiency="0.45"; Directional="65.0"; MinRetrace="0.20"; MaxRetrace="0.60"; Lookback="6" },
   [pscustomobject]@{ Name="sip_minret10"; End="9"; MinImpulse="0.60"; Efficiency="0.45"; Directional="55.0"; MinRetrace="0.10"; MaxRetrace="0.60"; Lookback="6" },
   [pscustomobject]@{ Name="sip_minret30"; End="9"; MinImpulse="0.60"; Efficiency="0.45"; Directional="55.0"; MinRetrace="0.30"; MaxRetrace="0.60"; Lookback="6" },
   [pscustomobject]@{ Name="sip_maxret45"; End="9"; MinImpulse="0.60"; Efficiency="0.45"; Directional="55.0"; MinRetrace="0.20"; MaxRetrace="0.45"; Lookback="6" },
   [pscustomobject]@{ Name="sip_maxret75"; End="9"; MinImpulse="0.60"; Efficiency="0.45"; Directional="55.0"; MinRetrace="0.20"; MaxRetrace="0.75"; Lookback="6" },
   [pscustomobject]@{ Name="sip_lookback4"; End="9"; MinImpulse="0.60"; Efficiency="0.45"; Directional="55.0"; MinRetrace="0.20"; MaxRetrace="0.60"; Lookback="4" },
   [pscustomobject]@{ Name="sip_lookback8"; End="9"; MinImpulse="0.60"; Efficiency="0.45"; Directional="55.0"; MinRetrace="0.20"; MaxRetrace="0.60"; Lookback="8" }
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
   Set-InputLine $inputs "InpObservationEndHour" $variant.End
   Set-InputLine $inputs "InpMinimumImpulseATR" $variant.MinImpulse
   Set-InputLine $inputs "InpMinimumEfficiency" $variant.Efficiency
   Set-InputLine $inputs "InpMinimumDirectionalBarsPercent" $variant.Directional
   Set-InputLine $inputs "InpMinimumPullbackRetracement" $variant.MinRetrace
   Set-InputLine $inputs "InpMaximumPullbackRetracement" $variant.MaxRetrace
   Set-InputLine $inputs "InpPullbackLookbackBars" $variant.Lookback
   Set-InputLine $inputs "InpEvidenceProfileId" $variant.Name
   Set-InputLine $inputs "InpEvidenceSourceHash" $sourceHash
   Set-InputLine $inputs "InpEvidenceRunLabel" "independent_m15_session_impulse_pullback_discovery_model1"
   Set-InputLine $inputs "InpLogFileName" "$($variant.Name)_trades.csv"
   $profileName = "$($variant.Name).set"
   $profilePath = Join-Path $profileDir $profileName
   @($inputs.Keys | Sort-Object | ForEach-Object { $inputs[$_] }) | Set-Content -LiteralPath $profilePath -Encoding ASCII
   $profileText = Get-Content -LiteralPath $profilePath -Raw
   foreach($requiredName in @('InpObservationStartHour','InpObservationEndHour','InpMinimumEfficiency','InpMinimumPullbackRetracement','InpMaximumPullbackRetracement')) {
      if($profileText -notmatch "(?m)^$requiredName=") { throw "Required session impulse profile input missing: $requiredName" }
   }
   if($profileText -notmatch '(?m)^InpExpectedAccountCurrency=USD\r?$') {
      throw "Expected account currency was not serialized as a literal string: $profilePath"
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
         QueueRank=$queueRank; Candidate=$variant.Name; CandidateRank=$candidateRank; SourceType="independent_m15_session_impulse_pullback"
         SourceRank=1; Phase="discovery_model1"; Set=$profileName; Window=$window.Name; From=$window.From; To=$window.To
         Model=1; Deposit=10000; Config="configs\$configName"; ExpectedReportName=$reportName; ProfileSnapshot="profiles\$profileName"
         ProfileSha256=$profileHash; SourceSha256=$sourceHash; SignalTimeframe="15"; ObservationEndHour=$variant.End
         MinimumImpulseATR=$variant.MinImpulse; MinimumEfficiency=$variant.Efficiency; MinimumDirectionalBarsPercent=$variant.Directional
         MinimumPullbackRetracement=$variant.MinRetrace; MaximumPullbackRetracement=$variant.MaxRetrace
         PullbackLookbackBars=$variant.Lookback; TakeProfitR="2.00"; StopRule=$stopRule
      }) | Out-Null
      $runRows.Add([pscustomobject]@{
         QueueRank=$queueRank; Candidate=$variant.Name; Phase="discovery_model1"; PhaseLabel="Independent M15 session impulse-pullback discovery Model1"
         Window=$window.Name; Model=1; Deposit=10000; PackageConfig="$PackageDir\configs\$configName"; SourceConfig="$PackageDir\configs\$configName"
         ExpectedReportName=$reportName; ReportDestination="$PackageDir\reports_here\$reportName"; ProfileSha256=$profileHash; StopRule=$stopRule
      }) | Out-Null
   }
}

$queueRows | Export-Csv -LiteralPath (Resolve-RepoPath $QueueManifestPath) -NoTypeInformation -Encoding ASCII
$runRows | Export-Csv -LiteralPath (Resolve-RepoPath $PackageManifestPath) -NoTypeInformation -Encoding ASCII
$md = @(
   "# Independent M15 Session Impulse-Pullback Discovery Package", "",
   "Standalone fixed-session auction-efficiency research family. No configuration includes data after 2020.", "",
   "- Source SHA-256: ``$sourceHash``", "- Variants: ``$($variants.Count)``",
   "- Discovery windows: ``$($windows.Name -join ', ')``", "- Configurations: ``$ordinal``", "",
   'All profiles use a complete fixed M15 observation window, a bounded pullback, and completed M15 reclaim confirmation. Risk is fixed at `0.10%` with minimum-lot refusal, a `$10,000` initial-balance contract, account-wide exposure protection, daily and equity loss caps, one trade per day, and real-account trading disabled. The package is intended for one-worker exact-binary execution.'
)
$md | Set-Content -LiteralPath (Resolve-RepoPath $MarkdownPath) -Encoding ASCII
[pscustomobject]@{ Status="READY"; SourceHash=$sourceHash; Variants=$variants.Count; Windows=$windows.Count; Configurations=$ordinal; PackageDir=$PackageDir }
