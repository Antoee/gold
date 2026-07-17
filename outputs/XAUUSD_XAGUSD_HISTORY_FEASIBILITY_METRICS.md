# First-Pass Validation Log Metrics

Generated from exported MT5 reports when present and hidden MT5 tester logs when no report was exported. No MT5 process was launched.

- Queue manifest: `outputs\XAUUSD_XAGUSD_HISTORY_FEASIBILITY_QUEUE.csv`
- Hidden run CSV: `outputs\XAUUSD_XAGUSD_HISTORY_FEASIBILITY_RUN.csv`
- Log files scanned: `2`
- Expected rows: `2`
- Parsed exported reports: `2`
- Parsed from tester log: `0`
- Missing reports/results: `0`
- Unparsed log rows: `0`

Log-parsed rows are enough to reject bad fast screens, but exported full reports are still required before any candidate can be trusted for promotion.

## Summary By Candidate

| Candidate | Source | Phase | Parsed Reports | Parsed Logs | Expected | Total Net | Worst Window | Avg Ann. Return % | Worst Ann. Return % | Worst DD % | Min PF | Trades |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `xau_xag_history_discovery_2019_2020` | xau_xag_history_feasibility | history_feasibility_diagnostic | 1 | 0 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| `xau_xag_history_older_2015_2018` | xau_xag_history_feasibility | history_feasibility_diagnostic | 1 | 0 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |

## Missing Or Unparsed

All queued rows have report or log evidence.
