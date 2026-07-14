# First-Pass Validation Log Metrics

Generated from exported MT5 reports when present and hidden MT5 tester logs when no report was exported. No MT5 process was launched.

- Queue manifest: `.\outputs\PEAK_R20_OOS_YEARLY_QUEUE.csv`
- Hidden run CSV: `.\outputs\PEAK_R20_OOS_YEARLY_HIDDEN_RUN_PLAN.csv`
- Log files scanned: `1`
- Expected rows: `24`
- Parsed exported reports: `0`
- Parsed from tester log: `24`
- Missing reports/results: `0`
- Unparsed log rows: `0`

Log-parsed rows are enough to reject bad fast screens, but exported full reports are still required before any candidate can be trusted for promotion.

## Summary By Candidate

| Candidate | Source | Phase | Parsed Reports | Parsed Logs | Expected | Total Net | Worst Window | Avg Ann. Return % | Worst Ann. Return % | Worst DD % | Min PF | Trades |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `r10_base` | peak_r20_oos_yearly | phase2_oos_yearly_model1 | 0 | 8 | 8 | 1371.43 | -66.26 | 19.94 | -6.65 | 12.44 | 0.3507 | 176 |
| `r10_loss_scale_15` | peak_r20_oos_yearly | phase2_oos_yearly_model1 | 0 | 8 | 8 | 956.26 | -90.25 | 14.74 | -9.06 | 14.21 | 0.4153 | 180 |
| `r10_profit_guard40` | peak_r20_oos_yearly | phase2_oos_yearly_model1 | 0 | 8 | 8 | 848.09 | -61.65 | 12.85 | -6.19 | 12.78 | 0.3507 | 116 |

## Missing Or Unparsed

All queued rows have report or log evidence.
