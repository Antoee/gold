# First-Pass Validation Log Metrics

Generated from exported MT5 reports when present and hidden MT5 tester logs when no report was exported. No MT5 process was launched.

- Queue manifest: `outputs\RANGE_ELITE_LATE15_MAY140_MODEL4_QUEUE.csv`
- Hidden run CSV: `outputs\RANGE_ELITE_LATE15_MAY140_MODEL4_RUN.csv`
- Log files scanned: `2`
- Expected rows: `6`
- Parsed exported reports: `6`
- Parsed from tester log: `0`
- Missing reports/results: `0`
- Unparsed log rows: `0`

Log-parsed rows are enough to reject bad fast screens, but exported full reports are still required before any candidate can be trusted for promotion.

## Summary By Candidate

| Candidate | Source | Phase | Parsed Reports | Parsed Logs | Expected | Total Net | Worst Window | Avg Ann. Return % | Worst Ann. Return % | Worst DD % | Min PF | Trades |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `re_may140_late15_pure` | range_elite_risk_shape_probe | phase4_range_elite_risk_shape_model4 | 6 | 0 | 6 | 3108.1 | -62.11 | 58.95 | -6.23 | 24.72 | 0 | 26 |

## Missing Or Unparsed

All queued rows have report or log evidence.
