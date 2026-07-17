param(
   [string]$SourcePath = "work\Independent_XAUUSD_M15_XAG_Synchronized_Continuation.mq5",
   [string]$PackageDir = "outputs\independent_m15_xag_synchronized_continuation_discovery_model1_package",
   [string]$QueueManifestPath = "outputs\INDEPENDENT_M15_XAG_SYNCHRONIZED_CONTINUATION_DISCOVERY_MODEL1_QUEUE.csv",
   [string]$PackageManifestPath = "outputs\INDEPENDENT_M15_XAG_SYNCHRONIZED_CONTINUATION_DISCOVERY_MODEL1_PACKAGE_MANIFEST.csv",
   [string]$MarkdownPath = "outputs\INDEPENDENT_M15_XAG_SYNCHRONIZED_CONTINUATION_DISCOVERY_MODEL1_PACKAGE.md"
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
      InpAllowedSymbol="XAUUSD"; InpReferenceSymbol="XAGUSD"; InpMagicNumber="26071761"
      InpUseSymbolSafetyLock="true"; InpUseRealAccountSafetyLock="true"
      InpAllowRealAccountTrading="false"; InpRealAccountApprovalCode="DISABLED"
      InpSignalTimeframe="15"; InpMoveLookbackBars="16"; InpBreakoutLookbackBars="20"
      InpCorrelationLookbackBars="32"; InpMinimumCorrelation="0.35"
      InpMinimumXAUMoveATR="0.50"; InpMinimumXAGMoveATR="0.50"
      InpBreakoutBufferATR="0.05"; InpRequireFreshBreakout="true"
      InpRequireDirectionCandle="true"; InpMinimumSignalBodyPercent="35.0"
      InpMinimumSignalCloseLocation="0.65"; InpMaximumAlignmentSeconds="900"
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
      InpLogFileName="Independent_XAUUSD_M15_XAG_Synchronized_Continuation_Trades.csv"
      InpEvidenceProfileId=""; InpEvidenceSourceHash=""; InpEvidenceRunLabel=""
   }
   foreach($entry in $defaults.GetEnumerator()) { Set-InputLine -Inputs $inputs -Name $entry.Key -Value ([string]$entry.Value) }
   return $inputs
}

& (Join-Path $PSScriptRoot "test_independent_m15_xag_synchronized_continuation_source.ps1") -SourcePath $SourcePath | Out-Null
$sourceFull = (Resolve-Path -LiteralPath (Resolve-RepoPath $SourcePath)).Path
$sourceHash = (Get-FileHash -LiteralPath $sourceFull -Algorithm SHA256).Hash

$base = [ordered]@{
   Move="16"; Breakout="20"; CorrLook="32"; MinCorr="0.35"
   MinimumXAU="0.50"; MinimumXAG="0.50"; BreakoutBuffer="0.05"; FreshBreakout="true"
   Body="35.0"; CloseLocation="0.65"; StopLook="8"; TakeProfitR="1.50"
   BreakEven="true"; Hold="24"
}
function New-Variant([string]$Name, [hashtable]$Changes) {
   $values = [ordered]@{}
   foreach($entry in $base.GetEnumerator()) { $values[$entry.Key] = $entry.Value }
   foreach($entry in $Changes.GetEnumerator()) { $values[$entry.Key] = [string]$entry.Value }
   return [pscustomobject]@{ Name=$Name; Values=$values }
}
$variants = @(
   (New-Variant "xmsc_base" @{}),
   (New-Variant "xmsc_move8" @{ Move="8" }),
   (New-Variant "xmsc_move24" @{ Move="24" }),
   (New-Variant "xmsc_move32" @{ Move="32" }),
   (New-Variant "xmsc_breakout12" @{ Breakout="12" }),
   (New-Variant "xmsc_breakout16" @{ Breakout="16" }),
   (New-Variant "xmsc_breakout28" @{ Breakout="28" }),
   (New-Variant "xmsc_breakout40" @{ Breakout="40" }),
   (New-Variant "xmsc_move025" @{ MinimumXAU="0.25"; MinimumXAG="0.25" }),
   (New-Variant "xmsc_move075" @{ MinimumXAU="0.75"; MinimumXAG="0.75" }),
   (New-Variant "xmsc_corr020" @{ MinCorr="0.20" }),
   (New-Variant "xmsc_corr050" @{ MinCorr="0.50" }),
   (New-Variant "xmsc_buffer000" @{ BreakoutBuffer="0.00" }),
   (New-Variant "xmsc_buffer010" @{ BreakoutBuffer="0.10" }),
   (New-Variant "xmsc_tp125" @{ TakeProfitR="1.25" }),
   (New-Variant "xmsc_tp200" @{ TakeProfitR="2.00" })
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
      InpMoveLookbackBars=$v.Move; InpBreakoutLookbackBars=$v.Breakout
      InpCorrelationLookbackBars=$v.CorrLook; InpMinimumCorrelation=$v.MinCorr
      InpMinimumXAUMoveATR=$v.MinimumXAU; InpMinimumXAGMoveATR=$v.MinimumXAG
      InpBreakoutBufferATR=$v.BreakoutBuffer; InpRequireFreshBreakout=$v.FreshBreakout
      InpMinimumSignalBodyPercent=$v.Body
      InpMinimumSignalCloseLocation=$v.CloseLocation; InpStopLookbackBars=$v.StopLook
      InpTakeProfitR=$v.TakeProfitR; InpUseBreakEven=$v.BreakEven; InpMaximumHoldBars=$v.Hold
   }
   foreach($entry in $map.GetEnumerator()) { Set-InputLine -Inputs $inputs -Name $entry.Key -Value ([string]$entry.Value) }
   Set-InputLine -Inputs $inputs -Name "InpEvidenceProfileId" -Value $variant.Name
   Set-InputLine -Inputs $inputs -Name "InpEvidenceSourceHash" -Value $sourceHash
   Set-InputLine -Inputs $inputs -Name "InpEvidenceRunLabel" -Value "independent_m15_xag_synchronized_continuation_discovery_model1"
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
         SourceType="independent_m15_xag_synchronized_continuation"; SourceRank=1; Phase="discovery_model1"
         Set=$profileName; Window=$window.Name; From=$window.From; To=$window.To; Model=1; Deposit=10000
         Config="configs\$configName"; ExpectedReportName=$reportName; ProfileSnapshot="profiles\$profileName"
         ProfileSha256=$profileHash; SourceSha256=$sourceHash; SignalTimeframe="15"
         MoveLookback=$v.Move; BreakoutLookback=$v.Breakout
         CorrelationLookback=$v.CorrLook; MinimumCorrelation=$v.MinCorr
         MinimumXAUMoveATR=$v.MinimumXAU; MinimumXAGMoveATR=$v.MinimumXAG
         BreakoutBufferATR=$v.BreakoutBuffer; RequireFreshBreakout=$v.FreshBreakout
         TakeProfitR=$v.TakeProfitR; StopRule=$stopRule
      }) | Out-Null
      $runRows.Add([pscustomobject]@{
         QueueRank=$rank; Candidate=$variant.Name; Phase="discovery_model1"
         PhaseLabel="Independent M15 XAG synchronized-continuation discovery Model1"; Window=$window.Name
         Model=1; Deposit=10000; PackageConfig="$PackageDir\configs\$configName"
         SourceConfig="$PackageDir\configs\$configName"; ExpectedReportName=$reportName
         ReportDestination="$PackageDir\reports_here\$reportName"; ProfileSha256=$profileHash; StopRule=$stopRule
      }) | Out-Null
   }
}
$queueRows | Export-Csv -LiteralPath (Resolve-RepoPath $QueueManifestPath) -NoTypeInformation -Encoding ASCII
$runRows | Export-Csv -LiteralPath (Resolve-RepoPath $PackageManifestPath) -NoTypeInformation -Encoding ASCII
@(
   "# Independent M15 XAG Synchronized-Continuation Discovery Package",
   "",
   "Standalone cross-metal continuation family. XAUUSD is traded only when XAU and XAG have same-direction ATR-normalized moves, rolling return correlation is positive, and XAU makes a fresh closed-bar channel breakout.",
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
