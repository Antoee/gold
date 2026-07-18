$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot "seasonal_gate_helpers.ps1")

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
& (Join-Path $PSScriptRoot "build_rc2_momentum_risk_extension_model1_package.ps1") | Out-Null
$queue = @(Import-Csv -LiteralPath (Join-Path $repo "outputs\RC2_MOMENTUM_RISK_EXTENSION_MODEL1_QUEUE.csv"))
$package = Join-Path $repo "outputs\rc2_momentum_risk_extension_model1_package"
if($queue.Count -ne 28) { throw "Expected 28 queue rows." }
if(@($queue.Candidate | Sort-Object -Unique).Count -ne 7) { throw "Expected seven profiles." }
if(@($queue.Window | Sort-Object -Unique).Count -ne 4) { throw "Expected four windows." }
if(@($queue | Where-Object {[int]$_.Model -ne 1 -or [double]$_.Deposit -ne 10000}).Count -ne 0) { throw "Tester contract changed." }
if(@($queue | Where-Object {$_.SourceSha256 -ne "9141137A9550F3394DE85E1725E018671B4F2A2FF0F43A3EF23F9FB1238CD302"}).Count -ne 0) { throw "Source identity changed." }

$expected = [ordered]@{
   mre_mo015_control="0.15";mre_mo0175="0.175";mre_mo020_center="0.20";mre_mo0225="0.225"
   mre_mo025="0.25";mre_mo0275="0.275";mre_mo030="0.30"
}
foreach($group in ($queue | Group-Object Candidate)) {
   if($group.Count -ne 4) { throw "Each profile must have four windows: $($group.Name)" }
   $row = $group.Group[0]
   if(!$expected.Contains($group.Name) -or $row.MORiskPercent -ne $expected[$group.Name]) { throw "Momentum risk mismatch: $($group.Name)" }
   if([double]$row.RVRiskPercent + [double]$row.MORiskPercent -gt 0.7500001) { throw "Requested risks exceed cap: $($group.Name)" }
   $profile = Join-Path $package $row.ProfileSnapshot
   if((Get-FileHash -LiteralPath $profile -Algorithm SHA256).Hash -ne $row.ProfileSha256) { throw "Profile hash mismatch: $($group.Name)" }
   $inputs = Import-SetInputs -Path $profile
   if($inputs.Keys.Count -ne 105) { throw "Input count mismatch: $($group.Name)" }
   foreach($required in @(
      "InpRVRiskPercent=0.45||", "InpMORiskPercent=$($row.MORiskPercent)||",
      "InpMaximumPortfolioOpenRiskPercent=0.75||", "InpAllowRealAccountTrading=false||",
      "InpUseRealAccountSafetyLock=true||", "InpRequireHedgingAccount=true||",
      "InpExpectedInitialBalance=10000.0||", "InpLogTrades=false||"
   )) {
      if((Get-Content -Raw -LiteralPath $profile) -notmatch [regex]::Escape($required)) { throw "Profile safety marker missing: $required" }
   }
}

[pscustomobject]@{Status="PASS";Rows=$queue.Count;Profiles=7;Windows=4;SourceSha256=$queue[0].SourceSha256;MaximumOpenRiskPercent=0.75;RealTrading=$false}
