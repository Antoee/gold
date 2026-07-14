# First-Pass Validation Report Metrics

Generated from exported MT5 report files only. No MT5 process was launched.

- Queue manifest: `outputs\FIRST_PASS_VALIDATION_QUEUE.csv`
- Expected reports: `22`
- Parsed reports: `0`
- Missing reports: `22`
- Unparsed reports: `0`

## Summary By Candidate

| Candidate | Source | Phase | Parsed/Expected | Total Net | Worst Window | Avg Ann. Return % | Worst Ann. Return % | Avg CAGR % | Worst CAGR % | Worst DD % | Min PF | Avg Sharpe | Avg Win % | Worst Loss Run |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `trade_ready_conservative` | broker_proxy | phase5_broker_proxy_realtick | 0/6 |  |  |  |  |  |  |  |  |  |  |  |
| `trade_ready_conservative` | validation | phase0_fast_model1 | 0/4 |  |  |  |  |  |  |  |  |  |  |  |
| `trade_ready_conservative` | validation | phase1_exact_realtick | 0/4 |  |  |  |  |  |  |  |  |  |  |  |
| `trade_ready_conservative` | validation | phase2_realtick_quarterly | 0/3 |  |  |  |  |  |  |  |  |  |  |  |
| `trade_ready_conservative` | validation | phase3_realtick_monthly | 0/2 |  |  |  |  |  |  |  |  |  |  |  |
| `trade_ready_conservative` | validation | phase4_stress_realtick | 0/3 |  |  |  |  |  |  |  |  |  |  |  |

## Missing Or Unparsed Reports

| Rank | Candidate | Phase | Window | Status |
| ---: | --- | --- | --- | --- |
| 1 | `trade_ready_conservative` | phase0_fast_model1 | continuous_2024_2026 | MISSING_REPORT |
| 2 | `trade_ready_conservative` | phase0_fast_model1 | 2024_full | MISSING_REPORT |
| 3 | `trade_ready_conservative` | phase0_fast_model1 | 2025_full | MISSING_REPORT |
| 4 | `trade_ready_conservative` | phase0_fast_model1 | 2026_ytd | MISSING_REPORT |
| 5 | `trade_ready_conservative` | phase1_exact_realtick | continuous_2024_2026 | MISSING_REPORT |
| 6 | `trade_ready_conservative` | phase1_exact_realtick | 2024_full | MISSING_REPORT |
| 7 | `trade_ready_conservative` | phase1_exact_realtick | 2025_full | MISSING_REPORT |
| 8 | `trade_ready_conservative` | phase1_exact_realtick | 2026_ytd | MISSING_REPORT |
| 9 | `trade_ready_conservative` | phase2_realtick_quarterly | 2024_Q4 | MISSING_REPORT |
| 10 | `trade_ready_conservative` | phase2_realtick_quarterly | 2025_Q4 | MISSING_REPORT |
| 11 | `trade_ready_conservative` | phase2_realtick_quarterly | 2026_Q2 | MISSING_REPORT |
| 12 | `trade_ready_conservative` | phase3_realtick_monthly | 2024_12 | MISSING_REPORT |
| 13 | `trade_ready_conservative` | phase3_realtick_monthly | 2025_12 | MISSING_REPORT |
| 14 | `trade_ready_conservative` | phase4_stress_realtick | continuous_2024_2026 | MISSING_REPORT |
| 15 | `trade_ready_conservative` | phase4_stress_realtick | continuous_2024_2026 | MISSING_REPORT |
| 16 | `trade_ready_conservative` | phase4_stress_realtick | continuous_2024_2026 | MISSING_REPORT |
| 17 | `trade_ready_conservative` | phase5_broker_proxy_realtick | continuous_2024_2026 | MISSING_REPORT |
| 18 | `trade_ready_conservative` | phase5_broker_proxy_realtick | 2026_ytd | MISSING_REPORT |
| 19 | `trade_ready_conservative` | phase5_broker_proxy_realtick | continuous_2024_2026 | MISSING_REPORT |
| 20 | `trade_ready_conservative` | phase5_broker_proxy_realtick | continuous_2024_2026 | MISSING_REPORT |
| 21 | `trade_ready_conservative` | phase5_broker_proxy_realtick | continuous_2024_2026 | MISSING_REPORT |
| 22 | `trade_ready_conservative` | phase5_broker_proxy_realtick | continuous_2024_2026 | MISSING_REPORT |
