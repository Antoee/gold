# First-Pass Validation Log Metrics

Generated from exported MT5 reports when present and hidden MT5 tester logs when no report was exported. No MT5 process was launched.

- Queue manifest: `outputs\RANGE_ELITE_DGF_CUSHION_MODEL4_QUEUE.csv`
- Hidden run CSV: `outputs\RANGE_ELITE_DGF_CUSHION_MODEL4_RUN.csv`
- Log files scanned: `2`
- Expected rows: `24`
- Parsed exported reports: `24`
- Parsed from tester log: `0`
- Missing reports/results: `0`
- Unparsed log rows: `0`

Log-parsed rows are enough to reject bad fast screens, but exported full reports are still required before any candidate can be trusted for promotion.

## Summary By Candidate

| Candidate | Source | Phase | Parsed Reports | Parsed Logs | Expected | Total Net | Worst Window | Avg Ann. Return % | Worst Ann. Return % | Worst DD % | Min PF | Trades |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `re_may140_late15_dgf_liq_reject1` | range_elite_risk_shape_probe | phase4_range_elite_risk_shape_model4 | 6 | 0 | 6 | 3218.26 | -40.2 | 60.79 | -4.03 | 24.72 | 0 | 30 |
| `re_may140_late15_dgf_liq_reject1_cush25` | range_elite_risk_shape_probe | phase4_range_elite_risk_shape_model4 | 6 | 0 | 6 | 2196.77 | -55.38 | 36.97 | -5.56 | 20.76 | 0.18 | 51 |
| `re_may140_late15_dgf_liq_reject1_cush35` | range_elite_risk_shape_probe | phase4_range_elite_risk_shape_model4 | 6 | 0 | 6 | 2294.11 | -39.13 | 38.54 | -3.93 | 20.76 | 0.32 | 50 |
| `re_may140_late15_dgf_liq_reject1_cush50` | range_elite_risk_shape_probe | phase4_range_elite_risk_shape_model4 | 6 | 0 | 6 | 2770.74 | -38.49 | 51.6 | -3.86 | 20.84 | 0 | 36 |

## Missing Or Unparsed

All queued rows have report or log evidence.
