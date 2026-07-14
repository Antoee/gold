# First-Pass Validation Log Metrics

Generated from exported MT5 reports when present and hidden MT5 tester logs when no report was exported. No MT5 process was launched.

- Queue manifest: `.\outputs\PEAK_R20_NO_PEAKTRAIL_R10_MODEL4_QUEUE.csv`
- Hidden run CSV: `.\outputs\PEAK_R20_NO_PEAKTRAIL_R10_MODEL4_HIDDEN_RUN_PLAN.csv`
- Log files scanned: `1`
- Expected rows: `1`
- Parsed exported reports: `0`
- Parsed from tester log: `1`
- Missing reports/results: `0`
- Unparsed log rows: `0`

Log-parsed rows are enough to reject bad fast screens, but exported full reports are still required before any candidate can be trusted for promotion.

## Summary By Candidate

| Candidate | Source | Phase | Parsed Reports | Parsed Logs | Expected | Total Net | Worst Window | Avg Ann. Return % | Worst Ann. Return % | Worst DD % | Min PF | Trades |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `peak_r20_no_peaktrail_r10` | single_profile | single_profile_model4 | 0 | 1 | 1 | 1564.01 | 1564.01 | 61.89 | 61.89 | 10.64 | 2.6874 | 74 |

## Missing Or Unparsed

All queued rows have report or log evidence.
