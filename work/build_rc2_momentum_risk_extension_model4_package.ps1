param(
   [string]$SourcePath = "work\Professional_XAUUSD_Operational_Hardening_Portfolio_RC2.mq5",
   [string]$Model1QueuePath = "outputs\RC2_MOMENTUM_RISK_EXTENSION_MODEL1_QUEUE.csv",
   [string]$Model1DecisionPath = "outputs\RC2_MOMENTUM_RISK_EXTENSION_MODEL1_DECISION.csv",
   [string]$PackageDir = "outputs\rc2_momentum_risk_extension_model4_package",
   [string]$QueuePath = "outputs\RC2_MOMENTUM_RISK_EXTENSION_MODEL4_QUEUE.csv",
   [string]$ManifestPath = "outputs\RC2_MOMENTUM_RISK_EXTENSION_MODEL4_PACKAGE_MANIFEST.csv",
   [string]$MarkdownPath = "outputs\RC2_MOMENTUM_RISK_EXTENSION_MODEL4_PACKAGE.md"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot "seasonal_gate_helpers.ps1")
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$outputsRoot = (Resolve-Path (Join-Path $repo "outputs")).Path
$sourceHashExpected = "9141137A9550F3394DE85E1725E018671B4F2A2FF0F43A3EF23F9FB1238CD302"
$controlNet = 1615.36
function Resolve-RepoPath([string]$Path) { if([IO.Path]::IsPathRooted($Path)){return $Path};return Join-Path $repo $Path }
function Set-PinnedInput($Inputs,[string]$Name,[string]$Value,[switch]$StringValue) {
   if(!$Inputs.Contains($Name)) { throw "Unknown input override: $Name" }
   $Inputs[$Name] = if($StringValue){"$Name=$Value"}else{"$Name=$Value||$Value||0||0||N"}
}
function Clear-OutputDirSafe([string]$Path) {
   if(Test-Path -LiteralPath $Path) {
      $resolved=(Resolve-Path -LiteralPath $Path).Path
      if(!$resolved.StartsWith($outputsRoot+'\',[StringComparison]::OrdinalIgnoreCase)){throw "Refusing to clear outside outputs: $resolved"}
      Remove-Item -LiteralPath $resolved -Recurse -Force
   }
   New-Item -ItemType Directory -Path $Path -Force | Out-Null
}

$decision=@(Import-Csv -LiteralPath (Resolve-RepoPath $Model1DecisionPath))
if($decision.Count-ne 1 -or $decision[0].Status-ne "MODEL1_GATE_PASSED" -or $decision[0].Model4Permitted-ne "True") {
   throw "Frozen Model1 gate does not permit a Model4 package."
}
$source=(Resolve-Path -LiteralPath (Resolve-RepoPath $SourcePath)).Path
$sourceHash=(Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
if($sourceHash-ne$sourceHashExpected -or $decision[0].SourceSha256-ne$sourceHash){throw "Source identity changed."}
$model1=@(Import-Csv -LiteralPath (Resolve-RepoPath $Model1QueuePath))
$variants=@(
   [pscustomobject]@{Name="mre_mo0175";MO="0.175";Role="lower_neighbor"},
   [pscustomobject]@{Name="mre_mo020_center";MO="0.20";Role="center"},
   [pscustomobject]@{Name="mre_mo0225";MO="0.225";Role="upper_neighbor"}
)
$windows=@(
   [pscustomobject]@{Name="older_2015_2018";From="2015.01.01";To="2018.12.31"},
   [pscustomobject]@{Name="middle_2019_2022";From="2019.01.01";To="2022.12.31"},
   [pscustomobject]@{Name="recent_2023_2026";From="2023.01.01";To="2026.07.16"},
   [pscustomobject]@{Name="continuous_2015_2026";From="2015.01.01";To="2026.07.16"}
)
$stopRule="Center must clear the frozen Model4 baseline by 10%, PF 1.50, 340 trades, DD 4%, recovery 4, and all broad eras positive; both neighbors must clear 5%, PF 1.45, 340 trades, DD 4.25%, recovery 3.75, and all broad eras positive."
$package=Resolve-RepoPath $PackageDir
Clear-OutputDirSafe $package
$configDir=Join-Path $package "configs";$profileDir=Join-Path $package "profiles";$reportDir=Join-Path $package "reports_here";$sourceDir=Join-Path $package "source"
New-Item -ItemType Directory -Path $configDir,$profileDir,$reportDir,$sourceDir -Force | Out-Null
Copy-Item -LiteralPath $source -Destination (Join-Path $sourceDir "Professional_XAUUSD_EA.mq5") -Force

$queue=[Collections.Generic.List[object]]::new();$manifest=[Collections.Generic.List[object]]::new();$rank=0;$candidateRank=0
foreach($variant in $variants) {
   $candidateRank++
   $model1Row=@($model1 | Where-Object Candidate -eq $variant.Name | Select-Object -First 1)
   if($model1Row.Count-ne 1){throw "Model1 profile missing: $($variant.Name)"}
   $model1Profile=Join-Path $repo ("outputs\rc2_momentum_risk_extension_model1_package\"+$model1Row[0].ProfileSnapshot)
   if((Get-FileHash -LiteralPath $model1Profile -Algorithm SHA256).Hash-ne$model1Row[0].ProfileSha256){throw "Model1 profile hash changed: $($variant.Name)"}
   $inputs=Import-SetInputs -Path $model1Profile
   if($inputs.Keys.Count-ne 105){throw "Expected 105 inputs: $($variant.Name)"}
   Set-PinnedInput $inputs "InpEvidenceRunLabel" "rc2_momentum_risk_extension_model4" -StringValue
   Set-PinnedInput $inputs "InpRVLogFileName" "$($variant.Name)_model4_rv.csv" -StringValue
   Set-PinnedInput $inputs "InpMOLogFileName" "$($variant.Name)_model4_mo.csv" -StringValue
   $profileName="$($variant.Name)_model4.set";$profilePath=Join-Path $profileDir $profileName
   @($inputs.Keys|Sort-Object|ForEach-Object{$inputs[$_]})|Set-Content -LiteralPath $profilePath -Encoding ASCII
   $profileHash=(Get-FileHash -LiteralPath $profilePath -Algorithm SHA256).Hash
   foreach($window in $windows) {
      $rank++
      $configName="{0:000}_{1}_{2}_m4.ini"-f$rank,$variant.Name,$window.Name
      $reportName="$($variant.Name)_$($window.Name)_m4"
      Write-SeasonalTesterConfig -Path (Join-Path $configDir $configName) -ReportRoot $reportDir -ReportName $reportName -From $window.From -To $window.To -Inputs $inputs -Model 4 -Deposit 10000
      $queue.Add([pscustomobject]@{QueueRank=$rank;Candidate=$variant.Name;CandidateRank=$candidateRank;Role=$variant.Role;Phase="rc2_momentum_risk_extension_model4";Window=$window.Name;From=$window.From;To=$window.To;Model=4;Deposit=10000;Config="configs\$configName";ExpectedReportName=$reportName;ProfileSnapshot="profiles\$profileName";ProfileSha256=$profileHash;SourceSha256=$sourceHash;RVRiskPercent="0.45";MORiskPercent=$variant.MO;PortfolioOpenRiskPercent="0.75";ControlModel4NetProfit=$controlNet;StopRule=$stopRule})|Out-Null
      $manifest.Add([pscustomobject]@{QueueRank=$rank;Candidate=$variant.Name;Window=$window.Name;Model=4;PackageConfig="$PackageDir\configs\$configName";ExpectedReportName=$reportName;ReportDestination="$PackageDir\reports_here\$reportName";ProfileSha256=$profileHash;StopRule=$stopRule})|Out-Null
   }
}
$queue|Export-Csv -LiteralPath (Resolve-RepoPath $QueuePath) -NoTypeInformation -Encoding ASCII
$manifest|Export-Csv -LiteralPath (Resolve-RepoPath $ManifestPath) -NoTypeInformation -Encoding ASCII
@("# RC2 Momentum-Risk Extension Model4 Package","","Frozen real-tick confirmation of the Model1-eligible center and its two adjacent profiles.","","- Source SHA-256: $sourceHash","- Existing exact-source Model4 control: +`$$($controlNet.ToString('N2'))","- Profiles: 3","- Configurations: $rank","- Real-account trading: disabled","","$stopRule")|Set-Content -LiteralPath (Resolve-RepoPath $MarkdownPath) -Encoding ASCII
[pscustomobject]@{Status="READY";Configurations=$rank;Profiles=3;Windows=4;SourceSha256=$sourceHash;ControlNetProfit=$controlNet}
