param(
   [string]$SourcePath = "work\Independent_XAUUSD_H4_Channel_Trend.mq5",
   [string]$DiscoveryPackageDir = "outputs\independent_h4_channel_trend_trail_discovery_model1_package",
   [string]$PackageDir = "outputs\independent_h4_channel_trend_holdout_model1_package",
   [string]$QueueManifestPath = "outputs\INDEPENDENT_H4_CHANNEL_TREND_HOLDOUT_MODEL1_QUEUE.csv",
   [string]$PackageManifestPath = "outputs\INDEPENDENT_H4_CHANNEL_TREND_HOLDOUT_MODEL1_PACKAGE_MANIFEST.csv",
   [string]$RegistrationPath = "outputs\INDEPENDENT_H4_CHANNEL_TREND_HOLDOUT_REGISTRATION.md"
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

& (Join-Path $PSScriptRoot "test_independent_h4_channel_trend_source.ps1") | Out-Null
$sourceFull = (Resolve-Path -LiteralPath (Resolve-RepoPath $SourcePath)).Path
$sourceHash = (Get-FileHash -LiteralPath $sourceFull -Algorithm SHA256).Hash
$expectedSourceHash = "C27025A3605EEBBA54C5B88D564CE641D00634E2C42C8BAC6D127751ABF58F4A"
if($sourceHash -ne $expectedSourceHash) { throw "H4 channel source changed: $sourceHash" }

$candidates = @(
   [pscustomobject]@{ Name = "h4ct_trail_40_20_l20_a25"; Profile = "h4ct_trail_40_20_l20_a25.set"; DiscoveryNet = 268.97; DiscoveryPF = 1.73; DiscoveryTrades = 101; DiscoveryDD = 0.89 },
   [pscustomobject]@{ Name = "h4ct_trail_55_20_l20_a25"; Profile = "h4ct_trail_55_20_l20_a25.set"; DiscoveryNet = 264.96; DiscoveryPF = 1.94; DiscoveryTrades = 81; DiscoveryDD = 0.70 },
   [pscustomobject]@{ Name = "h4ct_trail_55_20_l20_a30"; Profile = "h4ct_trail_55_20_l20_a30.set"; DiscoveryNet = 328.77; DiscoveryPF = 2.12; DiscoveryTrades = 76; DiscoveryDD = 0.76 },
   [pscustomobject]@{ Name = "h4ct_trail_80_40_l20_a30"; Profile = "h4ct_trail_80_40_l20_a30.set"; DiscoveryNet = 314.57; DiscoveryPF = 2.54; DiscoveryTrades = 61; DiscoveryDD = 0.62 }
)
$windows = @(
   [pscustomobject]@{ Name = "holdout_2021_2023"; From = "2021.01.01"; To = "2023.12.31" },
   [pscustomobject]@{ Name = "holdout_2024_2026"; From = "2024.01.01"; To = "2026.07.12" },
   [pscustomobject]@{ Name = "holdout_continuous_2021_2026"; From = "2021.01.01"; To = "2026.07.12" },
   [pscustomobject]@{ Name = "2021"; From = "2021.01.01"; To = "2021.12.31" },
   [pscustomobject]@{ Name = "2022"; From = "2022.01.01"; To = "2022.12.31" },
   [pscustomobject]@{ Name = "2023"; From = "2023.01.01"; To = "2023.12.31" },
   [pscustomobject]@{ Name = "2024"; From = "2024.01.01"; To = "2024.12.31" },
   [pscustomobject]@{ Name = "2025"; From = "2025.01.01"; To = "2025.12.31" },
   [pscustomobject]@{ Name = "2026_ytd"; From = "2026.01.01"; To = "2026.07.12" }
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
$registrationRows = [System.Collections.Generic.List[object]]::new()
$rank = 0
$candidateRank = 0
$stopRule = "Frozen holdout: require both broad holdout eras positive, continuous PF at least 1.20, at least 40 trades, DD at or below 3%, no completed year below -0.50%, and no more than two red completed years before Model4."
foreach($candidate in $candidates) {
   $candidateRank++
   $discoveryProfile = Resolve-RepoPath (Join-Path $DiscoveryPackageDir "profiles\$($candidate.Profile)")
   if(!(Test-Path -LiteralPath $discoveryProfile)) { throw "Frozen discovery profile missing: $discoveryProfile" }
   $inputs = Import-SetInputs $discoveryProfile
   Set-InputLine -Inputs $inputs -Name "InpEvidenceProfileId" -Value $candidate.Name
   Set-InputLine -Inputs $inputs -Name "InpEvidenceSourceHash" -Value $sourceHash
   Set-InputLine -Inputs $inputs -Name "InpEvidenceRunLabel" -Value "independent_h4_channel_trend_holdout_model1"
   Set-InputLine -Inputs $inputs -Name "InpLogFileName" -Value "$($candidate.Name)_holdout_trades.csv"
   $profilePath = Join-Path $profileDir $candidate.Profile
   @($inputs.Keys | Sort-Object | ForEach-Object { $inputs[$_] }) | Set-Content -LiteralPath $profilePath -Encoding ASCII
   $profileHash = (Get-FileHash -LiteralPath $profilePath -Algorithm SHA256).Hash
   $registrationRows.Add([pscustomobject]@{
      Candidate = $candidate.Name; Profile = $candidate.Profile; ProfileSha256 = $profileHash
      DiscoveryNet = $candidate.DiscoveryNet; DiscoveryPF = $candidate.DiscoveryPF
      DiscoveryTrades = $candidate.DiscoveryTrades; DiscoveryDD = $candidate.DiscoveryDD
   }) | Out-Null

   foreach($window in $windows) {
      $rank++
      $configName = "{0:000}_{1}_{2}_m1.ini" -f $rank, $candidate.Name, $window.Name
      $reportName = "$($candidate.Name)_$($window.Name)_m1"
      Write-SeasonalTesterConfig -Path (Join-Path $configDir $configName) -ReportRoot $reportDir `
         -ReportName $reportName -From $window.From -To $window.To -Inputs $inputs -Model 1 -Deposit 10000
      $queueRows.Add([pscustomobject]@{
         QueueRank = $rank; Candidate = $candidate.Name; CandidateRank = $candidateRank
         SourceType = "independent_h4_channel_trend"; SourceRank = 1; Phase = "frozen_holdout_model1"
         Set = $candidate.Profile; Window = $window.Name; From = $window.From; To = $window.To; Model = 1; Deposit = 10000
         Config = "configs\$configName"; ExpectedReportName = $reportName; ProfileSnapshot = "profiles\$($candidate.Profile)"
         ProfileSha256 = $profileHash; SourceSha256 = $sourceHash; StopRule = $stopRule
      }) | Out-Null
      $runRows.Add([pscustomobject]@{
         QueueRank = $rank; Candidate = $candidate.Name; Phase = "frozen_holdout_model1"
         PhaseLabel = "Independent H4 channel trend frozen holdout Model1"; Window = $window.Name; Model = 1; Deposit = 10000
         PackageConfig = "$PackageDir\configs\$configName"; SourceConfig = "$PackageDir\configs\$configName"
         ExpectedReportName = $reportName; ReportDestination = "$PackageDir\reports_here\$reportName"
         ProfileSha256 = $profileHash; StopRule = $stopRule
      }) | Out-Null
   }
}

$queueRows | Export-Csv -LiteralPath (Resolve-RepoPath $QueueManifestPath) -NoTypeInformation -Encoding ASCII
$runRows | Export-Csv -LiteralPath (Resolve-RepoPath $PackageManifestPath) -NoTypeInformation -Encoding ASCII
$md = [System.Collections.Generic.List[string]]::new()
$md.Add("# Independent H4 Channel-Trend Holdout Registration")
$md.Add("")
$md.Add("Frozen before any 2021-2026 result was generated for this strategy family. This is a strategy-specific holdout, not globally unseen market data for the project.")
$md.Add("")
$md.Add("- Source SHA-256: ``$sourceHash``")
$md.Add("- Holdout end: ``2026-07-12``")
$md.Add("- Candidates: ``$($candidates.Count)``")
$md.Add("- Configurations: ``$rank``")
$md.Add("")
$md.Add("| Candidate | Frozen profile SHA-256 | Discovery net | PF | Trades | DD |")
$md.Add("|---|---|---:|---:|---:|---:|")
foreach($row in $registrationRows) {
   $md.Add("| ``$($row.Candidate)`` | ``$($row.ProfileSha256)`` | ``+$($row.DiscoveryNet)`` | ``$($row.DiscoveryPF)`` | ``$($row.DiscoveryTrades)`` | ``$($row.DiscoveryDD)%`` |")
}
$md.Add("")
$md.Add($stopRule)
$md.Add("")
$md.Add("No threshold or profile may be changed after holdout inspection. A failure rejects this frozen family rather than starting another holdout-tuned sweep.")
$md | Set-Content -LiteralPath (Resolve-RepoPath $RegistrationPath) -Encoding ASCII
[pscustomobject]@{ Status = "FROZEN"; SourceHash = $sourceHash; Candidates = $candidates.Count; Windows = $windows.Count; Configurations = $rank; PackageDir = $PackageDir }
