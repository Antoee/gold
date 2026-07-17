param(
   [string]$SourcePath = "work\Professional_XAUUSD_Transferable_Portfolio.mq5",
   [string]$PackageDir = "outputs\transferable_portfolio_growth_discovery_model1_package",
   [string]$QueueManifestPath = "outputs\TRANSFERABLE_PORTFOLIO_GROWTH_DISCOVERY_MODEL1_QUEUE.csv",
   [string]$PackageManifestPath = "outputs\TRANSFERABLE_PORTFOLIO_GROWTH_DISCOVERY_MODEL1_PACKAGE_MANIFEST.csv",
   [string]$MarkdownPath = "outputs\TRANSFERABLE_PORTFOLIO_GROWTH_DISCOVERY_MODEL1_PACKAGE.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "seasonal_gate_helpers.ps1")

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$outputsRoot = (Resolve-Path (Join-Path $repo "outputs")).Path
$expectedSourceHash = "5BADDE1BC7C1E8020E64F00793058AD5C6174370A866F5D3002FA1FA12248FC3"

function Resolve-RepoPath([string]$Path) {
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}

function Clear-OutputDirSafe([string]$Path) {
   if(Test-Path -LiteralPath $Path) {
      $resolved = (Resolve-Path -LiteralPath $Path).Path
      if(!$resolved.StartsWith($outputsRoot, [StringComparison]::OrdinalIgnoreCase)) {
         throw "Refusing to clear non-outputs directory: $resolved"
      }
      Remove-Item -LiteralPath $resolved -Recurse -Force
   }
   New-Item -ItemType Directory -Path $Path -Force | Out-Null
}

function Convert-SourceDefault([string]$Type, [string]$Value) {
   $trimmed = $Value.Trim()
   if($Type -eq "string") {
      if($trimmed.Length -lt 2 -or !$trimmed.StartsWith('"') -or !$trimmed.EndsWith('"')) {
         throw "Unsupported string default: $trimmed"
      }
      return $trimmed.Substring(1, $trimmed.Length - 2)
   }
   if($Type -eq "ENUM_TIMEFRAMES") {
      $timeframes = @{
         PERIOD_H1 = "16385"
         PERIOD_D1 = "16408"
      }
      if(!$timeframes.ContainsKey($trimmed)) { throw "Unsupported timeframe default: $trimmed" }
      return $timeframes[$trimmed]
   }
   return $trimmed
}

function Get-PinnedSourceInputs([string]$Path) {
   $inputs = [ordered]@{}
   foreach($line in Get-Content -LiteralPath $Path) {
      if($line -notmatch '^\s*input\s+([A-Za-z_][A-Za-z0-9_]*)\s+(Inp[A-Za-z0-9_]+)\s*=\s*(.+?)\s*;\s*$') {
         continue
      }
      $type = $Matches[1]
      $name = $Matches[2]
      $value = Convert-SourceDefault -Type $type -Value $Matches[3]
      if($inputs.Contains($name)) { throw "Duplicate source input: $name" }
      if($type -eq "string") { $inputs[$name] = "$name=$value" }
      else { $inputs[$name] = "$name=$value||$value||0||0||N" }
   }
   if($inputs.Count -lt 90) { throw "Unexpectedly small combined input contract: $($inputs.Count)" }
   return $inputs
}

function Set-PinnedInput($Inputs, [string]$Name, [string]$Value, [switch]$StringValue) {
   if(!$Inputs.Contains($Name)) { throw "Cannot override unknown input: $Name" }
   if($StringValue) { $Inputs[$Name] = "$Name=$Value" }
   else { $Inputs[$Name] = "$Name=$Value||$Value||0||0||N" }
}

& (Join-Path $PSScriptRoot "test_transferable_portfolio_source.ps1") -SourcePath $SourcePath | Out-Null
$sourceFull = (Resolve-Path -LiteralPath (Resolve-RepoPath $SourcePath)).Path
$sourceHash = (Get-FileHash -LiteralPath $sourceFull -Algorithm SHA256).Hash
if($sourceHash -ne $expectedSourceHash) { throw "Combined source identity changed: $sourceHash" }

$baseInputs = Get-PinnedSourceInputs -Path $sourceFull
Set-PinnedInput -Inputs $baseInputs -Name "InpEvidenceSourceHash" -Value $sourceHash -StringValue
Set-PinnedInput -Inputs $baseInputs -Name "InpLogTrades" -Value "false"

$variants = @(
   [pscustomobject]@{ Name="tpg_rv045_mo015_control"; RV="0.45"; MO="0.15"; Control=$true },
   [pscustomobject]@{ Name="tpg_rv050_mo010"; RV="0.50"; MO="0.10"; Control=$false },
   [pscustomobject]@{ Name="tpg_rv050_mo015"; RV="0.50"; MO="0.15"; Control=$false },
   [pscustomobject]@{ Name="tpg_rv055_mo010"; RV="0.55"; MO="0.10"; Control=$false },
   [pscustomobject]@{ Name="tpg_rv055_mo015"; RV="0.55"; MO="0.15"; Control=$false },
   [pscustomobject]@{ Name="tpg_rv060_mo010"; RV="0.60"; MO="0.10"; Control=$false },
   [pscustomobject]@{ Name="tpg_rv060_mo015"; RV="0.60"; MO="0.15"; Control=$false }
)
$windows = @(
   [pscustomobject]@{ Name="older_2015_2018"; From="2015.01.01"; To="2018.12.31" },
   [pscustomobject]@{ Name="middle_2019_2022"; From="2019.01.01"; To="2022.12.31" },
   [pscustomobject]@{ Name="recent_2023_2026"; From="2023.01.01"; To="2026.07.16" },
   [pscustomobject]@{ Name="continuous_2015_2026"; From="2015.01.01"; To="2026.07.16" }
)
$stopRule = "Require every broad era positive, continuous net at least 15% above the same-source control, PF at least 1.50, at least 330 trades, DD at or below 4%, recovery at least 4, and at least one adjacent passing growth allocation before Model4."

$packageFull = Resolve-RepoPath $PackageDir
Clear-OutputDirSafe $packageFull
$configDir = Join-Path $packageFull "configs"
$profileDir = Join-Path $packageFull "profiles"
$reportDir = Join-Path $packageFull "reports_here"
$sourceDir = Join-Path $packageFull "source"
New-Item -ItemType Directory -Path $configDir,$profileDir,$reportDir,$sourceDir -Force | Out-Null
Copy-Item -LiteralPath $sourceFull -Destination (Join-Path $sourceDir "Professional_XAUUSD_EA.mq5") -Force

$queueRows = [System.Collections.Generic.List[object]]::new()
$manifestRows = [System.Collections.Generic.List[object]]::new()
$rank = 0
$candidateRank = 0
foreach($variant in $variants) {
   $candidateRank++
   $inputs = [ordered]@{}
   foreach($key in $baseInputs.Keys) { $inputs[$key] = $baseInputs[$key] }
   Set-PinnedInput -Inputs $inputs -Name "InpRVRiskPercent" -Value $variant.RV
   Set-PinnedInput -Inputs $inputs -Name "InpMORiskPercent" -Value $variant.MO
   Set-PinnedInput -Inputs $inputs -Name "InpMaximumPortfolioOpenRiskPercent" -Value "0.75"
   Set-PinnedInput -Inputs $inputs -Name "InpEvidenceRunLabel" -Value "transferable_growth_discovery_model1" -StringValue
   Set-PinnedInput -Inputs $inputs -Name "InpRVLogFileName" -Value "$($variant.Name)_rv.csv" -StringValue
   Set-PinnedInput -Inputs $inputs -Name "InpMOLogFileName" -Value "$($variant.Name)_mo.csv" -StringValue
   $profileName = "$($variant.Name).set"
   $profilePath = Join-Path $profileDir $profileName
   @($inputs.Keys | Sort-Object | ForEach-Object { $inputs[$_] }) | Set-Content -LiteralPath $profilePath -Encoding ASCII
   $profileHash = (Get-FileHash -LiteralPath $profilePath -Algorithm SHA256).Hash

   foreach($window in $windows) {
      $rank++
      $configName = "{0:000}_{1}_{2}_m1.ini" -f $rank,$variant.Name,$window.Name
      $reportName = "$($variant.Name)_$($window.Name)_m1"
      Write-SeasonalTesterConfig -Path (Join-Path $configDir $configName) -ReportRoot $reportDir `
         -ReportName $reportName -From $window.From -To $window.To -Inputs $inputs -Model 1 -Deposit 10000
      $queueRows.Add([pscustomobject]@{
         QueueRank=$rank; Candidate=$variant.Name; CandidateRank=$candidateRank; Control=$variant.Control
         SourceType="transferable_portfolio_growth_allocation"; SourceRank=1; Phase="growth_discovery_model1"
         Set=$profileName; Window=$window.Name; From=$window.From; To=$window.To; Model=1; Deposit=10000
         Config="configs\$configName"; ExpectedReportName=$reportName; ProfileSnapshot="profiles\$profileName"
         ProfileSha256=$profileHash; SourceSha256=$sourceHash; RVRiskPercent=$variant.RV
         MORiskPercent=$variant.MO; PortfolioOpenRiskPercent="0.75"; StopRule=$stopRule
      }) | Out-Null
      $manifestRows.Add([pscustomobject]@{
         QueueRank=$rank; Candidate=$variant.Name; Phase="growth_discovery_model1"
         PhaseLabel="Transferable two-lane growth allocation discovery Model1"; Window=$window.Name; Model=1; Deposit=10000
         PackageConfig="$PackageDir\configs\$configName"; SourceConfig="$PackageDir\configs\$configName"
         ExpectedReportName=$reportName; ReportDestination="$PackageDir\reports_here\$reportName"
         ProfileSha256=$profileHash; StopRule=$stopRule
      }) | Out-Null
   }
}

$queueRows | Export-Csv -LiteralPath (Resolve-RepoPath $QueueManifestPath) -NoTypeInformation -Encoding ASCII
$manifestRows | Export-Csv -LiteralPath (Resolve-RepoPath $PackageManifestPath) -NoTypeInformation -Encoding ASCII
@(
   "# Transferable Portfolio Growth Discovery Model1 Package",
   "",
   "Exact released source with seven risk-allocation profiles and four broad/continuous windows.",
   "",
   "- Source SHA-256: $sourceHash",
   "- Profiles: $($variants.Count)",
   "- Configurations: $rank",
   "- Shared open-risk cap: 0.75%",
   "- Real-account trading: disabled",
   "",
   $stopRule
) | Set-Content -LiteralPath (Resolve-RepoPath $MarkdownPath) -Encoding ASCII

[pscustomobject]@{ Status="READY"; Configurations=$rank; Profiles=$variants.Count; Windows=$windows.Count; SourceHash=$sourceHash; PackageDir=$PackageDir }
