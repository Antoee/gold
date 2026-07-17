param(
   [string]$SourcePath = "work\Independent_XAUUSD_Multiscale_Momentum.mq5",
   [string]$PackageDir = "outputs\independent_multiscale_momentum_discovery_model1_package",
   [string]$QueueManifestPath = "outputs\INDEPENDENT_MULTISCALE_MOMENTUM_DISCOVERY_MODEL1_QUEUE.csv",
   [string]$PackageManifestPath = "outputs\INDEPENDENT_MULTISCALE_MOMENTUM_DISCOVERY_MODEL1_PACKAGE_MANIFEST.csv",
   [string]$MarkdownPath = "outputs\INDEPENDENT_MULTISCALE_MOMENTUM_DISCOVERY_MODEL1_PACKAGE.md"
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
      InpAllowedSymbol="XAUUSD"; InpMagicNumber="26071761"; InpUseSymbolSafetyLock="true"
      InpUseRealAccountSafetyLock="true"; InpAllowRealAccountTrading="false"; InpRealAccountApprovalCode="DISABLED"
      InpSignalTimeframe="16385"; InpMomentumTimeframe="16408"; InpMomentumLookbackBars="126"
      InpEntryLookbackBars="10"; InpBreakoutBufferATR="0.05"; InpAllowBuy="true"
      InpAllowSell="true"; InpRequireFreshBreakout="true"; InpUseVolatilityFilter="true"
      InpMinimumATRPercent="0.03"; InpMaximumATRPercent="2.50"; InpATRPeriod="20"
      InpStopLookbackBars="5"; InpStopBufferATR="0.10"; InpMinimumStopATR="0.40"
      InpMaximumStopATR="2.50"; InpMaximumStopPriceDistance="10.00"; InpTakeProfitR="2.00"
      InpUseBreakEven="true"; InpBreakEvenTriggerR="1.00"; InpBreakEvenLockR="0.10"
      InpUseChannelExit="true"; InpExitLookbackBars="5"; InpUseMomentumFailureExit="true"
      InpMaximumHoldBars="120"; InpUseSessionFilter="true"; InpSessionStartHour="6"
      InpSessionEndHour="20"; InpDisableFridayAfterHour="true"; InpFridayCutoffHour="18"
      InpRiskPercent="0.10"; InpMaximumPositionLots="1.00"; InpMaximumSimultaneousPositions="1"
      InpMaximumTradesPerDay="2"; InpMaximumDailyLossPercent="0.75"
      InpMaximumEquityDrawdownPercent="5.00"; InpMaximumConsecutiveLosses="4"
      InpLossCooldownHours="24"; InpMaximumSpreadPoints="50.0"; InpDeviationPoints="20"
      InpUseAccountWideExposureGuard="true"; InpAccountWideMaxOpenRiskPercent="3.00"
      InpAccountWideMaxPositions="3"; InpAccountWideBlockUnprotectedExposure="true"
      InpLogTrades="false"; InpLogFileName="Independent_XAUUSD_Multiscale_Momentum_Trades.csv"
      InpEvidenceProfileId=""; InpEvidenceSourceHash=""; InpEvidenceRunLabel=""
   }
   foreach($entry in $defaults.GetEnumerator()) {
      Set-InputLine -Inputs $inputs -Name $entry.Key -Value ([string]$entry.Value)
   }
   return $inputs
}

& (Join-Path $PSScriptRoot "test_independent_multiscale_momentum_source.ps1") | Out-Null
$sourceFull = (Resolve-Path -LiteralPath (Resolve-RepoPath $SourcePath)).Path
$sourceHash = (Get-FileHash -LiteralPath $sourceFull -Algorithm SHA256).Hash

$variants = @(
   [pscustomobject]@{ Name="mtsm_m63_e10_r200"; Momentum="63"; Entry="10"; TargetR="2.00" },
   [pscustomobject]@{ Name="mtsm_m126_e10_r200"; Momentum="126"; Entry="10"; TargetR="2.00" },
   [pscustomobject]@{ Name="mtsm_m252_e10_r200"; Momentum="252"; Entry="10"; TargetR="2.00" },
   [pscustomobject]@{ Name="mtsm_m126_e6_r200"; Momentum="126"; Entry="6"; TargetR="2.00" },
   [pscustomobject]@{ Name="mtsm_m126_e20_r200"; Momentum="126"; Entry="20"; TargetR="2.00" },
   [pscustomobject]@{ Name="mtsm_m126_e10_r150"; Momentum="126"; Entry="10"; TargetR="1.50" },
   [pscustomobject]@{ Name="mtsm_m126_e10_r250"; Momentum="126"; Entry="10"; TargetR="2.50" }
)
$windows = @(
   [pscustomobject]@{ Name="older_2015_2018"; From="2015.01.01"; To="2018.12.31" },
   [pscustomobject]@{ Name="discovery_2019_2020"; From="2019.01.01"; To="2020.12.31" },
   [pscustomobject]@{ Name="continuous_2015_2020"; From="2015.01.01"; To="2020.12.31" }
)
$stopRule = "Discovery only: require both disjoint eras profitable, continuous PF >= 1.20, at least 100 continuous trades, DD <= 5%, and at least two adjacent momentum/entry/target shapes passing before any 2021+ run."

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
$rank = 0
$candidateRank = 0
foreach($variant in $variants) {
   $candidateRank++
   $inputs = New-BaseInputs
   Set-InputLine -Inputs $inputs -Name "InpMomentumLookbackBars" -Value $variant.Momentum
   Set-InputLine -Inputs $inputs -Name "InpEntryLookbackBars" -Value $variant.Entry
   Set-InputLine -Inputs $inputs -Name "InpTakeProfitR" -Value $variant.TargetR
   Set-InputLine -Inputs $inputs -Name "InpEvidenceProfileId" -Value $variant.Name
   Set-InputLine -Inputs $inputs -Name "InpEvidenceSourceHash" -Value $sourceHash
   Set-InputLine -Inputs $inputs -Name "InpEvidenceRunLabel" -Value "independent_multiscale_momentum_discovery_model1"
   Set-InputLine -Inputs $inputs -Name "InpLogFileName" -Value "$($variant.Name)_trades.csv"
   $profileName = "$($variant.Name).set"
   $profilePath = Join-Path $profileDir $profileName
   @($inputs.Keys | Sort-Object | ForEach-Object { $inputs[$_] }) |
      Set-Content -LiteralPath $profilePath -Encoding ASCII
   $profileHash = (Get-FileHash -LiteralPath $profilePath -Algorithm SHA256).Hash

   foreach($window in $windows) {
      $rank++
      $configName = "{0:000}_{1}_{2}_m1.ini" -f $rank,$variant.Name,$window.Name
      $reportName = "$($variant.Name)_$($window.Name)_m1"
      Write-SeasonalTesterConfig -Path (Join-Path $configDir $configName) -ReportRoot $reportDir `
         -ReportName $reportName -From $window.From -To $window.To -Inputs $inputs -Model 1 -Deposit 10000
      $queueRows.Add([pscustomobject]@{
         QueueRank=$rank; Candidate=$variant.Name; CandidateRank=$candidateRank
         SourceType="independent_multiscale_momentum"; SourceRank=1; Phase="discovery_model1"
         Set=$profileName; Window=$window.Name; From=$window.From; To=$window.To; Model=1; Deposit=10000
         Config="configs\$configName"; ExpectedReportName=$reportName; ProfileSnapshot="profiles\$profileName"
         ProfileSha256=$profileHash; SourceSha256=$sourceHash; MomentumLookback=$variant.Momentum
         EntryLookback=$variant.Entry; TargetR=$variant.TargetR; StopRule=$stopRule
      }) | Out-Null
      $runRows.Add([pscustomobject]@{
         QueueRank=$rank; Candidate=$variant.Name; Phase="discovery_model1"
         PhaseLabel="Independent multiscale momentum discovery Model1"; Window=$window.Name; Model=1; Deposit=10000
         PackageConfig="$PackageDir\configs\$configName"; SourceConfig="$PackageDir\configs\$configName"
         ExpectedReportName=$reportName; ReportDestination="$PackageDir\reports_here\$reportName"
         ProfileSha256=$profileHash; StopRule=$stopRule
      }) | Out-Null
   }
}

$queueRows | Export-Csv -LiteralPath (Resolve-RepoPath $QueueManifestPath) -NoTypeInformation -Encoding ASCII
$runRows | Export-Csv -LiteralPath (Resolve-RepoPath $PackageManifestPath) -NoTypeInformation -Encoding ASCII

$lines = @(
   "# Independent Multiscale Momentum Discovery Package",
   "",
   "Standalone date-independent discovery using only 2015-2020 data.",
   "",
   "- Source SHA-256: ``$sourceHash``",
   "- Variants: ``$($variants.Count)``",
   "- Windows: ``$($windows.Name -join ', ')``",
   "- Configurations: ``$rank``",
   '- Starting balance: `$10,000`',
   "- Risk per trade: ``0.10%``",
   "",
   'The direction signal is the sign of the trailing 3/6/12-month D1 return. Execution requires a fresh H1 channel breakout, and the stop uses recent H1 structure with a hard `$10` distance cap. No calendar gate or forced minimum lot is present.',
   "",
   $stopRule
)
$lines | Set-Content -LiteralPath (Resolve-RepoPath $MarkdownPath) -Encoding ASCII

[pscustomobject]@{ Status="READY"; SourceHash=$sourceHash; Variants=$variants.Count; Windows=$windows.Count; Configurations=$rank; PackageDir=$PackageDir }
