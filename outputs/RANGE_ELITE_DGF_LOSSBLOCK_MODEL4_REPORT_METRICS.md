# First-Pass Validation Log Metrics

Generated from exported MT5 reports when present and hidden MT5 tester logs when no report was exported. No MT5 process was launched.

- Queue manifest: `outputs\RANGE_ELITE_DGF_LOSSBLOCK_MODEL4_QUEUE.csv`
- Hidden run CSV: `outputs\RANGE_ELITE_DGF_LOSSBLOCK_MODEL4_RUN.csv`
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
| `re_may140_late15_dgf_liq_reject1_cush35_dgflossblock` | range_elite_risk_shape_probe | phase4_range_elite_risk_shape_model4 | 6 | 0 | 6 | 2323.11 | 0.68 | 39.02 | 0.07 | 20.76 | 1.01 | 31 |
| `re_may140_late15_dgf_liq_reject1_cush50` | range_elite_risk_shape_probe | phase4_range_elite_risk_shape_model4 | 6 | 0 | 6 | 2770.74 | -38.49 | 51.6 | -3.86 | 20.84 | 0 | 36 |
| `re_may140_late15_dgf_liq_reject1_cush50_dgflossblock` | range_elite_risk_shape_probe | phase4_range_elite_risk_shape_model4 | 6 | 0 | 6 | 2800.21 | -7.36 | 52.09 | -0.74 | 20.84 | 0.88 | 32 |

## Missing Or Unparsed

All queued rows have report or log evidence.
