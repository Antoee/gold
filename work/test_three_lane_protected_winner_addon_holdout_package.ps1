$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$repo=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$package=Join-Path $repo 'outputs\three_lane_protected_winner_addon_holdout_model1_package'
$manifest=Join-Path $repo 'outputs\THREE_LANE_PROTECTED_WINNER_ADDON_HOLDOUT_MODEL1_PACKAGE_MANIFEST.csv'
$sourceHash='F7AAEFF24C4A0FF8066C906A25F99462E1F2488765AD046364B970277AAD5B46'
$profileHashes=@{pwa_control='65A3228E1C705BFE1DC97ADE7CEF94D3F5AE49C63E4E8E92708DCE699E7B6BCD';pwa_trigger100='50CC443F2FE19D53EA38B15D10CD92242D7A291452B603EC4B2B7A67F0C78F42'}
$rows=@(Import-Csv -LiteralPath $manifest)
if($rows.Count-ne8-or@($rows.Candidate|Sort-Object -Unique).Count-ne2-or@($rows.Window|Sort-Object -Unique).Count-ne4){throw 'Holdout matrix coverage failed.'}
if(@($rows|Where-Object{$_.Model-ne'1'-or$_.Deposit-ne'10000'-or[datetime]$_.From-lt[datetime]'2021-01-01'-or[datetime]$_.To-gt[datetime]'2026-07-18'}).Count){throw 'Holdout date/model/deposit contract failed.'}
if(@($rows|Where-Object {$_.SourceSha256 -ne $sourceHash}).Count){throw 'Holdout source identity failed.'}
foreach($candidate in $profileHashes.Keys){
   $path=Join-Path $package "profiles\$candidate.set";$hash=(Get-FileHash $path -Algorithm SHA256).Hash.ToUpperInvariant()
   if($hash-ne$profileHashes[$candidate]-or@(Get-Content $path|Where-Object{$_-match'^Inp[^=]+='}).Count-ne187){throw "Holdout profile failed: $candidate"}
   if(@($rows|Where-Object{$_.Candidate-eq$candidate-and$_.ProfileSha256-ne$hash}).Count){throw "Manifest profile hash failed: $candidate"}
}
$selected=Get-Content (Join-Path $package 'profiles\pwa_trigger100.set') -Raw
foreach($token in @('InpMOUseProtectedWinnerAddOn=true||true||0||0||N','InpMOAddOnMinimumProfitR=1.00||1.00||0||0||N','InpAllowRealAccountTrading=false||false||0||0||N','InpMaximumPortfolioOpenRiskPercent=0.75||0.75||0||0||N')){if($selected.IndexOf($token,[StringComparison]::Ordinal)-lt0){throw "Selected pin missing: $token"}}
if((Get-FileHash (Join-Path $package 'source\Professional_XAUUSD_EA.mq5') -Algorithm SHA256).Hash.ToUpperInvariant()-ne$sourceHash){throw 'Packaged source failed.'}
[pscustomobject]@{Status='PASS';Rows=8;Profiles=2;Windows=4;EarliestDate='2021-01-01';LatestDate='2026-07-18';SourceSha256=$sourceHash}
