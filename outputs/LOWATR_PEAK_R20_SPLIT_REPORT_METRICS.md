# First-Pass Validation Log Metrics

Generated from exported MT5 reports when present and hidden MT5 tester logs when no report was exported. No MT5 process was launched.

- Queue manifest: `.\outputs\LOWATR_PEAK_R20_SPLIT_QUEUE.csv`
- Hidden run CSV: `.\outputs\LOWATR_PEAK_R20_SPLIT_HIDDEN_RUN_PLAN.csv`
- Log files scanned: `1`
- Expected rows: `3`
- Parsed exported reports: `0`
- Parsed from tester log: `3`
- Missing reports/results: `0`
- Unparsed log rows: `0`

Log-parsed rows are enough to reject bad fast screens, but exported full reports are still required before any candidate can be trusted for promotion.

## Summary By Candidate

| Candidate | Source | Phase | Parsed Reports | Parsed Logs | Expected | Total Net | Worst Window | Avg Ann. Return % | Worst Ann. Return % | Worst DD % | Min PF | Trades |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `lowatr_exit_peak_r20` | year_split | phase0_yearly_model1 | 0 | 3 | 3 | 678.31 | 21.17 | 28.41 | 2.12 | 5.81 | 1.6271 | 25 |

## Missing Or Unparsed

All queued rows have report or log evidence.
