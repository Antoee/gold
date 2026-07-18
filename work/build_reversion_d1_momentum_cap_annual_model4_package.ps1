param(
   [string]$SourcePath = "work\Professional_XAUUSD_Reversion_D1_Momentum_Cap_Portfolio.mq5",
   [string]$ProfilePath = "outputs\reversion_d1_momentum_cap_discovery_model1_package\profiles\rdmc_di10_cap12_center.set",
   [string]$Model4ContractPath = "outputs\REVERSION_D1_MOMENTUM_CAP_MODEL4_CONTRACT.md",
   [string]$AnnualContractPath = "outputs\REVERSION_D1_MOMENTUM_CAP_ANNUAL_MODEL4_CONTRACT.md",
   [string]$PackageDir = "outputs\reversion_d1_momentum_cap_annual_model4_package",
   [string]$QueuePath = "outputs\REVERSION_D1_MOMENTUM_CAP_ANNUAL_MODEL4_QUEUE.csv",
   [string]$ManifestPath = "outputs\REVERSION_D1_MOMENTUM_CAP_ANNUAL_MODEL4_MANIFEST.csv",
   [string]$MarkdownPath = "outputs\REVERSION_D1_MOMENTUM_CAP_ANNUAL_MODEL4_PACKAGE.md"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot "seasonal_gate_helpers.ps1")
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$outputsRoot = (Resolve-Path (Join-Path $repo "outputs")).Path
$expectedSourceHash = "8B1761EC5F1310C0A961DE30495D4CF52969490A97392721B21424F7D7B8DA2B"
$expectedProfileHash = "BC3ED745E8CEF680BF6785597044A7A24E488E1F45E498E1AC4EC7BCE3B5AEFC"
$expectedModel4ContractHash = "5CB8F52B08B9883E2BF0CC980C70B8D8ED99194D75508298696C4B009B0ADB4A"

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
$profile = (Resolve-Path -LiteralPath (Resolve-RepoPath $ProfilePath)).Path
$model4Contract = (Resolve-Path -LiteralPath (Resolve-RepoPath $Model4ContractPath)).Path
$annualContract = (Resolve-Path -LiteralPath (Resolve-RepoPath $AnnualContractPath)).Path
$sourceHash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
$profileHash = (Get-FileHash -LiteralPath $profile -Algorithm SHA256).Hash
$model4ContractHash = (Get-FileHash -LiteralPath $model4Contract -Algorithm SHA256).Hash
$annualContractHash = (Get-FileHash -LiteralPath $annualContract -Algorithm SHA256).Hash
if($sourceHash -ne $expectedSourceHash) { throw "Source identity changed." }
if($profileHash -ne $expectedProfileHash) { throw "Profile identity changed." }
if($model4ContractHash -ne $expectedModel4ContractHash) { throw "Model4 contract identity changed." }

$windows = [Collections.Generic.List[object]]::new()
foreach($year in 2015..2025) {
   $windows.Add([pscustomobject]@{Name="year_$year";From="$year.01.01";To="$year.12.31"}) | Out-Null
}
$windows.Add([pscustomobject]@{Name="year_2026_ytd";From="2026.01.01";To="2026.07.16"}) | Out-Null
$stopRule = "No negative year; >=10 positive years; summed trades>=300; every DD<=2.50%; every max loss streak<=8."

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
   $configName = "{0:000}_rdmc_di10_cap12_center_{1}_m4.ini" -f $rank,$window.Name
   $reportName = "rdmc_di10_cap12_center_$($window.Name)_m4"
   Write-SeasonalTesterConfig -Path (Join-Path $configDir $configName) `
      -ReportRoot $reportDir -ReportName $reportName -From $window.From -To $window.To `
      -Inputs $inputs -Model 4 -Deposit 10000 -Period 60
   $queue.Add([pscustomobject]@{
      QueueRank=$rank;Candidate="rdmc_di10_cap12_center";Window=$window.Name
      From=$window.From;To=$window.To;Model=4;Deposit=10000
      Config="configs\$configName";ExpectedReportName=$reportName
      ProfileSnapshot="profiles\rdmc_di10_cap12_center.set";ProfileSha256=$profileHash
      SourceSha256=$sourceHash;Model4ContractSha256=$model4ContractHash
      AnnualContractSha256=$annualContractHash;StopRule=$stopRule
   }) | Out-Null
   $manifest.Add([pscustomobject]@{
      QueueRank=$rank;Candidate="rdmc_di10_cap12_center";Window=$window.Name;Model=4;Deposit=10000
      PackageConfig="$PackageDir\configs\$configName";SourceConfig="$PackageDir\configs\$configName"
      ExpectedReportName=$reportName;ReportDestination="$PackageDir\reports_here\$reportName"
      ProfileSha256=$profileHash;SourceSha256=$sourceHash
      Model4ContractSha256=$model4ContractHash;AnnualContractSha256=$annualContractHash;StopRule=$stopRule
   }) | Out-Null
}

$queue | Export-Csv -LiteralPath (Resolve-RepoPath $QueuePath) -NoTypeInformation -Encoding ASCII
$manifest | Export-Csv -LiteralPath (Resolve-RepoPath $ManifestPath) -NoTypeInformation -Encoding ASCII
@(
   "# Reversion D1 Momentum-Cap Annual Model4 Package","",
   "- Source SHA-256: ``$sourceHash``",
   "- Profile SHA-256: ``$profileHash``",
   "- Annual contract SHA-256: ``$annualContractHash``",
   "- Configurations: ``$rank``","",
   "Frozen gate: $stopRule"
) | Set-Content -LiteralPath (Resolve-RepoPath $MarkdownPath) -Encoding ASCII

[pscustomobject]@{Status="READY";Configurations=$rank;SourceSha256=$sourceHash;ProfileSha256=$profileHash;AnnualContractSha256=$annualContractHash}
