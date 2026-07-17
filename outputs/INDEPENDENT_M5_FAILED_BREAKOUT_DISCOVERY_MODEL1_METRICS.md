# First-Pass Validation Log Metrics

Generated from exported MT5 reports when present and hidden MT5 tester logs when no report was exported. No MT5 process was launched.

- Queue manifest: `outputs\INDEPENDENT_M5_FAILED_BREAKOUT_DISCOVERY_MODEL1_QUEUE.csv`
- Hidden run CSV: `outputs\INDEPENDENT_M5_FAILED_BREAKOUT_DISCOVERY_MODEL1_RUN.csv`
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
| `m5fbt_b14_fixed_r125` | independent_m5_failed_breakout_trap | discovery_model1 | 2 | 0 | 2 | -561.23 | -313.54 | -0.94 | -1.05 | 3.86 | 0.5 | 201 |
| `m5fbt_b14_fixed_r150` | independent_m5_failed_breakout_trap | discovery_model1 | 2 | 0 | 2 | -556.19 | -312.82 | -0.92 | -1.04 | 3.66 | 0.51 | 201 |
| `m5fbt_b14_fixed_r200` | independent_m5_failed_breakout_trap | discovery_model1 | 2 | 0 | 2 | -626.87 | -317.37 | -1.04 | -1.06 | 3.83 | 0.49 | 200 |
| `m5fbt_b14_struct_r075` | independent_m5_failed_breakout_trap | discovery_model1 | 2 | 0 | 2 | -485.28 | -245.61 | -0.81 | -0.82 | 2.79 | 0.33 | 123 |
| `m5fbt_b16_fixed_r125` | independent_m5_failed_breakout_trap | discovery_model1 | 2 | 0 | 2 | -244.56 | -205.23 | -0.4 | -0.68 | 2.37 | 0.35 | 94 |
| `m5fbt_b16_fixed_r150` | independent_m5_failed_breakout_trap | discovery_model1 | 2 | 0 | 2 | -246.27 | -210.34 | -0.41 | -0.7 | 2.38 | 0.34 | 94 |
| `m5fbt_b16_fixed_r200` | independent_m5_failed_breakout_trap | discovery_model1 | 2 | 0 | 2 | -303.58 | -196.59 | -0.51 | -0.66 | 2.21 | 0.38 | 94 |
| `m5fbt_b16_struct_r075` | independent_m5_failed_breakout_trap | discovery_model1 | 2 | 0 | 2 | -151.77 | -112.77 | -0.26 | -0.38 | 1.39 | 0.33 | 57 |
| `m5fbt_b18_fixed_r125` | independent_m5_failed_breakout_trap | discovery_model1 | 2 | 0 | 2 | -166.45 | -120.69 | -0.28 | -0.4 | 1.21 | 0.28 | 51 |
| `m5fbt_b18_fixed_r150` | independent_m5_failed_breakout_trap | discovery_model1 | 2 | 0 | 2 | -147.09 | -124.88 | -0.24 | -0.42 | 1.25 | 0.25 | 51 |
| `m5fbt_b18_fixed_r200` | independent_m5_failed_breakout_trap | discovery_model1 | 2 | 0 | 2 | -173.68 | -110.93 | -0.29 | -0.37 | 1.11 | 0.34 | 51 |
| `m5fbt_b18_struct_r075` | independent_m5_failed_breakout_trap | discovery_model1 | 2 | 0 | 2 | -85.11 | -57.71 | -0.14 | -0.19 | 0.69 | 0.11 | 28 |

## Missing Or Unparsed

All queued rows have report or log evidence.
