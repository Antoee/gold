param(
   [string]$PackageDir = "outputs\low_activity_diversifier_holdout_model1_package",
   [string]$QueuePath = "outputs\LOW_ACTIVITY_DIVERSIFIER_HOLDOUT_MODEL1_QUEUE.csv",
   [string]$ManifestPath = "outputs\LOW_ACTIVITY_DIVERSIFIER_HOLDOUT_MODEL1_PACKAGE_MANIFEST.csv",
   [string]$MarkdownPath = "outputs\LOW_ACTIVITY_DIVERSIFIER_HOLDOUT_MODEL1_PACKAGE.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "seasonal_gate_helpers.ps1")
$repo=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$outputsRoot=(Resolve-Path (Join-Path $repo 'outputs')).Path
function Resolve-RepoPath([string]$Path){if([IO.Path]::IsPathRooted($Path)){return $Path};return Join-Path $repo $Path}
function Clear-OutputDirSafe([string]$Path){
   if(Test-Path -LiteralPath $Path){$actual=(Resolve-Path -LiteralPath $Path).Path;if(!$actual.StartsWith($outputsRoot,[StringComparison]::OrdinalIgnoreCase)){throw "Refusing to clear non-outputs directory: $actual"};Remove-Item -LiteralPath $actual -Recurse -Force}
   New-Item -ItemType Directory -Path $Path -Force | Out-Null
}

$lanes=@(
   [pscustomobject]@{
      Name='fbt_b16_fixed_r200'; Family='failed_breakout'; Source='work\Independent_XAUUSD_M15_Failed_Breakout_Trap.mq5'
      Profile='outputs\independent_m15_failed_breakout_liveness_model1_package\profiles\fbt_b16_fixed_r200.set'
      Test='work\test_independent_m15_failed_breakout_trap_source.ps1'; SourceHash='EFB39ED06E5C7CA3D75C971F24ADB3073E597CC9CB2373257521EC41BDC57990'
   },
   [pscustomobject]@{
      Name='m15sq_break8'; Family='volatility_squeeze'; Source='work\Independent_XAUUSD_M15_Volatility_Squeeze.mq5'
      Profile='outputs\independent_m15_volatility_squeeze_discovery_model1_package\profiles\m15sq_break8.set'
      Test='work\test_independent_m15_volatility_squeeze_source.ps1'; SourceHash='A47F7A8ED05916A07A7CCF713340C64B1DFF950504E28744212EA8FD5CA94F29'
   },
   [pscustomobject]@{
      Name='m15vcr_vol130'; Family='volume_climax_reversal'; Source='work\Independent_XAUUSD_M15_Volume_Climax_Reversal.mq5'
      Profile='outputs\independent_m15_volume_climax_reversal_discovery_model1_package\profiles\m15vcr_vol130.set'
      Test='work\test_independent_m15_volume_climax_reversal_source.ps1'; SourceHash='914C5F3832D61DFD3AD2E4F885C70EFBF35E35B6CFFFFE1B8387EDA96AC56A36'
   }
)
$windows=@(
   [pscustomobject]@{Name='holdout_2021_2022';From='2021.01.01';To='2022.12.31'},
   [pscustomobject]@{Name='holdout_2023_2026';From='2023.01.01';To='2026.07.16'},
   [pscustomobject]@{Name='continuous_2021_2026';From='2021.01.01';To='2026.07.16'}
)
$stopRule='Reject a lane if either disjoint holdout era loses, continuous PF is below 1.15, continuous trades are below 35, or continuous DD exceeds 2%; do not combine rejected lanes.'
$package=Resolve-RepoPath $PackageDir
Clear-OutputDirSafe $package
$queue=[System.Collections.Generic.List[object]]::new()
$manifest=[System.Collections.Generic.List[object]]::new()
$rank=0
$candidateRank=0
foreach($lane in $lanes){
   $candidateRank++
   $source=Resolve-RepoPath $lane.Source
   $profile=Resolve-RepoPath $lane.Profile
   $test=Resolve-RepoPath $lane.Test
   & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $test -SourcePath $source | Out-Null
   $sourceHash=(Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
   if($sourceHash -ne $lane.SourceHash){throw "Source identity changed for $($lane.Name): $sourceHash"}
   $laneRoot=Join-Path $package $lane.Name
   $configDir=Join-Path $laneRoot 'configs';$profileDir=Join-Path $laneRoot 'profiles';$reportDir=Join-Path $laneRoot 'reports_here';$sourceDir=Join-Path $laneRoot 'source'
   New-Item -ItemType Directory -Path $configDir,$profileDir,$reportDir,$sourceDir -Force | Out-Null
   Copy-Item -LiteralPath $source -Destination (Join-Path $sourceDir 'Professional_XAUUSD_EA.mq5') -Force
   $inputs=Import-SetInputs $profile
   Set-InputLine -Inputs $inputs -Name 'InpEvidenceRunLabel' -Value 'low_activity_diversifier_holdout_model1'
   Set-InputLine -Inputs $inputs -Name 'InpEvidenceSourceHash' -Value $sourceHash
   Set-InputLine -Inputs $inputs -Name 'InpLogTrades' -Value 'false'
   $profileName="$($lane.Name).set"
   $profileOut=Join-Path $profileDir $profileName
   @($inputs.Keys | Sort-Object | ForEach-Object {$inputs[$_]}) | Set-Content -LiteralPath $profileOut -Encoding ASCII
   $profileHash=(Get-FileHash -LiteralPath $profileOut -Algorithm SHA256).Hash
   foreach($window in $windows){
      $rank++
      $configName="{0:000}_{1}_{2}_m1.ini" -f $rank,$lane.Name,$window.Name
      $reportName="$($lane.Name)_$($window.Name)_m1"
      Write-SeasonalTesterConfig -Path (Join-Path $configDir $configName) -ReportRoot $reportDir -ReportName $reportName -From $window.From -To $window.To -Inputs $inputs -Model 1 -Deposit 10000
      $relativeLane="$PackageDir\$($lane.Name)"
      $queue.Add([pscustomobject]@{
         QueueRank=$rank;Candidate=$lane.Name;CandidateRank=$candidateRank;Family=$lane.Family;Phase='diversifier_holdout_model1'
         Window=$window.Name;From=$window.From;To=$window.To;Model=1;Deposit=10000;Config="$($lane.Name)\configs\$configName"
         ExpectedReportName=$reportName;ProfileSnapshot="$($lane.Name)\profiles\$profileName";ProfileSha256=$profileHash
         SourceSha256=$sourceHash;RiskPercent='0.10';StopRule=$stopRule
      }) | Out-Null
      $manifest.Add([pscustomobject]@{
         QueueRank=$rank;Candidate=$lane.Name;Phase='diversifier_holdout_model1';PhaseLabel='Low-activity diversifier holdout Model1'
         Window=$window.Name;Model=1;Deposit=10000;PackageConfig="$relativeLane\configs\$configName";SourceConfig="$relativeLane\configs\$configName"
         ExpectedReportName=$reportName;ReportDestination="$relativeLane\reports_here\$reportName";ProfileSha256=$profileHash;StopRule=$stopRule
      }) | Out-Null
   }
}
$queue | Export-Csv -LiteralPath (Resolve-RepoPath $QueuePath) -NoTypeInformation -Encoding ASCII
$manifest | Export-Csv -LiteralPath (Resolve-RepoPath $ManifestPath) -NoTypeInformation -Encoding ASCII
@(
   '# Low-Activity Diversifier Holdout Model1 Package','',
   'Three unchanged pre-2021 research profiles tested on two disjoint post-2020 eras and their continuous union.','',
   "- Profiles: $($lanes.Count)","- Windows: $($windows.Count)","- Configurations: $rank",'- Starting deposit: `$10,000`','- Requested risk: `0.10%` per lane','- Real-account trading: disabled','',
   $stopRule
) | Set-Content -LiteralPath (Resolve-RepoPath $MarkdownPath) -Encoding ASCII
[pscustomobject]@{Status='READY';Profiles=$lanes.Count;Windows=$windows.Count;Configurations=$rank;PackageDir=$PackageDir}
