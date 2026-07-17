# First-Pass Validation Log Metrics

Generated from exported MT5 reports when present and hidden MT5 tester logs when no report was exported. No MT5 process was launched.

- Queue manifest: `outputs\INDEPENDENT_M15_FAILED_BREAKOUT_TRAP_DISCOVERY_MODEL1_QUEUE.csv`
- Hidden run CSV: `outputs\INDEPENDENT_M15_FAILED_BREAKOUT_TRAP_DISCOVERY_MODEL1_RUN.csv`
- Log files scanned: `2`
- Expected rows: `48`
- Parsed exported reports: `48`
- Parsed from tester log: `0`
- Missing reports/results: `0`
- Unparsed log rows: `0`

Log-parsed rows are enough to reject bad fast screens, but exported full reports are still required before any candidate can be trusted for promotion.

## Summary By Candidate

| Candidate | Source | Phase | Parsed Reports | Parsed Logs | Expected | Total Net | Worst Window | Avg Ann. Return % | Worst Ann. Return % | Worst DD % | Min PF | Trades |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `fbt_adx22` | independent_m15_failed_breakout_trap | discovery_model1 | 3 | 0 | 3 | -92.56 | -46.7 | -0.1 | -0.18 | 0.64 | 0.61 | 73 |
| `fbt_adx30` | independent_m15_failed_breakout_trap | discovery_model1 | 3 | 0 | 3 | -199.58 | -99.79 | -0.17 | -0.17 | 1.28 | 0.73 | 144 |
| `fbt_age2` | independent_m15_failed_breakout_trap | discovery_model1 | 3 | 0 | 3 | -186.72 | -97.31 | -0.16 | -0.17 | 1 | 0.62 | 93 |
| `fbt_age6` | independent_m15_failed_breakout_trap | discovery_model1 | 3 | 0 | 3 | -207.96 | -104.4 | -0.18 | -0.2 | 1.07 | 0.64 | 103 |
| `fbt_base` | independent_m15_failed_breakout_trap | discovery_model1 | 3 | 0 | 3 | -173.58 | -87.21 | -0.16 | -0.2 | 0.9 | 0.69 | 99 |
| `fbt_both_volume` | independent_m15_failed_breakout_trap | discovery_model1 | 3 | 0 | 3 | 19.88 | -1.25 | 0.03 | 0 | 0.45 | 0.98 | 46 |
| `fbt_box_tight` | independent_m15_failed_breakout_trap | discovery_model1 | 3 | 0 | 3 | -59.06 | -45.24 | -0.03 | -0.11 | 0.57 | 0.02 | 22 |
| `fbt_box_wide` | independent_m15_failed_breakout_trap | discovery_model1 | 3 | 0 | 3 | -426.34 | -213.31 | -0.34 | -0.41 | 2.52 | 0.55 | 224 |
| `fbt_box16` | independent_m15_failed_breakout_trap | discovery_model1 | 3 | 0 | 3 | 65.32 | 16.25 | 0.06 | 0.04 | 0.27 | 1.28 | 32 |
| `fbt_box8` | independent_m15_failed_breakout_trap | discovery_model1 | 3 | 0 | 3 | -445.39 | -219.09 | -0.37 | -0.38 | 2.41 | 0.65 | 240 |
| `fbt_break_strict` | independent_m15_failed_breakout_trap | discovery_model1 | 3 | 0 | 3 | -208.24 | -104.54 | -0.18 | -0.21 | 1.11 | 0.59 | 83 |
| `fbt_break_volume` | independent_m15_failed_breakout_trap | discovery_model1 | 3 | 0 | 3 | -83.34 | -42.09 | -0.07 | -0.08 | 0.8 | 0.72 | 65 |
| `fbt_fixed_r15` | independent_m15_failed_breakout_trap | discovery_model1 | 3 | 0 | 3 | -152.98 | -105.34 | -0.08 | -0.26 | 1.56 | 0.81 | 370 |
| `fbt_reclaim_strict` | independent_m15_failed_breakout_trap | discovery_model1 | 3 | 0 | 3 | -80.7 | -40.35 | -0.07 | -0.11 | 0.72 | 0.82 | 94 |
| `fbt_reclaim10` | independent_m15_failed_breakout_trap | discovery_model1 | 3 | 0 | 3 | -476.61 | -237.21 | -0.39 | -0.43 | 2.4 | 0.45 | 144 |
| `fbt_reclaim25` | independent_m15_failed_breakout_trap | discovery_model1 | 3 | 0 | 3 | -60.3 | -32.11 | -0.07 | -0.16 | 0.57 | 0.27 | 28 |

## Missing Or Unparsed

All queued rows have report or log evidence.
