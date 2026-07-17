$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
& (Join-Path $PSScriptRoot "build_h4_channel_capital_feasible_model1_package.ps1") | Out-Null

$queuePath = Join-Path $repo "outputs\H4_CHANNEL_CAPITAL_FEASIBLE_MODEL1_QUEUE.csv"
$manifestPath = Join-Path $repo "outputs\H4_CHANNEL_CAPITAL_FEASIBLE_MODEL1_PACKAGE_MANIFEST.csv"
$packagePath = Join-Path $repo "outputs\h4_channel_capital_feasible_model1_package"
$queue = @(Import-Csv -LiteralPath $queuePath)
$manifest = @(Import-Csv -LiteralPath $manifestPath)

if($queue.Count -ne 12 -or $manifest.Count -ne 12) { throw "Expected 12 package rows." }
if(@($queue | Where-Object RiskPercent -ne "0.50").Count -ne 0) { throw "Every row must use 0.50% risk." }
if(@($queue.Candidate | Sort-Object -Unique).Count -ne 4) { throw "Expected four candidates." }
if(@($queue.Window | Sort-Object -Unique).Count -ne 3) { throw "Expected three windows." }
foreach($row in $queue) {
   $config = Join-Path $packagePath $row.Config
   $profile = Join-Path $packagePath $row.ProfileSnapshot
   if(!(Test-Path -LiteralPath $config) -or !(Test-Path -LiteralPath $profile)) {
      throw "Missing package artifact for $($row.Candidate)/$($row.Window)."
   }
   $profileText = Get-Content -LiteralPath $profile -Raw
   if($profileText -notmatch '(?m)^InpRiskPercent=0\.50\|\|') { throw "Profile risk mismatch: $profile" }
   if($profileText -match '(?m)^InpAllowRealAccountTrading=true') { throw "Real trading enabled: $profile" }
}

"H4_CHANNEL_CAPITAL_FEASIBLE_PACKAGE_TEST_PASS"
