# First-Pass Validation Log Metrics

Generated from exported MT5 reports when present and hidden MT5 tester logs when no report was exported. No MT5 process was launched.

- Queue manifest: `outputs\INDEPENDENT_M15_FVG_RETEST_DISCOVERY_MODEL1_QUEUE.csv`
- Hidden run CSV: `outputs\INDEPENDENT_M15_FVG_RETEST_DISCOVERY_MODEL1_RUN.csv`
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
| `m15fvg_b12_a8_tp20` | independent_m15_fvg_retest | discovery_model1 | 3 | 0 | 3 | -1004.2 | -487.74 | -0.72 | -1.22 | 5.06 | 0.38 | 492 |
| `m15fvg_b20_a12_tp20` | independent_m15_fvg_retest | discovery_model1 | 3 | 0 | 3 | -1187.23 | -489.19 | -1.03 | -1.22 | 5.08 | 0.32 | 452 |
| `m15fvg_b20_a4_tp20` | independent_m15_fvg_retest | discovery_model1 | 3 | 0 | 3 | -1123.34 | -482.21 | -0.94 | -1.21 | 5 | 0.45 | 464 |
| `m15fvg_b20_a8_tp20` | independent_m15_fvg_retest | discovery_model1 | 3 | 0 | 3 | -1242.73 | -488.39 | -1.12 | -1.33 | 5.07 | 0.3 | 430 |
| `m15fvg_b20_gap10` | independent_m15_fvg_retest | discovery_model1 | 3 | 0 | 3 | -1173.03 | -483.65 | -1.02 | -1.21 | 5.02 | 0.28 | 417 |
| `m15fvg_b20_hold75` | independent_m15_fvg_retest | discovery_model1 | 3 | 0 | 3 | -1175.79 | -482.98 | -1.02 | -1.21 | 5.02 | 0.3 | 414 |
| `m15fvg_b20_imp15` | independent_m15_fvg_retest | discovery_model1 | 3 | 0 | 3 | -1407.22 | -490.16 | -1.4 | -2.14 | 5.09 | 0.56 | 560 |
| `m15fvg_b20_tp15` | independent_m15_fvg_retest | discovery_model1 | 3 | 0 | 3 | -1207.11 | -477.65 | -1.08 | -1.26 | 5.03 | 0.35 | 447 |
| `m15fvg_b20_tp25` | independent_m15_fvg_retest | discovery_model1 | 3 | 0 | 3 | -1293.14 | -507.19 | -1.17 | -1.39 | 5.3 | 0.24 | 422 |
| `m15fvg_b32_a8_tp20` | independent_m15_fvg_retest | discovery_model1 | 3 | 0 | 3 | -1150.18 | -486.94 | -0.97 | -1.22 | 5.06 | 0.59 | 570 |

## Missing Or Unparsed

All queued rows have report or log evidence.
