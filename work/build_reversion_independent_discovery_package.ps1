param(
   [string]$SourcePath = "work\Professional_XAUUSD_EA_REVERSION_INDEPENDENT.mq5",
   [string]$BaseProfilePath = "outputs\three_lane_ddb045_model4_validation_package\profiles\three_lane_ddb045.set",
   [string]$PackageDir = "outputs\reversion_independent_discovery_model1_package",
   [string]$QueueManifestPath = "outputs\REVERSION_INDEPENDENT_DISCOVERY_MODEL1_QUEUE.csv",
   [string]$PackageManifestPath = "outputs\REVERSION_INDEPENDENT_DISCOVERY_MODEL1_PACKAGE_MANIFEST.csv",
   [string]$MarkdownPath = "outputs\REVERSION_INDEPENDENT_DISCOVERY_MODEL1_PACKAGE.md"
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

& (Join-Path $PSScriptRoot "test_reversion_independent_source.ps1") -SourcePath $SourcePath | Out-Null
$sourceFull = (Resolve-Path -LiteralPath (Resolve-RepoPath $SourcePath)).Path
$profileFull = (Resolve-Path -LiteralPath (Resolve-RepoPath $BaseProfilePath)).Path
$sourceHash = (Get-FileHash -LiteralPath $sourceFull -Algorithm SHA256).Hash
$baseProfileHash = (Get-FileHash -LiteralPath $profileFull -Algorithm SHA256).Hash
if($sourceHash -ne "2108099D19EBF2E8D86709FFAA37331559EDA745794E1B01A1A4DA0C6C38CEEB") { throw "Unexpected experimental source hash: $sourceHash" }
if($baseProfileHash -ne "2E02246D24250D71DEC59A42AD1D7DE793614EBECEB309A879FE873D8F886312") { throw "Frozen three-lane profile changed: $baseProfileHash" }

$variants = @(
   [pscustomobject]@{ Name="ri_control"; Independent="false"; DIEdge="-12"; BandRisk="0.10"; MaxPositions="1" },
   [pscustomobject]@{ Name="ri_m12_r30"; Independent="true"; DIEdge="-12"; BandRisk="0.30"; MaxPositions="2" },
   [pscustomobject]@{ Name="ri_m12_r40"; Independent="true"; DIEdge="-12"; BandRisk="0.40"; MaxPositions="2" },
   [pscustomobject]@{ Name="ri_m10_r30"; Independent="true"; DIEdge="-10"; BandRisk="0.30"; MaxPositions="2" },
   [pscustomobject]@{ Name="ri_m10_r40"; Independent="true"; DIEdge="-10"; BandRisk="0.40"; MaxPositions="2" }
)
$windows = @(
   [pscustomobject]@{ Name="older_2015_2018"; From="2015.01.01"; To="2018.12.31" },
   [pscustomobject]@{ Name="discovery_2019_2020"; From="2019.01.01"; To="2020.12.31" },
   [pscustomobject]@{ Name="continuous_2015_2020"; From="2015.01.01"; To="2020.12.31" },
   [pscustomobject]@{ Name="year_2015"; From="2015.01.01"; To="2015.12.31" },
   [pscustomobject]@{ Name="year_2016"; From="2016.01.01"; To="2016.12.31" },
   [pscustomobject]@{ Name="year_2017"; From="2017.01.01"; To="2017.12.31" },
   [pscustomobject]@{ Name="year_2018"; From="2018.01.01"; To="2018.12.31" },
   [pscustomobject]@{ Name="year_2019"; From="2019.01.01"; To="2019.12.31" },
   [pscustomobject]@{ Name="year_2020"; From="2020.01.01"; To="2020.12.31" }
)

$packageFull = Resolve-RepoPath $PackageDir
Clear-OutputDirSafe $packageFull
$configDir = Join-Path $packageFull "configs"
$profileDir = Join-Path $packageFull "profiles"
$reportDir = Join-Path $packageFull "reports_here"
$sourceDir = Join-Path $packageFull "source"
New-Item -ItemType Directory -Path $configDir,$profileDir,$reportDir,$sourceDir -Force | Out-Null
Copy-Item -LiteralPath $sourceFull -Destination (Join-Path $sourceDir "Professional_XAUUSD_EA.mq5") -Force

$queueRows = [System.Collections.Generic.List[object]]::new()
$runRows = [System.Collections.Generic.List[object]]::new()
$rank = 0
$candidateRank = 0
$stopRule = "Discovery only through 2020: require exact control compatibility, both broad eras positive, no red active discovery year, continuous PF at least 1.50, continuous DD at or below 3%, and neighboring DI/risk support before any retrospective 2021-2026 implementation check."
foreach($variant in $variants) {
   $candidateRank++
   $inputs = Import-SetInputs $profileFull
   Set-InputLine -Inputs $inputs -Name "InpBandVWAPReversionIndependentAttempt" -Value $variant.Independent
   Set-InputLine -Inputs $inputs -Name "InpBandVWAPReversionMinDIEdge" -Value $variant.DIEdge
   Set-InputLine -Inputs $inputs -Name "InpBandVWAPReversionRiskMultiplier" -Value $variant.BandRisk
   Set-InputLine -Inputs $inputs -Name "InpMaxSimultaneousPositions" -Value $variant.MaxPositions
   Set-InputLine -Inputs $inputs -Name "InpTradeReadyMaxSimultaneousPositions" -Value $variant.MaxPositions
   Set-InputLine -Inputs $inputs -Name "InpMaxOpenRiskPercent" -Value "0.75"
   Set-InputLine -Inputs $inputs -Name "InpAccountWideMaxOpenRiskPercent" -Value "0.75"
   Set-InputLine -Inputs $inputs -Name "InpAccountWideMaxPositions" -Value "3"
   Set-InputLine -Inputs $inputs -Name "InpUseRealAccountSafetyLock" -Value "true"
   Set-InputLine -Inputs $inputs -Name "InpAllowRealAccountTrading" -Value "false"
   Set-InputLine -Inputs $inputs -Name "InpRealAccountApprovalCode" -Value "DISABLED"
   Set-InputLine -Inputs $inputs -Name "InpRealAccountApprovalProfileId" -Value "DISABLED"
   Set-InputLine -Inputs $inputs -Name "InpRealAccountApprovalSourceHash" -Value "DISABLED"
   Set-InputLine -Inputs $inputs -Name "InpEvidenceProfileId" -Value $variant.Name
   Set-InputLine -Inputs $inputs -Name "InpEvidenceSourceHash" -Value $sourceHash
   Set-InputLine -Inputs $inputs -Name "InpEvidenceRunLabel" -Value "reversion_independent_discovery_model1"
   Set-InputLine -Inputs $inputs -Name "InpLogLevel" -Value "0"
   Set-InputLine -Inputs $inputs -Name "InpUseBlockReasonDiagnostics" -Value "false"
   Set-InputLine -Inputs $inputs -Name "InpShowDashboard" -Value "false"
   Set-InputLine -Inputs $inputs -Name "InpDashboardInTester" -Value "false"

   $profileName = "$($variant.Name).set"
   $profilePath = Join-Path $profileDir $profileName
   @($inputs.Keys | Sort-Object | ForEach-Object { $inputs[$_] }) | Set-Content -LiteralPath $profilePath -Encoding ASCII
   $profileHash = (Get-FileHash -LiteralPath $profilePath -Algorithm SHA256).Hash

   foreach($window in $windows) {
      $rank++
      $configName = "{0:000}_{1}_{2}_m1.ini" -f $rank,$variant.Name,$window.Name
      $reportName = "$($variant.Name)_$($window.Name)_m1"
      Write-SeasonalTesterConfig -Path (Join-Path $configDir $configName) -ReportRoot $reportDir `
         -ReportName $reportName -From $window.From -To $window.To -Inputs $inputs -Model 1 -Deposit 10000
      $queueRows.Add([pscustomobject]@{
         QueueRank=$rank; Candidate=$variant.Name; CandidateRank=$candidateRank
         SourceType="reversion_independent"; SourceRank=1; Phase="discovery_model1"
         Set=$profileName; Window=$window.Name; From=$window.From; To=$window.To; Model=1; Deposit=10000
         Config="configs\$configName"; ExpectedReportName=$reportName; ProfileSnapshot="profiles\$profileName"
         ProfileSha256=$profileHash; BaseProfileSha256=$baseProfileHash; SourceSha256=$sourceHash
         IndependentAttempt=$variant.Independent; DIEdge=$variant.DIEdge; BandRiskMultiplier=$variant.BandRisk
         MaxPositions=$variant.MaxPositions; StopRule=$stopRule
      }) | Out-Null
      $runRows.Add([pscustomobject]@{
         QueueRank=$rank; Candidate=$variant.Name; Phase="discovery_model1"
         PhaseLabel="Reversion independent scheduling discovery Model1"; Window=$window.Name; Model=1; Deposit=10000
         PackageConfig="$PackageDir\configs\$configName"; SourceConfig="$PackageDir\configs\$configName"
         ExpectedReportName=$reportName; ReportDestination="$PackageDir\reports_here\$reportName"
         ProfileSha256=$profileHash; StopRule=$stopRule
      }) | Out-Null
   }
}

$queueRows | Export-Csv -LiteralPath (Resolve-RepoPath $QueueManifestPath) -NoTypeInformation -Encoding ASCII
$runRows | Export-Csv -LiteralPath (Resolve-RepoPath $PackageManifestPath) -NoTypeInformation -Encoding ASCII
$md = [System.Collections.Generic.List[string]]::new()
$md.Add("# Reversion Independent Scheduling Discovery Package")
$md.Add("")
$md.Add("Tests whether the already-validated H1 reversion lane should receive an independent entry attempt instead of being considered only when the primary lane is idle. No configuration includes data after 2020.")
$md.Add("")
$md.Add("- Source SHA-256: ``$sourceHash``")
$md.Add("- Frozen base profile SHA-256: ``$baseProfileHash``")
$md.Add("- Variants: ``$($variants.Count)``")
$md.Add("- Windows: ``$($windows.Count)``")
$md.Add("- Configurations: ``$rank``")
$md.Add("")
$md.Add('Candidate profiles retain the `$0.75%` open-risk cap, permit at most two EA positions, size through broker-native risk calculation, keep the new scheduling switch default off in source, and keep real-account trading disabled.')
$md | Set-Content -LiteralPath (Resolve-RepoPath $MarkdownPath) -Encoding ASCII

[pscustomobject]@{ Status="READY"; SourceHash=$sourceHash; Variants=$variants.Count; Windows=$windows.Count; Configurations=$rank; PackageDir=$PackageDir }
