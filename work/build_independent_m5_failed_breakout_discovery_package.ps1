param(
   [string]$SourcePath = "work\Independent_XAUUSD_M5_Failed_Breakout_Trap.mq5",
   [string]$PackageDir = "outputs\independent_m5_failed_breakout_discovery_model1_package",
   [string]$QueueManifestPath = "outputs\INDEPENDENT_M5_FAILED_BREAKOUT_DISCOVERY_MODEL1_QUEUE.csv",
   [string]$PackageManifestPath = "outputs\INDEPENDENT_M5_FAILED_BREAKOUT_DISCOVERY_MODEL1_PACKAGE_MANIFEST.csv",
   [string]$MarkdownPath = "outputs\INDEPENDENT_M5_FAILED_BREAKOUT_DISCOVERY_MODEL1_PACKAGE.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "seasonal_gate_helpers.ps1")
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$outputsRoot = (Resolve-Path (Join-Path $repo "outputs")).Path

function Resolve-RepoPath([string]$Path) {
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}

function Clear-OutputDirSafe([string]$Path) {
   if(Test-Path -LiteralPath $Path) {
      $resolved = (Resolve-Path -LiteralPath $Path).Path
      if(!$resolved.StartsWith($outputsRoot, [StringComparison]::OrdinalIgnoreCase)) {
         throw "Refusing to clear non-outputs directory: $resolved"
      }
      Remove-Item -LiteralPath $resolved -Recurse -Force
   }
   New-Item -ItemType Directory -Path $Path -Force | Out-Null
}

function New-BaseInputs {
   $inputs = [ordered]@{}
   $defaults = [ordered]@{
      InpAllowedSymbol="XAUUSD"; InpMagicNumber="26071781"; InpUseSymbolSafetyLock="true"
      InpUseRealAccountSafetyLock="true"; InpAllowRealAccountTrading="false"; InpRealAccountApprovalCode="DISABLED"
      InpSignalTimeframe="5"; InpBoxLookbackBars="12"; InpMaximumBreakoutAgeBars="4"
      InpMinimumBoxRangeATR="0.80"; InpMaximumBoxRangeATR="2.50"; InpBreakBufferATR="0.05"
      InpMaximumBreakExtensionATR="1.20"; InpMinimumBreakRangeATR="0.45"
      InpMinimumBreakBodyPercent="35.0"; InpMinimumBreakCloseLocation="0.60"
      InpMinimumReclaimDepthRatio="0.15"; InpMinimumReclaimRangeATR="0.30"
      InpMinimumReclaimBodyPercent="20.0"; InpMinimumReclaimCloseLocation="0.58"
      InpRequireDirectionCandle="true"; InpAllowBuy="true"; InpAllowSell="true"
      InpUseBreakoutTickVolumeFilter="false"; InpUseReclaimTickVolumeFilter="false"
      InpVolumeLookbackBars="20"; InpMinimumVolumeRatio="1.05"
      InpUseTrendEMAFilter="false"; InpTrendTimeframe="16385"; InpTrendEMAPeriod="100"
      InpTrendEMASlopeBars="3"; InpRequireTrendAlignment="true"; InpUseMaximumADXFilter="true"
      InpADXPeriod="14"; InpMaximumADX="26.0"; InpUseVolatilityFilter="true"
      InpMinimumATRPercent="0.03"; InpMaximumATRPercent="2.50"; InpATRPeriod="20"
      InpStopBufferATR="0.10"; InpMinimumStopATR="0.25"; InpMaximumStopATR="2.50"
      InpMaximumStopPriceDistance="10.00"; InpUseBoxOppositeTarget="true"
      InpMinimumTargetR="1.00"; InpMaximumTargetATR="4.00"; InpUseFixedTakeProfit="false"
      InpTakeProfitR="1.50"; InpUseBreakEven="true"; InpBreakEvenTriggerR="0.80"
      InpBreakEvenLockR="0.10"; InpUseChandelierTrail="false"; InpChandelierLookbackBars="8"
      InpChandelierATR="2.50"; InpUseTrendFailureExit="false"; InpMaximumHoldBars="32"
      InpUseSessionFilter="true"; InpSessionStartHour="6"; InpSessionEndHour="18"
      InpDisableFridayAfterHour="true"; InpFridayCutoffHour="18"; InpRiskPercent="0.10"
      InpMaximumPositionLots="1.00"; InpMaximumSimultaneousPositions="1"; InpMaximumTradesPerDay="2"
      InpMaximumDailyLossPercent="0.75"; InpMaximumEquityDrawdownPercent="5.00"
      InpMaximumConsecutiveLosses="4"; InpLossCooldownHours="24"; InpMaximumSpreadPoints="50.0"
      InpDeviationPoints="20"; InpUseAccountWideExposureGuard="true"
      InpAccountWideMaxOpenRiskPercent="3.00"; InpAccountWideMaxPositions="3"
      InpAccountWideBlockUnprotectedExposure="true"; InpLogTrades="false"
      InpLogFileName="Independent_XAUUSD_M5_Failed_Breakout_Trap_Trades.csv"
      InpEvidenceProfileId=""; InpEvidenceSourceHash=""; InpEvidenceRunLabel=""
   }
   foreach($entry in $defaults.GetEnumerator()) {
      Set-InputLine -Inputs $inputs -Name $entry.Key -Value ([string]$entry.Value)
   }
   return $inputs
}

& (Join-Path $PSScriptRoot "test_independent_m5_failed_breakout_trap_source.ps1") | Out-Null
$sourceFull = (Resolve-Path -LiteralPath (Resolve-RepoPath $SourcePath)).Path
$sourceHash = (Get-FileHash -LiteralPath $sourceFull -Algorithm SHA256).Hash

$base = [ordered]@{
   BoxBars="12"; Age="4"; MinBox="0.80"; MaxBox="2.50"; BreakBuffer="0.05"; MaxExtension="1.20"
   BreakRange="0.45"; BreakBody="35.0"; BreakClose="0.60"; ReclaimDepth="0.15"
   ReclaimRange="0.30"; ReclaimBody="20.0"; ReclaimClose="0.58"; BreakVolume="false"
   ReclaimVolume="false"; VolumeRatio="1.05"; MaxADX="26.0"; BoxTarget="true"
   MinTargetR="1.00"; TPR="1.50"
}
function New-Variant([string]$Name, [hashtable]$Changes) {
   $values = [ordered]@{}
   foreach($entry in $base.GetEnumerator()) { $values[$entry.Key] = $entry.Value }
   foreach($entry in $Changes.GetEnumerator()) { $values[$entry.Key] = [string]$entry.Value }
   return [pscustomobject]@{ Name=$Name; Values=$values }
}

$variants = @(
   (New-Variant "m5fbt_b14_struct_r075" @{ BoxBars="14"; MinTargetR="0.75" }),
   (New-Variant "m5fbt_b16_struct_r075" @{ BoxBars="16"; MinTargetR="0.75" }),
   (New-Variant "m5fbt_b18_struct_r075" @{ BoxBars="18"; MinTargetR="0.75" }),
   (New-Variant "m5fbt_b14_fixed_r125" @{ BoxBars="14"; BoxTarget="false"; TPR="1.25" }),
   (New-Variant "m5fbt_b14_fixed_r150" @{ BoxBars="14"; BoxTarget="false"; TPR="1.50" }),
   (New-Variant "m5fbt_b14_fixed_r200" @{ BoxBars="14"; BoxTarget="false"; TPR="2.00" }),
   (New-Variant "m5fbt_b16_fixed_r125" @{ BoxBars="16"; BoxTarget="false"; TPR="1.25" }),
   (New-Variant "m5fbt_b16_fixed_r150" @{ BoxBars="16"; BoxTarget="false"; TPR="1.50" }),
   (New-Variant "m5fbt_b16_fixed_r200" @{ BoxBars="16"; BoxTarget="false"; TPR="2.00" }),
   (New-Variant "m5fbt_b18_fixed_r125" @{ BoxBars="18"; BoxTarget="false"; TPR="1.25" }),
   (New-Variant "m5fbt_b18_fixed_r150" @{ BoxBars="18"; BoxTarget="false"; TPR="1.50" }),
   (New-Variant "m5fbt_b18_fixed_r200" @{ BoxBars="18"; BoxTarget="false"; TPR="2.00" })
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

$queueRows = [System.Collections.Generic.List[object]]::new()
$runRows = [System.Collections.Generic.List[object]]::new()
$rank = 0
$candidateRank = 0
$stopRule = "M5 discovery only through 2020: both equal eras must be profitable with PF >= 1.10, DD <= 5%, and >= 100 trades each. A supported box/exit neighborhood is required before continuous, recent-data, or Model4 testing."

foreach($variant in $variants) {
   $candidateRank++
   $v = $variant.Values
   $inputs = New-BaseInputs
   $map = [ordered]@{
      InpBoxLookbackBars=$v.BoxBars; InpMaximumBreakoutAgeBars=$v.Age
      InpMinimumBoxRangeATR=$v.MinBox; InpMaximumBoxRangeATR=$v.MaxBox
      InpBreakBufferATR=$v.BreakBuffer; InpMaximumBreakExtensionATR=$v.MaxExtension
      InpMinimumBreakRangeATR=$v.BreakRange; InpMinimumBreakBodyPercent=$v.BreakBody
      InpMinimumBreakCloseLocation=$v.BreakClose; InpMinimumReclaimDepthRatio=$v.ReclaimDepth
      InpMinimumReclaimRangeATR=$v.ReclaimRange; InpMinimumReclaimBodyPercent=$v.ReclaimBody
      InpMinimumReclaimCloseLocation=$v.ReclaimClose; InpUseBreakoutTickVolumeFilter=$v.BreakVolume
      InpUseReclaimTickVolumeFilter=$v.ReclaimVolume; InpMinimumVolumeRatio=$v.VolumeRatio
      InpMaximumADX=$v.MaxADX; InpUseBoxOppositeTarget=$v.BoxTarget
      InpMinimumTargetR=$v.MinTargetR
      InpUseFixedTakeProfit=([string]($v.BoxTarget -eq "false")).ToLowerInvariant(); InpTakeProfitR=$v.TPR
   }
   foreach($entry in $map.GetEnumerator()) {
      Set-InputLine -Inputs $inputs -Name $entry.Key -Value ([string]$entry.Value)
   }
   Set-InputLine -Inputs $inputs -Name "InpEvidenceProfileId" -Value $variant.Name
   Set-InputLine -Inputs $inputs -Name "InpEvidenceSourceHash" -Value $sourceHash
   Set-InputLine -Inputs $inputs -Name "InpEvidenceRunLabel" -Value "independent_m5_failed_breakout_discovery_model1"
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
         SourceType="independent_m5_failed_breakout_trap"; SourceRank=1; Phase="discovery_model1"
         Set=$profileName; Window=$window.Name; From=$window.From; To=$window.To; Model=1; Deposit=10000
         Config="configs\$configName"; ExpectedReportName=$reportName; ProfileSnapshot="profiles\$profileName"
         ProfileSha256=$profileHash; SourceSha256=$sourceHash; SignalTimeframe="5"
         BoxLookbackBars=$v.BoxBars; MaximumBreakoutAgeBars=$v.Age; MinimumBoxRangeATR=$v.MinBox
         MaximumBoxRangeATR=$v.MaxBox; BreakRangeATR=$v.BreakRange; ReclaimDepthRatio=$v.ReclaimDepth
         BreakVolume=$v.BreakVolume; ReclaimVolume=$v.ReclaimVolume; MaximumADX=$v.MaxADX
         BoxOppositeTarget=$v.BoxTarget; MinimumTargetR=$v.MinTargetR; TakeProfitR=$v.TPR; StopRule=$stopRule
      }) | Out-Null

      $runRows.Add([pscustomobject]@{
         QueueRank=$rank; Candidate=$variant.Name; Phase="discovery_model1"
         PhaseLabel="Independent M5 failed-breakout discovery Model1"; Window=$window.Name; Model=1; Deposit=10000
         PackageConfig="$PackageDir\configs\$configName"; SourceConfig="$PackageDir\configs\$configName"
         ExpectedReportName=$reportName; ReportDestination="$PackageDir\reports_here\$reportName"
         ProfileSha256=$profileHash; StopRule=$stopRule
      }) | Out-Null
   }
}

$queueRows | Export-Csv -LiteralPath (Resolve-RepoPath $QueueManifestPath) -NoTypeInformation -Encoding ASCII
$runRows | Export-Csv -LiteralPath (Resolve-RepoPath $PackageManifestPath) -NoTypeInformation -Encoding ASCII

$md = [System.Collections.Generic.List[string]]::new()
$md.Add("# Independent M5 Failed-Breakout Discovery Package")
$md.Add("")
$md.Add("Lower-timeframe activity test of the frozen 14/16/18-box and exit-shape neighborhood. No configuration includes data after 2020.")
$md.Add("")
$md.Add("- Source SHA-256: ``$sourceHash``")
$md.Add("- Variants: ``$($variants.Count)``")
$md.Add("- Discovery windows: ``$($windows.Name -join ', ')``")
$md.Add("- Configurations: ``$rank``")
$md.Add("")
$md.Add('Every profile requires a prior closed-bar break beyond a bounded M5 compression box and the first later snapback into that box. Stops sit beyond the failed excursion; target shapes match the M15 clue; stop distances above `$10` are rejected; `OrderCalcProfit` sizes at `0.10%`; no minimum lot is forced; and real-account trading is disabled.')
$md | Set-Content -LiteralPath (Resolve-RepoPath $MarkdownPath) -Encoding ASCII

[pscustomobject]@{ Status="READY"; SourceHash=$sourceHash; Variants=$variants.Count; Windows=$windows.Count; Configurations=$rank; PackageDir=$PackageDir }
