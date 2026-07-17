param(
   [string]$SourcePath = "work\Independent_XAUUSD_H1_PrevWeek_Break_Retest.mq5",
   [string]$PackageDir = "outputs\independent_h1_prevweek_break_retest_discovery_model1_package",
   [string]$QueueManifestPath = "outputs\INDEPENDENT_H1_PREVWEEK_BREAK_RETEST_DISCOVERY_MODEL1_QUEUE.csv",
   [string]$PackageManifestPath = "outputs\INDEPENDENT_H1_PREVWEEK_BREAK_RETEST_DISCOVERY_MODEL1_PACKAGE_MANIFEST.csv",
   [string]$MarkdownPath = "outputs\INDEPENDENT_H1_PREVWEEK_BREAK_RETEST_DISCOVERY_MODEL1_PACKAGE.md"
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
      InpAllowedSymbol = "XAUUSD"; InpMagicNumber = "26071731"; InpUseSymbolSafetyLock = "true"
      InpUseRealAccountSafetyLock = "true"; InpAllowRealAccountTrading = "false"; InpRealAccountApprovalCode = "DISABLED"
      InpSignalTimeframe = "16385"; InpMaximumSetupAgeBars = "8"; InpBreakBufferATR = "0.08"
      InpMinimumBreakRangeATR = "0.70"; InpMinimumBreakBodyPercent = "40.0"; InpMinimumBreakCloseLocation = "0.65"
      InpRequireFreshBreak = "true"; InpRetestToleranceATR = "0.20"; InpMaximumRetestPenetrationATR = "0.35"
      InpMinimumRetestReclaimATR = "0.02"; InpMinimumRetestBodyPercent = "15.0"; InpMinimumRetestCloseLocation = "0.55"
      InpMaximumEntryDistanceATR = "0.60"; InpRequireRetestDirectionCandle = "true"; InpAllowBuy = "true"
      InpAllowSell = "true"; InpUseBreakoutVolumeFilter = "false"; InpUseRetestVolumeFilter = "false"
      InpVolumeLookbackBars = "20"; InpMinimumVolumeRatio = "1.05"; InpUseTrendEMAFilter = "true"
      InpTrendTimeframe = "16388"; InpTrendEMAPeriod = "100"; InpTrendEMASlopeBars = "3"
      InpRequireTrendAlignment = "true"; InpUseMinimumADXFilter = "false"; InpADXPeriod = "14"
      InpMinimumADX = "16.0"; InpUseVolatilityFilter = "true"; InpMinimumATRPercent = "0.03"
      InpMaximumATRPercent = "2.50"; InpATRPeriod = "20"; InpStopBufferATR = "0.10"
      InpStopLookbackBars = "2"; InpMinimumStopATR = "0.30"; InpMaximumStopATR = "2.50"
      InpMaximumStopPriceDistance = "10.00"; InpUseFixedTakeProfit = "true"; InpTakeProfitR = "2.00"
      InpUseBreakEven = "true"; InpBreakEvenTriggerR = "1.00"; InpBreakEvenLockR = "0.10"
      InpUseChandelierTrail = "false"; InpChandelierLookbackBars = "8"; InpChandelierATR = "2.50"
      InpUseTrendFailureExit = "false"; InpMaximumHoldBars = "48"; InpUseSessionFilter = "true"
      InpSessionStartHour = "6"; InpSessionEndHour = "22"; InpDisableFridayAfterHour = "true"
      InpFridayCutoffHour = "18"; InpRiskPercent = "0.10"; InpMaximumPositionLots = "1.00"
      InpMaximumSimultaneousPositions = "1"; InpMaximumTradesPerDay = "2"; InpMaximumDailyLossPercent = "0.75"
      InpMaximumEquityDrawdownPercent = "5.00"; InpMaximumConsecutiveLosses = "4"; InpLossCooldownHours = "24"
      InpMaximumSpreadPoints = "50.0"; InpDeviationPoints = "20"; InpUseAccountWideExposureGuard = "true"
      InpAccountWideMaxOpenRiskPercent = "3.00"; InpAccountWideMaxPositions = "3"
      InpAccountWideBlockUnprotectedExposure = "true"; InpLogTrades = "false"
      InpLogFileName = "Independent_XAUUSD_H1_PrevWeek_Break_Retest_Trades.csv"
      InpEvidenceProfileId = ""; InpEvidenceSourceHash = ""; InpEvidenceRunLabel = ""
   }
   foreach($entry in $defaults.GetEnumerator()) {
      Set-InputLine -Inputs $inputs -Name $entry.Key -Value ([string]$entry.Value)
   }
   return $inputs
}

& (Join-Path $PSScriptRoot "test_independent_h1_prevweek_break_retest_source.ps1") | Out-Null
$sourceFull = (Resolve-Path -LiteralPath (Resolve-RepoPath $SourcePath)).Path
$sourceHash = (Get-FileHash -LiteralPath $sourceFull -Algorithm SHA256).Hash

$variants = @(
   [pscustomobject]@{ Name="pwbr_base"; Age="8"; Buffer="0.08"; BreakRange="0.70"; BreakBody="40.0"; BreakClose="0.65"; Tol="0.20"; Pen="0.35"; Reclaim="0.02"; RetBody="15.0"; RetClose="0.55"; MaxEntry="0.60"; BreakVol="false"; RetVol="false"; Trend="true"; AdxFilter="false"; MinAdx="16.0"; Session="true"; TPR="2.00" },
   [pscustomobject]@{ Name="pwbr_break_loose"; Age="8"; Buffer="0.08"; BreakRange="0.50"; BreakBody="30.0"; BreakClose="0.60"; Tol="0.20"; Pen="0.35"; Reclaim="0.02"; RetBody="15.0"; RetClose="0.55"; MaxEntry="0.60"; BreakVol="false"; RetVol="false"; Trend="true"; AdxFilter="false"; MinAdx="16.0"; Session="true"; TPR="2.00" },
   [pscustomobject]@{ Name="pwbr_break_strict"; Age="8"; Buffer="0.08"; BreakRange="1.00"; BreakBody="50.0"; BreakClose="0.70"; Tol="0.20"; Pen="0.35"; Reclaim="0.02"; RetBody="15.0"; RetClose="0.55"; MaxEntry="0.60"; BreakVol="false"; RetVol="false"; Trend="true"; AdxFilter="false"; MinAdx="16.0"; Session="true"; TPR="2.00" },
   [pscustomobject]@{ Name="pwbr_buffer15"; Age="8"; Buffer="0.15"; BreakRange="0.70"; BreakBody="40.0"; BreakClose="0.65"; Tol="0.20"; Pen="0.35"; Reclaim="0.02"; RetBody="15.0"; RetClose="0.55"; MaxEntry="0.60"; BreakVol="false"; RetVol="false"; Trend="true"; AdxFilter="false"; MinAdx="16.0"; Session="true"; TPR="2.00" },
   [pscustomobject]@{ Name="pwbr_age4"; Age="4"; Buffer="0.08"; BreakRange="0.70"; BreakBody="40.0"; BreakClose="0.65"; Tol="0.20"; Pen="0.35"; Reclaim="0.02"; RetBody="15.0"; RetClose="0.55"; MaxEntry="0.60"; BreakVol="false"; RetVol="false"; Trend="true"; AdxFilter="false"; MinAdx="16.0"; Session="true"; TPR="2.00" },
   [pscustomobject]@{ Name="pwbr_age12"; Age="12"; Buffer="0.08"; BreakRange="0.70"; BreakBody="40.0"; BreakClose="0.65"; Tol="0.20"; Pen="0.35"; Reclaim="0.02"; RetBody="15.0"; RetClose="0.55"; MaxEntry="0.60"; BreakVol="false"; RetVol="false"; Trend="true"; AdxFilter="false"; MinAdx="16.0"; Session="true"; TPR="2.00" },
   [pscustomobject]@{ Name="pwbr_retest_tight"; Age="8"; Buffer="0.08"; BreakRange="0.70"; BreakBody="40.0"; BreakClose="0.65"; Tol="0.10"; Pen="0.25"; Reclaim="0.05"; RetBody="15.0"; RetClose="0.60"; MaxEntry="0.40"; BreakVol="false"; RetVol="false"; Trend="true"; AdxFilter="false"; MinAdx="16.0"; Session="true"; TPR="2.00" },
   [pscustomobject]@{ Name="pwbr_retest_loose"; Age="8"; Buffer="0.08"; BreakRange="0.70"; BreakBody="40.0"; BreakClose="0.65"; Tol="0.30"; Pen="0.50"; Reclaim="0.00"; RetBody="10.0"; RetClose="0.52"; MaxEntry="0.80"; BreakVol="false"; RetVol="false"; Trend="true"; AdxFilter="false"; MinAdx="16.0"; Session="true"; TPR="2.00" },
   [pscustomobject]@{ Name="pwbr_volume_both"; Age="8"; Buffer="0.08"; BreakRange="0.70"; BreakBody="40.0"; BreakClose="0.65"; Tol="0.20"; Pen="0.35"; Reclaim="0.02"; RetBody="15.0"; RetClose="0.55"; MaxEntry="0.60"; BreakVol="true"; RetVol="true"; Trend="true"; AdxFilter="false"; MinAdx="16.0"; Session="true"; TPR="2.00" },
   [pscustomobject]@{ Name="pwbr_no_trend"; Age="8"; Buffer="0.08"; BreakRange="0.70"; BreakBody="40.0"; BreakClose="0.65"; Tol="0.20"; Pen="0.35"; Reclaim="0.02"; RetBody="15.0"; RetClose="0.55"; MaxEntry="0.60"; BreakVol="false"; RetVol="false"; Trend="false"; AdxFilter="false"; MinAdx="16.0"; Session="true"; TPR="2.00" },
   [pscustomobject]@{ Name="pwbr_adx18"; Age="8"; Buffer="0.08"; BreakRange="0.70"; BreakBody="40.0"; BreakClose="0.65"; Tol="0.20"; Pen="0.35"; Reclaim="0.02"; RetBody="15.0"; RetClose="0.55"; MaxEntry="0.60"; BreakVol="false"; RetVol="false"; Trend="true"; AdxFilter="true"; MinAdx="18.0"; Session="true"; TPR="2.00" },
   [pscustomobject]@{ Name="pwbr_session_off"; Age="8"; Buffer="0.08"; BreakRange="0.70"; BreakBody="40.0"; BreakClose="0.65"; Tol="0.20"; Pen="0.35"; Reclaim="0.02"; RetBody="15.0"; RetClose="0.55"; MaxEntry="0.60"; BreakVol="false"; RetVol="false"; Trend="true"; AdxFilter="false"; MinAdx="16.0"; Session="false"; TPR="2.00" },
   [pscustomobject]@{ Name="pwbr_rr15"; Age="8"; Buffer="0.08"; BreakRange="0.70"; BreakBody="40.0"; BreakClose="0.65"; Tol="0.20"; Pen="0.35"; Reclaim="0.02"; RetBody="15.0"; RetClose="0.55"; MaxEntry="0.60"; BreakVol="false"; RetVol="false"; Trend="true"; AdxFilter="false"; MinAdx="16.0"; Session="true"; TPR="1.50" },
   [pscustomobject]@{ Name="pwbr_rr25"; Age="8"; Buffer="0.08"; BreakRange="0.70"; BreakBody="40.0"; BreakClose="0.65"; Tol="0.20"; Pen="0.35"; Reclaim="0.02"; RetBody="15.0"; RetClose="0.55"; MaxEntry="0.60"; BreakVol="false"; RetVol="false"; Trend="true"; AdxFilter="false"; MinAdx="16.0"; Session="true"; TPR="2.50" }
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
New-Item -ItemType Directory -Path $configDir, $profileDir, $reportDir, $sourceDir -Force | Out-Null
Copy-Item -LiteralPath $sourceFull -Destination (Join-Path $sourceDir "Professional_XAUUSD_EA.mq5") -Force

$queueRows = [System.Collections.Generic.List[object]]::new()
$runRows = [System.Collections.Generic.List[object]]::new()
$rank = 0
$candidateRank = 0
$stopRule = "Discovery only through 2020: require both disjoint eras positive, continuous PF at least 1.20, at least 40 continuous trades, DD at or below 5%, and support from neighboring break/retest/payoff shapes before opening 2021-2026."

foreach($variant in $variants) {
   $candidateRank++
   $inputs = New-BaseInputs
   $map = [ordered]@{
      InpMaximumSetupAgeBars=$variant.Age; InpBreakBufferATR=$variant.Buffer
      InpMinimumBreakRangeATR=$variant.BreakRange; InpMinimumBreakBodyPercent=$variant.BreakBody
      InpMinimumBreakCloseLocation=$variant.BreakClose; InpRetestToleranceATR=$variant.Tol
      InpMaximumRetestPenetrationATR=$variant.Pen; InpMinimumRetestReclaimATR=$variant.Reclaim
      InpMinimumRetestBodyPercent=$variant.RetBody; InpMinimumRetestCloseLocation=$variant.RetClose
      InpMaximumEntryDistanceATR=$variant.MaxEntry; InpUseBreakoutVolumeFilter=$variant.BreakVol
      InpUseRetestVolumeFilter=$variant.RetVol; InpUseTrendEMAFilter=$variant.Trend
      InpUseMinimumADXFilter=$variant.AdxFilter; InpMinimumADX=$variant.MinAdx
      InpUseSessionFilter=$variant.Session; InpTakeProfitR=$variant.TPR
   }
   foreach($entry in $map.GetEnumerator()) {
      Set-InputLine -Inputs $inputs -Name $entry.Key -Value ([string]$entry.Value)
   }
   Set-InputLine -Inputs $inputs -Name "InpEvidenceProfileId" -Value $variant.Name
   Set-InputLine -Inputs $inputs -Name "InpEvidenceSourceHash" -Value $sourceHash
   Set-InputLine -Inputs $inputs -Name "InpEvidenceRunLabel" -Value "independent_h1_prevweek_break_retest_discovery_model1"
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
         SourceType="independent_h1_prevweek_break_retest"; SourceRank=1; Phase="discovery_model1"
         Set=$profileName; Window=$window.Name; From=$window.From; To=$window.To; Model=1; Deposit=10000
         Config="configs\$configName"; ExpectedReportName=$reportName; ProfileSnapshot="profiles\$profileName"
         ProfileSha256=$profileHash; SourceSha256=$sourceHash; SignalTimeframe="16385"
         SetupAge=$variant.Age; BreakBufferATR=$variant.Buffer; BreakRangeATR=$variant.BreakRange
         BreakBodyPercent=$variant.BreakBody; RetestToleranceATR=$variant.Tol; RetestPenetrationATR=$variant.Pen
         RetestReclaimATR=$variant.Reclaim; TrendFilter=$variant.Trend; ADXFilter=$variant.AdxFilter
         SessionFilter=$variant.Session; TakeProfitR=$variant.TPR; StopRule=$stopRule
      }) | Out-Null
      $runRows.Add([pscustomobject]@{
         QueueRank=$rank; Candidate=$variant.Name; Phase="discovery_model1"
         PhaseLabel="Independent H1 previous-week break-retest discovery Model1"; Window=$window.Name; Model=1; Deposit=10000
         PackageConfig="$PackageDir\configs\$configName"; SourceConfig="$PackageDir\configs\$configName"
         ExpectedReportName=$reportName; ReportDestination="$PackageDir\reports_here\$reportName"
         ProfileSha256=$profileHash; StopRule=$stopRule
      }) | Out-Null
   }
}

$queueRows | Export-Csv -LiteralPath (Resolve-RepoPath $QueueManifestPath) -NoTypeInformation -Encoding ASCII
$runRows | Export-Csv -LiteralPath (Resolve-RepoPath $PackageManifestPath) -NoTypeInformation -Encoding ASCII

$md = [System.Collections.Generic.List[string]]::new()
$md.Add("# Independent H1 Previous-Week Break-And-Retest Discovery Package")
$md.Add("")
$md.Add("Standalone, date-independent market-structure family. No configuration includes data after 2020.")
$md.Add("")
$md.Add("- Source SHA-256: ``$sourceHash``")
$md.Add("- Variants: ``$($variants.Count)``")
$md.Add("- Discovery windows: ``$($windows.Name -join ', ')``")
$md.Add("- Configurations: ``$rank``")
$md.Add("")
$md.Add('Every profile requires an H1 close beyond the previous W1 high or low and a later bounded retest/reclaim. Stops use recent structure, reject distances above `$10`, preserve take profit during stop updates, size with broker-accurate `OrderCalcProfit` at `0.10%` risk, and keep real-account trading disabled.')
$md | Set-Content -LiteralPath (Resolve-RepoPath $MarkdownPath) -Encoding ASCII

[pscustomobject]@{ Status="READY"; SourceHash=$sourceHash; Variants=$variants.Count; Windows=$windows.Count; Configurations=$rank; PackageDir=$PackageDir }
