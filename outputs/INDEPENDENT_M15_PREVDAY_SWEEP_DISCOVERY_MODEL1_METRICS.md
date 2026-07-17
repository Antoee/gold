# First-Pass Validation Log Metrics

Generated from exported MT5 reports when present and hidden MT5 tester logs when no report was exported. No MT5 process was launched.

- Queue manifest: `outputs\INDEPENDENT_M15_PREVDAY_SWEEP_DISCOVERY_MODEL1_QUEUE.csv`
- Hidden run CSV: `outputs\INDEPENDENT_M15_PREVDAY_SWEEP_DISCOVERY_MODEL1_RUN.csv`
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
| `pds_adx24` | independent_m15_prevday_sweep | discovery_model1 | 3 | 0 | 3 | -178 | -89 | -0.16 | -0.19 | 1.33 | 0.34 | 56 |
| `pds_base` | independent_m15_prevday_sweep | discovery_model1 | 3 | 0 | 3 | -165.65 | -114.65 | -0.08 | -0.29 | 1.85 | 0.45 | 130 |
| `pds_midpoint` | independent_m15_prevday_sweep | discovery_model1 | 3 | 0 | 3 | -328.01 | -166.76 | -0.27 | -0.29 | 2.41 | 0.42 | 126 |
| `pds_reclaim05` | independent_m15_prevday_sweep | discovery_model1 | 3 | 0 | 3 | -165.65 | -114.65 | -0.08 | -0.29 | 1.85 | 0.45 | 130 |
| `pds_rr20` | independent_m15_prevday_sweep | discovery_model1 | 3 | 0 | 3 | -192.53 | -123.53 | -0.1 | -0.31 | 2 | 0.43 | 130 |
| `pds_session12_22` | independent_m15_prevday_sweep | discovery_model1 | 3 | 0 | 3 | -214.44 | -123.33 | -0.14 | -0.31 | 1.76 | 0.34 | 118 |
| `pds_sweep10` | independent_m15_prevday_sweep | discovery_model1 | 3 | 0 | 3 | -109.13 | -127.47 | -0.01 | -0.32 | 1.93 | 0.44 | 150 |
| `pds_trend` | independent_m15_prevday_sweep | discovery_model1 | 3 | 0 | 3 | -101.62 | -50.81 | -0.08 | -0.09 | 1.17 | 0.02 | 20 |
| `pds_volume105` | independent_m15_prevday_sweep | discovery_model1 | 3 | 0 | 3 | 74.12 | -37.94 | 0.12 | -0.09 | 1.11 | 0.67 | 92 |
| `pds_wick15` | independent_m15_prevday_sweep | discovery_model1 | 3 | 0 | 3 | -92.81 | -95.07 | -0.03 | -0.24 | 1.14 | 0.39 | 96 |

## Missing Or Unparsed

All queued rows have report or log evidence.
