param(
   [string]$SourcePath = "work\Professional_XAUUSD_Reversion_D1_Momentum_Cap_Signal_Range_Gate.mq5",
   [string]$BaseProfilePath = "outputs\REVERSION_D1_MOMENTUM_CAP_CENTER_PROFILE.set",
   [string]$ContractPath = "outputs\RDMC_SIGNAL_RANGE_GATE_REPAIR_CONTRACT.md",
   [string]$PackageDir = "outputs\rdmc_signal_range_gate_repair_model1_package",
   [string]$QueuePath = "outputs\RDMC_SIGNAL_RANGE_GATE_REPAIR_MODEL1_QUEUE.csv",
   [string]$ManifestPath = "outputs\RDMC_SIGNAL_RANGE_GATE_REPAIR_MODEL1_MANIFEST.csv",
   [string]$MarkdownPath = "outputs\RDMC_SIGNAL_RANGE_GATE_REPAIR_MODEL1_PACKAGE.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "seasonal_gate_helpers.ps1")

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$outputsRoot = (Resolve-Path (Join-Path $repo "outputs")).Path
$expectedSourceHash = "32DE39C13DBE06A6AE2BD733ED2183D7103C003884F08DD13024FDEE18BAD241"
$expectedBaseProfileHash = "BC3ED745E8CEF680BF6785597044A7A24E488E1F45E498E1AC4EC7BCE3B5AEFC"

function Resolve-RepoPath([string]$Path) {
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}

function Reset-OutputDirectory([string]$Path) {
   if(Test-Path -LiteralPath $Path) {
      $resolved = (Resolve-Path -LiteralPath $Path).Path
      if(!$resolved.StartsWith($outputsRoot, [StringComparison]::OrdinalIgnoreCase)) {
         throw "Refusing to clear non-output directory: $resolved"
      }
      Remove-Item -LiteralPath $resolved -Recurse -Force
   }
   New-Item -ItemType Directory -Path $Path -Force | Out-Null
}

$source = (Resolve-Path -LiteralPath (Resolve-RepoPath $SourcePath)).Path
$baseProfile = (Resolve-Path -LiteralPath (Resolve-RepoPath $BaseProfilePath)).Path
$contract = (Resolve-Path -LiteralPath (Resolve-RepoPath $ContractPath)).Path
$sourceHash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
$baseProfileHash = (Get-FileHash -LiteralPath $baseProfile -Algorithm SHA256).Hash
$contractHash = (Get-FileHash -LiteralPath $contract -Algorithm SHA256).Hash
if($sourceHash -ne $expectedSourceHash) { throw "Research source identity changed: $sourceHash" }
if($baseProfileHash -ne $expectedBaseProfileHash) { throw "Parent profile identity changed: $baseProfileHash" }

$variants = @(
   [pscustomobject]@{Name="srg_control";Enabled="false";Minimum="1.25";Role="control"},
   [pscustomobject]@{Name="srg_min100";Enabled="true";Minimum="1.00";Role="loose_neighbor"},
   [pscustomobject]@{Name="srg_min125_center";Enabled="true";Minimum="1.25";Role="center"},
   [pscustomobject]@{Name="srg_min150";Enabled="true";Minimum="1.50";Role="strict_neighbor"}
)
$windows = @(
   [pscustomobject]@{Name="year_2019";From="2019.01.01";To="2019.12.31"},
   [pscustomobject]@{Name="year_2022";From="2022.01.01";To="2022.12.31"}
)
$stopRule = "Center and one adjacent threshold must each be profitable with at least 18 trades in both 2019 and 2022, and beat control combined; otherwise stop before Model4."

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
      @("InpPortfolioMagic","26072231"),
      @("InpRVMagicNumber","26072232"),
      @("InpMOMagicNumber","26072233"),
      @("InpMOUseMinimumSignalRangeGate",$variant.Enabled),
      @("InpMOMinimumSignalRangeATR",$variant.Minimum),
      @("InpLogTrades","false"),
      @("InpShowDashboard","false"),
      @("InpEvidenceSourceHash",$sourceHash),
      @("InpEvidenceRunLabel","rdmc_signal_range_gate_repair_model1")
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
         SourceSha256=$sourceHash;BaseProfileSha256=$baseProfileHash;ContractSha256=$contractHash
         SignalRangeGateEnabled=$variant.Enabled;MinimumSignalRangeATR=$variant.Minimum
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
   "# RDMC Signal-Range Gate Repair Model1 Package","",
   "- Source SHA-256: ``$sourceHash``",
   "- Parent profile SHA-256: ``$baseProfileHash``",
   "- Contract SHA-256: ``$contractHash``",
   "- Profiles: ``$($variants.Count)``",
   "- Configurations: ``$rank``","",
   "Frozen early-stop gate: $stopRule"
) | Set-Content -LiteralPath (Resolve-RepoPath $MarkdownPath) -Encoding ASCII

[pscustomobject]@{
   Status="READY";SourceSha256=$sourceHash;ContractSha256=$contractHash
   Profiles=$variants.Count;Configurations=$rank;PackageDir=$PackageDir
}
