$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
& (Join-Path $PSScriptRoot "build_independent_multiscale_momentum_holdout_package.ps1") | Out-Null

$queue = @(Import-Csv -LiteralPath (Join-Path $repo "outputs\INDEPENDENT_MULTISCALE_MOMENTUM_HOLDOUT_MODEL1_QUEUE.csv"))
$manifest = @(Import-Csv -LiteralPath (Join-Path $repo "outputs\INDEPENDENT_MULTISCALE_MOMENTUM_HOLDOUT_MODEL1_PACKAGE_MANIFEST.csv"))
$package = Join-Path $repo "outputs\independent_multiscale_momentum_holdout_model1_package"
$frozenProfiles = Join-Path $repo "outputs\INDEPENDENT_MULTISCALE_MOMENTUM_FROZEN_PROFILES"
if($queue.Count -ne 16 -or $manifest.Count -ne 16) { throw "Expected 16 holdout package rows." }
if(@($queue.Candidate | Sort-Object -Unique).Count -ne 4) { throw "Expected four frozen survivors." }
if(@($queue.Window | Sort-Object -Unique).Count -ne 4) { throw "Expected four holdout/full-history windows." }
if(@($queue | Where-Object {$_.To -ne "2026.07.16" -and $_.Window -ne "holdout_2021_2023"}).Count) {
   throw "Unexpected holdout end date."
}
foreach($row in $queue) {
   $profile = Join-Path $package $row.ProfileSnapshot
   $frozenProfile = Join-Path $frozenProfiles $row.Set
   $config = Join-Path $package $row.Config
   if(!(Test-Path -LiteralPath $profile) -or !(Test-Path -LiteralPath $config)) { throw "Missing package artifact." }
   if((Get-FileHash -LiteralPath $profile -Algorithm SHA256).Hash -ne $row.ProfileSha256) { throw "Holdout profile hash mismatch." }
   if((Get-FileHash -LiteralPath $frozenProfile -Algorithm SHA256).Hash -ne $row.ProfileSha256) { throw "Frozen discovery profile identity changed." }
   $text = Get-Content -LiteralPath $profile -Raw
   if($text -match '(?m)^InpAllowRealAccountTrading=true') { throw "Real trading enabled in profile." }
   if($text -notmatch '(?m)^InpRiskPercent=0\.10\|\|') { throw "Risk contract mismatch." }
   if($text -match 'Inp(Allowed|Blocked)(Year|Month)') { throw "Calendar-fitting input found." }
}

"INDEPENDENT_MULTISCALE_MOMENTUM_HOLDOUT_PACKAGE_TEST_PASS"
