param(
   [string]$SourcePath = "work\Independent_XAUUSD_M15_XAG_Relative_Value.mq5",
   [string]$PackageDir = "outputs\independent_m15_xag_relative_value_discovery_model1_package",
   [string]$QueueManifestPath = "outputs\INDEPENDENT_M15_XAG_RELATIVE_VALUE_DISCOVERY_MODEL1_QUEUE.csv",
   [string]$PackageManifestPath = "outputs\INDEPENDENT_M15_XAG_RELATIVE_VALUE_DISCOVERY_MODEL1_PACKAGE_MANIFEST.csv",
   [string]$MarkdownPath = "outputs\INDEPENDENT_M15_XAG_RELATIVE_VALUE_DISCOVERY_MODEL1_PACKAGE.md"
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
      InpAllowedSymbol="XAUUSD"; InpReferenceSymbol="XAGUSD"; InpMagicNumber="26071751"
      InpUseSymbolSafetyLock="true"; InpUseRealAccountSafetyLock="true"
      InpAllowRealAccountTrading="false"; InpRealAccountApprovalCode="DISABLED"
      InpSignalTimeframe="15"; InpMoveLookbackBars="16"; InpCorrelationLookbackBars="32"
      InpMinimumCorrelation="0.35"; InpDivergenceThresholdATR="1.00"
      InpRequireDivergenceTurn="true"; InpMinimumDivergenceTurnATR="0.05"
      InpRequireXAUStretchDirection="true"; InpMinimumXAUMoveATR="0.25"
      InpRequireDirectionCandle="true"; InpMinimumSignalBodyPercent="25.0"
      InpMinimumSignalCloseLocation="0.60"; InpMaximumAlignmentSeconds="900"
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
      InpLogFileName="Independent_XAUUSD_M15_XAG_Relative_Value_Trades.csv"
      InpEvidenceProfileId=""; InpEvidenceSourceHash=""; InpEvidenceRunLabel=""
   }
   foreach($entry in $defaults.GetEnumerator()) { Set-InputLine -Inputs $inputs -Name $entry.Key -Value ([string]$entry.Value) }
   return $inputs
}

& (Join-Path $PSScriptRoot "test_independent_m15_xag_relative_value_source.ps1") -SourcePath $SourcePath | Out-Null
$sourceFull = (Resolve-Path -LiteralPath (Resolve-RepoPath $SourcePath)).Path
$sourceHash = (Get-FileHash -LiteralPath $sourceFull -Algorithm SHA256).Hash

$base = [ordered]@{
   Move="16"; CorrLook="32"; MinCorr="0.35"; Divergence="1.00"; RequireTurn="true"
   TurnMinimum="0.05"; RequireXAU="true"; MinimumXAU="0.25"; Body="25.0"
   CloseLocation="0.60"; StopLook="8"; TakeProfitR="1.50"; BreakEven="true"; Hold="24"
}
function New-Variant([string]$Name, [hashtable]$Changes) {
   $values = [ordered]@{}
   foreach($entry in $base.GetEnumerator()) { $values[$entry.Key] = $entry.Value }
   foreach($entry in $Changes.GetEnumerator()) { $values[$entry.Key] = [string]$entry.Value }
   return [pscustomobject]@{ Name=$Name; Values=$values }
}
$variants = @(
   (New-Variant "xmrv_base" @{}),
   (New-Variant "xmrv_move8" @{ Move="8" }),
   (New-Variant "xmrv_move12" @{ Move="12" }),
   (New-Variant "xmrv_move24" @{ Move="24" }),
   (New-Variant "xmrv_move32" @{ Move="32" }),
   (New-Variant "xmrv_div075" @{ Divergence="0.75" }),
   (New-Variant "xmrv_div125" @{ Divergence="1.25" }),
   (New-Variant "xmrv_div150" @{ Divergence="1.50" }),
   (New-Variant "xmrv_corr020" @{ MinCorr="0.20" }),
   (New-Variant "xmrv_corr050" @{ MinCorr="0.50" }),
   (New-Variant "xmrv_no_turn" @{ RequireTurn="false" }),
   (New-Variant "xmrv_turn010" @{ TurnMinimum="0.10" }),
   (New-Variant "xmrv_xau000" @{ MinimumXAU="0.00" }),
   (New-Variant "xmrv_xau040" @{ MinimumXAU="0.40" }),
   (New-Variant "xmrv_tp125" @{ TakeProfitR="1.25" }),
   (New-Variant "xmrv_tp200" @{ TakeProfitR="2.00" })
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
      InpMoveLookbackBars=$v.Move; InpCorrelationLookbackBars=$v.CorrLook; InpMinimumCorrelation=$v.MinCorr
      InpDivergenceThresholdATR=$v.Divergence; InpRequireDivergenceTurn=$v.RequireTurn
      InpMinimumDivergenceTurnATR=$v.TurnMinimum; InpRequireXAUStretchDirection=$v.RequireXAU
      InpMinimumXAUMoveATR=$v.MinimumXAU; InpMinimumSignalBodyPercent=$v.Body
      InpMinimumSignalCloseLocation=$v.CloseLocation; InpStopLookbackBars=$v.StopLook
      InpTakeProfitR=$v.TakeProfitR; InpUseBreakEven=$v.BreakEven; InpMaximumHoldBars=$v.Hold
   }
   foreach($entry in $map.GetEnumerator()) { Set-InputLine -Inputs $inputs -Name $entry.Key -Value ([string]$entry.Value) }
   Set-InputLine -Inputs $inputs -Name "InpEvidenceProfileId" -Value $variant.Name
   Set-InputLine -Inputs $inputs -Name "InpEvidenceSourceHash" -Value $sourceHash
   Set-InputLine -Inputs $inputs -Name "InpEvidenceRunLabel" -Value "independent_m15_xag_relative_value_discovery_model1"
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
         SourceType="independent_m15_xag_relative_value"; SourceRank=1; Phase="discovery_model1"
         Set=$profileName; Window=$window.Name; From=$window.From; To=$window.To; Model=1; Deposit=10000
         Config="configs\$configName"; ExpectedReportName=$reportName; ProfileSnapshot="profiles\$profileName"
         ProfileSha256=$profileHash; SourceSha256=$sourceHash; SignalTimeframe="15"
         MoveLookback=$v.Move; CorrelationLookback=$v.CorrLook; MinimumCorrelation=$v.MinCorr
         DivergenceThresholdATR=$v.Divergence; RequireTurn=$v.RequireTurn; TurnMinimumATR=$v.TurnMinimum
         MinimumXAUMoveATR=$v.MinimumXAU; TakeProfitR=$v.TakeProfitR; StopRule=$stopRule
      }) | Out-Null
      $runRows.Add([pscustomobject]@{
         QueueRank=$rank; Candidate=$variant.Name; Phase="discovery_model1"
         PhaseLabel="Independent M15 XAG relative-value discovery Model1"; Window=$window.Name
         Model=1; Deposit=10000; PackageConfig="$PackageDir\configs\$configName"
         SourceConfig="$PackageDir\configs\$configName"; ExpectedReportName=$reportName
         ReportDestination="$PackageDir\reports_here\$reportName"; ProfileSha256=$profileHash; StopRule=$stopRule
      }) | Out-Null
   }
}
$queueRows | Export-Csv -LiteralPath (Resolve-RepoPath $QueueManifestPath) -NoTypeInformation -Encoding ASCII
$runRows | Export-Csv -LiteralPath (Resolve-RepoPath $PackageManifestPath) -NoTypeInformation -Encoding ASCII
@(
   "# Independent M15 XAG Relative-Value Discovery Package",
   "",
   "Standalone cross-metal mean-reversion family. XAUUSD is traded only after an ATR-normalized XAU/XAG divergence begins reversing while rolling return correlation remains positive.",
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
