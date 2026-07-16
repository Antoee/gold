param(
   [string]$SourcePath = "work\Independent_XAUUSD_H4_Channel_Trend.mq5",
   [string]$BaseProfilePath = "outputs\independent_h4_channel_trend_discovery_model1_package\profiles\h4ct_55_20_chandelier.set",
   [string]$PackageDir = "outputs\independent_h4_channel_trend_trail_discovery_model1_package",
   [string]$QueueManifestPath = "outputs\INDEPENDENT_H4_CHANNEL_TREND_TRAIL_DISCOVERY_MODEL1_QUEUE.csv",
   [string]$PackageManifestPath = "outputs\INDEPENDENT_H4_CHANNEL_TREND_TRAIL_DISCOVERY_MODEL1_PACKAGE_MANIFEST.csv",
   [string]$MarkdownPath = "outputs\INDEPENDENT_H4_CHANNEL_TREND_TRAIL_DISCOVERY_MODEL1_PACKAGE.md"
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
$baseProfile = Resolve-RepoPath $BaseProfilePath
if(!(Test-Path -LiteralPath $baseProfile)) { throw "Base Chandelier profile is missing: $baseProfile" }

$variants = @(
   [pscustomobject]@{ Name = "h4ct_trail_40_20_l20_a25"; Entry = "40"; Exit = "20"; TrailLookback = "20"; TrailATR = "2.50" },
   [pscustomobject]@{ Name = "h4ct_trail_40_20_l20_a30"; Entry = "40"; Exit = "20"; TrailLookback = "20"; TrailATR = "3.00" },
   [pscustomobject]@{ Name = "h4ct_trail_55_20_l10_a30"; Entry = "55"; Exit = "20"; TrailLookback = "10"; TrailATR = "3.00" },
   [pscustomobject]@{ Name = "h4ct_trail_55_20_l20_a25"; Entry = "55"; Exit = "20"; TrailLookback = "20"; TrailATR = "2.50" },
   [pscustomobject]@{ Name = "h4ct_trail_55_20_l20_a30"; Entry = "55"; Exit = "20"; TrailLookback = "20"; TrailATR = "3.00" },
   [pscustomobject]@{ Name = "h4ct_trail_55_20_l20_a35"; Entry = "55"; Exit = "20"; TrailLookback = "20"; TrailATR = "3.50" },
   [pscustomobject]@{ Name = "h4ct_trail_55_20_l30_a30"; Entry = "55"; Exit = "20"; TrailLookback = "30"; TrailATR = "3.00" },
   [pscustomobject]@{ Name = "h4ct_trail_80_40_l20_a30"; Entry = "80"; Exit = "40"; TrailLookback = "20"; TrailATR = "3.00" }
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
$stopRule = "Discovery-only Chandelier neighborhood: require both eras positive, continuous PF at least 1.30, at least 60 trades, DD at or below 3%, and at least three adjacent profitable shapes before opening 2021-2026."
foreach($variant in $variants) {
   $candidateRank++
   $inputs = Import-SetInputs $baseProfile
   Set-InputLine -Inputs $inputs -Name "InpEntryLookbackBars" -Value $variant.Entry
   Set-InputLine -Inputs $inputs -Name "InpExitLookbackBars" -Value $variant.Exit
   Set-InputLine -Inputs $inputs -Name "InpUseChandelierTrail" -Value "true"
   Set-InputLine -Inputs $inputs -Name "InpChandelierLookbackBars" -Value $variant.TrailLookback
   Set-InputLine -Inputs $inputs -Name "InpChandelierATR" -Value $variant.TrailATR
   Set-InputLine -Inputs $inputs -Name "InpEvidenceProfileId" -Value $variant.Name
   Set-InputLine -Inputs $inputs -Name "InpEvidenceSourceHash" -Value $sourceHash
   Set-InputLine -Inputs $inputs -Name "InpEvidenceRunLabel" -Value "independent_h4_channel_trend_trail_discovery_model1"
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
         SourceType = "independent_h4_channel_trend"; SourceRank = 1; Phase = "trail_discovery_model1"
         Set = $profileName; Window = $window.Name; From = $window.From; To = $window.To; Model = 1; Deposit = 10000
         Config = "configs\$configName"; ExpectedReportName = $reportName; ProfileSnapshot = "profiles\$profileName"
         ProfileSha256 = $profileHash; SourceSha256 = $sourceHash; EntryLookback = $variant.Entry
         ExitLookback = $variant.Exit; TrailLookback = $variant.TrailLookback; TrailATR = $variant.TrailATR; StopRule = $stopRule
      }) | Out-Null
      $runRows.Add([pscustomobject]@{
         QueueRank = $rank; Candidate = $variant.Name; Phase = "trail_discovery_model1"
         PhaseLabel = "Independent H4 channel Chandelier discovery Model1"; Window = $window.Name; Model = 1; Deposit = 10000
         PackageConfig = "$PackageDir\configs\$configName"; SourceConfig = "$PackageDir\configs\$configName"
         ExpectedReportName = $reportName; ReportDestination = "$PackageDir\reports_here\$reportName"
         ProfileSha256 = $profileHash; StopRule = $stopRule
      }) | Out-Null
   }
}

$queueRows | Export-Csv -LiteralPath (Resolve-RepoPath $QueueManifestPath) -NoTypeInformation -Encoding ASCII
$runRows | Export-Csv -LiteralPath (Resolve-RepoPath $PackageManifestPath) -NoTypeInformation -Encoding ASCII
$md = [System.Collections.Generic.List[string]]::new()
$md.Add("# Independent H4 Channel-Trend Chandelier Discovery Package")
$md.Add("")
$md.Add("Predeclared neighborhood around the first discovery lead. No configuration includes data after 2020.")
$md.Add("")
$md.Add("- Source SHA-256: ``$sourceHash``")
$md.Add("- Variants: ``$($variants.Count)``")
$md.Add("- Discovery windows: ``$($windows.Name -join ', ')``")
$md.Add("- Configurations: ``$rank``")
$md.Add("")
$md.Add('All safety, risk, broker-sizing, and account-wide exposure settings remain frozen from the first discovery package.')
$md | Set-Content -LiteralPath (Resolve-RepoPath $MarkdownPath) -Encoding ASCII
[pscustomobject]@{ Status = "READY"; SourceHash = $sourceHash; Variants = $variants.Count; Windows = $windows.Count; Configurations = $rank; PackageDir = $PackageDir }
