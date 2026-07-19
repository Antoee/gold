[CmdletBinding()]
param(
   [string]$ParentPackage = 'outputs\three_lane_adaptive_trend_model4_broad_package',
   [string]$PackageDir = 'outputs\three_lane_adaptive_trend_model4_annual_package',
   [string]$ManifestPath = 'outputs\THREE_LANE_ADAPTIVE_TREND_MODEL4_ANNUAL_MANIFEST.csv',
   [string]$ContractPath = 'outputs\THREE_LANE_ADAPTIVE_TREND_MODEL4_ANNUAL_CONTRACT.md'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'seasonal_gate_helpers.ps1')
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

function Resolve-RepoPath([string]$Path) {
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}

function Read-Profile([string]$Path) {
   $inputs = [ordered]@{}
   foreach($line in Get-Content -LiteralPath $Path) {
      if($line -match '^([^;=]+)=') {
         if($inputs.Contains($Matches[1])) { throw "Duplicate profile input: $($Matches[1])" }
         $inputs[$Matches[1]] = $line
      }
   }
   if($inputs.Count -lt 170) { throw "Unexpectedly small profile: $Path" }
   return $inputs
}

$parent = Resolve-RepoPath $ParentPackage
$parentSource = Join-Path $parent 'source\Professional_XAUUSD_EA.mq5'
$parentProfile = Join-Path $parent 'profiles\tlat_di12_atb10_center.set'
$expectedSourceHash = '51AE67DB56C3B584E8DA3A64C4B43ECAAE9ACE7E96541C22C9C5AC10E389FABB'
if((Get-FileHash -LiteralPath $parentSource -Algorithm SHA256).Hash.ToUpperInvariant() -ne $expectedSourceHash) {
   throw 'Parent source identity changed.'
}
$profileHash = (Get-FileHash -LiteralPath $parentProfile -Algorithm SHA256).Hash.ToUpperInvariant()
$inputs = Read-Profile $parentProfile

$windows = [Collections.Generic.List[object]]::new()
foreach($year in 2015..2025) {
   $windows.Add([pscustomobject]@{Name="year_$year";From="$year.01.01";To="$year.12.31"}) | Out-Null
}
$windows.Add([pscustomobject]@{Name='ytd_2026';From='2026.01.01';To='2026.07.12'}) | Out-Null

$package = Resolve-RepoPath $PackageDir
if(Test-Path -LiteralPath $package) { Remove-Item -LiteralPath $package -Recurse -Force }
$configDir = Join-Path $package 'configs'
$profileDir = Join-Path $package 'profiles'
$reportDir = Join-Path $package 'reports_here'
$sourceDir = Join-Path $package 'source'
New-Item -ItemType Directory -Path $configDir,$profileDir,$reportDir,$sourceDir -Force | Out-Null
Copy-Item -LiteralPath $parentSource -Destination (Join-Path $sourceDir 'Professional_XAUUSD_EA.mq5') -Force
Copy-Item -LiteralPath $parentProfile -Destination (Join-Path $profileDir 'tlat_di12_atb10_center.set') -Force

$rows = [Collections.Generic.List[object]]::new()
$rank = 0
foreach($window in $windows) {
   $rank++
   $reportName = "tlat_di12_atb10_center_$($window.Name)_m4"
   $configName = ('{0:D3}_{1}.ini' -f $rank,$reportName)
   $configPath = Join-Path $configDir $configName
   Write-SeasonalTesterConfig -Path $configPath -ReportRoot $reportDir -ReportName $reportName -From $window.From -To $window.To -Inputs $inputs -Model 4 -Deposit 10000
   $rows.Add([pscustomobject][ordered]@{
      QueueRank=$rank
      Profile='tlat_di12_atb10_center'
      Candidate='tlat_di12_atb10_center'
      Phase='annual_model4'
      Set='three_lane'
      Window=$window.Name
      From=$window.From
      To=$window.To
      Model=4
      Deposit=10000
      PackageConfig="$PackageDir\configs\$configName"
      ExpectedReportName=$reportName
      ReportDestination="$PackageDir\reports_here\$reportName"
      ConfigSha256=(Get-FileHash -LiteralPath $configPath -Algorithm SHA256).Hash.ToUpperInvariant()
      SourceSha256=$expectedSourceHash
      ProfileSha256=$profileHash
   }) | Out-Null
}

$manifest = Resolve-RepoPath $ManifestPath
$rows | Export-Csv -LiteralPath $manifest -NoTypeInformation -Encoding ASCII
$manifestHash = (Get-FileHash -LiteralPath $manifest -Algorithm SHA256).Hash.ToUpperInvariant()
@(
   '# Three-Lane Adaptive Trend Annual Model 4 Gate',
   '',
   '**Status: FROZEN ANNUAL REAL-TICK GATE / NO CANDIDATE CHANGE.**',
   '',
   "- Source SHA-256: ``$expectedSourceHash``",
   "- Profile SHA-256: ``$profileHash``",
   "- Manifest SHA-256: ``$manifestHash``",
   '- Profile is byte-identical to the center that passed critical and broad Model 4 gates.',
   '- Fresh USD 10,000 Model 4 restart for each complete year 2015-2025 and 2026 YTD through July 12.',
   '- Every window must have positive net profit, PF above 1.00, nonzero activity, and equity drawdown no more than 2.5%.',
   '- A red, flat, missing, unparsed, or identity-mismatched window rejects promotion without tuning.'
) | Set-Content -LiteralPath (Resolve-RepoPath $ContractPath) -Encoding ASCII

[pscustomobject]@{
   Status='FROZEN'
   Configurations=$rows.Count
   SourceSha256=$expectedSourceHash
   ProfileSha256=$profileHash
   ManifestSha256=$manifestHash
}
