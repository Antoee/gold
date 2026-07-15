# First-Pass Validation Log Metrics

Generated from exported MT5 reports when present and hidden MT5 tester logs when no report was exported. No MT5 process was launched.

- Queue manifest: `outputs\RANGE_ELITE_DGF_PROTECT_MODEL1_QUEUE.csv`
- Hidden run CSV: `outputs\RANGE_ELITE_DGF_PROTECT_MODEL1_RUN.csv`
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
| `re_may140_late15_dgf_liq_reject1_cush50` | range_elite_risk_shape_probe | phase4_range_elite_risk_shape_model1 | 6 | 0 | 6 | 2756.07 | -40.79 | 51.37 | -4.09 | 20.83 | 0 | 36 |
| `re_may140_late15_dgf_liq_reject1_cush50_dgfperf35` | range_elite_risk_shape_probe | phase4_range_elite_risk_shape_model1 | 6 | 0 | 6 | 2626.64 | -87.4 | 49.21 | -8.77 | 20.83 | 0.1 | 46 |
| `re_may140_late15_dgf_liq_reject1_cush50_dgfq_pa6` | range_elite_risk_shape_probe | phase4_range_elite_risk_shape_model1 | 6 | 0 | 6 | -249 | -128.18 | -6.09 | -24.38 | 20.75 | 0 | 50 |
| `re_may140_late15_dgf_liq_reject1_cush50_recovery_perf` | range_elite_risk_shape_probe | phase4_range_elite_risk_shape_model1 | 6 | 0 | 6 | 2639.21 | -85.42 | 49.42 | -8.57 | 20.83 | 0.11 | 46 |
| `re_may140_late15_dgf_liq_reject1_cush50_starterec35` | range_elite_risk_shape_probe | phase4_range_elite_risk_shape_model1 | 6 | 0 | 6 | 2767.24 | -40.79 | 51.56 | -4.09 | 20.83 | 0 | 43 |

## Missing Or Unparsed

All queued rows have report or log evidence.
