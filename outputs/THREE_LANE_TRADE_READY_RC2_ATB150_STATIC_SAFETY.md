# Three-Lane Trade-Ready RC2 ATB150 Static Safety

**Status: PASS. 60/60 checks passed.**

| Check | Status | Evidence |
|---|---|---|
| base RC2 static safety remains passing | PASS | THREE_LANE_TRADE_READY_RC2_STATIC_SAFETY_PASS checks=79 |
| artifact exists: Professional_XAUUSD_Three_Lane_Trade_Ready_RC2_ATB150.mq5 | PASS | release\three-lane-trade-ready-rc2-atb150\Professional_XAUUSD_Three_Lane_Trade_Ready_RC2_ATB150.mq5 |
| artifact exists: THREE_LANE_TRADE_READY_RC2_ATB150.set | PASS | release\three-lane-trade-ready-rc2-atb150\THREE_LANE_TRADE_READY_RC2_ATB150.set |
| artifact exists: tlat_rc2_decomp_atb150_continuous_2015_2026_m4.htm | PASS | outputs\three_lane_trade_ready_rc2_growth_decomp_model4_package\reports_here\tlat_rc2_decomp_atb150_continuous_2015_2026_m4.htm |
| artifact exists: tlat_rc2_decomp_atb150_continuous_2015_2026_m4.identity.json | PASS | outputs\three_lane_trade_ready_rc2_growth_decomp_model4_package\reports_here\tlat_rc2_decomp_atb150_continuous_2015_2026_m4.identity.json |
| release source identity is exact | PASS | 2F1C1C74067DA6173EB4133DB75C0B0DB4DE7BE46F2BB7A453AEE044536B2158 |
| release profile identity is exact | PASS | 705E2154CF6D123151B67757FFCA3EBF7D8BD525CD859E8237F89674CF70DC4E |
| continuous report identity is exact | PASS | 31A383253B7BF7611D6209E296317105E4C5756A8A12D883C0872245866B1B4D |
| release source matches work source | PASS | byte-identical source |
| release profile matches tested profile | PASS | byte-identical profile |
| identity source hash matches | PASS | 2F1C1C74067DA6173EB4133DB75C0B0DB4DE7BE46F2BB7A453AEE044536B2158 |
| identity report hash matches | PASS | 31A383253B7BF7611D6209E296317105E4C5756A8A12D883C0872245866B1B4D |
| identity binary hash matches | PASS | E24203F2E7AF184B6B6BB3902F7C8711DD887B0E0346C22ED87E8F07EB1AC7B8 |
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
| profile pin InpRequireConfirmedTradeResults | PASS | actual=true expected=true |
| profile pin InpUsePostFillRiskReconciliation | PASS | actual=true expected=true |
| profile pin InpPostFillRiskTolerancePercent | PASS | actual=0.005 expected=0.005 |
| profile pin InpRVRiskPercent | PASS | actual=0.45 expected=0.45 |
| profile pin InpMORiskPercent | PASS | actual=0.15 expected=0.15 |
| profile pin InpATBRiskPercent | PASS | actual=0.15 expected=0.15 |
| profile pin InpLogTrades | PASS | actual=false expected=false |
| profile pin InpShowDashboard | PASS | actual=false expected=false |
| profile embeds source identity | PASS | 2F1C1C74067DA6173EB4133DB75C0B0DB4DE7BE46F2BB7A453AEE044536B2158 |
| Model 4 broad candidate is complete and positive | PASS | rows=4 |
| continuous comparison rows are unique | PASS | candidate=1 baseline=1 |
| continuous net improves by at least 5% | PASS | candidate=2105.08 baseline=1994.62 |
| continuous equity drawdown improves | PASS | candidate=134.35 baseline=139.11 |
| continuous recovery improves | PASS | candidate=15.6686 baseline=14.3384 |
| continuous PF remains at least 1.80 | PASS | PF=1.81 |
| continuous trade count increases | PASS | candidate=404 baseline=367 |
| annual evidence is 12/12 parsed and positive | PASS | rows=12 |
| hard-risk ledger is complete | PASS | 404/404 pass |
| deterministic cost stress is 4/4 passing | PASS | 4/4 pass |
| severe cost remains useful | PASS | net=1506.55 PF=1.5146 |
| Monte Carlo stress is 8/8 passing | PASS | 8/8 pass |
| severe Monte Carlo P05 remains positive | PASS | minimum=238.64 |
| severe Monte Carlo P95 DD stays below 4.50% | PASS | maximum=4.2251 |
| severe Monte Carlo red trials stay below 1.50% | PASS | maximum=1.35 |
| repository launch lock restored | PASS | present |
| outer launch lock restored | PASS | present |
| MT5 processes absent | PASS | expected=0 |
