# First-Pass Validation Log Metrics

Generated from exported MT5 reports when present and hidden MT5 tester logs when no report was exported. No MT5 process was launched.

- Queue manifest: `outputs\RANGE_ELITE_FAILURE_TRADE_DIAG_QUEUE.csv`
- Hidden run CSV: `outputs\RANGE_ELITE_FAILURE_TRADE_DIAG_RUN.csv`
- Log files scanned: `2`
- Expected rows: `8`
- Parsed exported reports: `8`
- Parsed from tester log: `0`
- Missing reports/results: `0`
- Unparsed log rows: `0`

Log-parsed rows are enough to reject bad fast screens, but exported full reports are still required before any candidate can be trusted for promotion.

## Summary By Candidate

| Candidate | Source | Phase | Parsed Reports | Parsed Logs | Expected | Total Net | Worst Window | Avg Ann. Return % | Worst Ann. Return % | Worst DD % | Min PF | Trades |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `range_elite_diag` | range_elite_failure_trade_diag | phase3_range_elite_failure_trade_diag_model4 | 8 | 0 | 8 | 2953.27 | -131.33 | 45.31 | -13.18 | 27.87 | 0 | 61 |

## Missing Or Unparsed

All queued rows have report or log evidence.
