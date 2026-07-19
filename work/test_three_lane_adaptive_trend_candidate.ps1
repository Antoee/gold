Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$sourcePath = Join-Path $repo 'release\three-lane-adaptive-trend-rc1\Professional_XAUUSD_Three_Lane_Adaptive_Trend_RC1.mq5'
$profilePath = Join-Path $repo 'release\three-lane-adaptive-trend-rc1\THREE_LANE_ADAPTIVE_TREND_RC1.set'
$outCsv = Join-Path $repo 'outputs\THREE_LANE_ADAPTIVE_TREND_RC1_STATIC_SAFETY.csv'
$outMd = Join-Path $repo 'outputs\THREE_LANE_ADAPTIVE_TREND_RC1_STATIC_SAFETY.md'
$expectedSource = '51AE67DB56C3B584E8DA3A64C4B43ECAAE9ACE7E96541C22C9C5AC10E389FABB'
$expectedProfile = '48636124EE5E38D516A48D7551F401F4B179A34296B6373C317F843CD3DEF1B1'

$checks = [Collections.Generic.List[object]]::new()
function Add-Check([string]$Name,[bool]$Pass,[string]$Evidence) {
   $checks.Add([pscustomobject]@{Check=$Name;Pass=$Pass;Evidence=$Evidence}) | Out-Null
}
function Read-Csv([string]$Path) {
   if(!(Test-Path -LiteralPath $Path -PathType Leaf)){return @()}
   return @(Import-Csv -LiteralPath $Path)
}

Add-Check 'release source exists' (Test-Path -LiteralPath $sourcePath -PathType Leaf) $sourcePath
Add-Check 'release profile exists' (Test-Path -LiteralPath $profilePath -PathType Leaf) $profilePath
if(!(Test-Path -LiteralPath $sourcePath) -or !(Test-Path -LiteralPath $profilePath)) {
   throw 'Release source or profile is missing.'
}
$sourceHash=(Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash.ToUpperInvariant()
$profileHash=(Get-FileHash -LiteralPath $profilePath -Algorithm SHA256).Hash.ToUpperInvariant()
Add-Check 'source identity is frozen' ($sourceHash -eq $expectedSource) $sourceHash
Add-Check 'profile identity is frozen' ($profileHash -eq $expectedProfile) $profileHash

$source=Get-Content -LiteralPath $sourcePath -Raw
$requiredSource=@(
   'input bool   InpUseRealAccountSafetyLock = true;',
   'input bool   InpAllowRealAccountTrading = false;',
   'bool InitialAccountContractAllows(string &reason)',
   'bool RuntimeAccountHistoryContractAllows(string &reason)',
   'bool SharedSafetyAllows(string &reason)',
   'bool RiskMoneyForOrder(const string symbol,',
   'if(!OrderCalcProfit(orderType, symbol, lots, entryPrice, stopPrice, stopProfit))',
   'double AccountWideOpenRiskPercent(bool &hasUnprotectedPosition, int &positionCount)',
   'bool AccountWideExposureAllows(const bool buy,',
   'void AuditManagedPositionProtection()',
   'g_guardTrade.SetAsyncMode(false);'
)
foreach($marker in $requiredSource){Add-Check "source marker: $marker" ($source.Contains($marker)) $marker}
Add-Check 'all three entry paths use account-wide exposure gate' (([regex]::Matches($source,'AccountWideExposureAllows\(buy, entryPrice, stopPrice, lots, exposureReason\)')).Count -eq 3) 'expected=3'
Add-Check 'all three entry paths submit protective stops' (([regex]::Matches($source,'m_trade\.(Buy|Sell)\(lots, _Symbol, 0\.0,')).Count -eq 6) 'expected buy+sell calls=6'
Add-Check 'managed protection audit runs on tick and timer' (([regex]::Matches($source,'AuditManagedPositionProtection\(\);')).Count -ge 2) 'expected>=2'
Add-Check 'real-account approval cannot bypass active lock' ($source -match 'InpUseRealAccountSafetyLock \|\| !InpAllowRealAccountTrading \|\|') 'fail-closed real-account expression'
Add-Check 'prohibited sizing schemes absent' ($source -notmatch '(?i)martingale|averag(e|ing) down|recovery sizing') 'martingale/grid/recovery sizing absent'

$profile=[ordered]@{}
foreach($line in Get-Content -LiteralPath $profilePath){
   if($line -notmatch '^([^;=]+)=(.*)$'){continue}
   if($profile.Contains($Matches[1])){Add-Check "duplicate profile key $($Matches[1])" $false $line;continue}
   $profile[$Matches[1]]=$Matches[2].Split('||')[0]
}
Add-Check 'profile pins at least 170 inputs' ($profile.Count -ge 170) "count=$($profile.Count)"
$expectedInputs=[ordered]@{
   InpAllowedSymbol='XAUUSD';InpUseRealAccountSafetyLock='true';InpAllowRealAccountTrading='false';InpRealAccountApprovalCode='DISABLED'
   InpUseInitialBalanceContract='true';InpExpectedInitialBalance='10000.0';InpUseAccountCurrencyLock='true';InpRequiredAccountCurrency='USD'
   InpUseDedicatedAccountContract='true';InpRejectFundingChangesAfterRegistration='true';InpMaximumPortfolioEquityDrawdownPercent='5.00'
   InpMaximumPortfolioDailyLossPercent='0.75';InpMaximumPortfolioWeeklyLossPercent='1.25';InpMaximumPortfolioMonthlyLossPercent='1.50'
   InpMaximumPortfolioOpenRiskPercent='0.75';InpMaximumAccountPositions='3';InpBlockUnprotectedAccountExposure='true'
   InpCloseUnprotectedManagedPositions='true';InpRVRiskPercent='0.45';InpMORiskPercent='0.15';InpATBRiskPercent='0.10'
   InpLogTrades='false';InpShowDashboard='false'
}
foreach($pair in $expectedInputs.GetEnumerator()){
   $actual=if($profile.Contains($pair.Key)){$profile[$pair.Key]}else{'MISSING'}
   Add-Check "profile pin $($pair.Key)" ($actual -eq $pair.Value) "actual=$actual expected=$($pair.Value)"
}
Add-Check 'profile embeds source identity' ($profile['InpEvidenceSourceHash'] -eq $expectedSource) $profile['InpEvidenceSourceHash']

$critical=Read-Csv (Join-Path $repo 'outputs\THREE_LANE_ADAPTIVE_TREND_MODEL4_CRITICAL_RESULTS.csv')
Add-Check 'critical evidence complete' ($critical.Count -eq 6 -and @($critical|Where-Object Status -ne 'PARSED').Count -eq 0) "rows=$($critical.Count)"
$centerCritical=@($critical|Where-Object ExpectedReportName -like 'tlat_di12_atb10_center_*')
Add-Check 'center critical years positive' ($centerCritical.Count -eq 2 -and @($centerCritical|Where-Object {[double]$_.NetProfit -le 0}).Count -eq 0) (($centerCritical|ForEach-Object{"$($_.Window)=$($_.NetProfit)"}) -join '; ')

$broad=Read-Csv (Join-Path $repo 'outputs\THREE_LANE_ADAPTIVE_TREND_MODEL4_BROAD_RESULTS.csv')
Add-Check 'broad evidence complete' ($broad.Count -eq 8 -and @($broad|Where-Object Status -ne 'PARSED').Count -eq 0) "rows=$($broad.Count)"
Add-Check 'every broad row is profitable' ($broad.Count -eq 8 -and @($broad|Where-Object {[double]$_.NetProfit -le 0}).Count -eq 0) '8/8 positive'
$continuous=@($broad|Where-Object ExpectedReportName -eq 'tlat_di12_atb10_center_continuous_2015_2026_m4')
Add-Check 'continuous center passes quality gate' ($continuous.Count -eq 1 -and [double]$continuous[0].NetProfit -gt 0 -and [double]$continuous[0].ProfitFactor -ge 1.35 -and [int]$continuous[0].TotalTrades -ge 300 -and [double]$continuous[0].MaxDrawdownPercent -le 4.0 -and [double]$continuous[0].RecoveryFactor -ge 4.0 -and [double]$continuous[0].CagrPercent -ge 1.0) 'PF>=1.35 trades>=300 DD<=4 recovery>=4 CAGR>=1'

$annual=Read-Csv (Join-Path $repo 'outputs\THREE_LANE_ADAPTIVE_TREND_MODEL4_ANNUAL_RESULTS.csv')
Add-Check 'annual evidence complete' ($annual.Count -eq 12 -and @($annual|Where-Object Status -ne 'PARSED').Count -eq 0) "rows=$($annual.Count)"
Add-Check 'every annual/YTD row is profitable' ($annual.Count -eq 12 -and @($annual|Where-Object {[double]$_.NetProfit -le 0}).Count -eq 0) '12/12 positive'
Add-Check 'annual drawdown stays within gate' ($annual.Count -eq 12 -and @($annual|Where-Object {[double]$_.MaxDrawdownPercent -gt 2.5}).Count -eq 0) 'max<=2.5%'

$risk=Read-Csv (Join-Path $repo 'outputs\THREE_LANE_ADAPTIVE_TREND_MODEL4_RISK_AUDIT.csv')
Add-Check 'risk ledger complete' ($risk.Count -eq 367) "rows=$($risk.Count)"
Add-Check 'all lane and portfolio risks pass' ($risk.Count -eq 367 -and @($risk|Where-Object {$_.LanePass -ne 'True' -or $_.PortfolioPass -ne 'True'}).Count -eq 0) '367/367 pass'
$cost=Read-Csv (Join-Path $repo 'outputs\THREE_LANE_ADAPTIVE_TREND_MODEL4_COST_STRESS.csv')
$mc=Read-Csv (Join-Path $repo 'outputs\THREE_LANE_ADAPTIVE_TREND_MODEL4_MONTE_CARLO.csv')
Add-Check 'deterministic cost stress passes' ($cost.Count -eq 4 -and @($cost|Where-Object GatePass -ne 'True').Count -eq 0) '4/4 pass'
Add-Check 'Monte Carlo stress passes' ($mc.Count -eq 8 -and @($mc|Where-Object GatePass -ne 'True').Count -eq 0) '8/8 pass'

$repoLock=Join-Path $repo 'work\MT5_LOCAL_LAUNCH_DISABLED.lock'
$outerLock=Join-Path (Split-Path -Parent $repo) 'MT5_LOCAL_LAUNCH_DISABLED.lock'
Add-Check 'repository launch lock restored' (Test-Path -LiteralPath $repoLock -PathType Leaf) $repoLock
Add-Check 'outer launch lock restored' (Test-Path -LiteralPath $outerLock -PathType Leaf) $outerLock
Add-Check 'temporary launch authorization absent' (!(Test-Path -LiteralPath (Join-Path $repo 'work\ALLOW_MT5_LOCAL_LAUNCH.unlock'))) 'unlock absent'
Add-Check 'temporary focus acknowledgement absent' (!(Test-Path -LiteralPath (Join-Path $repo 'work\ALLOW_MT5_HIDDEN_DESKTOP_ACK.unlock'))) 'ack absent'

$checks|Export-Csv -LiteralPath $outCsv -NoTypeInformation -Encoding ASCII
$failed=@($checks|Where-Object {!$_.Pass})
$lines=[Collections.Generic.List[string]]::new()
$lines.Add('# Three-Lane Adaptive Trend RC1 Static Safety')|Out-Null
$lines.Add('')|Out-Null
$lines.Add("**Status: $(if($failed.Count -eq 0){'PASS'}else{'FAIL'}). $($checks.Count-$failed.Count)/$($checks.Count) checks passed.**")|Out-Null
$lines.Add('')|Out-Null
$lines.Add('| Check | Status | Evidence |')|Out-Null
$lines.Add('|---|---|---|')|Out-Null
foreach($check in $checks){$lines.Add("| $($check.Check) | $(if($check.Pass){'PASS'}else{'FAIL'}) | $($check.Evidence -replace '\|','/') |")|Out-Null}
$lines|Set-Content -LiteralPath $outMd -Encoding ASCII
if($failed.Count -gt 0){throw "Three-lane candidate safety failed $($failed.Count) check(s)."}
"THREE_LANE_ADAPTIVE_TREND_RC1_STATIC_SAFETY_PASS checks=$($checks.Count)"
