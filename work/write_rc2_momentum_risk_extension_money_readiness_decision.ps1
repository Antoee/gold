param(
   [string]$OutCsv="outputs\RC2_MOMENTUM_RISK_EXTENSION_MONEY_READINESS_DECISION.csv",
   [string]$OutMarkdown="outputs\RC2_MOMENTUM_RISK_EXTENSION_MONEY_READINESS_DECISION.md"
)
$ErrorActionPreference="Stop"
Set-StrictMode -Version Latest
$repo=(Resolve-Path (Join-Path $PSScriptRoot "..")).Path
function Resolve-RepoPath([string]$path){if([IO.Path]::IsPathRooted($path)){return $path};return Join-Path $repo $path}
function Read-One([string]$path){$rows=@(Import-Csv (Resolve-RepoPath $path));if($rows.Count-ne 1){throw "Expected one row: $path"};return $rows[0]}

$historical=Read-One "outputs\RC2_MOMENTUM_RISK_EXTENSION_MODEL4_DECISION.csv"
$annualGates=@(Import-Csv (Resolve-RepoPath "outputs\RC2_MOMENTUM_RISK_EXTENSION_YEARLY_MODEL4_GATES.csv"))
$stress=Read-One "outputs\RC2_MOMENTUM_RISK_EXTENSION_STRESS_DECISION.csv"
$monte=@(Import-Csv (Resolve-RepoPath "outputs\RC2_MOMENTUM_RISK_EXTENSION_MONTE_CARLO.csv"))
$comparison=@(Import-Csv (Resolve-RepoPath "outputs\RC2_MOMENTUM_RISK_EXTENSION_STRESS_CONTROL_COMPARISON.csv"))
$forward=Read-One "outputs\TRANSFERABLE_PORTFOLIO_FORWARD_DEMO_STATUS.csv"

$gates=[Collections.Generic.List[object]]::new()
function Add-Gate([string]$area,[string]$status,[string]$evidence){$gates.Add([pscustomobject]@{Area=$area;Status=$status;Evidence=$evidence})|Out-Null}
Add-Gate "historical:model4" $(if($historical.Status-eq"MODEL4_GATE_PASSED"){"PASS"}else{"FAIL"}) "net=$($historical.CenterNetProfit);reports=$($historical.ReportsParsed);profile=$($historical.CenterProfileSha256)"
$annualFailed=@($annualGates|Where-Object Pass -ne "True")
Add-Gate "historical:annual-restarts" $(if($annualFailed.Count-eq 0){"PASS"}else{"FAIL"}) "passed=$($annualGates.Count-$annualFailed.Count)/$($annualGates.Count);failed=$($annualFailed.Gate -join ',')"
Add-Gate "stress:deterministic-cost" $(if($stress.CostGatePass-eq"True"){"PASS"}else{"FAIL"}) "moderate and severe frozen cost gates"
Add-Gate "stress:bootstrap-monte-carlo" $(if($stress.MonteCarloGatePass-eq"True"){"PASS"}else{"FAIL"}) "standard/severe 10000-trial bootstrap gates"
Add-Gate "forward:capital-contract" $(if($forward.AccountContractPass-eq"True"){"PASS"}else{"FAIL"}) "attached balance does not match frozen 10000 contract"
$samplePass=([double]$forward.CalendarDays-ge[double]$forward.MinimumCalendarDays)-and([int]$forward.ClosedTrades-ge[int]$forward.MinimumClosedTrades)
Add-Gate "forward:minimum-sample" $(if($samplePass){"PASS"}else{"PENDING"}) "validDays=0/$($forward.MinimumCalendarDays);trades=$($forward.ClosedTrades)/$($forward.MinimumClosedTrades)"
Add-Gate "broker:second-specification" "PENDING" "no exact second-broker XAUUSD report"
Add-Gate "safety:real-account-lock" $(if($forward.RealAccountTradingAllowed-eq"False"){"PASS"}else{"FAIL"}) "real-account trading remains disabled"

$failed=@($gates|Where-Object Status -eq "FAIL")
$pending=@($gates|Where-Object Status -eq "PENDING")
$status=if($failed.Count-eq 0-and$pending.Count-eq 0){"MONEY_READY"}else{"NOT_MONEY_READY"}
$decision=[pscustomobject]@{
   Status=$status;HistoricalResearchBest=$true;RecommendedForwardCandidateChanged=$false
   CenterNetProfit=$historical.CenterNetProfit;CenterProfileSha256=$historical.CenterProfileSha256
   GatesPassed=@($gates|Where-Object Status -eq "PASS").Count;GatesFailed=$failed.Count;GatesPending=$pending.Count
   RealAccountTradingAllowed=$false
}
$decision|Export-Csv (Resolve-RepoPath $OutCsv) -NoTypeInformation -Encoding ASCII

$standardCenter=$comparison|Where-Object{$_.Profile-eq"center_mo020"-and$_.Scenario-eq"standard"}|Select-Object -First 1
$standardControl=$comparison|Where-Object{$_.Profile-eq"control_mo015"-and$_.Scenario-eq"standard"}|Select-Object -First 1
$severeCenter=$monte|Where-Object Scenario -eq "severe"|Select-Object -First 1
$md=[Collections.Generic.List[string]]::new()
$md.Add("# RC2 Momentum-Risk Extension Money-Readiness Decision")
$md.Add("")
$md.Add("**Decision: NOT MONEY-READY. The 0.20% profile remains the highest validated historical net, but the 0.15% control remains the safer forward-test candidate. Real-account trading remains disabled.**")
$md.Add("")
$md.Add("## What Passed")
$md.Add("")
$md.Add("- Continuous Model4: ``+$($historical.CenterNetProfit)``, PF ``1.50``, ``362`` trades, ``3.19%`` equity drawdown, ``12 / 12`` center/neighbor reports passed.")
$md.Add('- Annual restarts: `9 / 11` completed years positive, `+$1,778.14` summed restart net, worst annual loss `-$64.93`.')
$md.Add("- Added-cost stress: moderate ``0.05R`` and severe ``0.10R`` per trade remained profitable; deterministic cost gate passed.")
$md.Add("")
$md.Add("## Blocking Evidence")
$md.Add("")
$md.Add('- Annual restart gate: 2019-2020 totals `-$117.26` versus the frozen `-$100` floor; 2019 PF is `0.82` versus `0.85`.')
$md.Add("- Standard bootstrap: center P95 drawdown ``$($standardCenter.P95MaxClosedDrawdownPercent)%`` and loss run ``$($standardCenter.P95MaxConsecutiveLosses)``; both exceed the frozen caps. The 0.15% control is safer at ``$($standardControl.P95MaxClosedDrawdownPercent)%`` P95 drawdown.")
$md.Add("- Severe bootstrap: P05 net ``-$([math]::Abs([double]$severeCenter.P05NetProfit).ToString('N2'))``, P95 drawdown ``$($severeCenter.P95MaxClosedDrawdownPercent)%``, and ``$($severeCenter.RedTrialPercent)%`` red trials.")
$md.Add("- Forward demo: zero valid days and zero trades because the attached account violates the frozen starting-capital contract.")
$md.Add("- No exact second-broker XAUUSD validation exists.")
$md.Add("")
$md.Add("## Gate Summary")
$md.Add("")
$md.Add("| Area | Status | Evidence |")
$md.Add("|---|---|---|")
foreach($gate in $gates){$md.Add("| $($gate.Area) | $($gate.Status) | $($gate.Evidence) |")}
$md.Add("")
$md.Add("## Next Strategy Work")
$md.Add("")
$md.Add("Do not raise risk further. The next code experiment must improve the momentum lane's date-independent breakout quality or add a genuinely independent return stream, then repeat broad Model1, exact Model4, annual restart, cost, and bootstrap gates. Calendar exclusions and post-result threshold changes are not permitted.")
$md.Add("")
$md.Add("The registered source/profile/binary identity, evidence logs, account contract, and real-account lock remain unchanged.")
$md|Set-Content (Resolve-RepoPath $OutMarkdown) -Encoding ASCII
$decision
