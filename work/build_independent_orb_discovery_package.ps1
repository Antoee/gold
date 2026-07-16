param(
   [string]$SourcePath = "work\Independent_XAUUSD_Opening_Range_Breakout.mq5",
   [string]$PackageDir = "outputs\independent_orb_discovery_model1_package",
   [string]$QueueManifestPath = "outputs\INDEPENDENT_ORB_DISCOVERY_MODEL1_QUEUE.csv",
   [string]$PackageManifestPath = "outputs\INDEPENDENT_ORB_DISCOVERY_MODEL1_PACKAGE_MANIFEST.csv",
   [string]$MarkdownPath = "outputs\INDEPENDENT_ORB_DISCOVERY_MODEL1_PACKAGE.md"
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
      if(!$resolved.StartsWith($outputsRoot, [System.StringComparison]::OrdinalIgnoreCase)) { throw "Refusing to clear non-outputs directory: $resolved" }
      Remove-Item -LiteralPath $resolved -Recurse -Force
   }
   New-Item -ItemType Directory -Path $Path -Force | Out-Null
}
function New-BaseInputs {
   $inputs = [ordered]@{}
   $defaults = [ordered]@{
      InpAllowedSymbol = "XAUUSD"; InpMagicNumber = "26071641"; InpUseSymbolSafetyLock = "true"
      InpUseRealAccountSafetyLock = "true"; InpAllowRealAccountTrading = "false"; InpRealAccountApprovalCode = "DISABLED"
      InpUseLondonSession = "true"; InpLondonRangeStartHour = "7"; InpLondonRangeEndHour = "8"; InpLondonTradeEndHour = "12"
      InpUseNewYorkSession = "false"; InpNewYorkRangeStartHour = "13"; InpNewYorkRangeEndHour = "14"; InpNewYorkTradeEndHour = "17"
      InpCloseAtSessionEnd = "true"; InpSignalTimeframe = "15"; InpATRPeriod = "14"; InpBreakoutBufferATR = "0.05"
      InpMinimumRangeATR = "0.50"; InpMaximumRangeATR = "3.00"; InpMaximumExtensionATR = "0.60"
      InpMinimumBreakoutBodyPercent = "45.0"; InpAllowBuy = "true"; InpAllowSell = "true"
      InpUseH1TrendFilter = "true"; InpH1FastEMAPeriod = "50"; InpH1SlowEMAPeriod = "200"
      InpUseADXFilter = "true"; InpADXPeriod = "14"; InpMinimumADX = "18.0"
      InpUseTickVolumeFilter = "false"; InpVolumeLookbackBars = "20"; InpMinimumVolumeRatio = "1.00"
      InpMinimumStopATR = "0.60"; InpMaximumStopATR = "1.80"; InpTakeProfitRR = "2.00"
      InpUseBreakEven = "true"; InpBreakEvenTriggerR = "1.00"; InpBreakEvenLockR = "0.05"
      InpUseATRTrailing = "true"; InpTrailingStartR = "1.50"; InpTrailingATRMultiplier = "1.20"
      InpRiskPercent = "0.10"; InpMaximumPositionLots = "1.00"; InpMaximumSimultaneousPositions = "1"
      InpMaximumTradesPerDay = "2"; InpMaximumDailyLossPercent = "0.75"; InpMaximumEquityDrawdownPercent = "5.00"
      InpMaximumConsecutiveLosses = "3"; InpLossCooldownHours = "24"; InpMaximumSpreadPoints = "50.0"; InpDeviationPoints = "20"
      InpLogTrades = "false"; InpLogFileName = "Independent_XAUUSD_ORB_Trades.csv"
      InpEvidenceProfileId = ""; InpEvidenceSourceHash = ""; InpEvidenceRunLabel = ""
   }
   foreach($entry in $defaults.GetEnumerator()) { Set-InputLine -Inputs $inputs -Name $entry.Key -Value ([string]$entry.Value) }
   return $inputs
}

& (Join-Path $PSScriptRoot "test_independent_orb_source.ps1") | Out-Null
$sourceFull = (Resolve-Path -LiteralPath (Resolve-RepoPath $SourcePath)).Path
$sourceHash = (Get-FileHash -LiteralPath $sourceFull -Algorithm SHA256).Hash
$variants = @(
   [pscustomobject]@{ Name = "orb_london_adx18"; London = "true"; NewYork = "false"; Adx = "true"; Body = "45.0"; Volume = "false" },
   [pscustomobject]@{ Name = "orb_london_noadx"; London = "true"; NewYork = "false"; Adx = "false"; Body = "45.0"; Volume = "false" },
   [pscustomobject]@{ Name = "orb_london_adx18_body35"; London = "true"; NewYork = "false"; Adx = "true"; Body = "35.0"; Volume = "false" },
   [pscustomobject]@{ Name = "orb_newyork_adx18"; London = "false"; NewYork = "true"; Adx = "true"; Body = "45.0"; Volume = "false" },
   [pscustomobject]@{ Name = "orb_dual_adx18"; London = "true"; NewYork = "true"; Adx = "true"; Body = "45.0"; Volume = "false" },
   [pscustomobject]@{ Name = "orb_dual_adx18_volume"; London = "true"; NewYork = "true"; Adx = "true"; Body = "45.0"; Volume = "true" }
)
$windows = @(
   [pscustomobject]@{ Name = "older_2015_2018"; From = "2015.01.01"; To = "2018.12.31" },
   [pscustomobject]@{ Name = "discovery_2019_2020"; From = "2019.01.01"; To = "2020.12.31" },
   [pscustomobject]@{ Name = "continuous_2015_2020"; From = "2015.01.01"; To = "2020.12.31" }
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
$stopRule = "Discovery only: require both disjoint eras positive, PF at least 1.20, continuous trades at least 30, DD at or below 5%, and a neighboring profitable shape before opening the 2021-2026 holdout."
foreach($variant in $variants) {
   $candidateRank++
   $inputs = New-BaseInputs
   Set-InputLine -Inputs $inputs -Name "InpUseLondonSession" -Value $variant.London
   Set-InputLine -Inputs $inputs -Name "InpUseNewYorkSession" -Value $variant.NewYork
   Set-InputLine -Inputs $inputs -Name "InpUseADXFilter" -Value $variant.Adx
   Set-InputLine -Inputs $inputs -Name "InpMinimumBreakoutBodyPercent" -Value $variant.Body
   Set-InputLine -Inputs $inputs -Name "InpUseTickVolumeFilter" -Value $variant.Volume
   Set-InputLine -Inputs $inputs -Name "InpEvidenceProfileId" -Value $variant.Name
   Set-InputLine -Inputs $inputs -Name "InpEvidenceSourceHash" -Value $sourceHash
   Set-InputLine -Inputs $inputs -Name "InpEvidenceRunLabel" -Value "independent_orb_discovery_model1"
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
         QueueRank = $rank; Candidate = $variant.Name; CandidateRank = $candidateRank
         SourceType = "independent_orb"; SourceRank = 1; Phase = "discovery_model1"
         Set = $profileName; Window = $window.Name; From = $window.From; To = $window.To; Model = 1; Deposit = 10000
         Config = "configs\$configName"; ExpectedReportName = $reportName; ProfileSnapshot = "profiles\$profileName"
         ProfileSha256 = $profileHash; SourceSha256 = $sourceHash; London = $variant.London; NewYork = $variant.NewYork
         ADXFilter = $variant.Adx; MinimumBodyPercent = $variant.Body; VolumeFilter = $variant.Volume; StopRule = $stopRule
      }) | Out-Null
      $runRows.Add([pscustomobject]@{
         QueueRank = $rank; Candidate = $variant.Name; Phase = "discovery_model1"
         PhaseLabel = "Independent ORB discovery Model1"; Window = $window.Name; Model = 1; Deposit = 10000
         PackageConfig = "$PackageDir\configs\$configName"; SourceConfig = "$PackageDir\configs\$configName"
         ExpectedReportName = $reportName; ReportDestination = "$PackageDir\reports_here\$reportName"
         ProfileSha256 = $profileHash; StopRule = $stopRule
      }) | Out-Null
   }
}

$queueRows | Export-Csv -LiteralPath (Resolve-RepoPath $QueueManifestPath) -NoTypeInformation -Encoding ASCII
$runRows | Export-Csv -LiteralPath (Resolve-RepoPath $PackageManifestPath) -NoTypeInformation -Encoding ASCII
$md = [System.Collections.Generic.List[string]]::new()
$md.Add("# Independent Opening-Range Breakout Discovery Package")
$md.Add("")
$md.Add("Standalone, date-independent research lane. The 2021-2026 feature holdout is not included in this package.")
$md.Add("")
$md.Add("- Source SHA-256: ``$sourceHash``")
$md.Add("- Variants: ``$($variants.Count)``")
$md.Add("- Discovery windows: ``$($windows.Name -join ', ')``")
$md.Add("- Configurations: ``$rank``")
$md.Add("")
$md.Add('Every profile uses `0.10%` risk, one position, a `0.75%` daily-loss cap, a `5%` equity-drawdown cap, spread protection, and real-account trading disabled.')
$md | Set-Content -LiteralPath (Resolve-RepoPath $MarkdownPath) -Encoding ASCII
[pscustomobject]@{ Status = "READY"; SourceHash = $sourceHash; Variants = $variants.Count; Windows = $windows.Count; Configurations = $rank; PackageDir = $PackageDir }
