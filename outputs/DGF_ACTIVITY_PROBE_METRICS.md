# First-Pass Validation Log Metrics

Generated from exported MT5 reports when present and hidden MT5 tester logs when no report was exported. No MT5 process was launched.

- Queue manifest: `outputs\DGF_ACTIVITY_PROBE_QUEUE.csv`
- Hidden run CSV: `outputs\DGF_ACTIVITY_PROBE_RUN.csv`
- Log files scanned: `2`
- Expected rows: `45`
- Parsed exported reports: `45`
- Parsed from tester log: `0`
- Missing reports/results: `0`
- Unparsed log rows: `0`

Log-parsed rows are enough to reject bad fast screens, but exported full reports are still required before any candidate can be trusted for promotion.

## Summary By Candidate

| Candidate | Source | Phase | Parsed Reports | Parsed Logs | Expected | Total Net | Worst Window | Avg Ann. Return % | Worst Ann. Return % | Worst DD % | Min PF | Trades |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `dfa_lb_off_fullrisk` | broker_risk_sizing_probe | fast_model1 | 9 | 0 | 9 | 153.74 | -14.04 | 1.11 | -1.41 | 3.66 | 0 | 219 |
| `dfa_lb_off_throttle025` | broker_risk_sizing_probe | fast_model1 | 9 | 0 | 9 | -2.55 | -1.55 | -0.02 | -0.16 | 0.82 | 0 | 17 |
| `dfa_lb_off_throttle050` | broker_risk_sizing_probe | fast_model1 | 9 | 0 | 9 | -10.26 | -12.06 | 0 | -0.75 | 1.84 | 0 | 37 |
| `dfa_lb_off_throttle075` | broker_risk_sizing_probe | fast_model1 | 9 | 0 | 9 | 48.71 | -5.96 | 0.53 | -0.6 | 2.61 | 0 | 140 |
| `dfa_lb_on_throttle050` | broker_risk_sizing_probe | fast_model1 | 9 | 0 | 9 | 6.89 | -4.08 | 0.09 | -0.41 | 1.35 | 0 | 32 |

## Missing Or Unparsed

All queued rows have report or log evidence.
