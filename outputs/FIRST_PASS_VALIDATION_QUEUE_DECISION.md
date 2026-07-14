# First-Pass Validation Decision

- Overall: **FAIL**
- Passed gates: `14`
- Pending gates: `13`
- Failed gates: `2`
- Queue rows: `22`
- Imported result rows: `22`

This is an early screen only. Passing it does not approve live trading; it only decides whether a candidate deserves the full validation packages.

## Candidate Ranking

| Rank | Candidate | Evidence | Recommendation | Parsed | Fail | Pending | Red Windows | Total Net | Exact Continuous | Exact Ann. Return % | Exact CAGR % | Worst DD % | Min PF | Score |
| ---: | --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 1 | `lowatr_locked_risk18pure` | FAIL | REJECT_FIRST_PASS | 1/22 | 2 | 13 | 0 | 419.14 |  |  |  | 7.33 | 5.0524 |  |

## Candidate Summary

| Candidate | Parsed/Expected | Total Net | Worst Window | Continuous Exact Net | Continuous Ann. Return % | Continuous CAGR % | Worst DD % | Min PF | Min Expected | Min Sharpe | Min Win % | Worst Loss Run | Min Recovery |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `lowatr_locked_risk18pure` | 1/22 | 419.14 | 419.14 |  |  |  | 7.33 | 5.0524 | 52.3925 | 7.6671 | 75 | 2 | 3.7366 |

## Gates

| Gate | Status | Required | Actual | Evidence |
| --- | --- | --- | --- | --- |
| queue-total-shape | PASS | manifest rows = 22 x active candidate count | manifestRows=22; expectedRows=22 | outputs\FIRST_PASS_VALIDATION_QUEUE.csv |
| candidate-count-shape | PASS | at least one active candidate in queue | candidates=lowatr_locked_risk18pure | outputs\FIRST_PASS_VALIDATION_QUEUE.csv |
| results-present | PASS | at least one imported result row | resultRows=22 | outputs\FIRST_PASS_VALIDATION_QUEUE_RESULTS.csv |
| lowatr_locked_risk18pure-queue-shape | PASS | 22 rows per active candidate: 16 validation, 6 broker-proxy | rows=22; validation=16; broker=6 | outputs\FIRST_PASS_VALIDATION_QUEUE.csv |
| lowatr_locked_risk18pure-import-row-shape | PASS | one imported row per queued config | candidateResultRows=22/22 | outputs\FIRST_PASS_VALIDATION_QUEUE_RESULTS.csv |
| lowatr_locked_risk18pure-full-report-stats-complete | PASS | every parsed first-pass row includes PF, expected payoff, Sharpe, win rate, trades, max consecutive losses, drawdown %, and recovery factor | parsed=1; missingStats=0 | candidate=lowatr_locked_risk18pure |
| lowatr_locked_risk18pure-phase0_fast_model1-complete | FAIL | all queued phase0_fast_model1 reports parsed | parsed=1/4 | candidate=lowatr_locked_risk18pure |
| lowatr_locked_risk18pure-phase1_exact_realtick-complete | PENDING | all queued phase1_exact_realtick reports parsed | parsed=0/4 | candidate=lowatr_locked_risk18pure |
| lowatr_locked_risk18pure-phase2_realtick_quarterly-complete | PENDING | all queued phase2_realtick_quarterly reports parsed | parsed=0/3 | candidate=lowatr_locked_risk18pure |
| lowatr_locked_risk18pure-phase3_realtick_monthly-complete | PENDING | all queued phase3_realtick_monthly reports parsed | parsed=0/2 | candidate=lowatr_locked_risk18pure |
| lowatr_locked_risk18pure-phase4_stress_realtick-complete | PENDING | all queued phase4_stress_realtick reports parsed | parsed=0/3 | candidate=lowatr_locked_risk18pure |
| lowatr_locked_risk18pure-phase5_broker_proxy_realtick-complete | PENDING | all queued phase5_broker_proxy_realtick reports parsed | parsed=0/6 | candidate=lowatr_locked_risk18pure |
| lowatr_locked_risk18pure-fast-model1-profitable | PENDING | all fast Model1 windows net >= 0 | bad=0 | candidate=lowatr_locked_risk18pure |
| lowatr_locked_risk18pure-fast-model1-continuous-annualized-return-floor | PASS | fast Model1 continuous annualized return >= 8% | annualizedReturn=16.59 | candidate=lowatr_locked_risk18pure |
| lowatr_locked_risk18pure-fast-model1-continuous-return-drawdown-efficiency | PASS | fast Model1 continuous return % / equity DD % >= 1.5 | returnToDD=5.7181; returnPct=41.91; ddPct=7.33 | candidate=lowatr_locked_risk18pure |
| lowatr_locked_risk18pure-exact-realtick-profitable | PENDING | all exact real-tick windows net >= 0 | bad=0 | candidate=lowatr_locked_risk18pure |
| lowatr_locked_risk18pure-exact-continuous-min-trades | PENDING | continuous exact real-tick trades >= 20 | continuousTrades= | candidate=lowatr_locked_risk18pure |
| lowatr_locked_risk18pure-exact-continuous-annualized-return-floor | PENDING | continuous exact annualized return >= 12% | annualizedReturn= | candidate=lowatr_locked_risk18pure |
| lowatr_locked_risk18pure-exact-continuous-cagr-floor | PENDING | continuous exact CAGR >= 10% | cagr= | candidate=lowatr_locked_risk18pure |
| lowatr_locked_risk18pure-exact-continuous-return-drawdown-efficiency | PENDING | continuous exact return % / equity DD % >= 3 | returnToDD=; returnPct=; ddPct= | candidate=lowatr_locked_risk18pure |
| lowatr_locked_risk18pure-fragile-seasonal-profitable | PENDING | fragile Q4/December/recent windows net >= 0 | bad=0 | candidate=lowatr_locked_risk18pure |
| lowatr_locked_risk18pure-stress-broker-profitable | PENDING | stress and broker-proxy windows net >= 0 | bad=0 | candidate=lowatr_locked_risk18pure |
| lowatr_locked_risk18pure-drawdown-within-first-pass-cap | FAIL | worst parsed DD <= 6% | worstDD=7.33; samples=1 | candidate=lowatr_locked_risk18pure |
| lowatr_locked_risk18pure-profit-factor-floor | PASS | minimum parsed PF >= 1.2 | minPF=5.0524; samples=1 | candidate=lowatr_locked_risk18pure |
| lowatr_locked_risk18pure-expected-payoff-floor | PASS | minimum parsed expected payoff >= 0 | minExpectedPayoff=52.3925; samples=1 | candidate=lowatr_locked_risk18pure |
| lowatr_locked_risk18pure-sharpe-ratio-floor | PASS | minimum parsed Sharpe ratio >= 0.1 | minSharpe=7.6671; samples=1 | candidate=lowatr_locked_risk18pure |
| lowatr_locked_risk18pure-win-rate-floor | PASS | minimum parsed win rate >= 20% | minWinRate=75; samples=1 | candidate=lowatr_locked_risk18pure |
| lowatr_locked_risk18pure-consecutive-losses-cap | PASS | maximum parsed consecutive losses <= 5 | worstLossRun=2; samples=1 | candidate=lowatr_locked_risk18pure |
| lowatr_locked_risk18pure-recovery-factor-floor | PASS | minimum parsed recovery factor >= 1.25 | minRecovery=3.7366; samples=1 | candidate=lowatr_locked_risk18pure |
