# First-Pass Validation Log Metrics

Generated from exported MT5 reports when present and hidden MT5 tester logs when no report was exported. No MT5 process was launched.

- Queue manifest: `outputs\BROKER_RISK_SIZING_PROBE_QUEUE.csv`
- Hidden run CSV: `outputs\BROKER_RISK_SIZING_PROBE_RUN.csv`
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
| `brs_cap075_sweep_off` | broker_risk_sizing_probe | fast_model1 | 9 | 0 | 9 | 6.89 | -4.08 | 0.09 | -0.41 | 1.35 | 0 | 32 |
| `brs_cap100_sweep_off` | broker_risk_sizing_probe | fast_model1 | 9 | 0 | 9 | 6.89 | -4.08 | 0.09 | -0.41 | 1.35 | 0 | 32 |
| `brs_cap100_sweep_on` | broker_risk_sizing_probe | fast_model1 | 9 | 0 | 9 | -44.09 | -42.98 | -0.16 | -2.69 | 4.71 | 0 | 120 |
| `brs_uncapped_sweep_off` | broker_risk_sizing_probe | fast_model1 | 9 | 0 | 9 | 6.89 | -4.08 | 0.09 | -0.41 | 1.35 | 0 | 32 |
| `brs_uncapped_sweep_on` | broker_risk_sizing_probe | fast_model1 | 9 | 0 | 9 | -39.61 | -38.84 | -0.11 | -2.69 | 4.3 | 0 | 120 |

## Missing Or Unparsed

All queued rows have report or log evidence.
