# First-Pass Validation Log Metrics

Generated from exported MT5 reports when present and hidden MT5 tester logs when no report was exported. No MT5 process was launched.

- Queue manifest: `.\outputs\PEAK_R20_DRAWDOWN_SHORTLIST_QUEUE.csv`
- Hidden run CSV: `.\outputs\PEAK_R20_DRAWDOWN_SHORTLIST_HIDDEN_RUN_PLAN.csv`
- Log files scanned: `1`
- Expected rows: `5`
- Parsed exported reports: `0`
- Parsed from tester log: `5`
- Missing reports/results: `0`
- Unparsed log rows: `0`

Log-parsed rows are enough to reject bad fast screens, but exported full reports are still required before any candidate can be trusted for promotion.

## Summary By Candidate

| Candidate | Source | Phase | Parsed Reports | Parsed Logs | Expected | Total Net | Worst Window | Avg Ann. Return % | Worst Ann. Return % | Worst DD % | Min PF | Trades |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `r10_base` | peak_r20_drawdown_shortlist | phase1_model4_shortlist | 0 | 1 | 1 | 1564.01 | 1564.01 | 61.89 | 61.89 | 10.64 | 2.6874 | 74 |
| `r10_dailytrail35` | peak_r20_drawdown_shortlist | phase1_model4_shortlist | 0 | 1 | 1 | 1577.25 | 1577.25 | 62.42 | 62.42 | 10.64 | 2.7264 | 73 |
| `r10_loss_scale_15` | peak_r20_drawdown_shortlist | phase1_model4_shortlist | 0 | 1 | 1 | 1281.41 | 1281.41 | 50.71 | 50.71 | 8.53 | 2.7634 | 68 |
| `r10_loss_scale_25` | peak_r20_drawdown_shortlist | phase1_model4_shortlist | 0 | 1 | 1 | 1396.22 | 1396.22 | 55.25 | 55.25 | 9.32 | 2.6496 | 75 |
| `r10_profit_guard40` | peak_r20_drawdown_shortlist | phase1_model4_shortlist | 0 | 1 | 1 | 1000.97 | 1000.97 | 39.61 | 39.61 | 7.76 | 3.4058 | 46 |

## Missing Or Unparsed

All queued rows have report or log evidence.
