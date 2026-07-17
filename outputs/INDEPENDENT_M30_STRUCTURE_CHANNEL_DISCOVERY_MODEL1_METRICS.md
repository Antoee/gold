# First-Pass Validation Log Metrics

Generated from exported MT5 reports when present and hidden MT5 tester logs when no report was exported. No MT5 process was launched.

- Queue manifest: `outputs\INDEPENDENT_M30_STRUCTURE_CHANNEL_DISCOVERY_MODEL1_QUEUE.csv`
- Hidden run CSV: `outputs\INDEPENDENT_M30_STRUCTURE_CHANNEL_DISCOVERY_MODEL1_RUN.csv`
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
| `m30sc_24_12_tp20` | independent_m30_structure_channel | discovery_model1 | 3 | 0 | 3 | -285.92 | -159.44 | -0.19 | -0.4 | 4.59 | 0.9 | 960 |
| `m30sc_48_24_channel` | independent_m30_structure_channel | discovery_model1 | 3 | 0 | 3 | 728.66 | 156.68 | 0.66 | 0.39 | 2.62 | 1.18 | 578 |
| `m30sc_48_24_noema` | independent_m30_structure_channel | discovery_model1 | 3 | 0 | 3 | -122.18 | -86.62 | -0.07 | -0.22 | 3.9 | 0.94 | 942 |
| `m30sc_48_24_session` | independent_m30_structure_channel | discovery_model1 | 3 | 0 | 3 | 81.3 | -4.09 | 0.05 | -0.02 | 2.44 | 0.99 | 304 |
| `m30sc_48_24_stop2_d8` | independent_m30_structure_channel | discovery_model1 | 3 | 0 | 3 | -239.35 | -118.49 | -0.18 | -0.25 | 3.5 | 0.91 | 652 |
| `m30sc_48_24_stop5` | independent_m30_structure_channel | discovery_model1 | 3 | 0 | 3 | 614.68 | 113.86 | 0.59 | 0.28 | 1.69 | 1.19 | 452 |
| `m30sc_48_24_tp15` | independent_m30_structure_channel | discovery_model1 | 3 | 0 | 3 | 568.36 | 105.25 | 0.48 | 0.41 | 2.44 | 1.18 | 610 |
| `m30sc_48_24_tp20` | independent_m30_structure_channel | discovery_model1 | 3 | 0 | 3 | 582.38 | 101.06 | 0.54 | 0.25 | 2.36 | 1.11 | 588 |
| `m30sc_48_24_tp25` | independent_m30_structure_channel | discovery_model1 | 3 | 0 | 3 | 717.96 | 163.84 | 0.63 | 0.45 | 2.62 | 1.2 | 582 |
| `m30sc_72_36_tp20` | independent_m30_structure_channel | discovery_model1 | 3 | 0 | 3 | 1104.94 | 229.59 | 1.04 | 0.57 | 2.34 | 1.3 | 478 |

## Missing Or Unparsed

All queued rows have report or log evidence.
