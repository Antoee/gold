[CmdletBinding()]
param(
   [string]$PackageDir='outputs\three_lane_reversion_strong_signal_lot_cap_model4_package',
   [string]$ManifestPath='outputs\THREE_LANE_REVERSION_STRONG_SIGNAL_LOT_CAP_MODEL4_MANIFEST.csv',
   [string]$QueuePath='outputs\THREE_LANE_REVERSION_STRONG_SIGNAL_LOT_CAP_MODEL4_QUEUE.csv',
   [string]$PackageMarkdownPath='outputs\THREE_LANE_REVERSION_STRONG_SIGNAL_LOT_CAP_MODEL4_PACKAGE.md',
   [string]$ContractPath='outputs\THREE_LANE_REVERSION_STRONG_SIGNAL_LOT_CAP_MODEL4_CONTRACT.md'
)
$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'seasonal_gate_helpers.ps1')
$repo=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path;$outputsRoot=(Resolve-Path (Join-Path $repo 'outputs')).Path
$sourceHash='C28534F328F3775AC825E5A8C53B1A66BD2745662B7AAC7B4CACBB76B31D1F91';$controlHash='AD0289B7A96150C930B54A2C44845C11DF05D42FD9A8D8DE4FA2703C308697F6';$centerHash='A0099C6701311BAE105F29909166358D4D30050593318F340AD8F3B932F65F04'
function Resolve-P([string]$p){if([IO.Path]::IsPathRooted($p)){return $p};return Join-Path $repo $p}
function Clear-Safe([string]$p){if(Test-Path $p){$r=(Resolve-Path $p).Path;if(!$r.StartsWith($outputsRoot,[StringComparison]::OrdinalIgnoreCase)){throw "Unsafe output path $r"};Remove-Item $r -Recurse -Force};New-Item -ItemType Directory -Path $p -Force|Out-Null}
$holdout=Import-Csv (Join-Path $repo 'outputs\THREE_LANE_REVERSION_STRONG_SIGNAL_LOT_CAP_HOLDOUT_DECISION.csv')
if($holdout.Status-ne'HOLDOUT_GATE_PASSED'-or$holdout.Model4ValidationPermitted-ne'True'-or$holdout.SourceSha256-ne$sourceHash-or$holdout.CenterProfileSha256-ne$centerHash){throw 'Exact recent-data authorization is missing or changed.'}
& (Join-Path $PSScriptRoot 'build_three_lane_reversion_strong_signal_lot_cap_holdout_package.ps1')|Out-Null
$holdoutPackage=Join-Path $repo 'outputs\three_lane_reversion_strong_signal_lot_cap_holdout_model1_package'
$source=Join-Path $holdoutPackage 'source\Professional_XAUUSD_EA.mq5'
$profiles=@(
 [pscustomobject]@{Candidate='sslc_control';Role='exact_control';Path=(Join-Path $holdoutPackage 'profiles\sslc_control.set');ExpectedHash=$controlHash},
 [pscustomobject]@{Candidate='sslc_center015';Role='frozen_center';Path=(Join-Path $holdoutPackage 'profiles\sslc_center015.set');ExpectedHash=$centerHash}
)
if((Get-FileHash $source -Algorithm SHA256).Hash-ne$sourceHash){throw 'Packaged source identity changed.'};foreach($p in $profiles){if((Get-FileHash $p.Path -Algorithm SHA256).Hash-ne$p.ExpectedHash){throw "Profile identity changed: $($p.Candidate)"}}
$windows=@(
 [pscustomobject]@{Name='older_2015_2018';From='2015.01.01';To='2018.12.31'},
 [pscustomobject]@{Name='middle_2019_2022';From='2019.01.01';To='2022.12.31'},
 [pscustomobject]@{Name='recent_2023_2026';From='2023.01.01';To='2026.07.18'},
 [pscustomobject]@{Name='continuous_2015_2026';From='2015.01.01';To='2026.07.18'}
)
$stopRule='Exact Model 4 real-tick comparison. Every center window positive/no worse control. Continuous center net >=control +5%, CAGR >=control +0.08 point, PF/recovery/return-DD >=control, DD <=1.25% and <=control +0.10 point, trades >=control -2. No retuning.'
$package=Resolve-P $PackageDir;Clear-Safe $package;$configDir=Join-Path $package 'configs';$profileDir=Join-Path $package 'profiles';$reportDir=Join-Path $package 'reports_here';$sourceDir=Join-Path $package 'source';New-Item -ItemType Directory -Path $configDir,$profileDir,$reportDir,$sourceDir -Force|Out-Null;Copy-Item $source (Join-Path $sourceDir 'Professional_XAUUSD_EA.mq5')
$queue=[Collections.Generic.List[object]]::new();$run=[Collections.Generic.List[object]]::new();$rank=0
foreach($p in $profiles){$inputs=Import-SetInputs $p.Path;$profileName="$($p.Candidate).set";Copy-Item $p.Path (Join-Path $profileDir $profileName);foreach($w in $windows){$rank++;$configName='{0:000}_{1}_{2}_m4.ini' -f $rank,$p.Candidate,$w.Name;$config=Join-Path $configDir $configName;$reportName="$($p.Candidate)_$($w.Name)_m4";Write-SeasonalTesterConfig -Path $config -ReportRoot $reportDir -ReportName $reportName -From $w.From -To $w.To -Inputs $inputs -Model 4 -Deposit 10000 -Period 15;$configHash=(Get-FileHash $config -Algorithm SHA256).Hash;$common=[ordered]@{QueueRank=$rank;Candidate=$p.Candidate;Role=$p.Role;Phase='three_lane_reversion_strong_signal_lot_cap_model4';Window=$w.Name;From=$w.From;To=$w.To;Model=4;Deposit=10000;ExpectedReportName=$reportName;ConfigSha256=$configHash;ProfileSha256=$p.ExpectedHash;SourceSha256=$sourceHash;StopRule=$stopRule};$queue.Add([pscustomobject]($common+[ordered]@{Config="configs\$configName";ProfileSnapshot="profiles\$profileName"}))|Out-Null;$run.Add([pscustomobject]($common+[ordered]@{PackageConfig="$PackageDir\configs\$configName";SourceConfig="$PackageDir\configs\$configName";ReportDestination="$PackageDir\reports_here\$reportName"}))|Out-Null}}
$queue|Export-Csv (Resolve-P $QueuePath)-NoTypeInformation -Encoding ASCII;$run|Export-Csv (Resolve-P $ManifestPath)-NoTypeInformation -Encoding ASCII
@('# Strong-Signal Selective Lot-Cap Model 4 Package','','**Status: FROZEN EXACT REAL-TICK COMPARISON. PROMOTION REMAINS CLOSED.**','',"- Source: ``$sourceHash``","- Control profile: ``$controlHash``","- Center profile: ``$centerHash``",'- Profiles: `2`; configurations: `8`; model: `4` real ticks','- No setting may change after reports open. Annual, cost, Monte Carlo, broker, forward, and live gates remain closed.')|Set-Content (Resolve-P $PackageMarkdownPath)-Encoding ASCII
@('# Strong-Signal Selective Lot-Cap Model 4 Contract','','**Status: RESEARCH ONLY. NOT PROMOTION OR REAL-MONEY APPROVAL.**','','- Freeze exact control and center across 2015-2018, 2019-2022, 2023-2026, and continuous 2015-2026 Model 4 real ticks.','- Require every center window positive and no worse than control. Require continuous net at least 5% and CAGR at least 0.08 point above control.','- Require continuous PF, recovery, and return/drawdown no worse than control; drawdown at most 1.25% and no more than 0.10 point above control; trades at least control minus two.','- Reject identity mismatch, losing/weaker era, efficiency loss, excess drawdown, or retuning. A pass opens annual and stress validation only; it is not promotion.','- Keep all risk, stop, exposure, loss, capital, forward, and real-account safeguards unchanged.')|Set-Content (Resolve-P $ContractPath)-Encoding ASCII
[pscustomobject][ordered]@{Status='READY';SourceSha256=$sourceHash;ControlProfileSha256=$controlHash;CenterProfileSha256=$centerHash;Profiles=2;Windows=4;Configurations=$rank;Model=4;LatestDate='2026-07-18'}
