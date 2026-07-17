# First-Pass Validation Log Metrics

Generated from exported MT5 reports when present and hidden MT5 tester logs when no report was exported. No MT5 process was launched.

- Queue manifest: `outputs\INDEPENDENT_M15_XAG_LEAD_LAG_PULLBACK_NEIGHBORHOOD_MODEL1_QUEUE.csv`
- Hidden run CSV: `outputs\INDEPENDENT_M15_XAG_LEAD_LAG_PULLBACK_NEIGHBORHOOD_MODEL1_RUN.csv`
- Log files scanned: `2`
- Expected rows: `12`
- Parsed exported reports: `12`
- Parsed from tester log: `0`
- Missing reports/results: `0`
- Unparsed log rows: `0`

Log-parsed rows are enough to reject bad fast screens, but exported full reports are still required before any candidate can be trusted for promotion.

## Summary By Candidate

| Candidate | Source | Phase | Parsed Reports | Parsed Logs | Expected | Total Net | Worst Window | Avg Ann. Return % | Worst Ann. Return % | Worst DD % | Min PF | Trades |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `xmll_lead2` | independent_m15_xag_lead_lag_pullback | neighborhood_model1 | 2 | 0 | 2 | -169.49 | -87.77 | -0.28 | -0.29 | 1.36 | 0.69 | 117 |
| `xmll_lead3` | independent_m15_xag_lead_lag_pullback | neighborhood_model1 | 2 | 0 | 2 | -45.42 | -36.36 | -0.08 | -0.12 | 1.25 | 0.9 | 157 |
| `xmll_lead4` | independent_m15_xag_lead_lag_pullback | neighborhood_model1 | 2 | 0 | 2 | 177.54 | 42.08 | 0.3 | 0.14 | 1.04 | 1.13 | 151 |
| `xmll_lead5` | independent_m15_xag_lead_lag_pullback | neighborhood_model1 | 2 | 0 | 2 | -59.3 | -33.47 | -0.1 | -0.11 | 1.24 | 0.92 | 172 |
| `xmll_lead6` | independent_m15_xag_lead_lag_pullback | neighborhood_model1 | 2 | 0 | 2 | -101.07 | -61.94 | -0.17 | -0.21 | 1.69 | 0.85 | 189 |
| `xmll_lead7` | independent_m15_xag_lead_lag_pullback | neighborhood_model1 | 2 | 0 | 2 | -43.64 | -41.02 | -0.08 | -0.14 | 1.64 | 0.92 | 205 |

## Missing Or Unparsed

All queued rows have report or log evidence.
