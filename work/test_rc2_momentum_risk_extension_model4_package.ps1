$ErrorActionPreference="Stop";Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot "seasonal_gate_helpers.ps1")
$repo=(Resolve-Path (Join-Path $PSScriptRoot "..")).Path
& (Join-Path $PSScriptRoot "build_rc2_momentum_risk_extension_model4_package.ps1")|Out-Null
$queue=@(Import-Csv (Join-Path $repo "outputs\RC2_MOMENTUM_RISK_EXTENSION_MODEL4_QUEUE.csv"))
$package=Join-Path $repo "outputs\rc2_momentum_risk_extension_model4_package"
if($queue.Count-ne 12){throw "Expected 12 Model4 rows."}
if(@($queue.Candidate|Sort-Object -Unique).Count-ne 3 -or @($queue.Window|Sort-Object -Unique).Count-ne 4){throw "Frozen Model4 shape changed."}
if(@($queue|Where-Object{[int]$_.Model-ne 4 -or [double]$_.Deposit-ne 10000}).Count-ne 0){throw "Tester contract changed."}
if(@($queue|Where-Object{$_.SourceSha256-ne "9141137A9550F3394DE85E1725E018671B4F2A2FF0F43A3EF23F9FB1238CD302"}).Count-ne 0){throw "Source identity changed."}
$expected=[ordered]@{mre_mo0175="0.175";mre_mo020_center="0.20";mre_mo0225="0.225"}
foreach($group in ($queue|Group-Object Candidate)) {
   if($group.Count-ne 4 -or !$expected.Contains($group.Name)){throw "Unexpected Model4 profile: $($group.Name)"}
   $row=$group.Group[0]
   if($row.MORiskPercent-ne$expected[$group.Name] -or [double]$row.RVRiskPercent+[double]$row.MORiskPercent-gt 0.7500001){throw "Risk contract changed: $($group.Name)"}
   $profile=Join-Path $package $row.ProfileSnapshot
   if((Get-FileHash $profile -Algorithm SHA256).Hash-ne$row.ProfileSha256){throw "Profile hash mismatch: $($group.Name)"}
   $inputs=Import-SetInputs -Path $profile
   if($inputs.Keys.Count-ne 105){throw "Input count changed: $($group.Name)"}
   $raw=Get-Content -Raw $profile
   foreach($required in @("InpRVRiskPercent=0.45||","InpMORiskPercent=$($row.MORiskPercent)||","InpMaximumPortfolioOpenRiskPercent=0.75||","InpAllowRealAccountTrading=false||","InpUseRealAccountSafetyLock=true||","InpExpectedInitialBalance=10000.0||","InpEvidenceRunLabel=rc2_momentum_risk_extension_model4")) {
      if($raw-notmatch[regex]::Escape($required)){throw "Safety marker missing: $required"}
   }
}
foreach($config in (Get-ChildItem (Join-Path $package "configs") -File)) {
   $raw=Get-Content -Raw $config.FullName
   foreach($required in @("Model=4","Deposit=10000","Visual=0","Expert=Professional_XAUUSD_EA.ex5")){if($raw-notmatch[regex]::Escape($required)){throw "Config marker missing: $required"}}
}
[pscustomobject]@{Status="PASS";Rows=12;Profiles=3;Windows=4;Model=4;SourceSha256=$queue[0].SourceSha256;RealTrading=$false}
