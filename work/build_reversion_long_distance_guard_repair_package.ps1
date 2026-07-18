param(
   [string]$SourcePath = "work\Professional_XAUUSD_Reversion_Long_Distance_Guard_Portfolio.mq5",
   [string]$BaseProfilePath = "outputs\OPERATIONAL_HARDENING_RC2_FORWARD_DEMO_PROFILE.set",
   [string]$ContractPath = "outputs\REVERSION_LONG_DISTANCE_GUARD_CONTRACT.md",
   [string]$PackageDir = "outputs\reversion_long_distance_guard_repair_model1_package",
   [string]$QueuePath = "outputs\REVERSION_LONG_DISTANCE_GUARD_REPAIR_MODEL1_QUEUE.csv",
   [string]$ManifestPath = "outputs\REVERSION_LONG_DISTANCE_GUARD_REPAIR_MODEL1_MANIFEST.csv",
   [string]$MarkdownPath = "outputs\REVERSION_LONG_DISTANCE_GUARD_REPAIR_MODEL1_PACKAGE.md"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot "seasonal_gate_helpers.ps1")
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$outputsRoot = (Resolve-Path (Join-Path $repo "outputs")).Path
$expectedSourceHash = "7E8D680807B0565992ECC9B98E15C636A86AF34742194687DBB64D61CE2EFD7A"

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
$baseProfile = (Resolve-Path -LiteralPath (Resolve-RepoPath $BaseProfilePath)).Path
$contract = (Resolve-Path -LiteralPath (Resolve-RepoPath $ContractPath)).Path
$sourceHash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
if($sourceHash -ne $expectedSourceHash) { throw "RC2 source identity changed: $sourceHash" }
$baseHash = (Get-FileHash -LiteralPath $baseProfile -Algorithm SHA256).Hash
$contractHash = (Get-FileHash -LiteralPath $contract -Algorithm SHA256).Hash

$variants = @(
   [pscustomobject]@{Name="rld_fixed_control"; Enabled="false"; MinimumDistanceATR="-10.0"},
   [pscustomobject]@{Name="rld_m12"; Enabled="true"; MinimumDistanceATR="-12.0"},
   [pscustomobject]@{Name="rld_m10"; Enabled="true"; MinimumDistanceATR="-10.0"},
   [pscustomobject]@{Name="rld_m8"; Enabled="true"; MinimumDistanceATR="-8.0"}
)
$windows = @(
   [pscustomobject]@{Name="repair_2019_2020";From="2019.01.01";To="2020.12.31"},
   [pscustomobject]@{Name="continuous_2015_2020";From="2015.01.01";To="2020.12.31"}
)
$stopRule = "Both eras positive; continuous PF>=1.45, trades>=180, DD<=2.80%; net>=control; drawdown<=control; one passing adjacent threshold. No post-2020 data."

$package = Resolve-RepoPath $PackageDir
Reset-OutputDirectory $package
$configDir = Join-Path $package "configs"
$profileDir = Join-Path $package "profiles"
$reportDir = Join-Path $package "reports_here"
$sourceDir = Join-Path $package "source"
New-Item -ItemType Directory -Path $configDir,$profileDir,$reportDir,$sourceDir -Force | Out-Null
Copy-Item -LiteralPath $source -Destination (Join-Path $sourceDir "Professional_XAUUSD_EA.mq5") -Force

$queue = [Collections.Generic.List[object]]::new()
$manifest = [Collections.Generic.List[object]]::new()
$rank = 0
foreach($variant in $variants) {
   $inputs = Import-SetInputs -Path $baseProfile
   foreach($pair in @(
      @("InpPortfolioMagic","26071931"),
      @("InpRVMagicNumber","26071932"),
      @("InpMOMagicNumber","26071933"),
      @("InpRVUseLongDistanceGate",$variant.Enabled),
      @("InpRVLongDistanceLookbackBars","200"),
      @("InpRVMinimumLongDistanceATR",$variant.MinimumDistanceATR),
      @("InpLogTrades","false"),
      @("InpShowDashboard","false"),
      @("InpEvidenceSourceHash",$sourceHash),
      @("InpEvidenceRunLabel","reversion_long_distance_guard_repair_model1")
   )) { Set-InputLine -Inputs $inputs -Name $pair[0] -Value $pair[1] }

   $profileName = "$($variant.Name).set"
   $profilePath = Join-Path $profileDir $profileName
   @($inputs.Keys | Sort-Object | ForEach-Object { $inputs[$_] }) |
      Set-Content -LiteralPath $profilePath -Encoding ASCII
   $profileHash = (Get-FileHash -LiteralPath $profilePath -Algorithm SHA256).Hash

   foreach($window in $windows) {
      $rank++
      $configName = "{0:000}_{1}_{2}_m1.ini" -f $rank,$variant.Name,$window.Name
      $reportName = "$($variant.Name)_$($window.Name)_m1"
      Write-SeasonalTesterConfig -Path (Join-Path $configDir $configName) `
         -ReportRoot $reportDir -ReportName $reportName -From $window.From -To $window.To `
         -Inputs $inputs -Model 1 -Deposit 10000 -Period 60
      $queue.Add([pscustomobject]@{
         QueueRank=$rank;Candidate=$variant.Name;Window=$window.Name;From=$window.From;To=$window.To
         Model=1;Deposit=10000;Config="configs\$configName";ExpectedReportName=$reportName
         ProfileSnapshot="profiles\$profileName";ProfileSha256=$profileHash;SourceSha256=$sourceHash
         BaseProfileSha256=$baseHash;ContractSha256=$contractHash
         GuardEnabled=$variant.Enabled;LookbackBars=200
         MinimumAlignedDistanceATR=$variant.MinimumDistanceATR;StopRule=$stopRule
      }) | Out-Null
      $manifest.Add([pscustomobject]@{
         QueueRank=$rank;Candidate=$variant.Name;Window=$window.Name;Model=1;Deposit=10000
         PackageConfig="$PackageDir\configs\$configName";SourceConfig="$PackageDir\configs\$configName"
         ExpectedReportName=$reportName;ReportDestination="$PackageDir\reports_here\$reportName"
         ProfileSha256=$profileHash;SourceSha256=$sourceHash;ContractSha256=$contractHash;StopRule=$stopRule
      }) | Out-Null
   }
}

$queue | Export-Csv -LiteralPath (Resolve-RepoPath $QueuePath) -NoTypeInformation -Encoding ASCII
$manifest | Export-Csv -LiteralPath (Resolve-RepoPath $ManifestPath) -NoTypeInformation -Encoding ASCII
@(
   "# Reversion Long-Distance Guard Repair Model1 Package","",
   "- Source SHA-256: ``$sourceHash``",
   "- Base-profile SHA-256: ``$baseHash``",
   "- Contract SHA-256: ``$contractHash``",
   "- Profiles: ``$($variants.Count)``",
   "- Configurations: ``$rank``",
   "- Data cutoff: ``2020-12-31``","",
   "Frozen gate: $stopRule"
) | Set-Content -LiteralPath (Resolve-RepoPath $MarkdownPath) -Encoding ASCII

[pscustomobject]@{
   Status="READY";SourceSha256=$sourceHash;ContractSha256=$contractHash
   Profiles=$variants.Count;Configurations=$rank;PackageDir=$PackageDir
}
