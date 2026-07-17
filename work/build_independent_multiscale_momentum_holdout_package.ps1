param(
   [string]$SourcePath = "work\Independent_XAUUSD_Multiscale_Momentum.mq5",
   [string]$DiscoveryResultsPath = "outputs\INDEPENDENT_MULTISCALE_MOMENTUM_DISCOVERY_MODEL1_RESULTS.csv",
   [string]$FrozenProfileDir = "outputs\INDEPENDENT_MULTISCALE_MOMENTUM_FROZEN_PROFILES",
   [string]$PackageDir = "outputs\independent_multiscale_momentum_holdout_model1_package",
   [string]$QueueManifestPath = "outputs\INDEPENDENT_MULTISCALE_MOMENTUM_HOLDOUT_MODEL1_QUEUE.csv",
   [string]$PackageManifestPath = "outputs\INDEPENDENT_MULTISCALE_MOMENTUM_HOLDOUT_MODEL1_PACKAGE_MANIFEST.csv",
   [string]$MarkdownPath = "outputs\INDEPENDENT_MULTISCALE_MOMENTUM_HOLDOUT_MODEL1_PACKAGE.md"
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

& (Join-Path $PSScriptRoot "test_independent_multiscale_momentum_source.ps1") | Out-Null
$sourceFull = (Resolve-Path -LiteralPath (Resolve-RepoPath $SourcePath)).Path
$sourceHash = (Get-FileHash -LiteralPath $sourceFull -Algorithm SHA256).Hash
$discoveryResults = @(Import-Csv -LiteralPath (Resolve-RepoPath $DiscoveryResultsPath))
if($discoveryResults.Count -ne 21) { throw "Expected 21 parsed discovery rows before holdout registration." }

$passing = @($discoveryResults | Group-Object Candidate | ForEach-Object {
   $older = $_.Group | Where-Object Window -eq "older_2015_2018"
   $recent = $_.Group | Where-Object Window -eq "discovery_2019_2020"
   $continuous = $_.Group | Where-Object Window -eq "continuous_2015_2020"
   if(@($older).Count -ne 1 -or @($recent).Count -ne 1 -or @($continuous).Count -ne 1) {
      throw "Incomplete discovery evidence for $($_.Name)."
   }
   if([double]$older.NetProfit -gt 0 -and [double]$recent.NetProfit -gt 0 -and
      [double]$continuous.ProfitFactor -ge 1.20 -and [int]$continuous.TotalTrades -ge 100 -and
      [double]$continuous.MaxDrawdownPercent -le 5.00) {
      $_.Name
   }
})

$expectedPassing = @(
   "mtsm_m126_e10_r200",
   "mtsm_m126_e20_r200",
   "mtsm_m126_e10_r150",
   "mtsm_m126_e10_r250"
)
$passingIdentity = (($passing | Sort-Object) -join "|")
$expectedIdentity = (($expectedPassing | Sort-Object) -join "|")
if($passingIdentity -ne $expectedIdentity) {
   throw "Discovery survivor set changed; holdout registration is frozen to the original four-profile plateau."
}

$windows = @(
   [pscustomobject]@{ Name="holdout_2021_2023"; From="2021.01.01"; To="2023.12.31" },
   [pscustomobject]@{ Name="holdout_2024_present"; From="2024.01.01"; To="2026.07.16" },
   [pscustomobject]@{ Name="holdout_2021_present"; From="2021.01.01"; To="2026.07.16" },
   [pscustomobject]@{ Name="continuous_2015_present"; From="2015.01.01"; To="2026.07.16" }
)
$stopRule = "Frozen holdout: require both disjoint holdout windows profitable, 2021-present PF >= 1.20, >= 100 trades, DD <= 5%, full 2015-present PF >= 1.20, and at least two adjacent profiles passing before Model4."

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
foreach($candidate in $expectedPassing) {
   $candidateRank++
   $frozenProfile = Resolve-RepoPath (Join-Path $FrozenProfileDir "$candidate.set")
   if(!(Test-Path -LiteralPath $frozenProfile)) { throw "Frozen discovery profile missing: $frozenProfile" }
   $inputs = Import-SetInputs -Path $frozenProfile
   $profileName = "$candidate.set"
   $profilePath = Join-Path $profileDir $profileName
   Copy-Item -LiteralPath $frozenProfile -Destination $profilePath -Force
   $profileHash = (Get-FileHash -LiteralPath $profilePath -Algorithm SHA256).Hash
   $discoveryHash = @($discoveryResults | Where-Object Candidate -eq $candidate | Select-Object -ExpandProperty ProfileSha256 -Unique)
   if($discoveryHash.Count -ne 1 -or $profileHash -ne $discoveryHash[0]) {
      throw "Frozen profile hash mismatch for $candidate."
   }

   foreach($window in $windows) {
      $rank++
      $configName = "{0:000}_{1}_{2}_m1.ini" -f $rank,$candidate,$window.Name
      $reportName = "${candidate}_$($window.Name)_m1"
      Write-SeasonalTesterConfig -Path (Join-Path $configDir $configName) -ReportRoot $reportDir `
         -ReportName $reportName -From $window.From -To $window.To -Inputs $inputs -Model 1 -Deposit 10000
      $queueRows.Add([pscustomobject]@{
         QueueRank=$rank; Candidate=$candidate; CandidateRank=$candidateRank
         SourceType="independent_multiscale_momentum"; SourceRank=1; Phase="frozen_holdout_model1"
         Set=$profileName; Window=$window.Name; From=$window.From; To=$window.To; Model=1; Deposit=10000
         Config="configs\$configName"; ExpectedReportName=$reportName; ProfileSnapshot="profiles\$profileName"
         ProfileSha256=$profileHash; SourceSha256=$sourceHash; StopRule=$stopRule
      }) | Out-Null
      $runRows.Add([pscustomobject]@{
         QueueRank=$rank; Candidate=$candidate; Phase="frozen_holdout_model1"
         PhaseLabel="Independent multiscale momentum frozen holdout Model1"; Window=$window.Name; Model=1; Deposit=10000
         PackageConfig="$PackageDir\configs\$configName"; SourceConfig="$PackageDir\configs\$configName"
         ExpectedReportName=$reportName; ReportDestination="$PackageDir\reports_here\$reportName"
         ProfileSha256=$profileHash; StopRule=$stopRule
      }) | Out-Null
   }
}

$queueRows | Export-Csv -LiteralPath (Resolve-RepoPath $QueueManifestPath) -NoTypeInformation -Encoding ASCII
$runRows | Export-Csv -LiteralPath (Resolve-RepoPath $PackageManifestPath) -NoTypeInformation -Encoding ASCII

$lines = @(
   "# Independent Multiscale Momentum Frozen Holdout Package",
   "",
   "Registered before opening any post-2020 result for this strategy family.",
   "",
   "- Source SHA-256: ``$sourceHash``",
   "- Frozen survivors: ``$($expectedPassing -join ', ')``",
   "- Windows: ``$($windows.Name -join ', ')``",
   "- Holdout end date: ``2026-07-16`` (last completed day at registration)",
   "- Configurations: ``$rank``",
   '- Starting balance: `$10,000`',
   "- Risk per trade: ``0.10%``",
   "",
   $stopRule
)
$lines | Set-Content -LiteralPath (Resolve-RepoPath $MarkdownPath) -Encoding ASCII

[pscustomobject]@{ Status="READY"; SourceHash=$sourceHash; Survivors=$expectedPassing.Count; Windows=$windows.Count; Configurations=$rank; PackageDir=$PackageDir }
