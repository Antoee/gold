# First-Pass Validation Log Metrics

Generated from exported MT5 reports when present and hidden MT5 tester logs when no report was exported. No MT5 process was launched.

- Queue manifest: `outputs\RANGE_ELITE_RISK_SHAPE_PROBE_QUEUE.csv`
- Hidden run CSV: `outputs\RANGE_ELITE_RISK_SHAPE_PROBE_RUN.csv`
- Log files scanned: `2`
- Expected rows: `80`
- Parsed exported reports: `80`
- Parsed from tester log: `0`
- Missing reports/results: `0`
- Unparsed log rows: `0`

Log-parsed rows are enough to reject bad fast screens, but exported full reports are still required before any candidate can be trusted for promotion.

## Summary By Candidate

| Candidate | Source | Phase | Parsed Reports | Parsed Logs | Expected | Total Net | Worst Window | Avg Ann. Return % | Worst Ann. Return % | Worst DD % | Min PF | Trades |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `re_base` | range_elite_risk_shape_probe | phase4_range_elite_risk_shape_model1 | 5 | 0 | 5 | 2994.93 | -129.87 | 79.9 | -13.03 | 24.36 | 0 | 54 |
| `re_blockliq` | range_elite_risk_shape_probe | phase4_range_elite_risk_shape_model1 | 5 | 0 | 5 | 2994.93 | -129.87 | 79.9 | -13.03 | 24.36 | 0 | 54 |
| `re_blockliq_may100` | range_elite_risk_shape_probe | phase4_range_elite_risk_shape_model1 | 5 | 0 | 5 | 2752.83 | -141.94 | 72.31 | -14.24 | 20.75 | 0 | 44 |
| `re_blockliq_may140` | range_elite_risk_shape_probe | phase4_range_elite_risk_shape_model1 | 5 | 0 | 5 | 3015.75 | -138.37 | 77.62 | -13.88 | 20.75 | 0 | 39 |
| `re_dgfq_default` | range_elite_risk_shape_probe | phase4_range_elite_risk_shape_model1 | 5 | 0 | 5 | 58.14 | -183.18 | 4.02 | -18.38 | 30.95 | 0 | 31 |
| `re_dgfq_pa6_smq4` | range_elite_risk_shape_probe | phase4_range_elite_risk_shape_model1 | 5 | 0 | 5 | -254.76 | -183.18 | -7.89 | -29.22 | 30.95 | 0 | 29 |
| `re_dgfq_struct` | range_elite_risk_shape_probe | phase4_range_elite_risk_shape_model1 | 5 | 0 | 5 | 83.15 | -153.6 | -1.09 | -29.22 | 22.67 | 0 | 26 |
| `re_dgfq_struct_liq` | range_elite_risk_shape_probe | phase4_range_elite_risk_shape_model1 | 5 | 0 | 5 | 83.15 | -153.6 | -1.09 | -29.22 | 22.67 | 0 | 26 |
| `re_lotcap030` | range_elite_risk_shape_probe | phase4_range_elite_risk_shape_model1 | 5 | 0 | 5 | 1815.23 | -152.76 | 55.58 | -15.33 | 22.51 | 0 | 41 |
| `re_maxrisk100` | range_elite_risk_shape_probe | phase4_range_elite_risk_shape_model1 | 5 | 0 | 5 | 2743.48 | -129.87 | 74.3 | -13.03 | 22.51 | 0 | 42 |
| `re_may100` | range_elite_risk_shape_probe | phase4_range_elite_risk_shape_model1 | 5 | 0 | 5 | 2752.83 | -141.94 | 72.31 | -14.24 | 20.75 | 0 | 44 |
| `re_may140` | range_elite_risk_shape_probe | phase4_range_elite_risk_shape_model1 | 5 | 0 | 5 | 3015.75 | -138.37 | 77.62 | -13.88 | 20.75 | 0 | 39 |
| `re_may140_dgfq` | range_elite_risk_shape_probe | phase4_range_elite_risk_shape_model1 | 5 | 0 | 5 | -175.18 | -161.42 | -0.65 | -16.2 | 20.75 | 0 | 32 |
| `re_may200` | range_elite_risk_shape_probe | phase4_range_elite_risk_shape_model1 | 5 | 0 | 5 | 2043.58 | -152.76 | 60.25 | -15.33 | 22.37 | 0 | 38 |
| `re_ny_end16` | range_elite_risk_shape_probe | phase4_range_elite_risk_shape_model1 | 5 | 0 | 5 | 2231.58 | -129.87 | 64.63 | -13.03 | 20.75 | 0 | 37 |
| `re_ny16_may140_lot030` | range_elite_risk_shape_probe | phase4_range_elite_risk_shape_model1 | 5 | 0 | 5 | 1786.9 | -138.37 | 53.03 | -13.88 | 19.71 | 0 | 39 |

## Missing Or Unparsed

All queued rows have report or log evidence.
