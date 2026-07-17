param(
   [string]$SourcePath = "work\Professional_XAUUSD_Early_Failure_Portfolio.mq5",
   [string]$BaseProfilePath = "outputs\TRANSFERABLE_PORTFOLIO_BASE_PROFILE.set",
   [string]$PackageDir = "outputs\early_failure_portfolio_discovery_model1_package",
   [string]$QueueManifestPath = "outputs\EARLY_FAILURE_PORTFOLIO_DISCOVERY_MODEL1_QUEUE.csv",
   [string]$PackageManifestPath = "outputs\EARLY_FAILURE_PORTFOLIO_DISCOVERY_MODEL1_PACKAGE_MANIFEST.csv",
   [string]$MarkdownPath = "outputs\EARLY_FAILURE_PORTFOLIO_DISCOVERY_MODEL1_PACKAGE.md"
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

& (Join-Path $PSScriptRoot "test_early_failure_portfolio_source.ps1") | Out-Null
$sourceFull = (Resolve-Path -LiteralPath (Resolve-RepoPath $SourcePath)).Path
$sourceHash = (Get-FileHash -LiteralPath $sourceFull -Algorithm SHA256).Hash
$baseProfileFull = (Resolve-Path -LiteralPath (Resolve-RepoPath $BaseProfilePath)).Path
$baseProfileHash = (Get-FileHash -LiteralPath $baseProfileFull -Algorithm SHA256).Hash
$variants = @(
   [pscustomobject]@{ Name="efp_fixed_control"; RVEnabled="false"; RVBars="3"; RVR="0.00"; MOEnabled="false"; MOBars="4"; MOR="0.00" },
   [pscustomobject]@{ Name="efp_center"; RVEnabled="true"; RVBars="3"; RVR="0.00"; MOEnabled="true"; MOBars="4"; MOR="0.00" },
   [pscustomobject]@{ Name="efp_rv_only"; RVEnabled="true"; RVBars="3"; RVR="0.00"; MOEnabled="false"; MOBars="4"; MOR="0.00" },
   [pscustomobject]@{ Name="efp_mo_only"; RVEnabled="false"; RVBars="3"; RVR="0.00"; MOEnabled="true"; MOBars="4"; MOR="0.00" },
   [pscustomobject]@{ Name="efp_fast"; RVEnabled="true"; RVBars="2"; RVR="0.00"; MOEnabled="true"; MOBars="3"; MOR="0.00" },
   [pscustomobject]@{ Name="efp_slow"; RVEnabled="true"; RVBars="4"; RVR="0.00"; MOEnabled="true"; MOBars="6"; MOR="0.00" },
   [pscustomobject]@{ Name="efp_relaxed"; RVEnabled="true"; RVBars="3"; RVR="-0.25"; MOEnabled="true"; MOBars="4"; MOR="-0.25" },
   [pscustomobject]@{ Name="efp_strict"; RVEnabled="true"; RVBars="3"; RVR="0.25"; MOEnabled="true"; MOBars="4"; MOR="0.25" }
)
$windows = @(
   [pscustomobject]@{ Name="older_2015_2018"; From="2015.01.01"; To="2018.12.31" },
   [pscustomobject]@{ Name="discovery_2019_2020"; From="2019.01.01"; To="2020.12.31" },
   [pscustomobject]@{ Name="continuous_2015_2020"; From="2015.01.01"; To="2020.12.31" }
)

$packageFull = Resolve-RepoPath $PackageDir
Clear-OutputDirSafe $packageFull
$configDir = Join-Path $packageFull "configs"; $profileDir = Join-Path $packageFull "profiles"
$reportDir = Join-Path $packageFull "reports_here"; $sourceDir = Join-Path $packageFull "source"
New-Item -ItemType Directory -Path $configDir, $profileDir, $reportDir, $sourceDir -Force | Out-Null
Copy-Item -LiteralPath $sourceFull -Destination (Join-Path $sourceDir "Professional_XAUUSD_EA.mq5") -Force

$queueRows = [System.Collections.Generic.List[object]]::new(); $runRows = [System.Collections.Generic.List[object]]::new()
$rank = 0; $candidateRank = 0
$stopRule = "Discovery only: both eras positive; continuous PF >= 1.45, trades >= 180, DD <= 2.80%; at least 5% control-relative net or return/DD improvement under frozen quality tolerances; one adjacent exit profile must pass."
foreach($variant in $variants) {
   $candidateRank++
   $inputs = Import-SetInputs -Path $baseProfileFull
   foreach($pair in @(
      @("InpPortfolioMagic","26071783"), @("InpRVMagicNumber","26071724"), @("InpMOMagicNumber","26071764"),
      @("InpRVUseNoFollowThroughExit",$variant.RVEnabled), @("InpRVNoFollowThroughBars",$variant.RVBars),
      @("InpRVNoFollowThroughMaximumR",$variant.RVR), @("InpMOUseNoFollowThroughExit",$variant.MOEnabled),
      @("InpMONoFollowThroughBars",$variant.MOBars), @("InpMONoFollowThroughMaximumR",$variant.MOR),
      @("InpEvidenceSourceHash",$sourceHash), @("InpEvidenceRunLabel","early_failure_portfolio_discovery_model1"),
      @("InpShowDashboard","false")
   )) { Set-InputLine -Inputs $inputs -Name $pair[0] -Value $pair[1] }
   $inputs["InpRVLogFileName"] = "InpRVLogFileName=$($variant.Name)_rv_events.csv"
   $inputs["InpMOLogFileName"] = "InpMOLogFileName=$($variant.Name)_mo_events.csv"
   $profileName = "$($variant.Name).set"
   $profilePath = Join-Path $profileDir $profileName
   @($inputs.Keys | Sort-Object | ForEach-Object { $inputs[$_] }) | Set-Content -LiteralPath $profilePath -Encoding ASCII
   $profileHash = (Get-FileHash -LiteralPath $profilePath -Algorithm SHA256).Hash
   foreach($window in $windows) {
      $rank++
      $configName = "{0:000}_{1}_{2}_m1.ini" -f $rank, $variant.Name, $window.Name
      $reportName = "$($variant.Name)_$($window.Name)_m1"
      Write-SeasonalTesterConfig -Path (Join-Path $configDir $configName) -ReportRoot $reportDir -ReportName $reportName `
         -From $window.From -To $window.To -Inputs $inputs -Model 1 -Deposit 10000 -Period 60
      $queueRows.Add([pscustomobject]@{
         QueueRank=$rank; Candidate=$variant.Name; CandidateRank=$candidateRank; SourceType="early_failure_portfolio"
         SourceRank=1; Phase="discovery_model1"; Set=$profileName; Window=$window.Name; From=$window.From; To=$window.To
         Model=1; Deposit=10000; Config="configs\$configName"; ExpectedReportName=$reportName; ProfileSnapshot="profiles\$profileName"
         ProfileSha256=$profileHash; SourceSha256=$sourceHash; BaseProfileSha256=$baseProfileHash; SignalTimeframe="60"
         RVFailureExitEnabled=$variant.RVEnabled; RVFailureBars=$variant.RVBars; RVFailureMaximumR=$variant.RVR
         MOFailureExitEnabled=$variant.MOEnabled; MOFailureBars=$variant.MOBars; MOFailureMaximumR=$variant.MOR; StopRule=$stopRule
      }) | Out-Null
      $runRows.Add([pscustomobject]@{
         QueueRank=$rank; Candidate=$variant.Name; Phase="discovery_model1"
         PhaseLabel="Early failure portfolio discovery Model1"; Window=$window.Name; Model=1; Deposit=10000
         PackageConfig="$PackageDir\configs\$configName"; SourceConfig="$PackageDir\configs\$configName"
         ExpectedReportName=$reportName; ReportDestination="$PackageDir\reports_here\$reportName"
         ProfileSha256=$profileHash; StopRule=$stopRule
      }) | Out-Null
   }
}
$queueRows | Export-Csv -LiteralPath (Resolve-RepoPath $QueueManifestPath) -NoTypeInformation -Encoding ASCII
$runRows | Export-Csv -LiteralPath (Resolve-RepoPath $PackageManifestPath) -NoTypeInformation -Encoding ASCII
@(
   "# Early Failure Portfolio Discovery Package", "",
   "Exact released entries, stops, targets, and risk with separately testable closed-bar no-follow-through exits. No configuration includes data after 2020.", "",
   "- Source SHA-256: ``$sourceHash``", "- Released base-profile SHA-256: ``$baseProfileHash``",
   "- Variants: ``$($variants.Count)``", "- Configurations: ``$rank``", "",
   "Frozen gate: $stopRule"
) | Set-Content -LiteralPath (Resolve-RepoPath $MarkdownPath) -Encoding ASCII
[pscustomobject]@{ Status="READY"; SourceHash=$sourceHash; BaseProfileHash=$baseProfileHash; Variants=$variants.Count; Windows=$windows.Count; Configurations=$rank; PackageDir=$PackageDir }
