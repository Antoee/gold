# First-Pass Validation Log Metrics

Generated from exported MT5 reports when present and hidden MT5 tester logs when no report was exported. No MT5 process was launched.

- Queue manifest: `.\outputs\LOWATR_EXIT_SWEEP_QUEUE.csv`
- Hidden run CSV: `.\outputs\LOWATR_EXIT_SWEEP_HIDDEN_RUN_PLAN.csv`
- Log files scanned: `1`
- Expected rows: `32`
- Parsed exported reports: `0`
- Parsed from tester log: `32`
- Missing reports/results: `0`
- Unparsed log rows: `0`

Log-parsed rows are enough to reject bad fast screens, but exported full reports are still required before any candidate can be trusted for promotion.

## Summary By Candidate

| Candidate | Source | Phase | Parsed Reports | Parsed Logs | Expected | Total Net | Worst Window | Avg Ann. Return % | Worst Ann. Return % | Worst DD % | Min PF | Trades |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `lowatr_exit_be06` | exit_sweep | phase0_fast_model1 | 0 | 1 | 1 | -124.55 | -124.55 | -4.93 | -4.93 | 33.25 | 0.5711 | 6 |
| `lowatr_exit_be08` | exit_sweep | phase0_fast_model1 | 0 | 1 | 1 | 6817.29 | 6817.29 | 269.77 | 269.77 | 25.98 | 2.6654 | 61 |
| `lowatr_exit_combo_guard` | exit_sweep | phase0_fast_model1 | 0 | 1 | 1 | 10.13 | 10.13 | 0.4 | 0.4 | 23.01 | 1.0729 | 4 |
| `lowatr_exit_loss_scale` | exit_sweep | phase0_fast_model1 | 0 | 1 | 1 | 8998.14 | 8998.14 | 356.07 | 356.07 | 25.91 | 2.9164 | 65 |
| `lowatr_exit_loss_scale_cap6` | exit_sweep | phase0_fast_model1 | 0 | 1 | 1 | 28.8 | 28.8 | 1.14 | 1.14 | 8.83 | 0 | 1 |
| `lowatr_exit_loss_scale_r25` | exit_sweep | phase0_fast_model1 | 0 | 1 | 1 | 517.03 | 517.03 | 20.46 | 20.46 | 7.28 | 5.8846 | 7 |
| `lowatr_exit_loss_scale_r30` | exit_sweep | phase0_fast_model1 | 0 | 1 | 1 | 630.58 | 630.58 | 24.95 | 24.95 | 8.74 | 5.5464 | 7 |
| `lowatr_exit_loss_scale_r35` | exit_sweep | phase0_fast_model1 | 0 | 1 | 1 | 761.59 | 761.59 | 30.14 | 30.14 | 10.26 | 5.2583 | 7 |
| `lowatr_exit_loss_scale_r40` | exit_sweep | phase0_fast_model1 | 0 | 1 | 1 | 901.7 | 901.7 | 35.68 | 35.68 | 11.65 | 5.0499 | 7 |
| `lowatr_exit_loss_scale_r50` | exit_sweep | phase0_fast_model1 | 0 | 1 | 1 | 1152.51 | 1152.51 | 45.61 | 45.61 | 14.53 | 4.5478 | 7 |
| `lowatr_exit_mfe_early` | exit_sweep | phase0_fast_model1 | 0 | 1 | 1 | 9274.07 | 9274.07 | 366.99 | 366.99 | 25.99 | 2.914 | 64 |
| `lowatr_exit_mfe_early_cap6` | exit_sweep | phase0_fast_model1 | 0 | 1 | 1 | 28.8 | 28.8 | 1.14 | 1.14 | 8.83 | 0 | 1 |
| `lowatr_exit_mfe_early_r25` | exit_sweep | phase0_fast_model1 | 0 | 1 | 1 | 517.03 | 517.03 | 20.46 | 20.46 | 7.28 | 5.8846 | 7 |
| `lowatr_exit_mfe_early_r30` | exit_sweep | phase0_fast_model1 | 0 | 1 | 1 | 630.58 | 630.58 | 24.95 | 24.95 | 8.74 | 5.5464 | 7 |
| `lowatr_exit_mfe_early_r35` | exit_sweep | phase0_fast_model1 | 0 | 1 | 1 | 761.59 | 761.59 | 30.14 | 30.14 | 10.26 | 5.2583 | 7 |
| `lowatr_exit_mfe_early_r40` | exit_sweep | phase0_fast_model1 | 0 | 1 | 1 | 901.7 | 901.7 | 35.68 | 35.68 | 11.65 | 5.0499 | 7 |
| `lowatr_exit_mfe_early_r50` | exit_sweep | phase0_fast_model1 | 0 | 1 | 1 | 1152.51 | 1152.51 | 45.61 | 45.61 | 14.53 | 4.5478 | 7 |
| `lowatr_exit_mfe_tight` | exit_sweep | phase0_fast_model1 | 0 | 1 | 1 | 1312.82 | 1312.82 | 51.95 | 51.95 | 23.24 | 4.0042 | 14 |
| `lowatr_exit_peak_guard` | exit_sweep | phase0_fast_model1 | 0 | 1 | 1 | 3412.46 | 3412.46 | 135.04 | 135.04 | 22.63 | 4.8249 | 25 |
| `lowatr_exit_peak_guard_cap6` | exit_sweep | phase0_fast_model1 | 0 | 1 | 1 | 16.8 | 16.8 | 0.66 | 0.66 | 5.81 | 0 | 1 |
| `lowatr_exit_peak_guard_cap8` | exit_sweep | phase0_fast_model1 | 0 | 1 | 1 | 16.8 | 16.8 | 0.66 | 0.66 | 5.81 | 0 | 1 |
| `lowatr_exit_peak_r20` | exit_sweep | phase0_fast_model1 | 0 | 1 | 1 | 464.86 | 464.86 | 18.4 | 18.4 | 5.81 | 6.789 | 7 |
| `lowatr_exit_peak_r22` | exit_sweep | phase0_fast_model1 | 0 | 1 | 1 | 482.82 | 482.82 | 19.11 | 19.11 | 6.48 | 6.2912 | 7 |
| `lowatr_exit_peak_r24` | exit_sweep | phase0_fast_model1 | 0 | 1 | 1 | 508.06 | 508.06 | 20.1 | 20.1 | 6.85 | 6.1554 | 7 |
| `lowatr_exit_peak_r25` | exit_sweep | phase0_fast_model1 | 0 | 1 | 1 | 517.03 | 517.03 | 20.46 | 20.46 | 7.28 | 5.8846 | 7 |
| `lowatr_exit_peak_r30` | exit_sweep | phase0_fast_model1 | 0 | 1 | 1 | 630.58 | 630.58 | 24.95 | 24.95 | 8.74 | 5.5464 | 7 |
| `lowatr_exit_peak_r35` | exit_sweep | phase0_fast_model1 | 0 | 1 | 1 | 761.59 | 761.59 | 30.14 | 30.14 | 10.26 | 5.2583 | 7 |
| `lowatr_exit_peak_r40` | exit_sweep | phase0_fast_model1 | 0 | 1 | 1 | 901.7 | 901.7 | 35.68 | 35.68 | 11.65 | 5.0499 | 7 |
| `lowatr_exit_peak_r50` | exit_sweep | phase0_fast_model1 | 0 | 1 | 1 | 1152.51 | 1152.51 | 45.61 | 45.61 | 14.53 | 4.5478 | 7 |
| `lowatr_exit_raw_cap6` | exit_sweep | phase0_fast_model1 | 0 | 1 | 1 | 28.8 | 28.8 | 1.14 | 1.14 | 8.83 | 0 | 1 |
| `lowatr_exit_trail10` | exit_sweep | phase0_fast_model1 | 0 | 1 | 1 | 919.72 | 919.72 | 36.4 | 36.4 | 22.7 | 5.1505 | 7 |
| `lowatr_exit_trail12` | exit_sweep | phase0_fast_model1 | 0 | 1 | 1 | 10.13 | 10.13 | 0.4 | 0.4 | 23.01 | 1.0729 | 4 |

## Missing Or Unparsed

All queued rows have report or log evidence.
