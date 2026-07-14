# First-Pass Validation Log Metrics

Generated from exported MT5 reports when present and hidden MT5 tester logs when no report was exported. No MT5 process was launched.

- Queue manifest: `.\outputs\PEAK_R20_DRAWDOWN_SWEEP_QUEUE.csv`
- Hidden run CSV: `.\outputs\PEAK_R20_DRAWDOWN_HIDDEN_RUN_PLAN.csv`
- Log files scanned: `1`
- Expected rows: `22`
- Parsed exported reports: `0`
- Parsed from tester log: `22`
- Missing reports/results: `0`
- Unparsed log rows: `0`

Log-parsed rows are enough to reject bad fast screens, but exported full reports are still required before any candidate can be trusted for promotion.

## Summary By Candidate

| Candidate | Source | Phase | Parsed Reports | Parsed Logs | Expected | Total Net | Worst Window | Avg Ann. Return % | Worst Ann. Return % | Worst DD % | Min PF | Trades |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `r10_aug25_floor05` | peak_r20_drawdown_sweep | phase0_fast_model1 | 0 | 1 | 1 | 102.81 | 102.81 | 4.07 | 4.07 | 6.83 | 1.7198 | 45 |
| `r10_base` | peak_r20_drawdown_sweep | phase0_fast_model1 | 0 | 1 | 1 | 1716.76 | 1716.76 | 67.94 | 67.94 | 10.62 | 2.8655 | 76 |
| `r10_bothgb_q15` | peak_r20_drawdown_sweep | phase0_fast_model1 | 0 | 1 | 1 | 329.09 | 329.09 | 13.02 | 13.02 | 5.35 | 5.6627 | 8 |
| `r10_dailytrail35` | peak_r20_drawdown_sweep | phase0_fast_model1 | 0 | 1 | 1 | 1729.28 | 1729.28 | 68.43 | 68.43 | 10.62 | 2.9051 | 75 |
| `r10_eqgb_q10_10_16` | peak_r20_drawdown_sweep | phase0_fast_model1 | 0 | 1 | 1 | 329.09 | 329.09 | 13.02 | 13.02 | 5.35 | 5.6627 | 8 |
| `r10_eqgb_q15_12_18` | peak_r20_drawdown_sweep | phase0_fast_model1 | 0 | 1 | 1 | 329.09 | 329.09 | 13.02 | 13.02 | 5.35 | 5.6627 | 8 |
| `r10_eqgb_q20_12_18` | peak_r20_drawdown_sweep | phase0_fast_model1 | 0 | 1 | 1 | 296.09 | 296.09 | 11.72 | 11.72 | 7.7 | 3.8586 | 9 |
| `r10_eqlock4_50` | peak_r20_drawdown_sweep | phase0_fast_model1 | 0 | 1 | 1 | 1716.76 | 1716.76 | 67.94 | 67.94 | 10.62 | 2.8655 | 76 |
| `r10_floor05_eqgb` | peak_r20_drawdown_sweep | phase0_fast_model1 | 0 | 1 | 1 | 146.26 | 146.26 | 5.79 | 5.79 | 2.79 | 5.027 | 8 |
| `r10_floor05_loss25` | peak_r20_drawdown_sweep | phase0_fast_model1 | 0 | 1 | 1 | 102.81 | 102.81 | 4.07 | 4.07 | 6.83 | 1.7198 | 45 |
| `r10_floor10_eqgb` | peak_r20_drawdown_sweep | phase0_fast_model1 | 0 | 1 | 1 | 165.16 | 165.16 | 6.54 | 6.54 | 2.74 | 5.5474 | 8 |
| `r10_floor10_loss25` | peak_r20_drawdown_sweep | phase0_fast_model1 | 0 | 1 | 1 | 113.44 | 113.44 | 4.49 | 4.49 | 8.12 | 1.4878 | 54 |
| `r10_loss_scale_15` | peak_r20_drawdown_sweep | phase0_fast_model1 | 0 | 1 | 1 | 1311.8 | 1311.8 | 51.91 | 51.91 | 8.72 | 2.8451 | 71 |
| `r10_loss_scale_25` | peak_r20_drawdown_sweep | phase0_fast_model1 | 0 | 1 | 1 | 1404.08 | 1404.08 | 55.56 | 55.56 | 9.26 | 2.7119 | 77 |
| `r10_may240_floor10` | peak_r20_drawdown_sweep | phase0_fast_model1 | 0 | 1 | 1 | 139.36 | 139.36 | 5.51 | 5.51 | 6.76 | 1.5431 | 60 |
| `r10_may260_floor10` | peak_r20_drawdown_sweep | phase0_fast_model1 | 0 | 1 | 1 | 146.72 | 146.72 | 5.81 | 5.81 | 6.97 | 1.5741 | 60 |
| `r10_minfloor02` | peak_r20_drawdown_sweep | phase0_fast_model1 | 0 | 1 | 1 | 117.29 | 117.29 | 4.64 | 4.64 | 5.25 | 2.6171 | 16 |
| `r10_minfloor05` | peak_r20_drawdown_sweep | phase0_fast_model1 | 0 | 1 | 1 | 102.81 | 102.81 | 4.07 | 4.07 | 6.83 | 1.7198 | 45 |
| `r10_minfloor10` | peak_r20_drawdown_sweep | phase0_fast_model1 | 0 | 1 | 1 | 161.71 | 161.71 | 6.4 | 6.4 | 7.02 | 1.6238 | 60 |
| `r10_profit_guard40` | peak_r20_drawdown_sweep | phase0_fast_model1 | 0 | 1 | 1 | 979.74 | 979.74 | 38.77 | 38.77 | 7.71 | 3.2752 | 47 |
| `r10_realgb_q15_12_18` | peak_r20_drawdown_sweep | phase0_fast_model1 | 0 | 1 | 1 | 1716.76 | 1716.76 | 67.94 | 67.94 | 10.62 | 2.8655 | 76 |
| `r10_realgb_q20_12_18` | peak_r20_drawdown_sweep | phase0_fast_model1 | 0 | 1 | 1 | 1716.76 | 1716.76 | 67.94 | 67.94 | 10.62 | 2.8655 | 76 |

## Missing Or Unparsed

All queued rows have report or log evidence.
