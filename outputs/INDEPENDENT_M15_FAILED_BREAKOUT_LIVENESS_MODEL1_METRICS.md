# First-Pass Validation Log Metrics

Generated from exported MT5 reports when present and hidden MT5 tester logs when no report was exported. No MT5 process was launched.

- Queue manifest: `outputs\INDEPENDENT_M15_FAILED_BREAKOUT_LIVENESS_MODEL1_QUEUE.csv`
- Hidden run CSV: `outputs\INDEPENDENT_M15_FAILED_BREAKOUT_LIVENESS_MODEL1_RUN.csv`
- Log files scanned: `2`
- Expected rows: `36`
- Parsed exported reports: `36`
- Parsed from tester log: `0`
- Missing reports/results: `0`
- Unparsed log rows: `0`

Log-parsed rows are enough to reject bad fast screens, but exported full reports are still required before any candidate can be trusted for promotion.

## Summary By Candidate

| Candidate | Source | Phase | Parsed Reports | Parsed Logs | Expected | Total Net | Worst Window | Avg Ann. Return % | Worst Ann. Return % | Worst DD % | Min PF | Trades |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `fbt_b14_fixed_r125` | independent_m15_failed_breakout_trap | liveness_model1 | 3 | 0 | 3 | 93.5 | -8.87 | 0.06 | -0.04 | 0.73 | 0.94 | 192 |
| `fbt_b14_fixed_r150` | independent_m15_failed_breakout_trap | liveness_model1 | 3 | 0 | 3 | 143.06 | -4.26 | 0.1 | -0.02 | 0.81 | 0.97 | 190 |
| `fbt_b14_fixed_r200` | independent_m15_failed_breakout_trap | liveness_model1 | 3 | 0 | 3 | 224.03 | 0.76 | 0.16 | 0 | 0.85 | 1 | 190 |
| `fbt_b14_struct_r075` | independent_m15_failed_breakout_trap | liveness_model1 | 3 | 0 | 3 | 63.94 | -19.91 | 0.03 | -0.1 | 0.61 | 0.79 | 102 |
| `fbt_b16_fixed_r125` | independent_m15_failed_breakout_trap | liveness_model1 | 3 | 0 | 3 | 110.66 | 20.43 | 0.09 | 0.09 | 0.58 | 1.22 | 108 |
| `fbt_b16_fixed_r150` | independent_m15_failed_breakout_trap | liveness_model1 | 3 | 0 | 3 | 182.4 | 29.87 | 0.15 | 0.15 | 0.65 | 1.39 | 108 |
| `fbt_b16_fixed_r200` | independent_m15_failed_breakout_trap | liveness_model1 | 3 | 0 | 3 | 190.4 | 29.31 | 0.16 | 0.15 | 0.6 | 1.42 | 108 |
| `fbt_b16_struct_r075` | independent_m15_failed_breakout_trap | liveness_model1 | 3 | 0 | 3 | 71.46 | 17.14 | 0.07 | 0.05 | 0.39 | 1.22 | 56 |
| `fbt_b18_fixed_r125` | independent_m15_failed_breakout_trap | liveness_model1 | 3 | 0 | 3 | 24.04 | -3.43 | 0.01 | -0.02 | 0.33 | 0.86 | 46 |
| `fbt_b18_fixed_r150` | independent_m15_failed_breakout_trap | liveness_model1 | 3 | 0 | 3 | 62.84 | -0.01 | 0.04 | 0 | 0.31 | 1 | 46 |
| `fbt_b18_fixed_r200` | independent_m15_failed_breakout_trap | liveness_model1 | 3 | 0 | 3 | 19.9 | -19.14 | 0 | -0.1 | 0.4 | 0.2 | 46 |
| `fbt_b18_struct_r075` | independent_m15_failed_breakout_trap | liveness_model1 | 3 | 0 | 3 | 50.04 | -7.43 | 0.03 | -0.04 | 0.23 | 0.52 | 22 |

## Missing Or Unparsed

All queued rows have report or log evidence.
