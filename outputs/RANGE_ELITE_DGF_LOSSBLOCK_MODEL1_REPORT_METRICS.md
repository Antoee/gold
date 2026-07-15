# First-Pass Validation Log Metrics

Generated from exported MT5 reports when present and hidden MT5 tester logs when no report was exported. No MT5 process was launched.

- Queue manifest: `outputs\RANGE_ELITE_DGF_LOSSBLOCK_MODEL1_QUEUE.csv`
- Hidden run CSV: `outputs\RANGE_ELITE_DGF_LOSSBLOCK_MODEL1_RUN.csv`
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
| `re_may140_late15_dgf_liq_reject1_cush35_dgflossblock` | range_elite_risk_shape_probe | phase4_range_elite_risk_shape_model1 | 6 | 0 | 6 | 2308.63 | 3.4 | 38.78 | 0.34 | 20.75 | 1.07 | 31 |
| `re_may140_late15_dgf_liq_reject1_cush50` | range_elite_risk_shape_probe | phase4_range_elite_risk_shape_model1 | 6 | 0 | 6 | 2756.07 | -40.79 | 51.37 | -4.09 | 20.83 | 0 | 36 |
| `re_may140_late15_dgf_liq_reject1_cush50_dgflossblock` | range_elite_risk_shape_probe | phase4_range_elite_risk_shape_model1 | 6 | 0 | 6 | 2792.38 | -4.52 | 51.98 | -0.45 | 20.83 | 0.92 | 32 |
| `re_may140_late15_dgf_liq_reject1_cush50_dgflossblock_neg` | range_elite_risk_shape_probe | phase4_range_elite_risk_shape_model1 | 6 | 0 | 6 | 2708.92 | -59.08 | 50.58 | -5.93 | 20.83 | 0.47 | 35 |

## Missing Or Unparsed

All queued rows have report or log evidence.
