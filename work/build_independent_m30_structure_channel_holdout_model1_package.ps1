param(
   [string]$SourcePath = "work\Independent_XAUUSD_M30_Structure_Channel.mq5",
   [string]$DiscoveryPackageDir = "outputs\independent_m30_structure_channel_discovery_model1_package",
   [string]$PackageDir = "outputs\independent_m30_structure_channel_holdout_model1_package",
   [string]$QueueManifestPath = "outputs\INDEPENDENT_M30_STRUCTURE_CHANNEL_HOLDOUT_MODEL1_QUEUE.csv",
   [string]$PackageManifestPath = "outputs\INDEPENDENT_M30_STRUCTURE_CHANNEL_HOLDOUT_MODEL1_PACKAGE_MANIFEST.csv",
   [string]$RegistrationPath = "outputs\INDEPENDENT_M30_STRUCTURE_CHANNEL_HOLDOUT_REGISTRATION.md"
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

& (Join-Path $PSScriptRoot "test_independent_m30_structure_channel_source.ps1") | Out-Null
$sourceFull = (Resolve-Path -LiteralPath (Resolve-RepoPath $SourcePath)).Path
$sourceHash = (Get-FileHash -LiteralPath $sourceFull -Algorithm SHA256).Hash
$expectedSourceHash = "4A524A8C6565B669FE9D68E84B4EE9B8C2AEAB49E0A7173FE6750A930B4594BB"
if($sourceHash -ne $expectedSourceHash) { throw "M30 structure-channel source changed: $sourceHash" }

$candidates = @(
   [pscustomobject]@{ Name = "m30sc_72_36_tp20"; Profile = "m30sc_72_36_tp20.set"; DiscoveryNet = 547.52; DiscoveryPF = 1.49; DiscoveryTrades = 239; DiscoveryDD = 2.34 },
   [pscustomobject]@{ Name = "m30sc_48_24_channel"; Profile = "m30sc_48_24_channel.set"; DiscoveryNet = 379.99; DiscoveryPF = 1.29; DiscoveryTrades = 289; DiscoveryDD = 2.62 },
   [pscustomobject]@{ Name = "m30sc_48_24_tp25"; Profile = "m30sc_48_24_tp25.set"; DiscoveryNet = 374.64; DiscoveryPF = 1.28; DiscoveryTrades = 291; DiscoveryDD = 2.62 },
   [pscustomobject]@{ Name = "m30sc_48_24_stop5"; Profile = "m30sc_48_24_stop5.set"; DiscoveryNet = 306.61; DiscoveryPF = 1.32; DiscoveryTrades = 226; DiscoveryDD = 1.69 }
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
$stopRule = "Frozen holdout: require both broad holdout eras positive, continuous PF at least 1.20, at least 150 trades, DD at or below 5%, no completed year below -1.50%, and no more than two red completed years before Model4."
foreach($candidate in $candidates) {
   $candidateRank++
   $discoveryProfile = Resolve-RepoPath (Join-Path $DiscoveryPackageDir "profiles\$($candidate.Profile)")
   if(!(Test-Path -LiteralPath $discoveryProfile)) { throw "Frozen discovery profile missing: $discoveryProfile" }
   $inputs = Import-SetInputs $discoveryProfile
   Set-InputLine -Inputs $inputs -Name "InpEvidenceProfileId" -Value $candidate.Name
   Set-InputLine -Inputs $inputs -Name "InpEvidenceSourceHash" -Value $sourceHash
   Set-InputLine -Inputs $inputs -Name "InpEvidenceRunLabel" -Value "independent_m30_structure_channel_holdout_model1"
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
         SourceType = "independent_m30_structure_channel"; SourceRank = 1; Phase = "frozen_holdout_model1"
         Set = $candidate.Profile; Window = $window.Name; From = $window.From; To = $window.To; Model = 1; Deposit = 10000
         Config = "configs\$configName"; ExpectedReportName = $reportName; ProfileSnapshot = "profiles\$($candidate.Profile)"
         ProfileSha256 = $profileHash; SourceSha256 = $sourceHash; StopRule = $stopRule
      }) | Out-Null
      $runRows.Add([pscustomobject]@{
         QueueRank = $rank; Candidate = $candidate.Name; Phase = "frozen_holdout_model1"
         PhaseLabel = "Independent M30 structure channel frozen holdout Model1"; Window = $window.Name; Model = 1; Deposit = 10000
         PackageConfig = "$PackageDir\configs\$configName"; SourceConfig = "$PackageDir\configs\$configName"
         ExpectedReportName = $reportName; ReportDestination = "$PackageDir\reports_here\$reportName"
         ProfileSha256 = $profileHash; StopRule = $stopRule
      }) | Out-Null
   }
}

$queueRows | Export-Csv -LiteralPath (Resolve-RepoPath $QueueManifestPath) -NoTypeInformation -Encoding ASCII
$runRows | Export-Csv -LiteralPath (Resolve-RepoPath $PackageManifestPath) -NoTypeInformation -Encoding ASCII
$md = [System.Collections.Generic.List[string]]::new()
$md.Add("# Independent M30 Structure-Channel Holdout Registration")
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
