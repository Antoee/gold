param(
   [string]$SourcePath = "work\Professional_XAUUSD_Reversion_D1_Momentum_Cap_Portfolio.mq5",
   [string]$ProfilePath = "outputs\reversion_d1_momentum_cap_discovery_model1_package\profiles\rdmc_di10_cap12_center.set",
   [string]$DiscoveryContractPath = "outputs\REVERSION_D1_MOMENTUM_CAP_CONTRACT.md",
   [string]$HoldoutContractPath = "outputs\REVERSION_D1_MOMENTUM_CAP_HOLDOUT_CONTRACT.md",
   [string]$PackageDir = "outputs\reversion_d1_momentum_cap_holdout_model1_package",
   [string]$QueuePath = "outputs\REVERSION_D1_MOMENTUM_CAP_HOLDOUT_MODEL1_QUEUE.csv",
   [string]$ManifestPath = "outputs\REVERSION_D1_MOMENTUM_CAP_HOLDOUT_MODEL1_MANIFEST.csv",
   [string]$MarkdownPath = "outputs\REVERSION_D1_MOMENTUM_CAP_HOLDOUT_MODEL1_PACKAGE.md"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot "seasonal_gate_helpers.ps1")
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$outputsRoot = (Resolve-Path (Join-Path $repo "outputs")).Path
$expectedSourceHash = "8B1761EC5F1310C0A961DE30495D4CF52969490A97392721B21424F7D7B8DA2B"
$expectedProfileHash = "BC3ED745E8CEF680BF6785597044A7A24E488E1F45E498E1AC4EC7BCE3B5AEFC"
$expectedDiscoveryContractHash = "0D1199E9BBDF4A9E02AE10359F912976246168FDA53A1917768BCADDD535AA67"

function Resolve-RepoPath([string]$Path) {
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}

function Reset-OutputDirectory([string]$Path) {
   if(Test-Path -LiteralPath $Path) {
      $resolved = (Resolve-Path -LiteralPath $Path).Path
      if(!$resolved.StartsWith($outputsRoot, [StringComparison]::OrdinalIgnoreCase)) {
         throw "Refusing to clear: $resolved"
      }
      Remove-Item -LiteralPath $resolved -Recurse -Force
   }
   New-Item -ItemType Directory -Path $Path -Force | Out-Null
}

$source = (Resolve-Path -LiteralPath (Resolve-RepoPath $SourcePath)).Path
$profile = (Resolve-Path -LiteralPath (Resolve-RepoPath $ProfilePath)).Path
$discoveryContract = (Resolve-Path -LiteralPath (Resolve-RepoPath $DiscoveryContractPath)).Path
$holdoutContract = (Resolve-Path -LiteralPath (Resolve-RepoPath $HoldoutContractPath)).Path
$sourceHash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
$profileHash = (Get-FileHash -LiteralPath $profile -Algorithm SHA256).Hash
$discoveryContractHash = (Get-FileHash -LiteralPath $discoveryContract -Algorithm SHA256).Hash
$holdoutContractHash = (Get-FileHash -LiteralPath $holdoutContract -Algorithm SHA256).Hash
if($sourceHash -ne $expectedSourceHash) { throw "Source identity changed: $sourceHash" }
if($profileHash -ne $expectedProfileHash) { throw "Center profile identity changed: $profileHash" }
if($discoveryContractHash -ne $expectedDiscoveryContractHash) { throw "Discovery contract identity changed." }

$windows = @(
   [pscustomobject]@{Name="holdout_2021_2023";From="2021.01.01";To="2023.12.31"},
   [pscustomobject]@{Name="holdout_2024_2026";From="2024.01.01";To="2026.07.16"},
   [pscustomobject]@{Name="continuous_2021_2026";From="2021.01.01";To="2026.07.16"}
)
$stopRule = "Both disjoint windows net>0, PF>=1.10, DD<=2.80%; continuous net>0, PF>=1.30, trades>=120, DD<=2.80%. Exact center only."

$package = Resolve-RepoPath $PackageDir
Reset-OutputDirectory $package
$configDir = Join-Path $package "configs"
$profileDir = Join-Path $package "profiles"
$reportDir = Join-Path $package "reports_here"
$sourceDir = Join-Path $package "source"
New-Item -ItemType Directory -Path $configDir,$profileDir,$reportDir,$sourceDir -Force | Out-Null
Copy-Item -LiteralPath $source -Destination (Join-Path $sourceDir "Professional_XAUUSD_EA.mq5") -Force
Copy-Item -LiteralPath $profile -Destination (Join-Path $profileDir "rdmc_di10_cap12_center.set") -Force
$inputs = Import-SetInputs -Path $profile

$queue = [Collections.Generic.List[object]]::new()
$manifest = [Collections.Generic.List[object]]::new()
$rank = 0
foreach($window in $windows) {
   $rank++
   $configName = "{0:000}_rdmc_di10_cap12_center_{1}_m1.ini" -f $rank,$window.Name
   $reportName = "rdmc_di10_cap12_center_$($window.Name)_m1"
   Write-SeasonalTesterConfig -Path (Join-Path $configDir $configName) `
      -ReportRoot $reportDir -ReportName $reportName -From $window.From -To $window.To `
      -Inputs $inputs -Model 1 -Deposit 10000 -Period 60
   $queue.Add([pscustomobject]@{
      QueueRank=$rank;Candidate="rdmc_di10_cap12_center";Window=$window.Name
      From=$window.From;To=$window.To;Model=1;Deposit=10000
      Config="configs\$configName";ExpectedReportName=$reportName
      ProfileSnapshot="profiles\rdmc_di10_cap12_center.set";ProfileSha256=$profileHash
      SourceSha256=$sourceHash;DiscoveryContractSha256=$discoveryContractHash
      HoldoutContractSha256=$holdoutContractHash;StopRule=$stopRule
   }) | Out-Null
   $manifest.Add([pscustomobject]@{
      QueueRank=$rank;Candidate="rdmc_di10_cap12_center";Window=$window.Name;Model=1;Deposit=10000
      PackageConfig="$PackageDir\configs\$configName";SourceConfig="$PackageDir\configs\$configName"
      ExpectedReportName=$reportName;ReportDestination="$PackageDir\reports_here\$reportName"
      ProfileSha256=$profileHash;SourceSha256=$sourceHash
      DiscoveryContractSha256=$discoveryContractHash;HoldoutContractSha256=$holdoutContractHash
      StopRule=$stopRule
   }) | Out-Null
}

$queue | Export-Csv -LiteralPath (Resolve-RepoPath $QueuePath) -NoTypeInformation -Encoding ASCII
$manifest | Export-Csv -LiteralPath (Resolve-RepoPath $ManifestPath) -NoTypeInformation -Encoding ASCII
@(
   "# Reversion D1 Momentum-Cap Holdout Model1 Package","",
   "- Source SHA-256: ``$sourceHash``",
   "- Profile SHA-256: ``$profileHash``",
   "- Discovery contract SHA-256: ``$discoveryContractHash``",
   "- Holdout contract SHA-256: ``$holdoutContractHash``",
   "- Configurations: ``$rank``","",
   "Frozen gate: $stopRule"
) | Set-Content -LiteralPath (Resolve-RepoPath $MarkdownPath) -Encoding ASCII

[pscustomobject]@{Status="READY";Configurations=$rank;SourceSha256=$sourceHash;ProfileSha256=$profileHash;HoldoutContractSha256=$holdoutContractHash}
