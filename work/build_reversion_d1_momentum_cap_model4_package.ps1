param(
   [string]$SourcePath = "work\Professional_XAUUSD_Reversion_D1_Momentum_Cap_Portfolio.mq5",
   [string]$ProfileDir = "outputs\reversion_d1_momentum_cap_discovery_model1_package\profiles",
   [string]$DiscoveryContractPath = "outputs\REVERSION_D1_MOMENTUM_CAP_CONTRACT.md",
   [string]$HoldoutContractPath = "outputs\REVERSION_D1_MOMENTUM_CAP_HOLDOUT_CONTRACT.md",
   [string]$Model4ContractPath = "outputs\REVERSION_D1_MOMENTUM_CAP_MODEL4_CONTRACT.md",
   [string]$PackageDir = "outputs\reversion_d1_momentum_cap_model4_package",
   [string]$QueuePath = "outputs\REVERSION_D1_MOMENTUM_CAP_MODEL4_QUEUE.csv",
   [string]$ManifestPath = "outputs\REVERSION_D1_MOMENTUM_CAP_MODEL4_MANIFEST.csv",
   [string]$MarkdownPath = "outputs\REVERSION_D1_MOMENTUM_CAP_MODEL4_PACKAGE.md"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot "seasonal_gate_helpers.ps1")
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$outputsRoot = (Resolve-Path (Join-Path $repo "outputs")).Path
$expectedSourceHash = "8B1761EC5F1310C0A961DE30495D4CF52969490A97392721B21424F7D7B8DA2B"
$expectedDiscoveryContractHash = "0D1199E9BBDF4A9E02AE10359F912976246168FDA53A1917768BCADDD535AA67"
$expectedHoldoutContractHash = "7214D856192510C1958BE7AA714DC8130A3E1ED145921FCDA85AE8210703EF76"

function Resolve-RepoPath([string]$Path) {
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}

function Reset-OutputDirectory([string]$Path) {
   if(Test-Path -LiteralPath $Path) {
      $resolved = (Resolve-Path -LiteralPath $Path).Path
      if(!$resolved.StartsWith($outputsRoot, [StringComparison]::OrdinalIgnoreCase)) { throw "Refusing to clear: $resolved" }
      Remove-Item -LiteralPath $resolved -Recurse -Force
   }
   New-Item -ItemType Directory -Path $Path -Force | Out-Null
}

$source = (Resolve-Path -LiteralPath (Resolve-RepoPath $SourcePath)).Path
$profilesRoot = (Resolve-Path -LiteralPath (Resolve-RepoPath $ProfileDir)).Path
$discoveryContract = (Resolve-Path -LiteralPath (Resolve-RepoPath $DiscoveryContractPath)).Path
$holdoutContract = (Resolve-Path -LiteralPath (Resolve-RepoPath $HoldoutContractPath)).Path
$model4Contract = (Resolve-Path -LiteralPath (Resolve-RepoPath $Model4ContractPath)).Path
$sourceHash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
$discoveryContractHash = (Get-FileHash -LiteralPath $discoveryContract -Algorithm SHA256).Hash
$holdoutContractHash = (Get-FileHash -LiteralPath $holdoutContract -Algorithm SHA256).Hash
$model4ContractHash = (Get-FileHash -LiteralPath $model4Contract -Algorithm SHA256).Hash
if($sourceHash -ne $expectedSourceHash) { throw "Source identity changed." }
if($discoveryContractHash -ne $expectedDiscoveryContractHash) { throw "Discovery contract identity changed." }
if($holdoutContractHash -ne $expectedHoldoutContractHash) { throw "Holdout contract identity changed." }

$profiles = @(
   [pscustomobject]@{Name="rdmc_di10_parent";Hash="9A5C91BCB4013C510D9AB1EB65083D302C7DF27C7FFA5B01C0A8F98C0EF22C66";Role="parent"},
   [pscustomobject]@{Name="rdmc_di10_cap12_center";Hash="BC3ED745E8CEF680BF6785597044A7A24E488E1F45E498E1AC4EC7BCE3B5AEFC";Role="center"},
   [pscustomobject]@{Name="rdmc_di10_cap14";Hash="0271FB8073C2282D8BDE1FDBC7823C9B6F7F34EA5B44E67A1304C191D806AA7B";Role="neighbor"}
)
$windows = @(
   [pscustomobject]@{Name="discovery_2015_2020";From="2015.01.01";To="2020.12.31"},
   [pscustomobject]@{Name="holdout_2021_2023";From="2021.01.01";To="2023.12.31"},
   [pscustomobject]@{Name="holdout_2024_2026";From="2024.01.01";To="2026.07.16"},
   [pscustomobject]@{Name="continuous_2021_2026";From="2021.01.01";To="2026.07.16"},
   [pscustomobject]@{Name="continuous_2015_2026";From="2015.01.01";To="2026.07.16"}
)
$stopRule = "Each disjoint era net>0 and PF>=1.10; full PF>=1.40, trades>=300, DD<=3.50%; net>=parent; DD<=parent; cap14 neighbor passes."

$package = Resolve-RepoPath $PackageDir
Reset-OutputDirectory $package
$configDir = Join-Path $package "configs"
$packageProfileDir = Join-Path $package "profiles"
$reportDir = Join-Path $package "reports_here"
$sourceDir = Join-Path $package "source"
New-Item -ItemType Directory -Path $configDir,$packageProfileDir,$reportDir,$sourceDir -Force | Out-Null
Copy-Item -LiteralPath $source -Destination (Join-Path $sourceDir "Professional_XAUUSD_EA.mq5") -Force

$queue = [Collections.Generic.List[object]]::new()
$manifest = [Collections.Generic.List[object]]::new()
$rank = 0
foreach($profile in $profiles) {
   $profilePath = Join-Path $profilesRoot "$($profile.Name).set"
   if((Get-FileHash -LiteralPath $profilePath -Algorithm SHA256).Hash -ne $profile.Hash) { throw "Profile identity changed: $($profile.Name)" }
   Copy-Item -LiteralPath $profilePath -Destination (Join-Path $packageProfileDir "$($profile.Name).set") -Force
   $inputs = Import-SetInputs -Path $profilePath
   foreach($window in $windows) {
      $rank++
      $configName = "{0:000}_{1}_{2}_m4.ini" -f $rank,$profile.Name,$window.Name
      $reportName = "$($profile.Name)_$($window.Name)_m4"
      Write-SeasonalTesterConfig -Path (Join-Path $configDir $configName) `
         -ReportRoot $reportDir -ReportName $reportName -From $window.From -To $window.To `
         -Inputs $inputs -Model 4 -Deposit 10000 -Period 60
      $queue.Add([pscustomobject]@{
         QueueRank=$rank;Candidate=$profile.Name;Role=$profile.Role;Window=$window.Name
         From=$window.From;To=$window.To;Model=4;Deposit=10000
         Config="configs\$configName";ExpectedReportName=$reportName
         ProfileSnapshot="profiles\$($profile.Name).set";ProfileSha256=$profile.Hash
         SourceSha256=$sourceHash;DiscoveryContractSha256=$discoveryContractHash
         HoldoutContractSha256=$holdoutContractHash;Model4ContractSha256=$model4ContractHash;StopRule=$stopRule
      }) | Out-Null
      $manifest.Add([pscustomobject]@{
         QueueRank=$rank;Candidate=$profile.Name;Window=$window.Name;Model=4;Deposit=10000
         PackageConfig="$PackageDir\configs\$configName";SourceConfig="$PackageDir\configs\$configName"
         ExpectedReportName=$reportName;ReportDestination="$PackageDir\reports_here\$reportName"
         ProfileSha256=$profile.Hash;SourceSha256=$sourceHash
         DiscoveryContractSha256=$discoveryContractHash;HoldoutContractSha256=$holdoutContractHash
         Model4ContractSha256=$model4ContractHash;StopRule=$stopRule
      }) | Out-Null
   }
}

$queue | Export-Csv -LiteralPath (Resolve-RepoPath $QueuePath) -NoTypeInformation -Encoding ASCII
$manifest | Export-Csv -LiteralPath (Resolve-RepoPath $ManifestPath) -NoTypeInformation -Encoding ASCII
@(
   "# Reversion D1 Momentum-Cap Model4 Package","",
   "- Source SHA-256: ``$sourceHash``",
   "- Model4 contract SHA-256: ``$model4ContractHash``",
   "- Profiles: ``$($profiles.Count)``",
   "- Configurations: ``$rank``","",
   "Frozen gate: $stopRule"
) | Set-Content -LiteralPath (Resolve-RepoPath $MarkdownPath) -Encoding ASCII

[pscustomobject]@{Status="READY";Profiles=$profiles.Count;Configurations=$rank;SourceSha256=$sourceHash;Model4ContractSha256=$model4ContractHash}
