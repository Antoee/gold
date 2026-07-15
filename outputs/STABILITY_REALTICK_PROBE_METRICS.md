# First-Pass Validation Log Metrics

Generated from exported MT5 reports when present and hidden MT5 tester logs when no report was exported. No MT5 process was launched.

- Queue manifest: `outputs\STABILITY_REALTICK_PROBE_QUEUE.csv`
- Hidden run CSV: `outputs\STABILITY_REALTICK_PROBE_RUN.csv`
- Log files scanned: `2`
- Expected rows: `1`
- Parsed exported reports: `1`
- Parsed from tester log: `0`
- Missing reports/results: `0`
- Unparsed log rows: `0`

Log-parsed rows are enough to reject bad fast screens, but exported full reports are still required before any candidate can be trusted for promotion.

## Summary By Candidate

| Candidate | Source | Phase | Parsed Reports | Parsed Logs | Expected | Total Net | Worst Window | Avg Ann. Return % | Worst Ann. Return % | Worst DD % | Min PF | Trades |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `sr_m4_sweep_off` | broker_risk_sizing_probe | fast_model4 | 1 | 0 | 1 | 211.37 | 211.37 | 0.28 | 0.28 | 0.82 | 2.12 | 26 |

## Missing Or Unparsed

All queued rows have report or log evidence.
