Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$sourcePath = Join-Path $repo 'release\three-lane-trade-ready-rc2-atb150\Professional_XAUUSD_Three_Lane_Trade_Ready_RC2_ATB150.mq5'
$profilePath = Join-Path $repo 'release\three-lane-trade-ready-rc2-atb150\THREE_LANE_TRADE_READY_RC2_ATB150.set'
$reportPath = Join-Path $repo 'outputs\three_lane_trade_ready_rc2_growth_decomp_model4_package\reports_here\tlat_rc2_decomp_atb150_continuous_2015_2026_m4.htm'
$identityPath = Join-Path $repo 'outputs\three_lane_trade_ready_rc2_growth_decomp_model4_package\reports_here\tlat_rc2_decomp_atb150_continuous_2015_2026_m4.identity.json'
$outCsv = Join-Path $repo 'outputs\THREE_LANE_TRADE_READY_RC2_ATB150_STATIC_SAFETY.csv'
$outMd = Join-Path $repo 'outputs\THREE_LANE_TRADE_READY_RC2_ATB150_STATIC_SAFETY.md'

$expectedSource = '2F1C1C74067DA6173EB4133DB75C0B0DB4DE7BE46F2BB7A453AEE044536B2158'
$expectedProfile = '705E2154CF6D123151B67757FFCA3EBF7D8BD525CD859E8237F89674CF70DC4E'
$expectedReport = '31A383253B7BF7611D6209E296317105E4C5756A8A12D883C0872245866B1B4D'
$expectedBinary = 'E24203F2E7AF184B6B6BB3902F7C8711DD887B0E0346C22ED87E8F07EB1AC7B8'

$checks = [Collections.Generic.List[object]]::new()
function Add-Check([string]$Name,[bool]$Pass,[string]$Evidence) {
   $checks.Add([pscustomobject]@{Check=$Name;Pass=$Pass;Evidence=$Evidence}) | Out-Null
}
function Read-Csv([string]$Path) {
   if(!(Test-Path -LiteralPath $Path -PathType Leaf)){return @()}
   return @(Import-Csv -LiteralPath $Path)
}

$baseOutput = & (Join-Path $PSScriptRoot 'test_three_lane_trade_ready_rc2_static_safety.ps1')
Add-Check 'base RC2 static safety remains passing' ($baseOutput -match 'PASS checks=79') ($baseOutput -join ' ')

foreach($path in @($sourcePath,$profilePath,$reportPath,$identityPath)) {
   Add-Check "artifact exists: $([IO.Path]::GetFileName($path))" (Test-Path -LiteralPath $path -PathType Leaf) $path.Replace($repo + '\','')
}
if(@($checks | Where-Object {!$_.Pass}).Count -gt 0) { throw 'Required ATB150 artifact is missing.' }

$sourceHash=(Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash.ToUpperInvariant()
$profileHash=(Get-FileHash -LiteralPath $profilePath -Algorithm SHA256).Hash.ToUpperInvariant()
$reportHash=(Get-FileHash -LiteralPath $reportPath -Algorithm SHA256).Hash.ToUpperInvariant()
Add-Check 'release source identity is exact' ($sourceHash -eq $expectedSource) $sourceHash
Add-Check 'release profile identity is exact' ($profileHash -eq $expectedProfile) $profileHash
Add-Check 'continuous report identity is exact' ($reportHash -eq $expectedReport) $reportHash
Add-Check 'release source matches work source' ((Get-FileHash -LiteralPath (Join-Path $repo 'work\Professional_XAUUSD_Three_Lane_Adaptive_Trend_Trade_Ready_RC2.mq5') -Algorithm SHA256).Hash -eq $sourceHash) 'byte-identical source'
Add-Check 'release profile matches tested profile' ((Get-FileHash -LiteralPath (Join-Path $repo 'outputs\three_lane_trade_ready_rc2_growth_decomp_model4_package\profiles\tlat_rc2_decomp_atb150.set') -Algorithm SHA256).Hash -eq $profileHash) 'byte-identical profile'

$identity=Get-Content -LiteralPath $identityPath -Raw | ConvertFrom-Json
Add-Check 'identity source hash matches' ([string]$identity.SourceSha256 -eq $expectedSource) ([string]$identity.SourceSha256)
Add-Check 'identity report hash matches' ([string]$identity.ReportSha256 -eq $expectedReport) ([string]$identity.ReportSha256)
Add-Check 'identity binary hash matches' ([string]$identity.PortableBinarySha256 -eq $expectedBinary) ([string]$identity.PortableBinarySha256)

$profile=[ordered]@{}
foreach($line in Get-Content -LiteralPath $profilePath){
   if($line -notmatch '^([^;=]+)=(.*)$'){continue}
   if($profile.Contains($Matches[1])){Add-Check "duplicate profile key $($Matches[1])" $false $line;continue}
   $profile[$Matches[1]]=$Matches[2].Split('||')[0]
}
Add-Check 'profile pins 178 inputs' ($profile.Count -eq 178) "count=$($profile.Count)"
$expectedInputs=[ordered]@{
   InpAllowedSymbol='XAUUSD';InpUseRealAccountSafetyLock='true';InpAllowRealAccountTrading='false';InpRealAccountApprovalCode='DISABLED'
   InpUseInitialBalanceContract='true';InpExpectedInitialBalance='10000.0';InpUseAccountCurrencyLock='true';InpRequiredAccountCurrency='USD'
   InpUseDedicatedAccountContract='true';InpRejectFundingChangesAfterRegistration='true';InpMaximumPortfolioEquityDrawdownPercent='5.00'
   InpMaximumPortfolioDailyLossPercent='0.75';InpMaximumPortfolioWeeklyLossPercent='1.25';InpMaximumPortfolioMonthlyLossPercent='1.50'
   InpMaximumPortfolioOpenRiskPercent='0.75';InpMaximumAccountPositions='3';InpBlockUnprotectedAccountExposure='true'
   InpCloseUnprotectedManagedPositions='true';InpUseTradeEnvironmentGuard='true';InpRequireConfirmedTradeResults='true'
   InpUsePostFillRiskReconciliation='true';InpPostFillRiskTolerancePercent='0.005'
   InpRVRiskPercent='0.45';InpMORiskPercent='0.15';InpATBRiskPercent='0.15';InpLogTrades='false';InpShowDashboard='false'
}
foreach($pair in $expectedInputs.GetEnumerator()){
   $actual=if($profile.Contains($pair.Key)){$profile[$pair.Key]}else{'MISSING'}
   Add-Check "profile pin $($pair.Key)" ($actual -eq $pair.Value) "actual=$actual expected=$($pair.Value)"
}
Add-Check 'profile embeds source identity' ($profile['InpEvidenceSourceHash'] -eq $expectedSource) $profile['InpEvidenceSourceHash']

$broad=Read-Csv (Join-Path $repo 'outputs\THREE_LANE_TRADE_READY_RC2_GROWTH_DECOMP_MODEL4_METRICS.csv')
$candidate=@($broad|Where-Object Profile -eq 'tlat_rc2_decomp_atb150')
$continuous=@($candidate|Where-Object Window -eq 'continuous_2015_2026')
$baseline=@(Read-Csv (Join-Path $repo 'outputs\THREE_LANE_TRADE_READY_RC2_MODEL4_BROAD_METRICS.csv')|Where-Object {$_.Profile -eq 'tlat_rc2_di12_center' -and $_.Window -eq 'continuous_2015_2026'})
Add-Check 'Model 4 broad candidate is complete and positive' ($candidate.Count -eq 4 -and @($candidate|Where-Object {$_.Status -ne 'PARSED' -or [double]$_.NetProfit -le 0}).Count -eq 0) "rows=$($candidate.Count)"
Add-Check 'continuous comparison rows are unique' ($continuous.Count -eq 1 -and $baseline.Count -eq 1) "candidate=$($continuous.Count) baseline=$($baseline.Count)"
if($continuous.Count -eq 1 -and $baseline.Count -eq 1) {
   $c=$continuous[0];$b=$baseline[0]
   Add-Check 'continuous net improves by at least 5%' ([double]$c.NetProfit -ge 1.05*[double]$b.NetProfit) "candidate=$($c.NetProfit) baseline=$($b.NetProfit)"
   Add-Check 'continuous equity drawdown improves' ([double]$c.MaxDrawdownMoney -lt [double]$b.MaxDrawdownMoney) "candidate=$($c.MaxDrawdownMoney) baseline=$($b.MaxDrawdownMoney)"
   Add-Check 'continuous recovery improves' ([double]$c.RecoveryFactor -gt [double]$b.RecoveryFactor) "candidate=$($c.RecoveryFactor) baseline=$($b.RecoveryFactor)"
   Add-Check 'continuous PF remains at least 1.80' ([double]$c.ProfitFactor -ge 1.80) "PF=$($c.ProfitFactor)"
   Add-Check 'continuous trade count increases' ([int]$c.TotalTrades -gt [int]$b.TotalTrades) "candidate=$($c.TotalTrades) baseline=$($b.TotalTrades)"
}

$annual=Read-Csv (Join-Path $repo 'outputs\THREE_LANE_TRADE_READY_RC2_ATB150_ANNUAL_MODEL4_METRICS.csv')
Add-Check 'annual evidence is 12/12 parsed and positive' ($annual.Count -eq 12 -and @($annual|Where-Object {$_.Status -ne 'PARSED' -or [double]$_.NetProfit -le 0}).Count -eq 0) "rows=$($annual.Count)"

$risk=Read-Csv (Join-Path $repo 'outputs\THREE_LANE_TRADE_READY_RC2_ATB150_MODEL4_RISK_AUDIT.csv')
$cost=Read-Csv (Join-Path $repo 'outputs\THREE_LANE_TRADE_READY_RC2_ATB150_MODEL4_COST_STRESS.csv')
$mc=Read-Csv (Join-Path $repo 'outputs\THREE_LANE_TRADE_READY_RC2_ATB150_MODEL4_MONTE_CARLO.csv')
Add-Check 'hard-risk ledger is complete' ($risk.Count -eq 404 -and @($risk|Where-Object {$_.LanePass -ne 'True' -or $_.PortfolioPass -ne 'True'}).Count -eq 0) '404/404 pass'
Add-Check 'deterministic cost stress is 4/4 passing' ($cost.Count -eq 4 -and @($cost|Where-Object GatePass -ne 'True').Count -eq 0) '4/4 pass'
$severeCost=@($cost|Where-Object Scenario -eq 'severe')
Add-Check 'severe cost remains useful' ($severeCost.Count -eq 1 -and [double]$severeCost[0].NetProfit -gt 1400 -and [double]$severeCost[0].ProfitFactor -ge 1.50 -and $severeCost[0].AllBroadErasPositive -eq 'True') "net=$($severeCost[0].NetProfit) PF=$($severeCost[0].ProfitFactor)"
Add-Check 'Monte Carlo stress is 8/8 passing' ($mc.Count -eq 8 -and @($mc|Where-Object GatePass -ne 'True').Count -eq 0) '8/8 pass'
$severeMc=@($mc|Where-Object StressScenario -eq 'severe')
Add-Check 'severe Monte Carlo P05 remains positive' ($severeMc.Count -eq 4 -and ($severeMc.P05NetProfit|Measure-Object -Minimum).Minimum -gt 200) "minimum=$((($severeMc.P05NetProfit|Measure-Object -Minimum).Minimum))"
Add-Check 'severe Monte Carlo P95 DD stays below 4.50%' ($severeMc.Count -eq 4 -and ($severeMc.P95MaxClosedDrawdownPercent|Measure-Object -Maximum).Maximum -lt 4.50) "maximum=$((($severeMc.P95MaxClosedDrawdownPercent|Measure-Object -Maximum).Maximum))"
Add-Check 'severe Monte Carlo red trials stay below 1.50%' ($severeMc.Count -eq 4 -and ($severeMc.RedTrialPercent|Measure-Object -Maximum).Maximum -lt 1.50) "maximum=$((($severeMc.RedTrialPercent|Measure-Object -Maximum).Maximum))"

$repoLock=Join-Path $repo 'work\MT5_LOCAL_LAUNCH_DISABLED.lock'
$outerLock=Join-Path (Split-Path -Parent $repo) 'MT5_LOCAL_LAUNCH_DISABLED.lock'
Add-Check 'repository launch lock restored' (Test-Path -LiteralPath $repoLock -PathType Leaf) 'present'
Add-Check 'outer launch lock restored' (Test-Path -LiteralPath $outerLock -PathType Leaf) 'present'
Add-Check 'MT5 processes absent' (@(Get-Process terminal,terminal64,metatester,metatester64,MetaEditor,metaeditor64 -ErrorAction SilentlyContinue).Count -eq 0) 'expected=0'

$checks|Export-Csv -LiteralPath $outCsv -NoTypeInformation -Encoding ASCII
$failed=@($checks|Where-Object {!$_.Pass})
$lines=[Collections.Generic.List[string]]::new()
$lines.Add('# Three-Lane Trade-Ready RC2 ATB150 Static Safety')|Out-Null
$lines.Add('')|Out-Null
$lines.Add("**Status: $(if($failed.Count -eq 0){'PASS'}else{'FAIL'}). $($checks.Count-$failed.Count)/$($checks.Count) checks passed.**")|Out-Null
$lines.Add('')|Out-Null
$lines.Add('| Check | Status | Evidence |')|Out-Null
$lines.Add('|---|---|---|')|Out-Null
foreach($check in $checks){$lines.Add("| $($check.Check) | $(if($check.Pass){'PASS'}else{'FAIL'}) | $($check.Evidence -replace '\|','/') |")|Out-Null}
$lines|Set-Content -LiteralPath $outMd -Encoding ASCII
if($failed.Count -gt 0){throw "ATB150 safety failed $($failed.Count) check(s)."}
"THREE_LANE_TRADE_READY_RC2_ATB150_STATIC_SAFETY_PASS checks=$($checks.Count)"
