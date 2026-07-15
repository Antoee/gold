# First-Pass Validation Log Metrics

Generated from exported MT5 reports when present and hidden MT5 tester logs when no report was exported. No MT5 process was launched.

- Queue manifest: `outputs\STABILITY_REBASE_PROBE_QUEUE.csv`
- Hidden run CSV: `outputs\STABILITY_REBASE_PROBE_RUN.csv`
- Log files scanned: `2`
- Expected rows: `18`
- Parsed exported reports: `18`
- Parsed from tester log: `0`
- Missing reports/results: `0`
- Unparsed log rows: `0`

Log-parsed rows are enough to reject bad fast screens, but exported full reports are still required before any candidate can be trusted for promotion.

## Summary By Candidate

| Candidate | Source | Phase | Parsed Reports | Parsed Logs | Expected | Total Net | Worst Window | Avg Ann. Return % | Worst Ann. Return % | Worst DD % | Min PF | Trades |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `sr_control` | broker_risk_sizing_probe | fast_model1 | 9 | 0 | 9 | 630.18 | 4.24 | 0.45 | 0.04 | 0.92 | 0 | 58 |
| `sr_sweep_off` | broker_risk_sizing_probe | fast_model1 | 9 | 0 | 9 | 655.63 | 4.24 | 0.47 | 0.04 | 0.82 | 0 | 56 |

## Missing Or Unparsed

All queued rows have report or log evidence.
