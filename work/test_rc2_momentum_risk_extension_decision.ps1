$ErrorActionPreference="Stop";Set-StrictMode -Version Latest
$repo=(Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$m1=@(Import-Csv (Join-Path $repo "outputs\RC2_MOMENTUM_RISK_EXTENSION_MODEL1_DECISION.csv"))
$m4=@(Import-Csv (Join-Path $repo "outputs\RC2_MOMENTUM_RISK_EXTENSION_MODEL4_DECISION.csv"))
$summary=@(Import-Csv (Join-Path $repo "outputs\RC2_MOMENTUM_RISK_EXTENSION_MODEL4_SUMMARY.csv"))
$results=@(Import-Csv (Join-Path $repo "outputs\RC2_MOMENTUM_RISK_EXTENSION_MODEL4_RESULTS.csv"))
if($m1.Count-ne 1 -or $m1[0].Status-ne "MODEL1_GATE_PASSED" -or $m1[0].Model4Permitted-ne "True"){throw "Model1 gate evidence changed."}
if($m4.Count-ne 1 -or $m4[0].Status-ne "MODEL4_GATE_PASSED" -or $m4[0].ResearchPromotionPermitted-ne "True" -or $m4[0].ForwardCandidateChanged-ne "False" -or $m4[0].CenterProfileSha256-ne "06AE8127CF2719D7D3A19FEE069ECA3D50B83B3B0329C04F7B08E5F9135AFA5A"){throw "Model4 decision changed."}
if($results.Count-ne 12 -or @($results|Where-Object{$_.Status-ne"PARSED" -or $_.RunnerStatus-ne"REPORT_FOUND"}).Count-ne 0){throw "Expected 12 parsed identity-valid Model4 reports."}
if($summary.Count-ne 3 -or @($summary|Where-Object{$_.GatePass-ne"True"}).Count-ne 0){throw "The center/neighbor plateau no longer passes."}
$center=@($summary|Where-Object Candidate -eq "mre_mo020_center")
if($center.Count-ne 1 -or [math]::Abs([double]$center[0].ContinuousNetProfit-1812.42)-gt 0.001 -or [double]$center[0].ProfitFactor-lt 1.50 -or [int]$center[0].Trades-ne 362 -or [double]$center[0].MaxDrawdownPercent-gt 4.00 -or [double]$center[0].RecoveryFactor-lt 4.00){throw "Center metrics changed."}
if([double]$center[0].TotalReturnPercent-ne 18.12 -or [double]$center[0].CagrPercent-ne 1.45){throw "Center return percentages changed."}
$profile=Join-Path $repo "outputs\RC2_MOMENTUM_RISK_EXTENSION_RESEARCH_PROFILE.set"
$profileHash=(Get-FileHash $profile -Algorithm SHA256).Hash
if($profileHash-ne "06AE8127CF2719D7D3A19FEE069ECA3D50B83B3B0329C04F7B08E5F9135AFA5A"){throw "Center profile identity changed: $profileHash"}
if(!(Test-Path (Join-Path $PSScriptRoot "MT5_LOCAL_LAUNCH_DISABLED.lock")) -or (Test-Path (Join-Path $PSScriptRoot "ALLOW_MT5_LOCAL_LAUNCH.unlock")) -or (Test-Path (Join-Path $PSScriptRoot "ALLOW_MT5_HIDDEN_DESKTOP_ACK.unlock"))){throw "MT5 launch lock is not restored."}
if(@(Get-Process terminal64,metatester64 -ErrorAction SilentlyContinue).Count-ne 0){throw "MT5 process remains after validation."}
[pscustomobject]@{Status="PASS";Model1Reports=28;Model4Reports=12;CenterNetProfit=1812.42;TotalReturnPercent=18.12;CagrPercent=1.45;ProfitFactor=1.50;Trades=362;MaxDrawdownPercent=3.19;RecoveryFactor=5.1252;ProfileSha256=$profileHash;ForwardCandidateChanged=$false}
