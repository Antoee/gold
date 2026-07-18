$ErrorActionPreference="Stop";Set-StrictMode -Version Latest
$repo=(Resolve-Path (Join-Path $PSScriptRoot "..")).Path
& (Join-Path $PSScriptRoot "write_rc2_momentum_risk_extension_money_readiness_decision.ps1")|Out-Null
$decision=@(Import-Csv (Join-Path $repo "outputs\RC2_MOMENTUM_RISK_EXTENSION_MONEY_READINESS_DECISION.csv"))
if($decision.Count-ne 1 -or $decision[0].Status-ne"NOT_MONEY_READY" -or $decision[0].HistoricalResearchBest-ne"True" -or $decision[0].RecommendedForwardCandidateChanged-ne"False"){throw "Money-readiness decision changed."}
if($decision[0].CenterProfileSha256-ne"06AE8127CF2719D7D3A19FEE069ECA3D50B83B3B0329C04F7B08E5F9135AFA5A" -or [double]$decision[0].CenterNetProfit-ne1812.42){throw "Center identity or net changed."}
if([int]$decision[0].GatesFailed-lt 1 -or [int]$decision[0].GatesPending-lt 1 -or $decision[0].RealAccountTradingAllowed-ne"False"){throw "Readiness blockers disappeared unexpectedly."}
if(!(Test-Path (Join-Path $PSScriptRoot "MT5_LOCAL_LAUNCH_DISABLED.lock")) -or (Test-Path (Join-Path $PSScriptRoot "ALLOW_MT5_LOCAL_LAUNCH.unlock")) -or @(Get-Process terminal64,metatester64 -ErrorAction SilentlyContinue).Count-ne 0){throw "MT5 safety lock is not restored."}
"RC2_MOMENTUM_RISK_EXTENSION_MONEY_READINESS_TEST_PASS status=NOT_MONEY_READY"
