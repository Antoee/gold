param(
   [string]$SourcePath = "work\Independent_XAUUSD_M15_XAG_Lead_Lag_Pullback.mq5",
   [string]$PackageDir = "outputs\independent_m15_xag_lead_lag_pullback_discovery_model1_package",
   [string]$QueueManifestPath = "outputs\INDEPENDENT_M15_XAG_LEAD_LAG_PULLBACK_DISCOVERY_MODEL1_QUEUE.csv",
   [string]$PackageManifestPath = "outputs\INDEPENDENT_M15_XAG_LEAD_LAG_PULLBACK_DISCOVERY_MODEL1_PACKAGE_MANIFEST.csv",
   [string]$MarkdownPath = "outputs\INDEPENDENT_M15_XAG_LEAD_LAG_PULLBACK_DISCOVERY_MODEL1_PACKAGE.md"
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
      InpAllowedSymbol="XAUUSD"; InpReferenceSymbol="XAGUSD"; InpMagicNumber="26071771"
      InpUseSymbolSafetyLock="true"; InpUseRealAccountSafetyLock="true"
      InpAllowRealAccountTrading="false"; InpRealAccountApprovalCode="DISABLED"
      InpSignalTimeframe="15"; InpLeadLookbackBars="8"; InpCorrelationLookbackBars="32"
      InpMinimumCorrelation="0.25"; InpMinimumXAGImpulseATR="1.00"
      InpMinimumXAGLeadGapATR="0.35"; InpMinimumAlignedXAUMoveATR="-0.10"
      InpMaximumXAUExtensionATR="0.75"; InpFastEMAPeriod="20"; InpSlowEMAPeriod="50"
      InpRequireFastEMASlope="true"; InpPullbackToleranceATR="0.10"
      InpRequirePriorRangeReclaim="true"; InpRequireDirectionCandle="true"
      InpMinimumSignalBodyPercent="25.0"; InpMinimumSignalCloseLocation="0.60"
      InpMaximumAlignmentSeconds="900"
      InpAllowBuy="true"; InpAllowSell="true"; InpATRPeriod="20"
      InpUseVolatilityFilter="true"; InpMinimumATRPercent="0.03"; InpMaximumATRPercent="2.50"
      InpStopLookbackBars="8"; InpStopBufferATR="0.15"; InpMinimumStopATR="0.50"
      InpMaximumStopATR="2.50"; InpMaximumStopPriceDistance="10.00"; InpTakeProfitR="1.50"
      InpUseBreakEven="true"; InpBreakEvenTriggerR="0.80"; InpBreakEvenLockR="0.05"
      InpMaximumHoldBars="24"; InpCloseBeforeWeekend="true"; InpFridayPositionCloseHour="20"
      InpUseSessionFilter="true"; InpSessionStartHour="6"; InpSessionEndHour="20"
      InpDisableFridayAfterHour="true"; InpFridayEntryCutoffHour="18"; InpRiskPercent="0.10"
      InpMaximumPositionLots="1.00"; InpMaximumSimultaneousPositions="1"; InpMaximumTradesPerDay="3"
      InpMaximumDailyLossPercent="0.75"; InpMaximumEquityDrawdownPercent="5.00"
      InpMaximumConsecutiveLosses="4"; InpLossCooldownHours="12"; InpMaximumSpreadPoints="50.0"
      InpDeviationPoints="20"; InpUseAccountWideExposureGuard="true"
      InpAccountWideMaxOpenRiskPercent="3.00"; InpAccountWideMaxPositions="3"
      InpAccountWideBlockUnprotectedExposure="true"; InpLogTrades="false"
      InpLogFileName="Independent_XAUUSD_M15_XAG_Lead_Lag_Pullback_Trades.csv"
      InpEvidenceProfileId=""; InpEvidenceSourceHash=""; InpEvidenceRunLabel=""
   }
   foreach($entry in $defaults.GetEnumerator()) { Set-InputLine -Inputs $inputs -Name $entry.Key -Value ([string]$entry.Value) }
   return $inputs
}

& (Join-Path $PSScriptRoot "test_independent_m15_xag_lead_lag_pullback_source.ps1") -SourcePath $SourcePath | Out-Null
$sourceFull = (Resolve-Path -LiteralPath (Resolve-RepoPath $SourcePath)).Path
$sourceHash = (Get-FileHash -LiteralPath $sourceFull -Algorithm SHA256).Hash

$base = [ordered]@{
   Lead="8"; CorrLook="32"; MinCorr="0.25"; MinimumXAG="1.00"; LeadGap="0.35"
   MinimumXAU="-0.10"; MaximumXAU="0.75"; FastEMA="20"; SlowEMA="50"
   RequireSlope="true"; PullbackTolerance="0.10"; RequireRangeReclaim="true"
   Body="25.0"; CloseLocation="0.60"; StopLook="8"; TakeProfitR="1.50"
   BreakEven="true"; Hold="24"
}
function New-Variant([string]$Name, [hashtable]$Changes) {
   $values = [ordered]@{}
   foreach($entry in $base.GetEnumerator()) { $values[$entry.Key] = $entry.Value }
   foreach($entry in $Changes.GetEnumerator()) { $values[$entry.Key] = [string]$entry.Value }
   return [pscustomobject]@{ Name=$Name; Values=$values }
}
$variants = @(
   (New-Variant "xmll_base" @{}),
   (New-Variant "xmll_lead4" @{ Lead="4" }),
   (New-Variant "xmll_lead12" @{ Lead="12" }),
   (New-Variant "xmll_lead16" @{ Lead="16" }),
   (New-Variant "xmll_xag075" @{ MinimumXAG="0.75" }),
   (New-Variant "xmll_xag125" @{ MinimumXAG="1.25" }),
   (New-Variant "xmll_gap020" @{ LeadGap="0.20" }),
   (New-Variant "xmll_gap050" @{ LeadGap="0.50" }),
   (New-Variant "xmll_xaumax050" @{ MaximumXAU="0.50" }),
   (New-Variant "xmll_xaumax100" @{ MaximumXAU="1.00" }),
   (New-Variant "xmll_tol000" @{ PullbackTolerance="0.00" }),
   (New-Variant "xmll_tol020" @{ PullbackTolerance="0.20" }),
   (New-Variant "xmll_no_slope" @{ RequireSlope="false" }),
   (New-Variant "xmll_no_range" @{ RequireRangeReclaim="false" }),
   (New-Variant "xmll_tp125" @{ TakeProfitR="1.25" }),
   (New-Variant "xmll_tp200" @{ TakeProfitR="2.00" })
)
$windows = @(
   [pscustomobject]@{ Name="older_2015_2017"; From="2015.01.01"; To="2017.12.31" },
   [pscustomobject]@{ Name="discovery_2018_2020"; From="2018.01.01"; To="2020.12.31" }
)

$packageFull = Resolve-RepoPath $PackageDir
Clear-OutputDirSafe $packageFull
$configDir = Join-Path $packageFull "configs"
$profileDir = Join-Path $packageFull "profiles"
$reportDir = Join-Path $packageFull "reports_here"
$sourceDir = Join-Path $packageFull "source"
New-Item -ItemType Directory -Path $configDir, $profileDir, $reportDir, $sourceDir -Force | Out-Null
Copy-Item -LiteralPath $sourceFull -Destination (Join-Path $sourceDir "Professional_XAUUSD_EA.mq5") -Force

$queueRows = [Collections.Generic.List[object]]::new()
$runRows = [Collections.Generic.List[object]]::new()
$rank = 0
$candidateRank = 0
$stopRule = "Pre-registered Model1 gate: both 2015-2017 and 2018-2020 must be profitable with PF >= 1.10, DD <= 5%, and >= 30 trades each. Only supported neighborhoods may receive a continuous 2015-2020 test; recent years remain closed."
foreach($variant in $variants) {
   $candidateRank++
   $v = $variant.Values
   $inputs = New-BaseInputs
   $map = [ordered]@{
      InpLeadLookbackBars=$v.Lead; InpCorrelationLookbackBars=$v.CorrLook
      InpMinimumCorrelation=$v.MinCorr; InpMinimumXAGImpulseATR=$v.MinimumXAG
      InpMinimumXAGLeadGapATR=$v.LeadGap; InpMinimumAlignedXAUMoveATR=$v.MinimumXAU
      InpMaximumXAUExtensionATR=$v.MaximumXAU; InpFastEMAPeriod=$v.FastEMA
      InpSlowEMAPeriod=$v.SlowEMA; InpRequireFastEMASlope=$v.RequireSlope
      InpPullbackToleranceATR=$v.PullbackTolerance
      InpRequirePriorRangeReclaim=$v.RequireRangeReclaim; InpMinimumSignalBodyPercent=$v.Body
      InpMinimumSignalCloseLocation=$v.CloseLocation; InpStopLookbackBars=$v.StopLook
      InpTakeProfitR=$v.TakeProfitR; InpUseBreakEven=$v.BreakEven; InpMaximumHoldBars=$v.Hold
   }
   foreach($entry in $map.GetEnumerator()) { Set-InputLine -Inputs $inputs -Name $entry.Key -Value ([string]$entry.Value) }
   Set-InputLine -Inputs $inputs -Name "InpEvidenceProfileId" -Value $variant.Name
   Set-InputLine -Inputs $inputs -Name "InpEvidenceSourceHash" -Value $sourceHash
   Set-InputLine -Inputs $inputs -Name "InpEvidenceRunLabel" -Value "independent_m15_xag_lead_lag_pullback_discovery_model1"
   Set-InputLine -Inputs $inputs -Name "InpLogFileName" -Value "$($variant.Name)_trades.csv"
   $profileName = "$($variant.Name).set"
   $profilePath = Join-Path $profileDir $profileName
   @($inputs.Keys | Sort-Object | ForEach-Object { $inputs[$_] }) | Set-Content -LiteralPath $profilePath -Encoding ASCII
   $profileHash = (Get-FileHash -LiteralPath $profilePath -Algorithm SHA256).Hash
   foreach($window in $windows) {
      $rank++
      $configName = "{0:000}_{1}_{2}_m1.ini" -f $rank, $variant.Name, $window.Name
      $reportName = "$($variant.Name)_$($window.Name)_m1"
      Write-SeasonalTesterConfig -Path (Join-Path $configDir $configName) -ReportRoot $reportDir `
         -ReportName $reportName -From $window.From -To $window.To -Inputs $inputs -Model 1 -Deposit 10000
      $queueRows.Add([pscustomobject]@{
         QueueRank=$rank; Candidate=$variant.Name; CandidateRank=$candidateRank
         SourceType="independent_m15_xag_lead_lag_pullback"; SourceRank=1; Phase="discovery_model1"
         Set=$profileName; Window=$window.Name; From=$window.From; To=$window.To; Model=1; Deposit=10000
         Config="configs\$configName"; ExpectedReportName=$reportName; ProfileSnapshot="profiles\$profileName"
         ProfileSha256=$profileHash; SourceSha256=$sourceHash; SignalTimeframe="15"
         LeadLookback=$v.Lead; CorrelationLookback=$v.CorrLook; MinimumCorrelation=$v.MinCorr
         MinimumXAGImpulseATR=$v.MinimumXAG; MinimumXAGLeadGapATR=$v.LeadGap
         MinimumAlignedXAUMoveATR=$v.MinimumXAU; MaximumXAUExtensionATR=$v.MaximumXAU
         FastEMA=$v.FastEMA; SlowEMA=$v.SlowEMA; RequireFastEMASlope=$v.RequireSlope
         PullbackToleranceATR=$v.PullbackTolerance; RequirePriorRangeReclaim=$v.RequireRangeReclaim
         TakeProfitR=$v.TakeProfitR; StopRule=$stopRule
      }) | Out-Null
      $runRows.Add([pscustomobject]@{
         QueueRank=$rank; Candidate=$variant.Name; Phase="discovery_model1"
         PhaseLabel="Independent M15 XAG lead-lag pullback discovery Model1"; Window=$window.Name
         Model=1; Deposit=10000; PackageConfig="$PackageDir\configs\$configName"
         SourceConfig="$PackageDir\configs\$configName"; ExpectedReportName=$reportName
         ReportDestination="$PackageDir\reports_here\$reportName"; ProfileSha256=$profileHash; StopRule=$stopRule
      }) | Out-Null
   }
}
$queueRows | Export-Csv -LiteralPath (Resolve-RepoPath $QueueManifestPath) -NoTypeInformation -Encoding ASCII
$runRows | Export-Csv -LiteralPath (Resolve-RepoPath $PackageManifestPath) -NoTypeInformation -Encoding ASCII
@(
   "# Independent M15 XAG Lead-Lag Pullback Discovery Package",
   "",
   "Standalone cross-metal lead-lag family. XAUUSD is traded only when XAG shows a stronger directional impulse, XAU remains trend-aligned but less extended, and XAU completes a closed-bar EMA pullback and reclaim.",
   "",
   "- Source SHA-256: ``$sourceHash``",
   "- Variants: ``$($variants.Count)``",
   "- Disjoint windows: ``$($windows.Name -join ', ')``",
   "- Configurations: ``$rank``",
   "- Latest permitted discovery date: ``2020-12-31``",
   "- Risk: ``0.10%`` per accepted trade; no minimum lot is forced; real trading is disabled.",
   "- Stop rule: $stopRule"
) | Set-Content -LiteralPath (Resolve-RepoPath $MarkdownPath) -Encoding ASCII
[pscustomobject]@{ Status="READY"; SourceHash=$sourceHash; Variants=$variants.Count; Windows=$windows.Count; Configurations=$rank; PackageDir=$PackageDir }
