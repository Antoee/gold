# First-Pass Validation Log Metrics

Generated from exported MT5 reports when present and hidden MT5 tester logs when no report was exported. No MT5 process was launched.

- Queue manifest: `.\outputs\PEAK_R20_DFG_SPREAD_YEARLY_QUEUE.csv`
- Hidden run CSV: `.\outputs\PEAK_R20_DFG_SPREAD_YEARLY_HIDDEN_RUN_PLAN.csv`
- Log files scanned: `1`
- Expected rows: `64`
- Parsed exported reports: `0`
- Parsed from tester log: `64`
- Missing reports/results: `0`
- Unparsed log rows: `0`

Log-parsed rows are enough to reject bad fast screens, but exported full reports are still required before any candidate can be trusted for promotion.

## Summary By Candidate

| Candidate | Source | Phase | Parsed Reports | Parsed Logs | Expected | Total Net | Worst Window | Avg Ann. Return % | Worst Ann. Return % | Worst DD % | Min PF | Trades |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `r10_a7_dfg_atr70` | peak_r20_dfg_spread_yearly | phase6_dfg_spread_yearly_model1 | 0 | 8 | 8 | 265.45 | -27.39 | 3.95 | -2.74 | 6.11 | 0 | 21 |
| `r10_a7_dfg_atr75` | peak_r20_dfg_spread_yearly | phase6_dfg_spread_yearly_model1 | 0 | 8 | 8 | 254.35 | -27.39 | 3.81 | -2.74 | 6.11 | 0 | 22 |
| `r10_a7_dfg_base` | peak_r20_dfg_spread_yearly | phase6_dfg_spread_yearly_model1 | 0 | 8 | 8 | 344.6 | 9.25 | 4.94 | 0.93 | 7.08 | 0 | 28 |
| `r10_a7_dfg_spread25` | peak_r20_dfg_spread_yearly | phase6_dfg_spread_yearly_model1 | 0 | 8 | 8 | 249.17 | -43.07 | 3.74 | -4.31 | 6.42 | 0 | 24 |
| `r10_a7_dfg_spread27` | peak_r20_dfg_spread_yearly | phase6_dfg_spread_yearly_model1 | 0 | 8 | 8 | 301.49 | -27.39 | 4.4 | -2.74 | 6.11 | 0 | 25 |
| `r10_a7_dfg_spread27_atr70` | peak_r20_dfg_spread_yearly | phase6_dfg_spread_yearly_model1 | 0 | 8 | 8 | 265.45 | -27.39 | 3.95 | -2.74 | 6.11 | 0 | 21 |
| `r10_a7_dfg_spread29` | peak_r20_dfg_spread_yearly | phase6_dfg_spread_yearly_model1 | 0 | 8 | 8 | 301.49 | -27.39 | 4.4 | -2.74 | 6.11 | 0 | 25 |
| `r10_a7_dfg_spread29_atr75` | peak_r20_dfg_spread_yearly | phase6_dfg_spread_yearly_model1 | 0 | 8 | 8 | 254.35 | -27.39 | 3.81 | -2.74 | 6.11 | 0 | 22 |

## Missing Or Unparsed

All queued rows have report or log evidence.
