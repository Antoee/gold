# Three-Lane Adaptive Trend RC1 Static Safety

**Status: PASS. 61/61 checks passed.**

| Check | Status | Evidence |
|---|---|---|
| release source exists | PASS | C:\Users\Ant\Documents\Codex\2026-07-03\absolutely-here-s-a-summary-you\work\gdr_rdmc\release\three-lane-adaptive-trend-rc1\Professional_XAUUSD_Three_Lane_Adaptive_Trend_RC1.mq5 |
| release profile exists | PASS | C:\Users\Ant\Documents\Codex\2026-07-03\absolutely-here-s-a-summary-you\work\gdr_rdmc\release\three-lane-adaptive-trend-rc1\THREE_LANE_ADAPTIVE_TREND_RC1.set |
| source identity is frozen | PASS | 51AE67DB56C3B584E8DA3A64C4B43ECAAE9ACE7E96541C22C9C5AC10E389FABB |
| profile identity is frozen | PASS | 48636124EE5E38D516A48D7551F401F4B179A34296B6373C317F843CD3DEF1B1 |
| source marker: input bool   InpUseRealAccountSafetyLock = true; | PASS | input bool   InpUseRealAccountSafetyLock = true; |
| source marker: input bool   InpAllowRealAccountTrading = false; | PASS | input bool   InpAllowRealAccountTrading = false; |
| source marker: bool InitialAccountContractAllows(string &reason) | PASS | bool InitialAccountContractAllows(string &reason) |
| source marker: bool RuntimeAccountHistoryContractAllows(string &reason) | PASS | bool RuntimeAccountHistoryContractAllows(string &reason) |
| source marker: bool SharedSafetyAllows(string &reason) | PASS | bool SharedSafetyAllows(string &reason) |
| source marker: bool RiskMoneyForOrder(const string symbol, | PASS | bool RiskMoneyForOrder(const string symbol, |
| source marker: if(!OrderCalcProfit(orderType, symbol, lots, entryPrice, stopPrice, stopProfit)) | PASS | if(!OrderCalcProfit(orderType, symbol, lots, entryPrice, stopPrice, stopProfit)) |
| source marker: double AccountWideOpenRiskPercent(bool &hasUnprotectedPosition, int &positionCount) | PASS | double AccountWideOpenRiskPercent(bool &hasUnprotectedPosition, int &positionCount) |
| source marker: bool AccountWideExposureAllows(const bool buy, | PASS | bool AccountWideExposureAllows(const bool buy, |
| source marker: void AuditManagedPositionProtection() | PASS | void AuditManagedPositionProtection() |
| source marker: g_guardTrade.SetAsyncMode(false); | PASS | g_guardTrade.SetAsyncMode(false); |
| all three entry paths use account-wide exposure gate | PASS | expected=3 |
| all three entry paths submit protective stops | PASS | expected buy+sell calls=6 |
| managed protection audit runs on tick and timer | PASS | expected>=2 |
| real-account approval cannot bypass active lock | PASS | fail-closed real-account expression |
| prohibited sizing schemes absent | PASS | martingale/grid/recovery sizing absent |
| profile pins at least 170 inputs | PASS | count=171 |
| profile pin InpAllowedSymbol | PASS | actual=XAUUSD expected=XAUUSD |
| profile pin InpUseRealAccountSafetyLock | PASS | actual=true expected=true |
| profile pin InpAllowRealAccountTrading | PASS | actual=false expected=false |
| profile pin InpRealAccountApprovalCode | PASS | actual=DISABLED expected=DISABLED |
| profile pin InpUseInitialBalanceContract | PASS | actual=true expected=true |
| profile pin InpExpectedInitialBalance | PASS | actual=10000.0 expected=10000.0 |
| profile pin InpUseAccountCurrencyLock | PASS | actual=true expected=true |
| profile pin InpRequiredAccountCurrency | PASS | actual=USD expected=USD |
| profile pin InpUseDedicatedAccountContract | PASS | actual=true expected=true |
| profile pin InpRejectFundingChangesAfterRegistration | PASS | actual=true expected=true |
| profile pin InpMaximumPortfolioEquityDrawdownPercent | PASS | actual=5.00 expected=5.00 |
| profile pin InpMaximumPortfolioDailyLossPercent | PASS | actual=0.75 expected=0.75 |
| profile pin InpMaximumPortfolioWeeklyLossPercent | PASS | actual=1.25 expected=1.25 |
| profile pin InpMaximumPortfolioMonthlyLossPercent | PASS | actual=1.50 expected=1.50 |
| profile pin InpMaximumPortfolioOpenRiskPercent | PASS | actual=0.75 expected=0.75 |
| profile pin InpMaximumAccountPositions | PASS | actual=3 expected=3 |
| profile pin InpBlockUnprotectedAccountExposure | PASS | actual=true expected=true |
| profile pin InpCloseUnprotectedManagedPositions | PASS | actual=true expected=true |
| profile pin InpRVRiskPercent | PASS | actual=0.45 expected=0.45 |
| profile pin InpMORiskPercent | PASS | actual=0.15 expected=0.15 |
| profile pin InpATBRiskPercent | PASS | actual=0.10 expected=0.10 |
| profile pin InpLogTrades | PASS | actual=false expected=false |
| profile pin InpShowDashboard | PASS | actual=false expected=false |
| profile embeds source identity | PASS | 51AE67DB56C3B584E8DA3A64C4B43ECAAE9ACE7E96541C22C9C5AC10E389FABB |
| critical evidence complete | PASS | rows=6 |
| center critical years positive | PASS | critical_2019=15.07; critical_2022=16.22 |
| broad evidence complete | PASS | rows=8 |
| every broad row is profitable | PASS | 8/8 positive |
| continuous center passes quality gate | PASS | PF>=1.35 trades>=300 DD<=4 recovery>=4 CAGR>=1 |
| annual evidence complete | PASS | rows=12 |
| every annual/YTD row is profitable | PASS | 12/12 positive |
| annual drawdown stays within gate | PASS | max<=2.5% |
| risk ledger complete | PASS | rows=367 |
| all lane and portfolio risks pass | PASS | 367/367 pass |
| deterministic cost stress passes | PASS | 4/4 pass |
| Monte Carlo stress passes | PASS | 8/8 pass |
| repository launch lock restored | PASS | C:\Users\Ant\Documents\Codex\2026-07-03\absolutely-here-s-a-summary-you\work\gdr_rdmc\work\MT5_LOCAL_LAUNCH_DISABLED.lock |
| outer launch lock restored | PASS | C:\Users\Ant\Documents\Codex\2026-07-03\absolutely-here-s-a-summary-you\work\MT5_LOCAL_LAUNCH_DISABLED.lock |
| temporary launch authorization absent | PASS | unlock absent |
| temporary focus acknowledgement absent | PASS | ack absent |
