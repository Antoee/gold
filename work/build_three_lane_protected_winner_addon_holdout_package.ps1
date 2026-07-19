[CmdletBinding()]
param(
   [string]$SourcePath = 'work\Professional_XAUUSD_Three_Lane_Protected_Winner_AddOn_Research.mq5',
   [string]$ControlProfilePath = 'outputs\THREE_LANE_PROTECTED_WINNER_ADDON_DISCOVERY_CONTROL.set',
   [string]$SelectedProfilePath = 'outputs\THREE_LANE_PROTECTED_WINNER_ADDON_DISCOVERY_SELECTED_TRIGGER100.set',
   [string]$PackageDir = 'outputs\three_lane_protected_winner_addon_holdout_model1_package',
   [string]$QueuePath = 'outputs\THREE_LANE_PROTECTED_WINNER_ADDON_HOLDOUT_MODEL1_QUEUE.csv',
   [string]$ManifestPath = 'outputs\THREE_LANE_PROTECTED_WINNER_ADDON_HOLDOUT_MODEL1_PACKAGE_MANIFEST.csv',
   [string]$MarkdownPath = 'outputs\THREE_LANE_PROTECTED_WINNER_ADDON_HOLDOUT_MODEL1_PACKAGE.md'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'seasonal_gate_helpers.ps1')
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$outputsRoot = (Resolve-Path (Join-Path $repo 'outputs')).Path
$expectedSourceHash = 'F7AAEFF24C4A0FF8066C906A25F99462E1F2488765AD046364B970277AAD5B46'
$expectedControlHash = '65A3228E1C705BFE1DC97ADE7CEF94D3F5AE49C63E4E8E92708DCE699E7B6BCD'
$expectedSelectedHash = '50CC443F2FE19D53EA38B15D10CD92242D7A291452B603EC4B2B7A67F0C78F42'
function Resolve-RepoPath([string]$Path) { if([IO.Path]::IsPathRooted($Path)){return $Path}; return Join-Path $repo $Path }
function Clear-OutputDirSafe([string]$Path) {
   if(Test-Path -LiteralPath $Path) {
      $resolved = (Resolve-Path -LiteralPath $Path).Path
      if(!$resolved.StartsWith($outputsRoot,[StringComparison]::OrdinalIgnoreCase)){throw "Unsafe package path: $resolved"}
      Remove-Item -LiteralPath $resolved -Recurse -Force
   }
   New-Item -ItemType Directory -Path $Path -Force | Out-Null
}

$decision = @(Import-Csv -LiteralPath (Join-Path $repo 'outputs\THREE_LANE_PROTECTED_WINNER_ADDON_DISCOVERY_DECISION.csv'))
if($decision.Count -ne 1 -or $decision[0].Status -ne 'DISCOVERY_SURVIVOR' -or
   $decision[0].SelectedCandidate -ne 'pwa_trigger100' -or $decision[0].SelectedProfileSha256 -ne $expectedSelectedHash) {
   throw 'Frozen discovery survivor authorization is missing or changed.'
}
$source = (Resolve-Path -LiteralPath (Resolve-RepoPath $SourcePath)).Path
if((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToUpperInvariant() -ne $expectedSourceHash) { throw 'Source identity changed.' }
$profiles = @(
   [pscustomobject]@{Candidate='pwa_control';Role='disabled_feature_control';Path=(Resolve-RepoPath $ControlProfilePath);ExpectedHash=$expectedControlHash},
   [pscustomobject]@{Candidate='pwa_trigger100';Role='frozen_discovery_survivor';Path=(Resolve-RepoPath $SelectedProfilePath);ExpectedHash=$expectedSelectedHash}
)
foreach($profile in $profiles) {
   if((Get-FileHash -LiteralPath $profile.Path -Algorithm SHA256).Hash.ToUpperInvariant() -ne $profile.ExpectedHash) {
      throw "Profile identity changed: $($profile.Candidate)"
   }
}
$windows = @(
   [pscustomobject]@{Name='holdout_2021_2022';From='2021.01.01';To='2022.12.31'},
   [pscustomobject]@{Name='holdout_2023_2024';From='2023.01.01';To='2024.12.31'},
   [pscustomobject]@{Name='holdout_2025_2026';From='2025.01.01';To='2026.07.18'},
   [pscustomobject]@{Name='continuous_2021_2026';From='2021.01.01';To='2026.07.18'}
)
$stopRule = 'Feature-level holdout only: every candidate window must remain positive; continuous PF >= 1.50, DD <= 2%, add-on activity >= 2, and net plus return/DD must beat the exact disabled-feature control before Model 4.'
$package = Resolve-RepoPath $PackageDir
Clear-OutputDirSafe $package
$configDir=Join-Path $package 'configs';$profileDir=Join-Path $package 'profiles';$reportDir=Join-Path $package 'reports_here';$sourceDir=Join-Path $package 'source'
New-Item -ItemType Directory -Path $configDir,$profileDir,$reportDir,$sourceDir -Force | Out-Null
Copy-Item -LiteralPath $source -Destination (Join-Path $sourceDir 'Professional_XAUUSD_EA.mq5') -Force
$queue=[Collections.Generic.List[object]]::new();$run=[Collections.Generic.List[object]]::new();$rank=0
foreach($profile in $profiles) {
   $inputs = Import-SetInputs -Path $profile.Path
   if($inputs.Count -ne 187) { throw "Expected 187 pinned inputs: $($profile.Candidate)" }
   $profileName="$($profile.Candidate).set";$profileOut=Join-Path $profileDir $profileName
   Get-Content -LiteralPath $profile.Path | Set-Content -LiteralPath $profileOut -Encoding ASCII
   if((Get-FileHash -LiteralPath $profileOut -Algorithm SHA256).Hash.ToUpperInvariant() -ne $profile.ExpectedHash) { throw 'Profile copy changed bytes.' }
   foreach($window in $windows) {
      $rank++;$configName='{0:000}_{1}_{2}_m1.ini' -f $rank,$profile.Candidate,$window.Name;$reportName="$($profile.Candidate)_$($window.Name)_m1"
      Write-SeasonalTesterConfig -Path (Join-Path $configDir $configName) -ReportRoot $reportDir -ReportName $reportName `
         -From $window.From -To $window.To -Inputs $inputs -Model 1 -Deposit 10000 -Period 15
      $common=[ordered]@{QueueRank=$rank;Candidate=$profile.Candidate;Role=$profile.Role;Phase='feature_holdout_model1';Window=$window.Name;From=$window.From;To=$window.To;Model=1;Deposit=10000;ExpectedReportName=$reportName;ProfileSha256=$profile.ExpectedHash;SourceSha256=$expectedSourceHash;StopRule=$stopRule}
      $queue.Add([pscustomobject]($common+[ordered]@{Config="configs\$configName";ProfileSnapshot="profiles\$profileName"}))|Out-Null
      $run.Add([pscustomobject]($common+[ordered]@{PackageConfig="$PackageDir\configs\$configName";SourceConfig="$PackageDir\configs\$configName";ReportDestination="$PackageDir\reports_here\$reportName"}))|Out-Null
   }
}
$queue|Export-Csv -LiteralPath (Resolve-RepoPath $QueuePath) -NoTypeInformation -Encoding ASCII
$run|Export-Csv -LiteralPath (Resolve-RepoPath $ManifestPath) -NoTypeInformation -Encoding ASCII
@(
   '# Three-Lane Protected Winner Add-On Holdout Package','',
   '**Status: FROZEN FEATURE-LEVEL 2021-2026 HOLDOUT.**','',
   "- Source SHA-256: ``$expectedSourceHash``","- Selected profile SHA-256: ``$expectedSelectedHash``",
   "- Control profile SHA-256: ``$expectedControlHash``",'- Profiles: `2`','- Configurations: `8`',
   '- This is untouched for selection of the protected-add-on feature, but it is not globally untouched market data because ATB150 research previously examined these years.',
   '- No setting may change after these reports are opened. A losing candidate window closes the feature before Model 4.'
) | Set-Content -LiteralPath (Resolve-RepoPath $MarkdownPath) -Encoding ASCII
[pscustomobject][ordered]@{Status='READY';Profiles=2;Windows=4;Configurations=$rank;SourceSha256=$expectedSourceHash;SelectedProfileSha256=$expectedSelectedHash;LatestDate='2026-07-18'}
