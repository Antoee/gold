# First-Pass Validation Log Metrics

Generated from exported MT5 reports when present and hidden MT5 tester logs when no report was exported. No MT5 process was launched.

- Queue manifest: `.\outputs\PEAK_R20_FAILURE_TRADE_DIAG_QUEUE.csv`
- Hidden run CSV: `.\outputs\PEAK_R20_FAILURE_TRADE_DIAG_HIDDEN_RUN_PLAN.csv`
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
| `r10_profit_guard40_diag` | peak_r20_failure_trade_diag | phase3_failure_trade_diag_model1 | 0 | 5 | 5 | 389.31 | -61.65 | 7.79 | -6.19 | 12.78 | 0.3507 | 64 |

## Missing Or Unparsed

All queued rows have report or log evidence.
