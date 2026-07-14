# First-Pass Validation Log Metrics

Generated from exported MT5 reports when present and hidden MT5 tester logs when no report was exported. No MT5 process was launched.

- Queue manifest: `outputs\R10_ACTIVITY_PROBE_QUEUE.csv`
- Hidden run CSV: `outputs\R10_ACTIVITY_PROBE_RUN.csv`
- Log files scanned: `2`
- Expected rows: `30`
- Parsed exported reports: `30`
- Parsed from tester log: `0`
- Missing reports/results: `0`
- Unparsed log rows: `0`

Log-parsed rows are enough to reject bad fast screens, but exported full reports are still required before any candidate can be trusted for promotion.

## Summary By Candidate

| Candidate | Source | Phase | Parsed Reports | Parsed Logs | Expected | Total Net | Worst Window | Avg Ann. Return % | Worst Ann. Return % | Worst DD % | Min PF | Trades |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `r10_a7_current` | r10_activity_probe | phase7_activity_probe_model1 | 5 | 0 | 5 | 171.05 | 9.25 | 4.42 | 0.93 | 7.08 | 0 | 21 |
| `r10_a7_dfg_fmlr_blend` | r10_activity_probe | phase7_activity_probe_model1 | 5 | 0 | 5 | 170.37 | 9.25 | 4.41 | 0.93 | 6.18 | 0 | 21 |
| `r10_a7_dfg_fmlr_tight` | r10_activity_probe | phase7_activity_probe_model1 | 5 | 0 | 5 | 170.37 | 9.25 | 4.41 | 0.93 | 6.18 | 0 | 21 |
| `r10_a7_dfg_risk_25_45_50` | r10_activity_probe | phase7_activity_probe_model1 | 5 | 0 | 5 | 170.37 | 9.25 | 4.41 | 0.93 | 6.18 | 0 | 21 |
| `r10_a7_fmlr_blend` | r10_activity_probe | phase7_activity_probe_model1 | 5 | 0 | 5 | 171.05 | 9.25 | 4.42 | 0.93 | 7.08 | 0 | 21 |
| `r10_a7_fmlr_tight` | r10_activity_probe | phase7_activity_probe_model1 | 5 | 0 | 5 | 171.05 | 9.25 | 4.42 | 0.93 | 7.08 | 0 | 21 |

## Missing Or Unparsed

All queued rows have report or log evidence.
