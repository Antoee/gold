param(
   [string]$SourcePath = "work\Independent_XAUUSD_M15_Dual_Regime_Portfolio.mq5",
   [string]$DiscoverySummaryPath = "outputs\INDEPENDENT_M15_DUAL_REGIME_PORTFOLIO_DISCOVERY_MODEL1_SUMMARY.csv",
   [string]$DiscoveryQueuePath = "outputs\INDEPENDENT_M15_DUAL_REGIME_PORTFOLIO_DISCOVERY_MODEL1_QUEUE.csv",
   [string]$DiscoveryPackageDir = "outputs\independent_m15_dual_regime_portfolio_discovery_model1_package",
   [string]$PackageDir = "outputs\independent_m15_dual_regime_portfolio_holdout_model1_package",
   [string]$QueueManifestPath = "outputs\INDEPENDENT_M15_DUAL_REGIME_PORTFOLIO_HOLDOUT_MODEL1_QUEUE.csv",
   [string]$PackageManifestPath = "outputs\INDEPENDENT_M15_DUAL_REGIME_PORTFOLIO_HOLDOUT_MODEL1_PACKAGE_MANIFEST.csv",
   [string]$MarkdownPath = "outputs\INDEPENDENT_M15_DUAL_REGIME_PORTFOLIO_HOLDOUT_MODEL1_PACKAGE.md"
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

& (Join-Path $PSScriptRoot "test_independent_m15_dual_regime_portfolio_discovery_decision.ps1") | Out-Null
& (Join-Path $PSScriptRoot "test_independent_m15_dual_regime_portfolio_source.ps1") | Out-Null
$sourceFull = (Resolve-Path -LiteralPath (Resolve-RepoPath $SourcePath)).Path
$sourceHash = (Get-FileHash -LiteralPath $sourceFull -Algorithm SHA256).Hash
$summary = @(Import-Csv -LiteralPath (Resolve-RepoPath $DiscoverySummaryPath))
$discoveryQueue = @(Import-Csv -LiteralPath (Resolve-RepoPath $DiscoveryQueuePath))
$eligible = @($summary | Where-Object Decision -eq "DISCOVERY_ELIGIBLE" | Sort-Object Candidate)
if($eligible.Count -lt 1) { throw "Discovery produced no eligible dual-engine profile." }
$windows = @(
   [pscustomobject]@{ Name="holdout_2021_2023"; From="2021.01.01"; To="2023.12.31" },
   [pscustomobject]@{ Name="recent_2024_2026ytd"; From="2024.01.01"; To="2026.07.17" },
   [pscustomobject]@{ Name="continuous_2021_2026ytd"; From="2021.01.01"; To="2026.07.17" }
)

$packageFull = Resolve-RepoPath $PackageDir
Clear-OutputDirSafe $packageFull
$configDir = Join-Path $packageFull "configs"; $profileDir = Join-Path $packageFull "profiles"
$reportDir = Join-Path $packageFull "reports_here"; $sourceDir = Join-Path $packageFull "source"
New-Item -ItemType Directory -Path $configDir, $profileDir, $reportDir, $sourceDir -Force | Out-Null
Copy-Item -LiteralPath $sourceFull -Destination (Join-Path $sourceDir "Professional_XAUUSD_EA.mq5") -Force

$queueRows = [System.Collections.Generic.List[object]]::new(); $runRows = [System.Collections.Generic.List[object]]::new()
$rank = 0; $candidateRank = 0
$stopRule = "Untouched holdout: both disjoint eras positive; continuous PF >= 1.20, trades >= 120, DD <= 5%, and a passing adjacent dual-engine profile. No setting changes are permitted after discovery."
foreach($row in $eligible) {
   $candidateRank++
   $candidate = [string]$row.Candidate
   $discoveryIdentity = $discoveryQueue | Where-Object Candidate -eq $candidate | Select-Object -First 1
   if(!$discoveryIdentity) { throw "Discovery identity missing: $candidate" }
   if($discoveryIdentity.SourceSha256 -ne $sourceHash) { throw "Discovery/source hash mismatch: $candidate" }
   $discoveryProfile = Join-Path (Resolve-RepoPath $DiscoveryPackageDir) ([string]$discoveryIdentity.ProfileSnapshot)
   if(!(Test-Path -LiteralPath $discoveryProfile -PathType Leaf)) { throw "Discovery profile missing: $candidate" }
   $profileHash = (Get-FileHash -LiteralPath $discoveryProfile -Algorithm SHA256).Hash
   if($profileHash -ne $discoveryIdentity.ProfileSha256) { throw "Discovery profile hash mismatch: $candidate" }
   $profileName = "$candidate.set"
   $profilePath = Join-Path $profileDir $profileName
   Copy-Item -LiteralPath $discoveryProfile -Destination $profilePath -Force
   $inputs = Import-SetInputs -Path $profilePath
   foreach($window in $windows) {
      $rank++
      $configName = "{0:000}_{1}_{2}_m1.ini" -f $rank, $candidate, $window.Name
      $reportName = "$candidate`_$($window.Name)_m1"
      Write-SeasonalTesterConfig -Path (Join-Path $configDir $configName) -ReportRoot $reportDir -ReportName $reportName `
         -From $window.From -To $window.To -Inputs $inputs -Model 1 -Deposit 10000 -Period 15
      $queueRows.Add([pscustomobject]@{
         QueueRank=$rank; Candidate=$candidate; CandidateRank=$candidateRank; SourceType="independent_m15_dual_regime_portfolio"
         SourceRank=1; Phase="holdout_model1"; Set=$profileName; Window=$window.Name; From=$window.From; To=$window.To
         Model=1; Deposit=10000; Config="configs\$configName"; ExpectedReportName=$reportName; ProfileSnapshot="profiles\$profileName"
         ProfileSha256=$profileHash; DiscoveryProfileSha256=$discoveryIdentity.ProfileSha256; SourceSha256=$sourceHash
         SignalTimeframe="15"; StopRule=$stopRule
      }) | Out-Null
      $runRows.Add([pscustomobject]@{
         QueueRank=$rank; Candidate=$candidate; Phase="holdout_model1"
         PhaseLabel="Independent M15 dual-regime portfolio untouched holdout Model1"; Window=$window.Name; Model=1; Deposit=10000
         PackageConfig="$PackageDir\configs\$configName"; SourceConfig="$PackageDir\configs\$configName"
         ExpectedReportName=$reportName; ReportDestination="$PackageDir\reports_here\$reportName"
         ProfileSha256=$profileHash; StopRule=$stopRule
      }) | Out-Null
   }
}
$queueRows | Export-Csv -LiteralPath (Resolve-RepoPath $QueueManifestPath) -NoTypeInformation -Encoding ASCII
$runRows | Export-Csv -LiteralPath (Resolve-RepoPath $PackageManifestPath) -NoTypeInformation -Encoding ASCII
@(
   "# Independent M15 Dual-Regime Portfolio Untouched Holdout Package", "",
   "Only exact discovery-eligible source/profile identities are included. No profile input was changed.", "",
   "- Source SHA-256: ``$sourceHash``", "- Frozen profiles: ``$($eligible.Count)``",
   "- Holdout windows: ``$($windows.Name -join ', ')``", "- Configurations: ``$rank``", "",
   "Frozen gate: $stopRule"
) | Set-Content -LiteralPath (Resolve-RepoPath $MarkdownPath) -Encoding ASCII
[pscustomobject]@{ Status="READY"; SourceHash=$sourceHash; Profiles=$eligible.Count; Windows=$windows.Count; Configurations=$rank; PackageDir=$PackageDir }
