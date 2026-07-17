param(
   [string]$SourcePath = "work\Independent_XAUUSD_H4_Channel_Trend.mq5",
   [string]$BaseProfilePath = "outputs\H4_CHANNEL_CAPITAL_FEASIBLE_BASE_PROFILE.set",
   [string]$PackageDir = "outputs\h4_channel_capital_feasible_model1_package",
   [string]$QueueManifestPath = "outputs\H4_CHANNEL_CAPITAL_FEASIBLE_MODEL1_QUEUE.csv",
   [string]$PackageManifestPath = "outputs\H4_CHANNEL_CAPITAL_FEASIBLE_MODEL1_PACKAGE_MANIFEST.csv",
   [string]$MarkdownPath = "outputs\H4_CHANNEL_CAPITAL_FEASIBLE_MODEL1_PACKAGE.md"
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

& (Join-Path $PSScriptRoot "test_independent_h4_channel_trend_source.ps1") | Out-Null
$sourceFull = (Resolve-Path -LiteralPath (Resolve-RepoPath $SourcePath)).Path
$sourceHash = (Get-FileHash -LiteralPath $sourceFull -Algorithm SHA256).Hash
$expectedSourceHashes = @(
   "C27025A3605EEBBA54C5B88D564CE641D00634E2C42C8BAC6D127751ABF58F4A",
   "E8EB53728A83042598460A691784E800512DFC43DC2B503B49427870B032A4FA"
)
if($sourceHash -notin $expectedSourceHashes) { throw "H4 channel source changed: $sourceHash" }
$baseProfile = Resolve-RepoPath $BaseProfilePath
if(!(Test-Path -LiteralPath $baseProfile)) { throw "Frozen base profile missing: $baseProfile" }
$baseProfileHash = (Get-FileHash -LiteralPath $baseProfile -Algorithm SHA256).Hash
$expectedBaseProfileHash = "940CB5B7C2E6C9786473460ED4C65274430C4CDC3665DDDBAF5EADDA870760DE"
if($baseProfileHash -ne $expectedBaseProfileHash) { throw "Frozen base profile changed: $baseProfileHash" }

# These are the four shapes frozen before the original 2021-2026 holdout.
# This follow-up changes only the risk budget needed to make broker-minimum volume feasible.
$candidates = @(
   [pscustomobject]@{ Name = "h4cf_40_20_l20_a25"; Entry = "40"; Exit = "20"; TrailLookback = "20"; TrailATR = "2.50" },
   [pscustomobject]@{ Name = "h4cf_55_20_l20_a25"; Entry = "55"; Exit = "20"; TrailLookback = "20"; TrailATR = "2.50" },
   [pscustomobject]@{ Name = "h4cf_55_20_l20_a30"; Entry = "55"; Exit = "20"; TrailLookback = "20"; TrailATR = "3.00" },
   [pscustomobject]@{ Name = "h4cf_80_40_l20_a30"; Entry = "80"; Exit = "40"; TrailLookback = "20"; TrailATR = "3.00" }
)
$windows = @(
   [pscustomobject]@{ Name = "discovery_2015_2020"; From = "2015.01.01"; To = "2020.12.31" },
   [pscustomobject]@{ Name = "validation_2021_2026"; From = "2021.01.01"; To = "2026.07.12" },
   [pscustomobject]@{ Name = "continuous_2015_2026"; From = "2015.01.01"; To = "2026.07.12" }
)
$riskPercent = "0.50"
$stopRule = "Require discovery and validation net above zero, continuous PF >= 1.30, at least 100 continuous trades, max DD <= 5%, and at least two neighboring shapes passing before Model4. This follow-up is holdout-informed capital-feasibility research, not pristine OOS evidence."

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
foreach($candidate in $candidates) {
   $candidateRank++
   $inputs = Import-SetInputs $baseProfile
   Set-InputLine -Inputs $inputs -Name "InpEntryLookbackBars" -Value $candidate.Entry
   Set-InputLine -Inputs $inputs -Name "InpExitLookbackBars" -Value $candidate.Exit
   Set-InputLine -Inputs $inputs -Name "InpChandelierLookbackBars" -Value $candidate.TrailLookback
   Set-InputLine -Inputs $inputs -Name "InpChandelierATR" -Value $candidate.TrailATR
   Set-InputLine -Inputs $inputs -Name "InpRiskPercent" -Value $riskPercent
   Set-InputLine -Inputs $inputs -Name "InpAccountWideMaxOpenRiskPercent" -Value "1.00"
   Set-InputLine -Inputs $inputs -Name "InpEvidenceProfileId" -Value $candidate.Name
   Set-InputLine -Inputs $inputs -Name "InpEvidenceSourceHash" -Value $sourceHash
   Set-InputLine -Inputs $inputs -Name "InpEvidenceRunLabel" -Value "h4_channel_capital_feasible_model1"
   Set-InputLine -Inputs $inputs -Name "InpLogFileName" -Value "$($candidate.Name)_trades.csv"
   $profileName = "$($candidate.Name).set"
   $profilePath = Join-Path $profileDir $profileName
   @($inputs.Keys | Sort-Object | ForEach-Object { $inputs[$_] }) |
      Set-Content -LiteralPath $profilePath -Encoding ASCII
   $profileHash = (Get-FileHash -LiteralPath $profilePath -Algorithm SHA256).Hash

   foreach($window in $windows) {
      $rank++
      $configName = "{0:000}_{1}_{2}_m1.ini" -f $rank,$candidate.Name,$window.Name
      $reportName = "$($candidate.Name)_$($window.Name)_m1"
      Write-SeasonalTesterConfig -Path (Join-Path $configDir $configName) -ReportRoot $reportDir `
         -ReportName $reportName -From $window.From -To $window.To -Inputs $inputs -Model 1 -Deposit 10000
      $queueRows.Add([pscustomobject]@{
         QueueRank = $rank; Candidate = $candidate.Name; CandidateRank = $candidateRank
         SourceType = "h4_channel_capital_feasible"; SourceRank = 1; Phase = "capital_feasible_model1"
         Set = $profileName; Window = $window.Name; From = $window.From; To = $window.To
         Model = 1; Deposit = 10000; Config = "configs\$configName"
         ExpectedReportName = $reportName; ProfileSnapshot = "profiles\$profileName"
         ProfileSha256 = $profileHash; SourceSha256 = $sourceHash
         RiskPercent = $riskPercent; StopRule = $stopRule
      }) | Out-Null
      $runRows.Add([pscustomobject]@{
         QueueRank = $rank; Candidate = $candidate.Name; Phase = "capital_feasible_model1"
         PhaseLabel = "H4 channel capital-feasible Model1"; Window = $window.Name
         Model = 1; Deposit = 10000; PackageConfig = "$PackageDir\configs\$configName"
         SourceConfig = "$PackageDir\configs\$configName"; ExpectedReportName = $reportName
         ReportDestination = "$PackageDir\reports_here\$reportName"
         ProfileSha256 = $profileHash; StopRule = $stopRule
      }) | Out-Null
   }
}

$queueRows | Export-Csv -LiteralPath (Resolve-RepoPath $QueueManifestPath) -NoTypeInformation -Encoding ASCII
$runRows | Export-Csv -LiteralPath (Resolve-RepoPath $PackageManifestPath) -NoTypeInformation -Encoding ASCII

$lines = @(
   "# H4 Channel Capital-Feasible Model1 Package",
   "",
   "This is a bounded engineering follow-up to the previously rejected 0.10% sizing experiment.",
   "The signal and exit shapes were frozen before the original holdout; only risk is changed to the project's existing 0.50% hard trade cap.",
   "",
   "- Source SHA-256: ``$sourceHash``",
   "- Frozen base-profile SHA-256: ``$baseProfileHash``",
   '- Starting balance: `$10,000`',
   "- Risk per requested trade: ``$riskPercent%``",
   "- Forced minimum lot: ``false``",
   "- Candidates: ``$($candidates.Count)``",
   "- Windows: ``$($windows.Name -join ', ')``",
   "- Configurations: ``$rank``",
   "",
   $stopRule
)
$lines | Set-Content -LiteralPath (Resolve-RepoPath $MarkdownPath) -Encoding ASCII

[pscustomobject]@{
   Status = "READY"; SourceHash = $sourceHash; Candidates = $candidates.Count
   Windows = $windows.Count; Configurations = $rank; PackageDir = $PackageDir
}
