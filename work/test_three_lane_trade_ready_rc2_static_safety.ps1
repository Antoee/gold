Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$sourcePath = Join-Path $repo 'work\Professional_XAUUSD_Three_Lane_Adaptive_Trend_Trade_Ready_RC2.mq5'
$profilePath = Join-Path $repo 'outputs\three_lane_trade_ready_rc2_model4_broad_package\profiles\tlat_rc2_di12_center.set'
$outCsv = Join-Path $repo 'outputs\THREE_LANE_TRADE_READY_RC2_STATIC_SAFETY.csv'
$outMd = Join-Path $repo 'outputs\THREE_LANE_TRADE_READY_RC2_STATIC_SAFETY.md'
$expectedSource = '2F1C1C74067DA6173EB4133DB75C0B0DB4DE7BE46F2BB7A453AEE044536B2158'
$expectedProfile = '60BF5D013153E3A38A6BD932E88CB41BD8FEAB5108648DDCBA1CCCCDD4D737F3'

$checks = [Collections.Generic.List[object]]::new()
function Add-Check([string]$Name,[bool]$Pass,[string]$Evidence) {
   $checks.Add([pscustomobject]@{Check=$Name;Pass=$Pass;Evidence=$Evidence}) | Out-Null
}
function Read-Csv([string]$Path) {
   if(!(Test-Path -LiteralPath $Path -PathType Leaf)){return @()}
   return @(Import-Csv -LiteralPath $Path)
}
function Test-MetricEqual($Left,$Right,[string[]]$Fields) {
   foreach($field in $Fields) {
      if([string]$Left.$field -ne [string]$Right.$field) { return $false }
   }
   return $true
}

Add-Check 'candidate source exists' (Test-Path -LiteralPath $sourcePath -PathType Leaf) 'work\Professional_XAUUSD_Three_Lane_Adaptive_Trend_Trade_Ready_RC2.mq5'
Add-Check 'candidate profile exists' (Test-Path -LiteralPath $profilePath -PathType Leaf) 'generated center profile'
if(!(Test-Path -LiteralPath $sourcePath) -or !(Test-Path -LiteralPath $profilePath)) {
   throw 'RC2 source or profile is missing.'
}
$sourceHash=(Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash.ToUpperInvariant()
$profileHash=(Get-FileHash -LiteralPath $profilePath -Algorithm SHA256).Hash.ToUpperInvariant()
Add-Check 'source identity is frozen' ($sourceHash -eq $expectedSource) $sourceHash
Add-Check 'profile identity is frozen' ($profileHash -eq $expectedProfile) $profileHash

$source=Get-Content -LiteralPath $sourcePath -Raw
$requiredSource=@(
   'bool VerifiedGlobalSet(const string key, const double value)',
   'bool VerifiedGlobalDelete(const string key)',
   'bool TradeResultAllows(CTrade &trade, const bool allowNoChanges = false)',
   'bool SelectOwnedPosition(const ulong ticket, const ulong magic)',
   'bool CloseOwnedPosition(CTrade &trade,',
   'bool ModifyOwnedPosition(CTrade &trade,',
   'bool DeleteOwnedOrder(CTrade &trade,',
   'bool AuditManagedOrders()',
   'bool StaticSafetyAllows(string &reason)',
   'bool TradeEnvironmentAllows(string &reason)',
   'bool PostFillReconcile(CTrade &trade,',
   'bool RejectPostFill(CTrade &trade,',
   'if(!OrderCalcProfit(orderType, symbol, lots, entryPrice, stopPrice, stopProfit))',
   'g_guardTrade.SetAsyncMode(false);'
)
foreach($marker in $requiredSource){Add-Check "source marker: $marker" ($source.Contains($marker)) $marker}
Add-Check 'all entries run post-fill reconciliation' (([regex]::Matches($source,'if\(!PostFillReconcile\(')).Count -eq 3) 'expected=3'
Add-Check 'all entries require confirmed trade result' (([regex]::Matches($source,'!TradeResultAllows\(m_trade, false\)')).Count -eq 3) 'expected=3'
Add-Check 'all entries use account-wide exposure gate' (([regex]::Matches($source,'AccountWideExposureAllows\(buy, entryPrice, stopPrice, lots, exposureReason\)')).Count -eq 3) 'expected=3'
Add-Check 'all entries submit protective stops' (([regex]::Matches($source,'m_trade\.(Buy|Sell)\(lots, _Symbol, 0\.0,')).Count -eq 6) 'expected=6'
Add-Check 'direct position close is wrapper-confined' (([regex]::Matches($source,'\.PositionClose\(')).Count -eq 1) 'expected=1 wrapper call'
Add-Check 'direct position modify is wrapper-confined' (([regex]::Matches($source,'\.PositionModify\(')).Count -eq 1) 'expected=1 wrapper call'
Add-Check 'direct order delete is wrapper-confined' (([regex]::Matches($source,'\.OrderDelete\(')).Count -eq 1) 'expected=1 wrapper call'
Add-Check 'placed result is not treated as final' ($source -notmatch 'TRADE_RETCODE_PLACED') 'PLACED absent from final-result allowlist'
Add-Check 'managed order audit runs at initialization, tick, and timer' (([regex]::Matches($source,'AuditManagedOrders\(\)')).Count -ge 4) 'expected declaration plus three calls'
Add-Check 'global writes are verification-confined' (([regex]::Matches($source,'GlobalVariableSet\(')).Count -eq 1) 'expected=1 wrapper call'
Add-Check 'global deletes are verification-confined' (([regex]::Matches($source,'GlobalVariableDel\(')).Count -eq 1) 'expected=1 wrapper call'
Add-Check 'managed protection audit runs on tick and timer' (([regex]::Matches($source,'AuditManagedPositionProtection\(\);')).Count -ge 2) 'expected>=2'
Add-Check 'real-account approval cannot bypass active lock' ($source -match 'InpUseRealAccountSafetyLock \|\| !InpAllowRealAccountTrading \|\|') 'fail-closed real-account expression'
Add-Check 'prohibited sizing schemes absent' ($source -notmatch '(?i)martingale|averag(e|ing) down|recovery sizing') 'prohibited sizing absent'

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
   InpCloseUnprotectedManagedPositions='true';InpUseTradeEnvironmentGuard='true';InpMaximumQuoteAgeSeconds='30'
   InpMaximumStopsLevelPoints='250.0';InpMaximumFreezeLevelPoints='250.0';InpRequireConfirmedTradeResults='true'
   InpUsePostFillRiskReconciliation='true';InpPostFillRiskTolerancePercent='0.005'
   InpRVRiskPercent='0.45';InpMORiskPercent='0.15';InpATBRiskPercent='0.10';InpLogTrades='false';InpShowDashboard='false'
}
foreach($pair in $expectedInputs.GetEnumerator()){
   $actual=if($profile.Contains($pair.Key)){$profile[$pair.Key]}else{'MISSING'}
   Add-Check "profile pin $($pair.Key)" ($actual -eq $pair.Value) "actual=$actual expected=$($pair.Value)"
}
Add-Check 'profile embeds source identity' ($profile['InpEvidenceSourceHash'] -eq $expectedSource) $profile['InpEvidenceSourceHash']

$m1=Read-Csv (Join-Path $repo 'outputs\THREE_LANE_TRADE_READY_RC2_CRITICAL_MODEL1_METRICS.csv')
$m4=Read-Csv (Join-Path $repo 'outputs\THREE_LANE_TRADE_READY_RC2_CRITICAL_MODEL4_METRICS.csv')
$broad=Read-Csv (Join-Path $repo 'outputs\THREE_LANE_TRADE_READY_RC2_MODEL4_BROAD_METRICS.csv')
$annual=Read-Csv (Join-Path $repo 'outputs\THREE_LANE_TRADE_READY_RC2_MODEL4_ANNUAL_METRICS.csv')
Add-Check 'Model 1 critical evidence complete and positive' ($m1.Count -eq 4 -and @($m1|Where-Object {$_.Status -ne 'PARSED' -or [double]$_.NetProfit -le 0}).Count -eq 0) "rows=$($m1.Count)"
Add-Check 'Model 4 critical evidence complete and positive' ($m4.Count -eq 4 -and @($m4|Where-Object {$_.Status -ne 'PARSED' -or [double]$_.NetProfit -le 0}).Count -eq 0) "rows=$($m4.Count)"
Add-Check 'Model 4 broad evidence complete and positive' ($broad.Count -eq 8 -and @($broad|Where-Object {$_.Status -ne 'PARSED' -or [double]$_.NetProfit -le 0}).Count -eq 0) "rows=$($broad.Count)"
Add-Check 'Model 4 annual evidence complete and positive' ($annual.Count -eq 12 -and @($annual|Where-Object {$_.Status -ne 'PARSED' -or [double]$_.NetProfit -le 0}).Count -eq 0) "rows=$($annual.Count)"

$rc1Broad=Read-Csv (Join-Path $repo 'outputs\THREE_LANE_ADAPTIVE_TREND_MODEL4_BROAD_RESULTS.csv')
$metricFields=@('NetProfit','ProfitFactor','TotalTrades','MaxDrawdownMoney','MaxDrawdownPercent','RecoveryFactor','CagrPercent')
$broadEquivalent=$broad.Count -eq 8
foreach($row in $broad){
   $prefix=if($row.Profile -eq 'tlat_rc2_di11'){'tlat_di11_atb10_'}else{'tlat_di12_atb10_center_'}
   $baseline=@($rc1Broad|Where-Object {$_.ExpectedReportName -eq "$prefix$($row.Window)_m4"})
   if($baseline.Count -ne 1 -or !(Test-MetricEqual $row $baseline[0] $metricFields)){$broadEquivalent=$false}
}
Add-Check 'broad metrics exactly match RC1' $broadEquivalent '8/8 rows, seven risk/return fields'

$rc1Annual=Read-Csv (Join-Path $repo 'outputs\THREE_LANE_ADAPTIVE_TREND_MODEL4_ANNUAL_RESULTS.csv')
$annualEquivalent=$annual.Count -eq 12
foreach($row in $annual){
   $baselineWindow=if($row.Window -eq 'year_2026_ytd'){'ytd_2026'}else{$row.Window}
   $baseline=@($rc1Annual|Where-Object {$_.Window -eq $baselineWindow})
   if($baseline.Count -ne 1 -or !(Test-MetricEqual $row $baseline[0] $metricFields)){$annualEquivalent=$false}
}
Add-Check 'annual metrics exactly match RC1' $annualEquivalent '12/12 rows, seven risk/return fields'

$rc1Trades=Read-Csv (Join-Path $repo 'outputs\THREE_LANE_ADAPTIVE_TREND_MODEL4_CONTINUOUS_TRADES.csv')
$rc2Trades=Read-Csv (Join-Path $repo 'outputs\THREE_LANE_TRADE_READY_RC2_MODEL4_CONTINUOUS_TRADES.csv')
$ledgerFields=@($rc1Trades[0].PSObject.Properties.Name|Where-Object {$_ -ne 'ExitComment'})
$ledgerDiff=@(Compare-Object @($rc1Trades|Select-Object $ledgerFields|ConvertTo-Csv -NoTypeInformation) @($rc2Trades|Select-Object $ledgerFields|ConvertTo-Csv -NoTypeInformation))
Add-Check 'continuous trade ledger matches RC1' ($rc1Trades.Count -eq 367 -and $rc2Trades.Count -eq 367 -and $ledgerDiff.Count -eq 0) "RC1=$($rc1Trades.Count) RC2=$($rc2Trades.Count) differences=$($ledgerDiff.Count)"

$risk=Read-Csv (Join-Path $repo 'outputs\THREE_LANE_ADAPTIVE_TREND_MODEL4_RISK_AUDIT.csv')
$cost=Read-Csv (Join-Path $repo 'outputs\THREE_LANE_ADAPTIVE_TREND_MODEL4_COST_STRESS.csv')
$mc=Read-Csv (Join-Path $repo 'outputs\THREE_LANE_ADAPTIVE_TREND_MODEL4_MONTE_CARLO.csv')
Add-Check 'equivalent risk ledger remains complete' ($risk.Count -eq 367 -and @($risk|Where-Object {$_.LanePass -ne 'True' -or $_.PortfolioPass -ne 'True'}).Count -eq 0) '367/367 pass'
Add-Check 'deterministic cost stress remains passing' ($cost.Count -eq 4 -and @($cost|Where-Object GatePass -ne 'True').Count -eq 0) '4/4 pass'
Add-Check 'Monte Carlo stress remains passing' ($mc.Count -eq 8 -and @($mc|Where-Object GatePass -ne 'True').Count -eq 0) '8/8 pass'

$repoLock=Join-Path $repo 'work\MT5_LOCAL_LAUNCH_DISABLED.lock'
$outerLock=Join-Path (Split-Path -Parent $repo) 'MT5_LOCAL_LAUNCH_DISABLED.lock'
Add-Check 'repository launch lock restored' (Test-Path -LiteralPath $repoLock -PathType Leaf) 'work\MT5_LOCAL_LAUNCH_DISABLED.lock'
Add-Check 'outer launch lock restored' (Test-Path -LiteralPath $outerLock -PathType Leaf) 'outer MT5_LOCAL_LAUNCH_DISABLED.lock'
Add-Check 'temporary launch authorization absent' (!(Test-Path -LiteralPath (Join-Path $repo 'work\ALLOW_MT5_LOCAL_LAUNCH.unlock'))) 'unlock absent'
Add-Check 'temporary focus acknowledgement absent' (!(Test-Path -LiteralPath (Join-Path $repo 'work\ALLOW_MT5_HIDDEN_DESKTOP_ACK.unlock'))) 'ack absent'
Add-Check 'MT5 processes absent' (@(Get-Process terminal,terminal64,metatester,metatester64,MetaEditor,metaeditor64 -ErrorAction SilentlyContinue).Count -eq 0) 'expected=0'

$checks|Export-Csv -LiteralPath $outCsv -NoTypeInformation -Encoding ASCII
$failed=@($checks|Where-Object {!$_.Pass})
$lines=[Collections.Generic.List[string]]::new()
$lines.Add('# Three-Lane Trade-Ready RC2 Static Safety')|Out-Null
$lines.Add('')|Out-Null
$lines.Add("**Status: $(if($failed.Count -eq 0){'PASS'}else{'FAIL'}). $($checks.Count-$failed.Count)/$($checks.Count) checks passed.**")|Out-Null
$lines.Add('')|Out-Null
$lines.Add('| Check | Status | Evidence |')|Out-Null
$lines.Add('|---|---|---|')|Out-Null
foreach($check in $checks){$lines.Add("| $($check.Check) | $(if($check.Pass){'PASS'}else{'FAIL'}) | $($check.Evidence -replace '\|','/') |")|Out-Null}
$lines|Set-Content -LiteralPath $outMd -Encoding ASCII
if($failed.Count -gt 0){throw "Three-lane trade-ready RC2 safety failed $($failed.Count) check(s)."}
"THREE_LANE_TRADE_READY_RC2_STATIC_SAFETY_PASS checks=$($checks.Count)"
