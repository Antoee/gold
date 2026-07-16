# First-Pass Validation Log Metrics

Generated from exported MT5 reports when present and hidden MT5 tester logs when no report was exported. No MT5 process was launched.

- Queue manifest: `outputs\INDEPENDENT_ORB_DISCOVERY_MODEL1_QUEUE.csv`
- Hidden run CSV: `outputs\INDEPENDENT_ORB_DISCOVERY_MODEL1_RUN.csv`
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
| `orb_dual_adx18` | independent_orb | discovery_model1 | 3 | 0 | 3 | -1260.56 | -497.42 | -1.13 | -1.33 | 5.84 | 0.22 | 37 |
| `orb_dual_adx18_volume` | independent_orb | discovery_model1 | 3 | 0 | 3 | -1587.19 | -545.96 | -1.59 | -2.48 | 6.25 | 0.47 | 53 |
| `orb_london_adx18` | independent_orb | discovery_model1 | 3 | 0 | 3 | -843.73 | -522.85 | -1.1 | -2.62 | 6.14 | 0.33 | 58 |
| `orb_london_adx18_body35` | independent_orb | discovery_model1 | 3 | 0 | 3 | -430.95 | -522.85 | -0.81 | -2.62 | 6.12 | 0.33 | 82 |
| `orb_london_noadx` | independent_orb | discovery_model1 | 3 | 0 | 3 | -101.63 | -458.03 | -0.51 | -2.29 | 6.12 | 0.42 | 99 |
| `orb_newyork_adx18` | independent_orb | discovery_model1 | 3 | 0 | 3 | -1389.06 | -577.56 | -1.19 | -1.44 | 5.78 | 0 | 25 |

## Missing Or Unparsed

All queued rows have report or log evidence.
