param(
   [string]$SourcePath = "work\Professional_XAUUSD_Reversion_Shock_Guard_Portfolio.mq5",
   [string]$BaseProfilePath = "outputs\operational_hardening_rc2_model4_package\profiles\operational_hardening_rc2_rv045_mo015_model4.set",
   [string]$PackageDir = "outputs\reversion_shock_guard_portfolio_discovery_model1_package",
   [string]$QueuePath = "outputs\REVERSION_SHOCK_GUARD_PORTFOLIO_DISCOVERY_MODEL1_QUEUE.csv",
   [string]$ManifestPath = "outputs\REVERSION_SHOCK_GUARD_PORTFOLIO_DISCOVERY_MODEL1_MANIFEST.csv",
   [string]$MarkdownPath = "outputs\REVERSION_SHOCK_GUARD_PORTFOLIO_DISCOVERY_MODEL1_PACKAGE.md"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot "seasonal_gate_helpers.ps1")

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$outputsRoot = (Resolve-Path (Join-Path $repo "outputs")).Path
$expectedSourceHash = "A681A1371E3DC2A07234C373F9E4574CC16F0E3C96C9C48E2B703962D2A5B8A9"
$expectedBaseProfileHash = "5C45D578B42609D3792EA692D5A13A9E0D90C8C14D0376F807E6F6079EC6B827"
$runLabel = "reversion_shock_guard_portfolio_discovery_model1"

function Resolve-RepoPath([string]$Path) {
   if([IO.Path]::IsPathRooted($Path)) { return $Path }
   return Join-Path $repo $Path
}
function Set-PinnedInput($Inputs, [string]$Name, [string]$Value, [switch]$StringValue) {
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

& (Join-Path $PSScriptRoot "test_reversion_shock_guard_portfolio_source.ps1") | Out-Null
$source = (Resolve-Path -LiteralPath (Resolve-RepoPath $SourcePath)).Path
$baseProfile = (Resolve-Path -LiteralPath (Resolve-RepoPath $BaseProfilePath)).Path
$sourceHash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
$baseHash = (Get-FileHash -LiteralPath $baseProfile -Algorithm SHA256).Hash
if($sourceHash -ne $expectedSourceHash) { throw "Shock-guard source identity changed: $sourceHash" }
if($baseHash -ne $expectedBaseProfileHash) { throw "RC2 base profile identity changed: $baseHash" }
$baseInputs = Import-SetInputs -Path $baseProfile
if($baseInputs.Keys.Count -ne 105) { throw "Expected 105 RC2 inputs, found $($baseInputs.Keys.Count)." }
$baseInputs["InpRVUseMinimumBodyGate"] = "InpRVUseMinimumBodyGate=false||false||0||0||N"
$baseInputs["InpRVMinimumBodyPercent"] = "InpRVMinimumBodyPercent=25.0||25.0||0||0||N"
if($baseInputs.Keys.Count -ne 107) { throw "Expected 107 shock-guard inputs, found $($baseInputs.Keys.Count)." }

$variants = @(
   [pscustomobject]@{Name="rsg_mo015_control";MO="0.15";DI="-12.0";Body="25.0";UseBody="false";Role="control"},
   [pscustomobject]@{Name="rsg_mo015_di10";MO="0.15";DI="-10.0";Body="25.0";UseBody="false";Role="di_only"},
   [pscustomobject]@{Name="rsg_mo015_body25";MO="0.15";DI="-12.0";Body="25.0";UseBody="true";Role="body_only"},
   [pscustomobject]@{Name="rsg_mo015_combo20";MO="0.15";DI="-10.0";Body="20.0";UseBody="true";Role="lower_body_neighbor"},
   [pscustomobject]@{Name="rsg_mo015_combo25";MO="0.15";DI="-10.0";Body="25.0";UseBody="true";Role="center"},
   [pscustomobject]@{Name="rsg_mo015_combo30";MO="0.15";DI="-10.0";Body="30.0";UseBody="true";Role="upper_body_neighbor"},
   [pscustomobject]@{Name="rsg_mo015_combo25_di08";MO="0.15";DI="-8.0";Body="25.0";UseBody="true";Role="strict_di_neighbor"},
   [pscustomobject]@{Name="rsg_mo020_control";MO="0.20";DI="-12.0";Body="25.0";UseBody="false";Role="control"},
   [pscustomobject]@{Name="rsg_mo020_di10";MO="0.20";DI="-10.0";Body="25.0";UseBody="false";Role="di_only"},
   [pscustomobject]@{Name="rsg_mo020_body25";MO="0.20";DI="-12.0";Body="25.0";UseBody="true";Role="body_only"},
   [pscustomobject]@{Name="rsg_mo020_combo20";MO="0.20";DI="-10.0";Body="20.0";UseBody="true";Role="lower_body_neighbor"},
   [pscustomobject]@{Name="rsg_mo020_combo25";MO="0.20";DI="-10.0";Body="25.0";UseBody="true";Role="primary_center"},
   [pscustomobject]@{Name="rsg_mo020_combo30";MO="0.20";DI="-10.0";Body="30.0";UseBody="true";Role="upper_body_neighbor"},
   [pscustomobject]@{Name="rsg_mo020_combo25_di08";MO="0.20";DI="-8.0";Body="25.0";UseBody="true";Role="strict_di_neighbor"}
)
$windows = @(
   [pscustomobject]@{Name="older_2015_2018";From="2015.01.01";To="2018.12.31"},
   [pscustomobject]@{Name="repair_2019";From="2019.01.01";To="2019.12.31"},
   [pscustomobject]@{Name="repair_2020";From="2020.01.01";To="2020.12.31"},
   [pscustomobject]@{Name="continuous_2015_2020";From="2015.01.01";To="2020.12.31"}
)
$stopRule = "Pre-2021 only: both DI -10/body-25 centers plus a same-risk body-20 or body-30 neighbor must pass older profitability, nonnegative 2019/2020, PF/activity/DD/return-efficiency, and exact identity gates before recent data opens."

$package = Resolve-RepoPath $PackageDir
Clear-OutputDirSafe $package
$configDir = Join-Path $package "configs"
$profileDir = Join-Path $package "profiles"
$reportDir = Join-Path $package "reports_here"
$sourceDir = Join-Path $package "source"
New-Item -ItemType Directory -Path $configDir, $profileDir, $reportDir, $sourceDir -Force | Out-Null
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
   Set-PinnedInput $inputs "InpRVUseDIEdgeGate" "true"
   Set-PinnedInput $inputs "InpRVMinimumDIEdge" $variant.DI
   Set-PinnedInput $inputs "InpRVUseMinimumBodyGate" $variant.UseBody
   Set-PinnedInput $inputs "InpRVMinimumBodyPercent" $variant.Body
   Set-PinnedInput $inputs "InpMORiskPercent" $variant.MO
   Set-PinnedInput $inputs "InpMaximumPortfolioOpenRiskPercent" "0.75"
   Set-PinnedInput $inputs "InpLogTrades" "false"
   Set-PinnedInput $inputs "InpShowDashboard" "false"
   Set-PinnedInput $inputs "InpEvidenceSourceHash" $sourceHash -StringValue
   Set-PinnedInput $inputs "InpEvidenceRunLabel" $runLabel -StringValue
   Set-PinnedInput $inputs "InpRVLogFileName" "$($variant.Name)_rv.csv" -StringValue
   Set-PinnedInput $inputs "InpMOLogFileName" "$($variant.Name)_mo.csv" -StringValue

   $profileName = "$($variant.Name).set"
   $profilePath = Join-Path $profileDir $profileName
   @($inputs.Keys | Sort-Object | ForEach-Object { $inputs[$_] }) | Set-Content -LiteralPath $profilePath -Encoding ASCII
   $profileHash = (Get-FileHash -LiteralPath $profilePath -Algorithm SHA256).Hash

   foreach($window in $windows) {
      $rank++
      $configName = "{0:000}_{1}_{2}_m1.ini" -f $rank, $variant.Name, $window.Name
      $reportName = "$($variant.Name)_$($window.Name)_m1"
      Write-SeasonalTesterConfig -Path (Join-Path $configDir $configName) -ReportRoot $reportDir `
         -ReportName $reportName -From $window.From -To $window.To -Inputs $inputs -Model 1 -Deposit 10000

      $queue.Add([pscustomobject]@{
         QueueRank=$rank;Candidate=$variant.Name;CandidateRank=$candidateRank;Role=$variant.Role
         Phase="discovery_model1";Window=$window.Name;From=$window.From;To=$window.To;Model=1;Deposit=10000
         Config="configs\$configName";ExpectedReportName=$reportName;ProfileSnapshot="profiles\$profileName"
         ProfileSha256=$profileHash;SourceSha256=$sourceHash;RunLabel=$runLabel
         RVRiskPercent="0.45";MORiskPercent=$variant.MO;RVMinimumDIEdge=$variant.DI
         RVUseMinimumBodyGate=$variant.UseBody;RVMinimumBodyPercent=$variant.Body
         PortfolioOpenRiskPercent="0.75";StopRule=$stopRule
      }) | Out-Null
      $manifest.Add([pscustomobject]@{
         QueueRank=$rank;Rank=$rank;Candidate=$variant.Name;Profile=$variant.Name;Phase="discovery_model1"
          Set="reversion_shock_guard_portfolio";Window=$window.Name;From=$window.From;To=$window.To;Model=1;Deposit=10000
         PackageConfig="$PackageDir\configs\$configName";ExpectedReportName=$reportName
         ReportDestination="$PackageDir\reports_here\$reportName";ProfileSha256=$profileHash
         SourceSha256=$sourceHash;RunLabel=$runLabel;StopRule=$stopRule
      }) | Out-Null
   }
}

$queue | Export-Csv -LiteralPath (Resolve-RepoPath $QueuePath) -NoTypeInformation -Encoding ASCII
$manifest | Export-Csv -LiteralPath (Resolve-RepoPath $ManifestPath) -NoTypeInformation -Encoding ASCII
@(
   "# Reversion Shock-Guard Portfolio Discovery Model1 Package", "",
   "RC2 research fork, two momentum-risk allocations, a frozen DI/body neighborhood, and four pre-2021 windows.", "",
   "- Source SHA-256: $sourceHash",
   "- Base profile SHA-256: $baseHash",
   "- Profiles: $($variants.Count)",
   "- Configurations: $rank",
   "- Reversion risk: 0.45%",
   "- Momentum risk: 0.15% and 0.20%",
   "- Shared open-risk cap: 0.75%",
   "- Latest discovery date: 2020-12-31",
   "- Real-account trading: disabled", "",
   $stopRule
) | Set-Content -LiteralPath (Resolve-RepoPath $MarkdownPath) -Encoding ASCII

[pscustomobject]@{
   Status="READY";Configurations=$rank;Profiles=$variants.Count;Windows=$windows.Count
   SourceSha256=$sourceHash;BaseProfileSha256=$baseHash;LatestDiscoveryDate="2020-12-31"
}
