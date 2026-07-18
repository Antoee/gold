$ErrorActionPreference="Stop";Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot "seasonal_gate_helpers.ps1")
$repo=(Resolve-Path (Join-Path $PSScriptRoot "..")).Path
& (Join-Path $PSScriptRoot "build_rc2_momentum_risk_extension_yearly_model4_package.ps1")|Out-Null
$queue=@(Import-Csv (Join-Path $repo "outputs\RC2_MOMENTUM_RISK_EXTENSION_YEARLY_MODEL4_QUEUE.csv"))
if($queue.Count-ne 12 -or @($queue|Where-Object{[int]$_.Model-ne 4 -or [double]$_.Deposit-ne 10000}).Count-ne 0){throw "Yearly tester shape changed."}
if(@($queue|Where-Object{$_.SourceSha256-ne"9141137A9550F3394DE85E1725E018671B4F2A2FF0F43A3EF23F9FB1238CD302" -or $_.ProfileSha256-ne"06AE8127CF2719D7D3A19FEE069ECA3D50B83B3B0329C04F7B08E5F9135AFA5A"}).Count-ne 0){throw "Frozen identity changed."}
$package=Join-Path $repo "outputs\rc2_momentum_risk_extension_yearly_model4_package"
$profile=Join-Path $package "profiles\RC2_MOMENTUM_RISK_EXTENSION_RESEARCH_PROFILE.set"
$inputs=Import-SetInputs $profile
if($inputs.Keys.Count-ne 105){throw "Profile input count changed."}
$raw=Get-Content -Raw $profile
foreach($marker in @("InpMORiskPercent=0.20||","InpRVRiskPercent=0.45||","InpMaximumPortfolioOpenRiskPercent=0.75||","InpAllowRealAccountTrading=false||","InpUseRealAccountSafetyLock=true||")){if($raw-notmatch[regex]::Escape($marker)){throw "Safety marker missing: $marker"}}
foreach($config in (Get-ChildItem (Join-Path $package "configs") -File)){ $text=Get-Content -Raw $config.FullName;foreach($marker in @("Model=4","Deposit=10000","Visual=0")){if($text-notmatch[regex]::Escape($marker)){throw "Config marker missing: $marker"}} }
[pscustomobject]@{Status="PASS";Rows=12;CompletedYears=11;YtdWindows=1;SourceSha256=$queue[0].SourceSha256;ProfileSha256=$queue[0].ProfileSha256;RealTrading=$false}
