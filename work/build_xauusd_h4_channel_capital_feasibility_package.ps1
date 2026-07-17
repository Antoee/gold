param(
   [string]$SourcePath = "work\XAUUSD_H4_Channel_Capital_Feasibility_Probe.mq5",
   [string]$PackageDir = "outputs\xauusd_h4_channel_capital_feasibility_package",
   [string]$ManifestPath = "outputs\XAUUSD_H4_CHANNEL_CAPITAL_FEASIBILITY_MANIFEST.csv",
   [string]$QueuePath = "outputs\XAUUSD_H4_CHANNEL_CAPITAL_FEASIBILITY_QUEUE.csv"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$outputsRoot = (Resolve-Path (Join-Path $repo "outputs")).Path
function Resolve-RepoPath([string]$Path) { if([IO.Path]::IsPathRooted($Path)) { return $Path }; return Join-Path $repo $Path }
function Clear-OutputDirSafe([string]$Path) {
   if(Test-Path -LiteralPath $Path) {
      $resolved = (Resolve-Path -LiteralPath $Path).Path
      if(!$resolved.StartsWith($outputsRoot, [StringComparison]::OrdinalIgnoreCase)) { throw "Refusing to clear outside outputs: $resolved" }
      Remove-Item -LiteralPath $resolved -Recurse -Force
   }
   New-Item -ItemType Directory -Path $Path -Force | Out-Null
}

& (Join-Path $PSScriptRoot "test_xauusd_h4_channel_capital_feasibility_source.ps1") -SourcePath $SourcePath | Out-Null
$sourceFull = (Resolve-Path -LiteralPath (Resolve-RepoPath $SourcePath)).Path
$sourceHash = (Get-FileHash -LiteralPath $sourceFull -Algorithm SHA256).Hash
$packageFull = Resolve-RepoPath $PackageDir
Clear-OutputDirSafe $packageFull
$configDir = Join-Path $packageFull "configs"
$profileDir = Join-Path $packageFull "profiles"
$reportDir = Join-Path $packageFull "reports_here"
$sourceDir = Join-Path $packageFull "source"
New-Item -ItemType Directory -Path $configDir, $profileDir, $reportDir, $sourceDir -Force | Out-Null
Copy-Item -LiteralPath $sourceFull -Destination (Join-Path $sourceDir "Professional_XAUUSD_EA.mq5") -Force

$lookbacks = @(40, 55, 80)
$manifest = [Collections.Generic.List[object]]::new()
$queue = [Collections.Generic.List[object]]::new()
$rank = 0
foreach($lookback in $lookbacks) {
   $rank++
   $candidate = "h4ct_capital_l${lookback}"
   $configName = "{0:000}_{1}_continuous_m1.ini" -f $rank, $candidate
   $reportName = "${candidate}_continuous_2015_2026_m1"
   $profileName = "${candidate}.set"
   $profileLines = @(
      "InpAllowedSymbol=XAUUSD",
      "InpUseSymbolSafetyLock=true||true||0||0||N",
      "InpUseRealAccountSafetyLock=true||true||0||0||N",
      "InpSignalTimeframe=16388||16388||0||0||N",
      "InpEntryLookbackBars=$lookback||$lookback||0||0||N",
      "InpRequireFreshBreakout=true||true||0||0||N",
      "InpBreakoutBufferATR=0.00||0.00||0||0||N",
      "InpATRPeriod=20||20||0||0||N",
      "InpInitialStopATR=2.00||2.00||0||0||N",
      "InpUseVolatilityFilter=true||true||0||0||N",
      "InpMinimumATRPercent=0.20||0.20||0||0||N",
      "InpMaximumATRPercent=5.00||5.00||0||0||N",
      "InpAssumedEquity=10000.00||10000.00||0||0||N",
      "InpRiskPercent=0.10||0.10||0||0||N",
      "InpProbeId=$candidate",
      "InpSourceSha256=$sourceHash",
      "InpOutputFileName=XAUUSD_H4_Channel_Capital_Feasibility.csv"
   )
   $profilePath = Join-Path $profileDir $profileName
   $profileLines | Set-Content -LiteralPath $profilePath -Encoding ASCII
   $profileHash = (Get-FileHash -LiteralPath $profilePath -Algorithm SHA256).Hash
   $configLines = @(
      "[Tester]",
      "Expert=Professional_XAUUSD_EA.ex5",
      "Symbol=XAUUSD",
      "Period=240",
      "Optimization=0",
      "Model=1",
      "FromDate=2015.01.01",
      "ToDate=2026.07.12",
      "ForwardMode=0",
      "Deposit=10000",
      "Currency=USD",
      "ProfitInPips=0",
      "Leverage=100",
      "ExecutionMode=0",
      "OptimizationCriterion=6",
      "Visual=0",
      "Report=$reportName",
      "ReplaceReport=1",
      "ShutdownTerminal=1",
      "[TesterInputs]"
   ) + $profileLines
   $configPath = Join-Path $configDir $configName
   $configLines | Set-Content -LiteralPath $configPath -Encoding ASCII
   $manifest.Add([pscustomobject]@{
      QueueRank = $rank; Candidate = $candidate; Phase = "capital_feasibility_diagnostic"
      PhaseLabel = "H4 channel broker minimum-lot feasibility"; Window = "continuous_2015_2026"
      Model = 1; Deposit = 10000; PackageConfig = "$PackageDir\configs\$configName"
      SourceConfig = "$PackageDir\configs\$configName"; ExpectedReportName = $reportName
      ReportDestination = "$PackageDir\reports_here\$reportName"; ProfileSha256 = $profileHash
      StopRule = "Diagnostic only; never promote strategy performance from this consumed-data run."
   }) | Out-Null
   $queue.Add([pscustomobject]@{
      QueueRank = $rank; Candidate = $candidate; CandidateRank = $rank
      SourceType = "capital_feasibility_probe"; SourceRank = 1; Phase = "capital_feasibility_diagnostic"
      Set = $profileName; Window = "continuous_2015_2026"; From = "2015.01.01"; To = "2026.07.12"
      Model = 1; Deposit = 10000; Config = "configs\$configName"; ExpectedReportName = $reportName
      ProfileSnapshot = "profiles\$profileName"; ProfileSha256 = $profileHash; SourceSha256 = $sourceHash
      StopRule = "Diagnostic only; no profit promotion and no risk overflow."
   }) | Out-Null
}
$manifest | Export-Csv -LiteralPath (Resolve-RepoPath $ManifestPath) -NoTypeInformation -Encoding ASCII
$queue | Export-Csv -LiteralPath (Resolve-RepoPath $QueuePath) -NoTypeInformation -Encoding ASCII
@(
   "# XAUUSD H4 Channel Capital-Feasibility Package",
   "",
   "No-trading diagnostic that reproduces H4 channel signals and uses broker-native ``OrderCalcProfit`` to measure the minimum-lot loss and required equity at ``0.10%`` risk.",
   "",
   "- Source SHA-256: ``$sourceHash``",
   "- Lookbacks: ``40, 55, 80``",
   "- Window: ``2015-01-01`` through ``2026-07-12``",
   "- Configurations: ``$rank``",
   "- Diagnostic only: this run cannot promote a strategy or repair the consumed holdout."
) | Set-Content -LiteralPath (Join-Path $packageFull "README.md") -Encoding ASCII
[pscustomobject]@{ Status = "READY"; SourceSha256 = $sourceHash; Configurations = $rank; PackageDir = $PackageDir }

