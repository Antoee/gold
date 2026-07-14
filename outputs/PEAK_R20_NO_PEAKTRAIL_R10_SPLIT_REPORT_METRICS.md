# First-Pass Validation Log Metrics

Generated from exported MT5 reports when present and hidden MT5 tester logs when no report was exported. No MT5 process was launched.

- Queue manifest: `.\outputs\PEAK_R20_NO_PEAKTRAIL_R10_SPLIT_QUEUE.csv`
- Hidden run CSV: `.\outputs\PEAK_R20_NO_PEAKTRAIL_R10_SPLIT_HIDDEN_RUN_PLAN.csv`
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
| `peak_r20_no_peaktrail_r10` | year_split | phase0_yearly_model1 | 0 | 3 | 3 | 1248.34 | 186.95 | 49.08 | 18.76 | 10.01 | 1.7478 | 74 |

## Missing Or Unparsed

All queued rows have report or log evidence.
