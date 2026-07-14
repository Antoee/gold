# First-Pass Validation Log Metrics

Generated from exported MT5 reports when present and hidden MT5 tester logs when no report was exported. No MT5 process was launched.

- Queue manifest: `outputs\RANGE_ELITE_GUARD_MODEL4_SHORTLIST_QUEUE.csv`
- Hidden run CSV: `outputs\RANGE_ELITE_GUARD_MODEL4_SHORTLIST_RUN.csv`
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
| `re_base` | range_elite_risk_shape_probe | phase4_range_elite_risk_shape_model4 | 6 | 0 | 6 | 2854.93 | -131.33 | 58.78 | -13.18 | 27.87 | 0 | 57 |
| `re_blockliq` | range_elite_risk_shape_probe | phase4_range_elite_risk_shape_model4 | 6 | 0 | 6 | 2854.93 | -131.33 | 58.78 | -13.18 | 27.87 | 0 | 57 |
| `re_blockliq_may140` | range_elite_risk_shape_probe | phase4_range_elite_risk_shape_model4 | 6 | 0 | 6 | 3166.19 | -140.18 | 65.9 | -14.07 | 24.28 | 0 | 41 |
| `re_may140` | range_elite_risk_shape_probe | phase4_range_elite_risk_shape_model4 | 6 | 0 | 6 | 3166.19 | -140.18 | 65.9 | -14.07 | 24.28 | 0 | 41 |

## Missing Or Unparsed

All queued rows have report or log evidence.
