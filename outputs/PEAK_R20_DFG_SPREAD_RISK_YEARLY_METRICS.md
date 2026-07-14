# First-Pass Validation Log Metrics

Generated from exported MT5 reports when present and hidden MT5 tester logs when no report was exported. No MT5 process was launched.

- Queue manifest: `.\outputs\PEAK_R20_DFG_SPREAD_RISK_YEARLY_QUEUE.csv`
- Hidden run CSV: `.\outputs\PEAK_R20_DFG_SPREAD_RISK_YEARLY_HIDDEN_RUN_PLAN.csv`
- Log files scanned: `1`
- Expected rows: `48`
- Parsed exported reports: `0`
- Parsed from tester log: `48`
- Missing reports/results: `0`
- Unparsed log rows: `0`

Log-parsed rows are enough to reject bad fast screens, but exported full reports are still required before any candidate can be trusted for promotion.

## Summary By Candidate

| Candidate | Source | Phase | Parsed Reports | Parsed Logs | Expected | Total Net | Worst Window | Avg Ann. Return % | Worst Ann. Return % | Worst DD % | Min PF | Trades |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `r10_a7_dfg_risk_20_31_25` | peak_r20_dfg_spread_risk_yearly | phase6_dfg_spread_risk_yearly_model1 | 0 | 8 | 8 | 278.55 | -24.17 | 4.11 | -2.42 | 6.26 | 0 | 28 |
| `r10_a7_dfg_risk_20_35_35` | peak_r20_dfg_spread_risk_yearly | phase6_dfg_spread_risk_yearly_model1 | 0 | 8 | 8 | 326.6 | -3.83 | 4.71 | -0.38 | 6.18 | 0 | 29 |
| `r10_a7_dfg_risk_25_31_25` | peak_r20_dfg_spread_risk_yearly | phase6_dfg_spread_risk_yearly_model1 | 0 | 8 | 8 | 291.63 | -24.17 | 4.28 | -2.42 | 6.18 | 0 | 28 |
| `r10_a7_dfg_risk_25_35_35` | peak_r20_dfg_spread_risk_yearly | phase6_dfg_spread_risk_yearly_model1 | 0 | 8 | 8 | 292.86 | -22.94 | 4.29 | -2.3 | 6.18 | 0 | 28 |
| `r10_a7_dfg_risk_25_45_50` | peak_r20_dfg_spread_risk_yearly | phase6_dfg_spread_risk_yearly_model1 | 0 | 8 | 8 | 343.92 | 9.25 | 4.93 | 0.93 | 6.18 | 0 | 28 |
| `r10_a7_dfg_risk_base` | peak_r20_dfg_spread_risk_yearly | phase6_dfg_spread_risk_yearly_model1 | 0 | 8 | 8 | 344.6 | 9.25 | 4.94 | 0.93 | 7.08 | 0 | 28 |

## Missing Or Unparsed

All queued rows have report or log evidence.
