[CmdletBinding()]
param(
   [string]$ParentPackage = 'outputs\three_lane_adaptive_trend_gate_package',
   [string]$PackageDir = 'outputs\three_lane_adaptive_trend_broad_package',
   [string]$ManifestPath = 'outputs\THREE_LANE_ADAPTIVE_TREND_BROAD_MANIFEST.csv',
   [string]$ContractPath = 'outputs\THREE_LANE_ADAPTIVE_TREND_BROAD_CONTRACT.md',
   [ValidateSet(1,4)][int]$Model = 1,
   [switch]$PassingProfilesOnly
)

$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'seasonal_gate_helpers.ps1')
$repo=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path
function Resolve-RepoPath([string]$Path){if([IO.Path]::IsPathRooted($Path)){return $Path};return Join-Path $repo $Path}
function Read-Profile([string]$Path){
   $inputs=[ordered]@{}
   foreach($line in Get-Content -LiteralPath $Path){if($line -match '^([^;=]+)='){if($inputs.Contains($Matches[1])){throw "Duplicate profile input: $($Matches[1])"};$inputs[$Matches[1]]=$line}}
   if($inputs.Count -lt 170){throw "Unexpectedly small profile: $Path"};return $inputs
}
$parent=Resolve-RepoPath $ParentPackage
$parentSource=Join-Path $parent 'source\Professional_XAUUSD_EA.mq5'
$expectedSourceHash='51AE67DB56C3B584E8DA3A64C4B43ECAAE9ACE7E96541C22C9C5AC10E389FABB'
if((Get-FileHash -LiteralPath $parentSource -Algorithm SHA256).Hash.ToUpperInvariant() -ne $expectedSourceHash){throw 'Parent source identity changed.'}
$profiles=@(
   [pscustomobject]@{Candidate='tlat_di11_atb10';File='tlat_di11_atb10.set'},
   [pscustomobject]@{Candidate='tlat_di12_atb10_center';File='tlat_di12_atb10_center.set'},
   [pscustomobject]@{Candidate='tlat_di13_atb10';File='tlat_di13_atb10.set'}
)
if($PassingProfilesOnly){
   $profiles=@($profiles|Where-Object Candidate -in @('tlat_di11_atb10','tlat_di12_atb10_center'))
}
$windows=@(
   [pscustomobject]@{Name='older_2015_2018';From='2015.01.01';To='2018.12.31'},
   [pscustomobject]@{Name='middle_2019_2022';From='2019.01.01';To='2022.12.31'},
   [pscustomobject]@{Name='recent_2023_2026';From='2023.01.01';To='2026.07.12'},
   [pscustomobject]@{Name='continuous_2015_2026';From='2015.01.01';To='2026.07.12'}
)
$package=Resolve-RepoPath $PackageDir
if(Test-Path -LiteralPath $package){Remove-Item -LiteralPath $package -Recurse -Force}
$configDir=Join-Path $package 'configs';$profileDir=Join-Path $package 'profiles';$reportDir=Join-Path $package 'reports_here';$sourceDir=Join-Path $package 'source'
New-Item -ItemType Directory -Path $configDir,$profileDir,$reportDir,$sourceDir -Force|Out-Null
Copy-Item -LiteralPath $parentSource -Destination (Join-Path $sourceDir 'Professional_XAUUSD_EA.mq5') -Force
$rows=[Collections.Generic.List[object]]::new();$rank=0
$modelTag=if($Model -eq 4){'m4'}else{'m1'}
foreach($profile in $profiles){
   $parentProfile=Join-Path $parent ('profiles\'+$profile.File)
   $profileHash=(Get-FileHash -LiteralPath $parentProfile -Algorithm SHA256).Hash.ToUpperInvariant()
   Copy-Item -LiteralPath $parentProfile -Destination (Join-Path $profileDir $profile.File) -Force
   $inputs=Read-Profile $parentProfile
   foreach($window in $windows){
      $rank++;$reportName="$($profile.Candidate)_$($window.Name)_$modelTag";$configName=('{0:D3}_{1}.ini' -f $rank,$reportName);$configPath=Join-Path $configDir $configName
      Write-SeasonalTesterConfig -Path $configPath -ReportRoot $reportDir -ReportName $reportName -From $window.From -To $window.To -Inputs $inputs -Model $Model -Deposit 10000
      $rows.Add([pscustomobject][ordered]@{QueueRank=$rank;Profile=$profile.Candidate;Candidate=$profile.Candidate;Phase='broad';Set='three_lane';Window=$window.Name;From=$window.From;To=$window.To;Model=$Model;Deposit=10000;PackageConfig="$PackageDir\configs\$configName";ExpectedReportName=$reportName;ReportDestination="$PackageDir\reports_here\$reportName";ConfigSha256=(Get-FileHash -LiteralPath $configPath -Algorithm SHA256).Hash.ToUpperInvariant();SourceSha256=$expectedSourceHash;ProfileSha256=$profileHash})|Out-Null
   }
}
$manifest=Resolve-RepoPath $ManifestPath;$rows|Export-Csv -LiteralPath $manifest -NoTypeInformation -Encoding ASCII
$manifestHash=(Get-FileHash -LiteralPath $manifest -Algorithm SHA256).Hash.ToUpperInvariant()
@('# Three-Lane Adaptive Trend Broad Gate','',
  "**Status: FROZEN MODEL $Model BROAD GATE / NO CANDIDATE CHANGE.**",'',
  "- Source SHA-256: ``$expectedSourceHash``","- Manifest SHA-256: ``$manifestHash``",
  '- Profiles are byte-identical to the passed critical gate: DI -11, -12 center, and -13.',
  "- Windows: three disjoint eras plus continuous 2015-2026 YTD; Model $Model; `$10,000.",
  '- Every era must be positive with PF at least 1.20 and drawdown no more than 4%.',
  '- Continuous center must have PF at least 1.35, at least 300 trades, drawdown no more than 4%, recovery at least 4, and CAGR at least 1%.',
  '- At least one adjacent DI profile must support the center. This gate is reject-only and cannot promote directly to live trading.')|Set-Content -LiteralPath (Resolve-RepoPath $ContractPath) -Encoding ASCII
[pscustomobject]@{Status='FROZEN';Profiles=$profiles.Count;Configurations=$rows.Count;SourceSha256=$expectedSourceHash;ManifestSha256=$manifestHash}
