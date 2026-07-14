# First-Pass Validation Log Metrics

Generated from exported MT5 reports when present and hidden MT5 tester logs when no report was exported. No MT5 process was launched.

- Queue manifest: `.\outputs\LOWATR_R20_OPPORTUNITY_SWEEP_QUEUE.csv`
- Hidden run CSV: `.\outputs\LOWATR_R20_OPPORTUNITY_HIDDEN_RUN_PLAN.csv`
- Log files scanned: `1`
- Expected rows: `33`
- Parsed exported reports: `0`
- Parsed from tester log: `33`
- Missing reports/results: `0`
- Unparsed log rows: `0`

Log-parsed rows are enough to reject bad fast screens, but exported full reports are still required before any candidate can be trusted for promotion.

## Summary By Candidate

| Candidate | Source | Phase | Parsed Reports | Parsed Logs | Expected | Total Net | Worst Window | Avg Ann. Return % | Worst Ann. Return % | Worst DD % | Min PF | Trades |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `peak_r20_all_nodec_r05_norm` | r20_opportunity_sweep | phase0_fast_model1 | 0 | 1 | 1 | 131.99 | 131.99 | 5.22 | 5.22 | 13.45 | 1.7833 | 15 |
| `peak_r20_all_nodec_r08_conf2` | r20_opportunity_sweep | phase0_fast_model1 | 0 | 1 | 1 | -162.02 | -162.02 | -6.41 | -6.41 | 35.38 | 0.9042 | 183 |
| `peak_r20_all_nodec_r08_diagq` | r20_opportunity_sweep | phase0_fast_model1 | 0 | 1 | 1 | 23.86 | 23.86 | 0.94 | 0.94 | 3.09 | 1.9983 | 2 |
| `peak_r20_all_nodec_r08_norm` | r20_opportunity_sweep | phase0_fast_model1 | 0 | 1 | 1 | 131.99 | 131.99 | 5.22 | 5.22 | 13.45 | 1.7833 | 15 |
| `peak_r20_all_nodec_r08_weighted` | r20_opportunity_sweep | phase0_fast_model1 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| `peak_r20_all_nodec_r10_conf2` | r20_opportunity_sweep | phase0_fast_model1 | 0 | 1 | 1 | -162.02 | -162.02 | -6.41 | -6.41 | 35.38 | 0.9042 | 183 |
| `peak_r20_all_nodec_r10_norm` | r20_opportunity_sweep | phase0_fast_model1 | 0 | 1 | 1 | 131.99 | 131.99 | 5.22 | 5.22 | 13.45 | 1.7833 | 15 |
| `peak_r20_all_nodec_r12_norm` | r20_opportunity_sweep | phase0_fast_model1 | 0 | 1 | 1 | 131.99 | 131.99 | 5.22 | 5.22 | 13.45 | 1.7833 | 15 |
| `peak_r20_aug_risk60` | r20_opportunity_sweep | phase0_fast_model1 | 0 | 1 | 1 | 464.86 | 464.86 | 18.4 | 18.4 | 5.81 | 6.789 | 7 |
| `peak_r20_base` | r20_opportunity_sweep | phase0_fast_model1 | 0 | 1 | 1 | 464.86 | 464.86 | 18.4 | 18.4 | 5.81 | 6.789 | 7 |
| `peak_r20_diag_2025` | r20_opportunity_sweep | phase0_fast_model1 | 0 | 1 | 1 | 21.17 | 21.17 | 2.12 | 2.12 | 4.9 | 1.6271 | 4 |
| `peak_r20_fmlr_fvg_ob` | r20_opportunity_sweep | phase0_fast_model1 | 0 | 1 | 1 | 464.86 | 464.86 | 18.4 | 18.4 | 5.81 | 6.789 | 7 |
| `peak_r20_fmlr_strict` | r20_opportunity_sweep | phase0_fast_model1 | 0 | 1 | 1 | 464.86 | 464.86 | 18.4 | 18.4 | 5.81 | 6.789 | 7 |
| `peak_r20_fmlr_sweep_bos` | r20_opportunity_sweep | phase0_fast_model1 | 0 | 1 | 1 | 464.86 | 464.86 | 18.4 | 18.4 | 5.81 | 6.789 | 7 |
| `peak_r20_islp_broad_lowrisk` | r20_opportunity_sweep | phase0_fast_model1 | 0 | 1 | 1 | 464.86 | 464.86 | 18.4 | 18.4 | 5.81 | 6.789 | 7 |
| `peak_r20_islp_may_aug` | r20_opportunity_sweep | phase0_fast_model1 | 0 | 1 | 1 | 464.86 | 464.86 | 18.4 | 18.4 | 5.81 | 6.789 | 7 |
| `peak_r20_may_full` | r20_opportunity_sweep | phase0_fast_model1 | 0 | 1 | 1 | 464.86 | 464.86 | 18.4 | 18.4 | 5.81 | 6.789 | 7 |
| `peak_r20_may_full_spread22` | r20_opportunity_sweep | phase0_fast_model1 | 0 | 1 | 1 | 464.86 | 464.86 | 18.4 | 18.4 | 5.81 | 6.789 | 7 |
| `peak_r20_may31_aug60` | r20_opportunity_sweep | phase0_fast_model1 | 0 | 1 | 1 | 464.86 | 464.86 | 18.4 | 18.4 | 5.81 | 6.789 | 7 |
| `peak_r20_no_day_window_lowrisk` | r20_opportunity_sweep | phase0_fast_model1 | 0 | 1 | 1 | 246 | 246 | 9.73 | 9.73 | 5.64 | 9.244 | 6 |
| `peak_r20_no_peaktrail` | r20_opportunity_sweep | phase0_fast_model1 | 0 | 1 | 1 | 1701.87 | 1701.87 | 67.35 | 67.35 | 14.41 | 2.5239 | 75 |
| `peak_r20_no_peaktrail_cap6` | r20_opportunity_sweep | phase0_fast_model1 | 0 | 1 | 1 | 452.02 | 452.02 | 17.89 | 17.89 | 6.69 | 5.8531 | 8 |
| `peak_r20_no_peaktrail_loss_scale` | r20_opportunity_sweep | phase0_fast_model1 | 0 | 1 | 1 | 1607.85 | 1607.85 | 63.63 | 63.63 | 12.41 | 2.5627 | 80 |
| `peak_r20_no_peaktrail_r08_floor05` | r20_opportunity_sweep | phase0_fast_model1 | 0 | 1 | 1 | 84.97 | 84.97 | 3.36 | 3.36 | 5.8 | 1.6702 | 45 |
| `peak_r20_no_peaktrail_r10` | r20_opportunity_sweep | phase0_fast_model1 | 0 | 1 | 1 | 1716.76 | 1716.76 | 67.94 | 67.94 | 10.62 | 2.8655 | 76 |
| `peak_r20_no_peaktrail_r10_floor05` | r20_opportunity_sweep | phase0_fast_model1 | 0 | 1 | 1 | 102.81 | 102.81 | 4.07 | 4.07 | 6.83 | 1.7198 | 45 |
| `peak_r20_no_peaktrail_r10_norm` | r20_opportunity_sweep | phase0_fast_model1 | 0 | 1 | 1 | 1698.8 | 1698.8 | 67.22 | 67.22 | 10.61 | 2.823 | 77 |
| `peak_r20_no_peaktrail_r12_floor05` | r20_opportunity_sweep | phase0_fast_model1 | 0 | 1 | 1 | 161.41 | 161.41 | 6.39 | 6.39 | 7.62 | 2.1173 | 44 |
| `peak_r20_no_peaktrail_r14_floor05` | r20_opportunity_sweep | phase0_fast_model1 | 0 | 1 | 1 | 209.97 | 209.97 | 8.31 | 8.31 | 8.08 | 2.2344 | 47 |
| `peak_r20_no_peaktrail_r15` | r20_opportunity_sweep | phase0_fast_model1 | 0 | 1 | 1 | 1668.2 | 1668.2 | 66.01 | 66.01 | 11.74 | 2.6522 | 75 |
| `peak_r20_no_peaktrail_r16_floor05` | r20_opportunity_sweep | phase0_fast_model1 | 0 | 1 | 1 | 242.72 | 242.72 | 9.6 | 9.6 | 8.56 | 2.3206 | 47 |
| `peak_r20_octnov_main_lowrisk` | r20_opportunity_sweep | phase0_fast_model1 | 0 | 1 | 1 | 464.86 | 464.86 | 18.4 | 18.4 | 5.81 | 6.789 | 7 |
| `peak_r20_soft_weak_gate` | r20_opportunity_sweep | phase0_fast_model1 | 0 | 1 | 1 | 245.08 | 245.08 | 9.7 | 9.7 | 3.6 | 9.451 | 5 |

## Missing Or Unparsed

All queued rows have report or log evidence.
