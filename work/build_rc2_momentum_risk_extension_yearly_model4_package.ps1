param(
   [string]$SourcePath="work\Professional_XAUUSD_Operational_Hardening_Portfolio_RC2.mq5",
   [string]$ProfilePath="outputs\RC2_MOMENTUM_RISK_EXTENSION_RESEARCH_PROFILE.set",
   [string]$PackageDir="outputs\rc2_momentum_risk_extension_yearly_model4_package",
   [string]$QueuePath="outputs\RC2_MOMENTUM_RISK_EXTENSION_YEARLY_MODEL4_QUEUE.csv",
   [string]$ManifestPath="outputs\RC2_MOMENTUM_RISK_EXTENSION_YEARLY_MODEL4_MANIFEST.csv",
   [string]$MarkdownPath="outputs\RC2_MOMENTUM_RISK_EXTENSION_YEARLY_MODEL4_PACKAGE.md"
)
$ErrorActionPreference="Stop"
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot "seasonal_gate_helpers.ps1")
$repo=(Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$outputsRoot=(Resolve-Path (Join-Path $repo "outputs")).Path
$expectedSource="9141137A9550F3394DE85E1725E018671B4F2A2FF0F43A3EF23F9FB1238CD302"
$expectedProfile="06AE8127CF2719D7D3A19FEE069ECA3D50B83B3B0329C04F7B08E5F9135AFA5A"
function Resolve-RepoPath([string]$path){if([IO.Path]::IsPathRooted($path)){return $path};return Join-Path $repo $path}
function Clear-OutputDirSafe([string]$path){
   if(Test-Path -LiteralPath $path){$resolved=(Resolve-Path $path).Path;if(!$resolved.StartsWith($outputsRoot+'\',[StringComparison]::OrdinalIgnoreCase)){throw "Refusing to clear outside outputs: $resolved"};Remove-Item $resolved -Recurse -Force}
   New-Item -ItemType Directory -Path $path -Force|Out-Null
}
$source=(Resolve-Path (Resolve-RepoPath $SourcePath)).Path
$profile=(Resolve-Path (Resolve-RepoPath $ProfilePath)).Path
if((Get-FileHash $source -Algorithm SHA256).Hash-ne$expectedSource){throw "Source identity changed."}
if((Get-FileHash $profile -Algorithm SHA256).Hash-ne$expectedProfile){throw "Profile identity changed."}
$inputs=Import-SetInputs -Path $profile
if($inputs.Keys.Count-ne 105){throw "Expected 105 frozen profile inputs."}
$windows=[Collections.Generic.List[object]]::new()
foreach($year in 2015..2025){$windows.Add([pscustomobject]@{Name=[string]$year;From="$year.01.01";To="$year.12.31";Completed=$true})|Out-Null}
$windows.Add([pscustomobject]@{Name="2026_ytd";From="2026.01.01";To="2026.07.16";Completed=$false})|Out-Null
$package=Resolve-RepoPath $PackageDir;Clear-OutputDirSafe $package
$configDir=Join-Path $package "configs";$profileDir=Join-Path $package "profiles";$reportDir=Join-Path $package "reports_here";$sourceDir=Join-Path $package "source"
New-Item -ItemType Directory -Path $configDir,$profileDir,$reportDir,$sourceDir -Force|Out-Null
Copy-Item $source (Join-Path $sourceDir "Professional_XAUUSD_EA.mq5") -Force
Copy-Item $profile (Join-Path $profileDir "RC2_MOMENTUM_RISK_EXTENSION_RESEARCH_PROFILE.set") -Force
$queue=[Collections.Generic.List[object]]::new();$manifest=[Collections.Generic.List[object]]::new();$rank=0
foreach($window in $windows){
   $rank++;$configName="{0:000}_mre_mo020_{1}_m4.ini"-f$rank,$window.Name;$reportName="mre_mo020_$($window.Name)_m4"
   Write-SeasonalTesterConfig -Path (Join-Path $configDir $configName) -ReportRoot $reportDir -ReportName $reportName -From $window.From -To $window.To -Inputs $inputs -Model 4 -Deposit 10000
   $queue.Add([pscustomobject]@{QueueRank=$rank;Candidate="mre_mo020_center";Window=$window.Name;CompletedYear=$window.Completed;From=$window.From;To=$window.To;Model=4;Deposit=10000;ExpectedReportName=$reportName;PackageConfig="$PackageDir\configs\$configName";ReportDestination="$PackageDir\reports_here\$reportName";ProfileSha256=$expectedProfile;SourceSha256=$expectedSource})|Out-Null
   $manifest.Add([pscustomobject]@{QueueRank=$rank;Candidate="mre_mo020_center";Window=$window.Name;Model=4;PackageConfig="$PackageDir\configs\$configName";ExpectedReportName=$reportName;ReportDestination="$PackageDir\reports_here\$reportName";ProfileSha256=$expectedProfile;StopRule="Apply the frozen annual restart gate; do not retune after results."})|Out-Null
}
$queue|Export-Csv (Resolve-RepoPath $QueuePath) -NoTypeInformation -Encoding ASCII
$manifest|Export-Csv (Resolve-RepoPath $ManifestPath) -NoTypeInformation -Encoding ASCII
@("# RC2 Momentum-Risk Extension Yearly Model4 Package","","Exact frozen source/profile, 2015-2025 calendar restarts and 2026 YTD, each from `$10,000`.","","- Source SHA-256: $expectedSource","- Profile SHA-256: $expectedProfile","- Configurations: 12","- Real-account trading: disabled","","See `outputs/RC2_MOMENTUM_RISK_EXTENSION_MONEY_READINESS_CONTRACT.md` for the frozen gate.")|Set-Content (Resolve-RepoPath $MarkdownPath) -Encoding ASCII
[pscustomobject]@{Status="READY";Configurations=12;SourceSha256=$expectedSource;ProfileSha256=$expectedProfile;RealTrading=$false}
