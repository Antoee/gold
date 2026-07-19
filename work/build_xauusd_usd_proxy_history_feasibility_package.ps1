param(
   [string]$SourcePath = "work\XAUUSD_USD_Proxy_History_Feasibility_Probe.mq5",
   [string]$PackageDir = "outputs\xauusd_usd_proxy_history_feasibility_package",
   [string]$ManifestPath = "outputs\XAUUSD_USD_PROXY_HISTORY_FEASIBILITY_MANIFEST.csv",
   [string]$QueuePath = "outputs\XAUUSD_USD_PROXY_HISTORY_FEASIBILITY_QUEUE.csv"
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

& (Join-Path $PSScriptRoot "test_xauusd_usd_proxy_history_feasibility_source.ps1") -SourcePath $SourcePath | Out-Null
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

$references = @('EURUSD','USDJPY')
$windows = @(
   [pscustomobject]@{ Name="older_2015_2018"; From="2015.01.01"; To="2018.12.31" },
   [pscustomobject]@{ Name="discovery_2019_2020"; From="2019.01.01"; To="2020.12.31" }
)
$manifest = [Collections.Generic.List[object]]::new()
$queue = [Collections.Generic.List[object]]::new()
$ordinal = 0
foreach($reference in $references) {
   foreach($window in $windows) {
      $ordinal++
      $pairIndex = [int][math]::Floor(($ordinal - 1) / 2)
      $queueRank = 3 * $pairIndex + $(if(($ordinal % 2) -eq 1) { 1 } else { 3 })
      $symbolKey = $reference.ToLowerInvariant()
      $candidate = "xau_${symbolKey}_history_$($window.Name)"
      $configName = "{0:000}_{1}_m1.ini" -f $ordinal, $candidate
      $reportName = "${candidate}_m1"
      $profileName = "${candidate}.set"
      $evidenceFile = "XAUUSD_${reference}_History_Feasibility.csv"
      $profileLines = @(
         "InpAllowedSymbol=XAUUSD",
         "InpUseSymbolSafetyLock=true||true||0||0||N",
         "InpUseRealAccountSafetyLock=true||true||0||0||N",
         "InpReferenceSymbol=$reference",
         "InpSignalTimeframe=15||15||0||0||N",
         "InpMaximumAlignmentSeconds=900||900||0||0||N",
         "InpRequiredLookbackBars=32||32||0||0||N",
         "InpProbeId=$candidate",
         "InpSourceSha256=$sourceHash",
         "InpOutputFileName=$evidenceFile"
      )
      $profilePath = Join-Path $profileDir $profileName
      $profileLines | Set-Content -LiteralPath $profilePath -Encoding ASCII
      $profileHash = (Get-FileHash -LiteralPath $profilePath -Algorithm SHA256).Hash
      $configLines = @(
         "[Tester]",
         "Expert=Professional_XAUUSD_EA.ex5",
         "Symbol=XAUUSD",
         "Period=15",
         "Optimization=0",
         "Model=1",
         "FromDate=$($window.From)",
         "ToDate=$($window.To)",
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
         QueueRank=$queueRank; Candidate=$candidate; Phase="history_feasibility_diagnostic"
         PhaseLabel="Pre-2021 XAUUSD/USD-proxy M15 history alignment"; Window=$window.Name
         Model=1; Deposit=10000; PackageConfig="$PackageDir\configs\$configName"
         SourceConfig="$PackageDir\configs\$configName"; ExpectedReportName=$reportName
         ReportDestination="$PackageDir\reports_here\$reportName"; ProfileSha256=$profileHash
         StopRule="No-trading data diagnostic only; do not infer or promote strategy performance."
      }) | Out-Null
      $queue.Add([pscustomobject]@{
         QueueRank=$queueRank; Candidate=$candidate; CandidateRank=$ordinal; SourceType="xau_usd_proxy_history_feasibility"
         SourceRank=1; Phase="history_feasibility_diagnostic"; Set=$profileName; Window=$window.Name
         From=$window.From; To=$window.To; Model=1; Deposit=10000; Config="configs\$configName"
         ExpectedReportName=$reportName; ProfileSnapshot="profiles\$profileName"; ProfileSha256=$profileHash
         SourceSha256=$sourceHash; ReferenceSymbol=$reference; EvidenceFile=$evidenceFile
         StopRule="No orders; pre-2021 history feasibility only."
      }) | Out-Null
   }
}
$manifest | Export-Csv -LiteralPath (Resolve-RepoPath $ManifestPath) -NoTypeInformation -Encoding ASCII
$queue | Export-Csv -LiteralPath (Resolve-RepoPath $QueuePath) -NoTypeInformation -Encoding ASCII
@(
   "# XAUUSD/USD-Proxy History-Feasibility Package",
   "",
   "Strictly no-trading diagnostic for synchronized M15 XAUUSD, EURUSD, and USDJPY broker history. It uses only 2015-2020 and records year-level bar coverage and alignment.",
   "",
   "- Source SHA-256: ``$sourceHash``",
   "- Reference symbols: ``$($references -join ', ')``",
   "- Windows: ``$($windows.Name -join ', ')``",
   "- Configurations: ``$ordinal``",
   "- Maximum alignment gap: ``900 seconds``",
   "- Required feature lookback: ``32 M15 bars``",
   "- Real accounts are rejected and the source contains no order API."
) | Set-Content -LiteralPath (Join-Path $packageFull "README.md") -Encoding ASCII
[pscustomobject]@{ Status="READY"; SourceSha256=$sourceHash; References=$references.Count; Configurations=$ordinal; PackageDir=$PackageDir }
