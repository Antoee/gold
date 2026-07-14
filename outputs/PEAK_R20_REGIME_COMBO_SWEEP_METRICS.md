# First-Pass Validation Log Metrics

Generated from exported MT5 reports when present and hidden MT5 tester logs when no report was exported. No MT5 process was launched.

- Queue manifest: `.\outputs\PEAK_R20_REGIME_COMBO_SWEEP_QUEUE.csv`
- Hidden run CSV: `.\outputs\PEAK_R20_REGIME_COMBO_SWEEP_HIDDEN_RUN_PLAN.csv`
- Log files scanned: `1`
- Expected rows: `45`
- Parsed exported reports: `0`
- Parsed from tester log: `45`
- Missing reports/results: `0`
- Unparsed log rows: `0`

Log-parsed rows are enough to reject bad fast screens, but exported full reports are still required before any candidate can be trusted for promotion.

## Summary By Candidate

| Candidate | Source | Phase | Parsed Reports | Parsed Logs | Expected | Total Net | Worst Window | Avg Ann. Return % | Worst Ann. Return % | Worst DD % | Min PF | Trades |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `r10_pg40_atr085_adapt6` | peak_r20_regime_combo_sweep | phase4_regime_combo_sweep_model1 | 0 | 5 | 5 | 22.12 | -55.32 | 0.44 | -5.55 | 8.99 | 0.558 | 36 |
| `r10_pg40_atr085_adapt6_session` | peak_r20_regime_combo_sweep | phase4_regime_combo_sweep_model1 | 0 | 5 | 5 | -2.98 | -55.32 | -0.06 | -5.55 | 8.99 | 0.558 | 34 |
| `r10_pg40_atr085_adapt7` | peak_r20_regime_combo_sweep | phase4_regime_combo_sweep_model1 | 0 | 5 | 5 | 226.91 | 15.72 | 4.55 | 1.57 | 7.08 | 0 | 19 |
| `r10_pg40_atr085_adapt7_session` | peak_r20_regime_combo_sweep | phase4_regime_combo_sweep_model1 | 0 | 5 | 5 | 185.25 | 15.72 | 3.72 | 1.57 | 7.08 | 0 | 18 |
| `r10_pg40_atr085_adx22` | peak_r20_regime_combo_sweep | phase4_regime_combo_sweep_model1 | 0 | 5 | 5 | 154.3 | -24.87 | 3.09 | -2.5 | 11.91 | 0.4667 | 57 |
| `r10_pg40_atr085_adx24` | peak_r20_regime_combo_sweep | phase4_regime_combo_sweep_model1 | 0 | 5 | 5 | 154.3 | -24.87 | 3.09 | -2.5 | 11.91 | 0.4667 | 57 |
| `r10_pg40_atr085_control` | peak_r20_regime_combo_sweep | phase4_regime_combo_sweep_model1 | 0 | 5 | 5 | 154.3 | -24.87 | 3.09 | -2.5 | 11.91 | 0.4667 | 57 |
| `r10_pg40_atr085_no_diagfallback` | peak_r20_regime_combo_sweep | phase4_regime_combo_sweep_model1 | 0 | 5 | 5 | 151.08 | -29.2 | 3.03 | -2.93 | 9.05 | 0.6622 | 29 |
| `r10_pg40_atr085_session` | peak_r20_regime_combo_sweep | phase4_regime_combo_sweep_model1 | 0 | 5 | 5 | 118.59 | -24.87 | 2.37 | -2.5 | 11.91 | 0.4667 | 49 |

## Missing Or Unparsed

All queued rows have report or log evidence.
