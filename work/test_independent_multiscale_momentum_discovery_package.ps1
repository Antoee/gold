$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
& (Join-Path $PSScriptRoot "build_independent_multiscale_momentum_discovery_package.ps1") | Out-Null

$queue = @(Import-Csv -LiteralPath (Join-Path $repo "outputs\INDEPENDENT_MULTISCALE_MOMENTUM_DISCOVERY_MODEL1_QUEUE.csv"))
$manifest = @(Import-Csv -LiteralPath (Join-Path $repo "outputs\INDEPENDENT_MULTISCALE_MOMENTUM_DISCOVERY_MODEL1_PACKAGE_MANIFEST.csv"))
$package = Join-Path $repo "outputs\independent_multiscale_momentum_discovery_model1_package"
if($queue.Count -ne 21 -or $manifest.Count -ne 21) { throw "Expected 21 package rows." }
if(@($queue.Candidate | Sort-Object -Unique).Count -ne 7) { throw "Expected seven candidates." }
if(@($queue.Window | Sort-Object -Unique).Count -ne 3) { throw "Expected three discovery windows." }
if(@($queue | Where-Object {[int]$_.To.Substring(0,4) -gt 2020}).Count) { throw "Post-2020 data leaked into discovery." }
foreach($row in $queue) {
   $profile = Join-Path $package $row.ProfileSnapshot
   $config = Join-Path $package $row.Config
   if(!(Test-Path -LiteralPath $profile) -or !(Test-Path -LiteralPath $config)) { throw "Missing package artifact." }
   $text = Get-Content -LiteralPath $profile -Raw
   if($text -match '(?m)^InpAllowRealAccountTrading=true') { throw "Real trading enabled in profile." }
   if($text -notmatch '(?m)^InpRiskPercent=0\.10\|\|') { throw "Risk contract mismatch." }
   if($text -match 'Inp(Allowed|Blocked)(Year|Month)') { throw "Calendar-fitting input found." }
}

"INDEPENDENT_MULTISCALE_MOMENTUM_PACKAGE_TEST_PASS"
