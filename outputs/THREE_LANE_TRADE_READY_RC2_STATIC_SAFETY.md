# Three-Lane Trade-Ready RC2 Static Safety

**Status: PASS. 79/79 checks passed.**

| Check | Status | Evidence |
|---|---|---|
| candidate source exists | PASS | work\Professional_XAUUSD_Three_Lane_Adaptive_Trend_Trade_Ready_RC2.mq5 |
| candidate profile exists | PASS | generated center profile |
| source identity is frozen | PASS | 2F1C1C74067DA6173EB4133DB75C0B0DB4DE7BE46F2BB7A453AEE044536B2158 |
| profile identity is frozen | PASS | 60BF5D013153E3A38A6BD932E88CB41BD8FEAB5108648DDCBA1CCCCDD4D737F3 |
| source marker: bool VerifiedGlobalSet(const string key, const double value) | PASS | bool VerifiedGlobalSet(const string key, const double value) |
| source marker: bool VerifiedGlobalDelete(const string key) | PASS | bool VerifiedGlobalDelete(const string key) |
| source marker: bool TradeResultAllows(CTrade &trade, const bool allowNoChanges = false) | PASS | bool TradeResultAllows(CTrade &trade, const bool allowNoChanges = false) |
| source marker: bool SelectOwnedPosition(const ulong ticket, const ulong magic) | PASS | bool SelectOwnedPosition(const ulong ticket, const ulong magic) |
| source marker: bool CloseOwnedPosition(CTrade &trade, | PASS | bool CloseOwnedPosition(CTrade &trade, |
| source marker: bool ModifyOwnedPosition(CTrade &trade, | PASS | bool ModifyOwnedPosition(CTrade &trade, |
| source marker: bool DeleteOwnedOrder(CTrade &trade, | PASS | bool DeleteOwnedOrder(CTrade &trade, |
| source marker: bool AuditManagedOrders() | PASS | bool AuditManagedOrders() |
| source marker: bool StaticSafetyAllows(string &reason) | PASS | bool StaticSafetyAllows(string &reason) |
| source marker: bool TradeEnvironmentAllows(string &reason) | PASS | bool TradeEnvironmentAllows(string &reason) |
| source marker: bool PostFillReconcile(CTrade &trade, | PASS | bool PostFillReconcile(CTrade &trade, |
| source marker: bool RejectPostFill(CTrade &trade, | PASS | bool RejectPostFill(CTrade &trade, |
| source marker: if(!OrderCalcProfit(orderType, symbol, lots, entryPrice, stopPrice, stopProfit)) | PASS | if(!OrderCalcProfit(orderType, symbol, lots, entryPrice, stopPrice, stopProfit)) |
| source marker: g_guardTrade.SetAsyncMode(false); | PASS | g_guardTrade.SetAsyncMode(false); |
| all entries run post-fill reconciliation | PASS | expected=3 |
| all entries require confirmed trade result | PASS | expected=3 |
| all entries use account-wide exposure gate | PASS | expected=3 |
| all entries submit protective stops | PASS | expected=6 |
| direct position close is wrapper-confined | PASS | expected=1 wrapper call |
| direct position modify is wrapper-confined | PASS | expected=1 wrapper call |
| direct order delete is wrapper-confined | PASS | expected=1 wrapper call |
| placed result is not treated as final | PASS | PLACED absent from final-result allowlist |
| managed order audit runs at initialization, tick, and timer | PASS | expected declaration plus three calls |
| global writes are verification-confined | PASS | expected=1 wrapper call |
| global deletes are verification-confined | PASS | expected=1 wrapper call |
| managed protection audit runs on tick and timer | PASS | expected>=2 |
| real-account approval cannot bypass active lock | PASS | fail-closed real-account expression |
| prohibited sizing schemes absent | PASS | prohibited sizing absent |
| profile pins 178 inputs | PASS | count=178 |
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
| profile pin InpUseTradeEnvironmentGuard | PASS | actual=true expected=true |
| profile pin InpMaximumQuoteAgeSeconds | PASS | actual=30 expected=30 |
| profile pin InpMaximumStopsLevelPoints | PASS | actual=250.0 expected=250.0 |
| profile pin InpMaximumFreezeLevelPoints | PASS | actual=250.0 expected=250.0 |
| profile pin InpRequireConfirmedTradeResults | PASS | actual=true expected=true |
| profile pin InpUsePostFillRiskReconciliation | PASS | actual=true expected=true |
| profile pin InpPostFillRiskTolerancePercent | PASS | actual=0.005 expected=0.005 |
| profile pin InpRVRiskPercent | PASS | actual=0.45 expected=0.45 |
| profile pin InpMORiskPercent | PASS | actual=0.15 expected=0.15 |
| profile pin InpATBRiskPercent | PASS | actual=0.10 expected=0.10 |
| profile pin InpLogTrades | PASS | actual=false expected=false |
| profile pin InpShowDashboard | PASS | actual=false expected=false |
| profile embeds source identity | PASS | 2F1C1C74067DA6173EB4133DB75C0B0DB4DE7BE46F2BB7A453AEE044536B2158 |
| Model 1 critical evidence complete and positive | PASS | rows=4 |
| Model 4 critical evidence complete and positive | PASS | rows=4 |
| Model 4 broad evidence complete and positive | PASS | rows=8 |
| Model 4 annual evidence complete and positive | PASS | rows=12 |
| broad metrics exactly match RC1 | PASS | 8/8 rows, seven risk/return fields |
| annual metrics exactly match RC1 | PASS | 12/12 rows, seven risk/return fields |
| continuous trade ledger matches RC1 | PASS | RC1=367 RC2=367 differences=0 |
| equivalent risk ledger remains complete | PASS | 367/367 pass |
| deterministic cost stress remains passing | PASS | 4/4 pass |
| Monte Carlo stress remains passing | PASS | 8/8 pass |
| repository launch lock restored | PASS | work\MT5_LOCAL_LAUNCH_DISABLED.lock |
| outer launch lock restored | PASS | outer MT5_LOCAL_LAUNCH_DISABLED.lock |
| temporary launch authorization absent | PASS | unlock absent |
| temporary focus acknowledgement absent | PASS | ack absent |
| MT5 processes absent | PASS | expected=0 |
