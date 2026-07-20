[CmdletBinding()]
param(
   [string]$PackageDir='outputs\three_lane_momentum_same_side_exit_cooldown_annual_model4_package',
   [string]$ManifestPath='outputs\THREE_LANE_MOMENTUM_SAME_SIDE_EXIT_COOLDOWN_ANNUAL_MODEL4_MANIFEST.csv',
   [string]$QueuePath='outputs\THREE_LANE_MOMENTUM_SAME_SIDE_EXIT_COOLDOWN_ANNUAL_MODEL4_QUEUE.csv',
   [string]$PackageMarkdownPath='outputs\THREE_LANE_MOMENTUM_SAME_SIDE_EXIT_COOLDOWN_ANNUAL_MODEL4_PACKAGE.md',
   [string]$ContractPath='outputs\THREE_LANE_MOMENTUM_SAME_SIDE_EXIT_COOLDOWN_ANNUAL_MODEL4_CONTRACT.md'
)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'seasonal_gate_helpers.ps1')
$repo=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$outputsRoot=(Resolve-Path (Join-Path $repo 'outputs')).Path
$sourceHash='B6810B305549968E2273DAAF736A63759FE5C16F3B416F5C69E39840FBE5173E'
$controlHash='EBF91F101273422422008BE481D8FF97448556384EBCCF561E7CBFC563A741F1'
$centerHash='ACFCE73E2A48723334CC416715F047E3CEA87018D46B12B8A6CB0663E025BA1C'

function Resolve-P([string]$Path){if([IO.Path]::IsPathRooted($Path)){return $Path};return Join-Path $repo $Path}
function Clear-Safe([string]$Path){
   if(Test-Path -LiteralPath $Path){
      $resolved=(Resolve-Path -LiteralPath $Path).Path
      if(!$resolved.StartsWith($outputsRoot,[StringComparison]::OrdinalIgnoreCase)){throw "Unsafe output path: $resolved"}
      Remove-Item -LiteralPath $resolved -Recurse -Force
   }
   New-Item -ItemType Directory -Path $Path -Force|Out-Null
}

$model4Decision=Import-Csv (Resolve-P 'outputs\THREE_LANE_MOMENTUM_SAME_SIDE_EXIT_COOLDOWN_MODEL4_DECISION.csv')
if($model4Decision.Status-ne'MODEL4_GATE_PASSED'-or$model4Decision.AnnualStressValidationPermitted-ne'True'-or$model4Decision.SourceSha256-ne$sourceHash-or$model4Decision.CenterProfileSha256-ne$centerHash){throw 'Exact Model 4 authorization is missing or changed.'}

$model4Package=Resolve-P 'outputs\three_lane_momentum_same_side_exit_cooldown_model4_package'
$source=Join-Path $model4Package 'source\Professional_XAUUSD_EA.mq5'
$profiles=@(
   [pscustomobject]@{Candidate='msec_control';Role='exact_control';Path=(Join-Path $model4Package 'profiles\msec_control.set');ExpectedHash=$controlHash},
   [pscustomobject]@{Candidate='msec_center_060';Role='frozen_center';Path=(Join-Path $model4Package 'profiles\msec_center_060.set');ExpectedHash=$centerHash}
)
if((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash-ne$sourceHash){throw 'Packaged source identity changed.'}
foreach($profile in $profiles){if((Get-FileHash -LiteralPath $profile.Path -Algorithm SHA256).Hash-ne$profile.ExpectedHash){throw "Profile identity changed: $($profile.Candidate)"}}

$contractLines=@(
   '# Momentum Same-Side Exit Cooldown Annual Model 4 Contract','',
   '**Status: FROZEN RESEARCH GATE. NOT PROMOTION OR REAL-MONEY APPROVAL.**','',
   '- Compare the exact control and 60-minute center on separate annual Model 4 real-tick restarts from 2015 through 2026 YTD. No retuning.','- Require all 12 center years profitable, at least 10 of 12 center years no worse than control, and at least three years strictly improved.','- Require center summed annual net strictly above control, summed trades at least 98% of control, every center annual drawdown no more than paired control plus 0.03 point and at most 1.50%, and every loss streak at most eight.','- Reject any identity mismatch, red center year, concentrated single-year benefit, broad annual degradation, activity collapse, excess drawdown, or excess loss clustering.','- A pass opens ledger cost and Monte Carlo stress only. Promotion, forward substitution, and real trading remain closed.'
)
$contract=Resolve-P $ContractPath
$contractLines|Set-Content -LiteralPath $contract -Encoding ASCII
$contractHash=(Get-FileHash -LiteralPath $contract -Algorithm SHA256).Hash

$windows=[Collections.Generic.List[object]]::new()
foreach($year in 2015..2025){$windows.Add([pscustomobject]@{Name="year_$year";From="$year.01.01";To="$year.12.31"})|Out-Null}
$windows.Add([pscustomobject]@{Name='year_2026_ytd';From='2026.01.01';To='2026.07.12'})|Out-Null
$stopRule='All 12 center years profitable; >=10/12 no worse and >=3/12 strictly improved; center summed net >control; trades >=98% control; each center DD <=paired control +0.03 point and <=1.50%; each center loss streak <=8. No retuning.'

$package=Resolve-P $PackageDir
Clear-Safe $package
$configDir=Join-Path $package 'configs';$profileDir=Join-Path $package 'profiles';$reportDir=Join-Path $package 'reports_here';$sourceDir=Join-Path $package 'source'
New-Item -ItemType Directory -Path $configDir,$profileDir,$reportDir,$sourceDir -Force|Out-Null
Copy-Item -LiteralPath $source -Destination (Join-Path $sourceDir 'Professional_XAUUSD_EA.mq5')
$queue=[Collections.Generic.List[object]]::new();$manifest=[Collections.Generic.List[object]]::new();$rank=0
foreach($profile in $profiles){
   $inputs=Import-SetInputs -Path $profile.Path
   $profileName="$($profile.Candidate).set"
   Copy-Item -LiteralPath $profile.Path -Destination (Join-Path $profileDir $profileName)
   foreach($window in $windows){
      $rank++
      $configName='{0:000}_{1}_{2}_m4.ini' -f $rank,$profile.Candidate,$window.Name
      $config=Join-Path $configDir $configName
      $reportName="$($profile.Candidate)_$($window.Name)_m4"
      Write-SeasonalTesterConfig -Path $config -ReportRoot $reportDir -ReportName $reportName -From $window.From -To $window.To -Inputs $inputs -Model 4 -Deposit 10000 -Period 15
      $configHash=(Get-FileHash -LiteralPath $config -Algorithm SHA256).Hash
      $common=[ordered]@{QueueRank=$rank;Candidate=$profile.Candidate;Role=$profile.Role;Phase='three_lane_momentum_same_side_exit_cooldown_annual_model4';Window=$window.Name;From=$window.From;To=$window.To;Model=4;Deposit=10000;ExpectedReportName=$reportName;ConfigSha256=$configHash;ProfileSha256=$profile.ExpectedHash;SourceSha256=$sourceHash;AnnualContractSha256=$contractHash;StopRule=$stopRule}
      $queue.Add([pscustomobject]($common+[ordered]@{Config="configs\$configName";ProfileSnapshot="profiles\$profileName"}))|Out-Null
      $manifest.Add([pscustomobject]($common+[ordered]@{PackageConfig="$PackageDir\configs\$configName";SourceConfig="$PackageDir\configs\$configName";ReportDestination="$PackageDir\reports_here\$reportName"}))|Out-Null
   }
}
$queue|Export-Csv -LiteralPath (Resolve-P $QueuePath) -NoTypeInformation -Encoding ASCII
$manifest|Export-Csv -LiteralPath (Resolve-P $ManifestPath) -NoTypeInformation -Encoding ASCII
@('# Momentum Same-Side Exit Cooldown Annual Model 4 Package','',"- Source: ``$sourceHash``","- Control: ``$controlHash``","- Center: ``$centerHash``","- Annual contract: ``$contractHash``",'- Profiles: `2`; annual windows: `12`; configurations: `24`; model: `4` real ticks','- Real trading remains disabled.')|Set-Content -LiteralPath (Resolve-P $PackageMarkdownPath) -Encoding ASCII
[pscustomobject][ordered]@{Status='READY';SourceSha256=$sourceHash;ControlProfileSha256=$controlHash;CenterProfileSha256=$centerHash;AnnualContractSha256=$contractHash;Profiles=2;Windows=12;Configurations=$rank;Model=4;LatestDate='2026-07-12'}
