param(
   [string]$SourcePath = "work\Professional_XAUUSD_Operational_Hardening_Portfolio_RC2.mq5",
   [string]$BaseProfilePath = "outputs\operational_hardening_rc2_model4_package\profiles\operational_hardening_rc2_rv045_mo015_model4.set",
   [string]$PackageDir = "outputs\rc2_momentum_risk_extension_model1_package",
   [string]$QueuePath = "outputs\RC2_MOMENTUM_RISK_EXTENSION_MODEL1_QUEUE.csv",
   [string]$ManifestPath = "outputs\RC2_MOMENTUM_RISK_EXTENSION_MODEL1_PACKAGE_MANIFEST.csv",
   [string]$MarkdownPath = "outputs\RC2_MOMENTUM_RISK_EXTENSION_MODEL1_PACKAGE.md"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot "seasonal_gate_helpers.ps1")

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$outputsRoot = (Resolve-Path (Join-Path $repo "outputs")).Path
$expectedSourceHash = "9141137A9550F3394DE85E1725E018671B4F2A2FF0F43A3EF23F9FB1238CD302"
$expectedBaseProfileHash = "5C45D578B42609D3792EA692D5A13A9E0D90C8C14D0376F807E6F6079EC6B827"

function Resolve-RepoPath([string]$Path) {
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}
function Set-PinnedInput($Inputs,[string]$Name,[string]$Value,[switch]$StringValue) {
   if(!$Inputs.Contains($Name)) { throw "Unknown input override: $Name" }
   if($StringValue) { $Inputs[$Name] = "$Name=$Value" }
   else { $Inputs[$Name] = "$Name=$Value||$Value||0||0||N" }
}
function Clear-OutputDirSafe([string]$Path) {
   if(Test-Path -LiteralPath $Path) {
      $resolved = (Resolve-Path -LiteralPath $Path).Path
      if(!$resolved.StartsWith($outputsRoot + '\', [StringComparison]::OrdinalIgnoreCase)) {
         throw "Refusing to clear a directory outside outputs: $resolved"
      }
      Remove-Item -LiteralPath $resolved -Recurse -Force
   }
   New-Item -ItemType Directory -Path $Path -Force | Out-Null
}

$source = (Resolve-Path -LiteralPath (Resolve-RepoPath $SourcePath)).Path
$baseProfile = (Resolve-Path -LiteralPath (Resolve-RepoPath $BaseProfilePath)).Path
$sourceHash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
$baseHash = (Get-FileHash -LiteralPath $baseProfile -Algorithm SHA256).Hash
if($sourceHash -ne $expectedSourceHash) { throw "RC2 source identity changed: $sourceHash" }
if($baseHash -ne $expectedBaseProfileHash) { throw "RC2 base profile identity changed: $baseHash" }
$baseInputs = Import-SetInputs -Path $baseProfile
if($baseInputs.Keys.Count -ne 105) { throw "Expected 105 RC2 inputs, found $($baseInputs.Keys.Count)." }

$variants = @(
   [pscustomobject]@{Name="mre_mo015_control";MO="0.15";Role="control"},
   [pscustomobject]@{Name="mre_mo0175";MO="0.175";Role="lower_neighbor"},
   [pscustomobject]@{Name="mre_mo020_center";MO="0.20";Role="center"},
   [pscustomobject]@{Name="mre_mo0225";MO="0.225";Role="upper_neighbor"},
   [pscustomobject]@{Name="mre_mo025";MO="0.25";Role="shape"},
   [pscustomobject]@{Name="mre_mo0275";MO="0.275";Role="shape"},
   [pscustomobject]@{Name="mre_mo030";MO="0.30";Role="cap_boundary"}
)
$windows = @(
   [pscustomobject]@{Name="older_2015_2018";From="2015.01.01";To="2018.12.31"},
   [pscustomobject]@{Name="middle_2019_2022";From="2019.01.01";To="2022.12.31"},
   [pscustomobject]@{Name="recent_2023_2026";From="2023.01.01";To="2026.07.16"},
   [pscustomobject]@{Name="continuous_2015_2026";From="2015.01.01";To="2026.07.16"}
)
$stopRule = "Only the nominated 0.20% center may advance, and only with both adjacent profiles, every broad era positive, broad net no worse than control, at least 10% continuous improvement, PF >= 1.50, trades >= 350, DD <= 4%, and recovery >= 4."

$package = Resolve-RepoPath $PackageDir
Clear-OutputDirSafe $package
$configDir = Join-Path $package "configs"
$profileDir = Join-Path $package "profiles"
$reportDir = Join-Path $package "reports_here"
$sourceDir = Join-Path $package "source"
New-Item -ItemType Directory -Path $configDir,$profileDir,$reportDir,$sourceDir -Force | Out-Null
Copy-Item -LiteralPath $source -Destination (Join-Path $sourceDir "Professional_XAUUSD_EA.mq5") -Force

$queue = [System.Collections.Generic.List[object]]::new()
$manifest = [System.Collections.Generic.List[object]]::new()
$rank = 0
$candidateRank = 0
foreach($variant in $variants) {
   $candidateRank++
   $inputs = [ordered]@{}
   foreach($key in $baseInputs.Keys) { $inputs[$key] = $baseInputs[$key] }
   Set-PinnedInput $inputs "InpRVRiskPercent" "0.45"
   Set-PinnedInput $inputs "InpMORiskPercent" $variant.MO
   Set-PinnedInput $inputs "InpMaximumPortfolioOpenRiskPercent" "0.75"
   Set-PinnedInput $inputs "InpLogTrades" "false"
   Set-PinnedInput $inputs "InpShowDashboard" "false"
   Set-PinnedInput $inputs "InpEvidenceRunLabel" "rc2_momentum_risk_extension_model1" -StringValue
   Set-PinnedInput $inputs "InpRVLogFileName" "$($variant.Name)_rv.csv" -StringValue
   Set-PinnedInput $inputs "InpMOLogFileName" "$($variant.Name)_mo.csv" -StringValue
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
      $queue.Add([pscustomobject]@{
         QueueRank=$rank;Candidate=$variant.Name;CandidateRank=$candidateRank;Role=$variant.Role
         Phase="rc2_momentum_risk_extension_model1";Window=$window.Name;From=$window.From;To=$window.To
         Model=1;Deposit=10000;Config="configs\$configName";ExpectedReportName=$reportName
         ProfileSnapshot="profiles\$profileName";ProfileSha256=$profileHash;SourceSha256=$sourceHash
         RVRiskPercent="0.45";MORiskPercent=$variant.MO;PortfolioOpenRiskPercent="0.75";StopRule=$stopRule
      }) | Out-Null
      $manifest.Add([pscustomobject]@{
         QueueRank=$rank;Candidate=$variant.Name;Window=$window.Name;Model=1
         PackageConfig="$PackageDir\configs\$configName";ExpectedReportName=$reportName
         ReportDestination="$PackageDir\reports_here\$reportName";ProfileSha256=$profileHash;StopRule=$stopRule
      }) | Out-Null
   }
}
$queue | Export-Csv -LiteralPath (Resolve-RepoPath $QueuePath) -NoTypeInformation -Encoding ASCII
$manifest | Export-Csv -LiteralPath (Resolve-RepoPath $ManifestPath) -NoTypeInformation -Encoding ASCII
@(
   "# RC2 Momentum-Risk Extension Model1 Package", "",
   "Exact RC2 source, seven momentum-risk points, four broad/continuous windows, and no strategy-rule changes.", "",
   "- Source SHA-256: $sourceHash",
   "- Base profile SHA-256: $baseHash",
   "- Profiles: $($variants.Count)",
   "- Configurations: $rank",
   "- Reversion risk: 0.45%",
   "- Shared open-risk cap: 0.75%",
   "- Real-account trading: disabled", "",
   $stopRule
) | Set-Content -LiteralPath (Resolve-RepoPath $MarkdownPath) -Encoding ASCII

[pscustomobject]@{Status="READY";Configurations=$rank;Profiles=$variants.Count;Windows=$windows.Count;SourceSha256=$sourceHash;BaseProfileSha256=$baseHash}
