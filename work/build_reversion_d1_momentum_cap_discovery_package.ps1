param(
   [string]$SourcePath = "work\Professional_XAUUSD_Reversion_D1_Momentum_Cap_Portfolio.mq5",
   [string]$BaseProfilePath = "outputs\OPERATIONAL_HARDENING_RC2_FORWARD_DEMO_PROFILE.set",
   [string]$ContractPath = "outputs\REVERSION_D1_MOMENTUM_CAP_CONTRACT.md",
   [string]$PackageDir = "outputs\reversion_d1_momentum_cap_discovery_model1_package",
   [string]$QueuePath = "outputs\REVERSION_D1_MOMENTUM_CAP_DISCOVERY_MODEL1_QUEUE.csv",
   [string]$ManifestPath = "outputs\REVERSION_D1_MOMENTUM_CAP_DISCOVERY_MODEL1_MANIFEST.csv",
   [string]$MarkdownPath = "outputs\REVERSION_D1_MOMENTUM_CAP_DISCOVERY_MODEL1_PACKAGE.md"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot "seasonal_gate_helpers.ps1")
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$outputsRoot = (Resolve-Path (Join-Path $repo "outputs")).Path
$expectedSourceHash = "8B1761EC5F1310C0A961DE30495D4CF52969490A97392721B21424F7D7B8DA2B"

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
if($sourceHash -ne $expectedSourceHash) { throw "Research source identity changed: $sourceHash" }
$baseHash = (Get-FileHash -LiteralPath $baseProfile -Algorithm SHA256).Hash
$contractHash = (Get-FileHash -LiteralPath $contract -Algorithm SHA256).Hash

$variants = @(
   [pscustomobject]@{Name="rdmc_released_control";DIEdge="-12.0";CapEnabled="false";CapPercent="12.0";Role="released_control"},
   [pscustomobject]@{Name="rdmc_di10_parent";DIEdge="-10.0";CapEnabled="false";CapPercent="12.0";Role="di_parent"},
   [pscustomobject]@{Name="rdmc_di10_cap10";DIEdge="-10.0";CapEnabled="true";CapPercent="10.0";Role="strict_neighbor"},
   [pscustomobject]@{Name="rdmc_di10_cap12_center";DIEdge="-10.0";CapEnabled="true";CapPercent="12.0";Role="center"},
   [pscustomobject]@{Name="rdmc_di10_cap14";DIEdge="-10.0";CapEnabled="true";CapPercent="14.0";Role="loose_neighbor"}
)
$windows = [Collections.Generic.List[object]]::new()
foreach($year in 2015..2020) {
   $windows.Add([pscustomobject]@{Name="year_$year";From="$year.01.01";To="$year.12.31"}) | Out-Null
}
$windows.Add([pscustomobject]@{Name="continuous_2015_2020";From="2015.01.01";To="2020.12.31"}) | Out-Null
$stopRule = "Every 2015-2020 year positive; continuous PF>=1.50, trades>=180, DD<=2.80%; net>=DI parent; DD<=DI parent; center plus one adjacent cap pass. No post-2020 data."

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
      @("InpPortfolioMagic","26072131"),
      @("InpRVMagicNumber","26072132"),
      @("InpMOMagicNumber","26072133"),
      @("InpRVUseDIEdgeGate","true"),
      @("InpRVMinimumDIEdge",$variant.DIEdge),
      @("InpRVUseD1MomentumCap",$variant.CapEnabled),
      @("InpRVD1MomentumLookbackBars","126"),
      @("InpRVMaximumAbsoluteD1MomentumPercent",$variant.CapPercent),
      @("InpLogTrades","false"),
      @("InpShowDashboard","false"),
      @("InpEvidenceSourceHash",$sourceHash),
      @("InpEvidenceRunLabel","reversion_d1_momentum_cap_discovery_model1")
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
         QueueRank=$rank;Candidate=$variant.Name;Role=$variant.Role;Window=$window.Name
         From=$window.From;To=$window.To;Model=1;Deposit=10000
         Config="configs\$configName";ExpectedReportName=$reportName
         ProfileSnapshot="profiles\$profileName";ProfileSha256=$profileHash
         SourceSha256=$sourceHash;BaseProfileSha256=$baseHash;ContractSha256=$contractHash
         RVMinimumDIEdge=$variant.DIEdge;D1MomentumCapEnabled=$variant.CapEnabled
         D1MomentumLookbackBars=126;MaximumAbsoluteD1MomentumPercent=$variant.CapPercent
         StopRule=$stopRule
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
   "# Reversion D1 Momentum-Cap Discovery Model1 Package","",
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
