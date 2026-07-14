# Conservative Trade-Ready Validation Decision

- Overall: **PENDING**
- Passed gates: `3`
- Pending gates: `25`
- Failed gates: `0`
- Manifest rows: `53`
- Result rows: `53`
- Broker proxy manifest rows: `10`
- Broker proxy result rows: `10`

This decision gate does not launch MT5. It only evaluates returned result evidence.

| Gate | Status | Required | Actual | Evidence |
| --- | --- | --- | --- | --- |
| validation-package-shape | PASS | validation manifest has 53 rows: 4 fast, 4 exact, 11 quarterly, 31 monthly, 3 stress | rows=53/53; phase0_fast_model1=4/4; phase1_exact_realtick=4/4; phase2_realtick_quarterly=11/11; phase3_realtick_monthly=31/31; phase4_stress_realtick=3/3 | outputs\TRADE_READY_CONSERVATIVE_VALIDATION_MANIFEST.csv |
| results-present | PASS | At least one returned result row | resultRows=53 | outputs\TRADE_READY_CONSERVATIVE_VALIDATION_RESULTS.csv |
| broker-proxy-package-present | PASS | broker proxy manifest has 10 configs | brokerManifestRows=10 | outputs\TRADE_READY_CONSERVATIVE_BROKER_PROXY_MANIFEST.csv |
| exported-report-evidence | PENDING | all validation and broker rows must come from exported MT5 reports with Status=PARSED | exportedParsed=0/63; missingOrUnparsed=63; untrusted=0 | outputs\TRADE_READY_CONSERVATIVE_VALIDATION_RESULTS.csv; outputs\TRADE_READY_CONSERVATIVE_BROKER_PROXY_RESULTS.csv |
| full-report-stats-complete | PENDING | every exported validation/broker report must include profit factor, expected payoff, Sharpe ratio, win rate, trades, max consecutive losses, drawdown %, and recovery factor | statRows=0; missingStats=0 | outputs\TRADE_READY_CONSERVATIVE_VALIDATION_RESULTS.csv; outputs\TRADE_READY_CONSERVATIVE_BROKER_PROXY_RESULTS.csv |
| phase0_fast_model1-complete | PENDING | parsed=4/4 | parsed=0/4 | phase=phase0_fast_model1 |
| phase1_exact_realtick-complete | PENDING | parsed=4/4 | parsed=0/4 | phase=phase1_exact_realtick |
| phase2_realtick_quarterly-complete | PENDING | parsed=11/11 | parsed=0/11 | phase=phase2_realtick_quarterly |
| phase3_realtick_monthly-complete | PENDING | parsed=31/31 | parsed=0/31 | phase=phase3_realtick_monthly |
| phase4_stress_realtick-complete | PENDING | parsed=3/3 | parsed=0/3 | phase=phase4_stress_realtick |
| exact-continuous-profitable | PENDING | continuous Model4 net >= 1 | continuous= | phase1_exact_realtick/continuous_2024_2026 |
| exact-splits-nonnegative | PENDING | train/oos/recent net >= 0 | badSplits=0; parsedSplits=0 | phase1_exact_realtick |
| exact-continuous-min-trades | PENDING | continuous trades >= 20 | continuousTrades= | phase1_exact_realtick/continuous_2024_2026 |
| exact-continuous-return-floor | PENDING | continuous return >= 1% on starting balance 1000 | continuousReturnPct=; continuousNet= | phase1_exact_realtick/continuous_2024_2026 |
| exact-continuous-return-drawdown-efficiency | PENDING | continuous return % / equity DD % >= 1 | returnToDD=; returnPct=; ddPct= | phase1_exact_realtick/continuous_2024_2026 |
| exact-continuous-annualized-return-floor | PENDING | continuous annualized return >= 1% | annualizedReturn= | phase1_exact_realtick/continuous_2024_2026 |
| exact-continuous-cagr-floor | PENDING | continuous CAGR >= 1% | cagr= | phase1_exact_realtick/continuous_2024_2026 |
| drawdown-within-cap | PENDING | max equity DD <= 3% | worstDD= | all parsed rows with drawdown stats |
| profit-factor-floor | PENDING | min nonzero PF >= 1.2 | minPF=; samples=0 | all parsed rows with PF stats |
| expected-payoff-floor | PENDING | min expected payoff >= 0 on active rows | minExpectedPayoff=; samples=0 | all active parsed rows |
| sharpe-ratio-floor | PENDING | min Sharpe ratio >= 0.1 on active rows | minSharpe=; samples=0 | all active parsed rows |
| win-rate-floor | PENDING | min win rate >= 20% on active rows | minWinRate=; samples=0 | all active parsed rows |
| consecutive-losses-cap | PENDING | max consecutive losses <= 5 on active rows | worstLossRun=; samples=0 | all active parsed rows |
| recovery-factor-floor | PENDING | min recovery >= 1 on active rows | minRecovery=; samples=0 | all active parsed rows |
| quarterly-no-red-windows | PENDING | all quarterly Model4 windows net >= 0 | badQuarters=0; parsed=0/11 | phase2_realtick_quarterly |
| monthly-no-red-windows | PENDING | all monthly Model4 windows net >= 0 | badMonths=0; parsed=0/31 | phase3_realtick_monthly |
| stress-profitable | PENDING | all stress variants net >= 0 | badStress=0; parsed=0/3 | phase4_stress_realtick |
| broker-proxy-profitable | PENDING | all broker-proxy Model4 windows net >= 0 | badBroker=0; parsed=0/10 | phase5_broker_proxy_realtick |
