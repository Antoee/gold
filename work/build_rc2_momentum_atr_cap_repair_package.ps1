param(
   [string]$SourcePath = "work\Professional_XAUUSD_Operational_Hardening_Portfolio_RC2.mq5",
   [string]$BaseProfilePath = "outputs\OPERATIONAL_HARDENING_RC2_FORWARD_DEMO_PROFILE.set",
   [string]$ContractPath = "outputs\RC2_MOMENTUM_ATR_CAP_REPAIR_CONTRACT.md",
   [string]$PackageDir = "outputs\rc2_momentum_atr_cap_repair_model1_package",
   [string]$QueuePath = "outputs\RC2_MOMENTUM_ATR_CAP_REPAIR_MODEL1_QUEUE.csv",
   [string]$ManifestPath = "outputs\RC2_MOMENTUM_ATR_CAP_REPAIR_MODEL1_MANIFEST.csv",
   [string]$MarkdownPath = "outputs\RC2_MOMENTUM_ATR_CAP_REPAIR_MODEL1_PACKAGE.md"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot "seasonal_gate_helpers.ps1")
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$outputsRoot = (Resolve-Path (Join-Path $repo "outputs")).Path
$expectedSourceHash = "9141137A9550F3394DE85E1725E018671B4F2A2FF0F43A3EF23F9FB1238CD302"

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
   [pscustomobject]@{Name="mac_fixed_control"; MaximumATRPercent="2.50"},
   [pscustomobject]@{Name="mac_cap024"; MaximumATRPercent="0.24"},
   [pscustomobject]@{Name="mac_cap026"; MaximumATRPercent="0.26"},
   [pscustomobject]@{Name="mac_cap028"; MaximumATRPercent="0.28"}
)
$windows = @(
   [pscustomobject]@{Name="repair_2019_2020";From="2019.01.01";To="2020.12.31"},
   [pscustomobject]@{Name="continuous_2015_2020";From="2015.01.01";To="2020.12.31"}
)
$stopRule = "Both eras positive; continuous PF>=1.45, trades>=180, DD<=2.80%; net>=control; drawdown<=110% control; one passing adjacent cap. No post-2020 data."

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
      @("InpMOMaximumATRPercent",$variant.MaximumATRPercent),
      @("InpLogTrades","false"),
      @("InpShowDashboard","false"),
      @("InpEvidenceSourceHash",$sourceHash),
      @("InpEvidenceRunLabel","rc2_momentum_atr_cap_repair_model1")
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
         MaximumATRPercent=$variant.MaximumATRPercent;StopRule=$stopRule
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
   "# RC2 Momentum ATR-Cap Repair Model1 Package","",
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
