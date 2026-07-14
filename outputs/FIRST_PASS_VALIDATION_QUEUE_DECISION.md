# First-Pass Validation Decision

- Overall: **PENDING**
- Passed gates: `5`
- Pending gates: `21`
- Failed gates: `0`
- Queue rows: `22`
- Imported result rows: `22`

This is an early screen only. Passing it does not approve live trading; it only decides whether a candidate deserves the full validation packages.

## Candidate Ranking

| Rank | Candidate | Evidence | Recommendation | Parsed | Fail | Pending | Red Windows | Total Net | Exact Continuous | Exact Ann. Return % | Exact CAGR % | Worst DD % | Min PF | Score |
| ---: | --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 1 | `trade_ready_conservative` | PENDING | WAIT_FOR_REPORTS | 0/22 | 0 | 21 | 0 |  |  |  |  |  |  |  |

## Candidate Summary

| Candidate | Parsed/Expected | Total Net | Worst Window | Continuous Exact Net | Continuous Ann. Return % | Continuous CAGR % | Worst DD % | Min PF | Min Expected | Min Sharpe | Min Win % | Worst Loss Run | Min Recovery |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `trade_ready_conservative` | 0/22 |  |  |  |  |  |  |  |  |  |  |  |  |

## Gates

| Gate | Status | Required | Actual | Evidence |
| --- | --- | --- | --- | --- |
| queue-total-shape | PASS | manifest rows = 22 x active candidate count | manifestRows=22; expectedRows=22 | outputs\FIRST_PASS_VALIDATION_QUEUE.csv |
| candidate-count-shape | PASS | at least one active candidate in queue | candidates=trade_ready_conservative | outputs\FIRST_PASS_VALIDATION_QUEUE.csv |
| results-present | PASS | at least one imported result row | resultRows=22 | outputs\FIRST_PASS_VALIDATION_QUEUE_RESULTS.csv |
| trade_ready_conservative-queue-shape | PASS | 22 rows per active candidate: 16 validation, 6 broker-proxy | rows=22; validation=16; broker=6 | outputs\FIRST_PASS_VALIDATION_QUEUE.csv |
| trade_ready_conservative-import-row-shape | PASS | one imported row per queued config | candidateResultRows=22/22 | outputs\FIRST_PASS_VALIDATION_QUEUE_RESULTS.csv |
| trade_ready_conservative-full-report-stats-complete | PENDING | every parsed first-pass row includes PF, expected payoff, Sharpe, win rate, trades, max consecutive losses, drawdown %, and recovery factor | parsed=0; missingStats=0 | candidate=trade_ready_conservative |
| trade_ready_conservative-phase0_fast_model1-complete | PENDING | all queued phase0_fast_model1 reports parsed | parsed=0/4 | candidate=trade_ready_conservative |
| trade_ready_conservative-phase1_exact_realtick-complete | PENDING | all queued phase1_exact_realtick reports parsed | parsed=0/4 | candidate=trade_ready_conservative |
| trade_ready_conservative-phase2_realtick_quarterly-complete | PENDING | all queued phase2_realtick_quarterly reports parsed | parsed=0/3 | candidate=trade_ready_conservative |
| trade_ready_conservative-phase3_realtick_monthly-complete | PENDING | all queued phase3_realtick_monthly reports parsed | parsed=0/2 | candidate=trade_ready_conservative |
| trade_ready_conservative-phase4_stress_realtick-complete | PENDING | all queued phase4_stress_realtick reports parsed | parsed=0/3 | candidate=trade_ready_conservative |
| trade_ready_conservative-phase5_broker_proxy_realtick-complete | PENDING | all queued phase5_broker_proxy_realtick reports parsed | parsed=0/6 | candidate=trade_ready_conservative |
| trade_ready_conservative-fast-model1-profitable | PENDING | all fast Model1 windows net >= 0 | bad=0 | candidate=trade_ready_conservative |
| trade_ready_conservative-exact-realtick-profitable | PENDING | all exact real-tick windows net >= 0 | bad=0 | candidate=trade_ready_conservative |
| trade_ready_conservative-exact-continuous-min-trades | PENDING | continuous exact real-tick trades >= 20 | continuousTrades= | candidate=trade_ready_conservative |
| trade_ready_conservative-exact-continuous-annualized-return-floor | PENDING | continuous exact annualized return >= 1% | annualizedReturn= | candidate=trade_ready_conservative |
| trade_ready_conservative-exact-continuous-cagr-floor | PENDING | continuous exact CAGR >= 1% | cagr= | candidate=trade_ready_conservative |
| trade_ready_conservative-fragile-seasonal-profitable | PENDING | fragile Q4/December/recent windows net >= 0 | bad=0 | candidate=trade_ready_conservative |
| trade_ready_conservative-stress-broker-profitable | PENDING | stress and broker-proxy windows net >= 0 | bad=0 | candidate=trade_ready_conservative |
| trade_ready_conservative-drawdown-within-first-pass-cap | PENDING | worst parsed DD <= 10% | worstDD=; samples=0 | candidate=trade_ready_conservative |
| trade_ready_conservative-profit-factor-floor | PENDING | minimum parsed PF >= 1.1 | minPF=; samples=0 | candidate=trade_ready_conservative |
| trade_ready_conservative-expected-payoff-floor | PENDING | minimum parsed expected payoff >= 0 | minExpectedPayoff=; samples=0 | candidate=trade_ready_conservative |
| trade_ready_conservative-sharpe-ratio-floor | PENDING | minimum parsed Sharpe ratio >= 0.1 | minSharpe=; samples=0 | candidate=trade_ready_conservative |
| trade_ready_conservative-win-rate-floor | PENDING | minimum parsed win rate >= 20% | minWinRate=; samples=0 | candidate=trade_ready_conservative |
| trade_ready_conservative-consecutive-losses-cap | PENDING | maximum parsed consecutive losses <= 5 | worstLossRun=; samples=0 | candidate=trade_ready_conservative |
| trade_ready_conservative-recovery-factor-floor | PENDING | minimum parsed recovery factor >= 1 | minRecovery=; samples=0 | candidate=trade_ready_conservative |
