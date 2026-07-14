# First-Pass Validation Log Metrics

Generated from exported MT5 reports when present and hidden MT5 tester logs when no report was exported. No MT5 process was launched.

- Queue manifest: `.\outputs\PEAK_R20_REGIME_FILTER_SWEEP_QUEUE.csv`
- Hidden run CSV: `.\outputs\PEAK_R20_REGIME_FILTER_SWEEP_HIDDEN_RUN_PLAN.csv`
- Log files scanned: `1`
- Expected rows: `65`
- Parsed exported reports: `0`
- Parsed from tester log: `65`
- Missing reports/results: `0`
- Unparsed log rows: `0`

Log-parsed rows are enough to reject bad fast screens, but exported full reports are still required before any candidate can be trusted for promotion.

## Summary By Candidate

| Candidate | Source | Phase | Parsed Reports | Parsed Logs | Expected | Total Net | Worst Window | Avg Ann. Return % | Worst Ann. Return % | Worst DD % | Min PF | Trades |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `r10_pg40_adapt_s5` | peak_r20_regime_filter_sweep | phase4_regime_filter_sweep_model1 | 0 | 5 | 5 | 58.95 | -66.34 | 1.18 | -6.66 | 10.82 | 0.3966 | 36 |
| `r10_pg40_adapt_s6` | peak_r20_regime_filter_sweep | phase4_regime_filter_sweep_model1 | 0 | 5 | 5 | 125.46 | -56.95 | 2.51 | -5.71 | 8.94 | 0.4336 | 37 |
| `r10_pg40_adapt_s6_eff45` | peak_r20_regime_filter_sweep | phase4_regime_filter_sweep_model1 | 0 | 5 | 5 | 125.46 | -56.95 | 2.51 | -5.71 | 8.94 | 0.4336 | 37 |
| `r10_pg40_adapt_s7_eff45` | peak_r20_regime_filter_sweep | phase4_regime_filter_sweep_model1 | 0 | 5 | 5 | 137.14 | -74.05 | 2.76 | -7.41 | 7.4 | 0 | 19 |
| `r10_pg40_adx22` | peak_r20_regime_filter_sweep | phase4_regime_filter_sweep_model1 | 0 | 5 | 5 | 389.31 | -61.65 | 7.79 | -6.19 | 12.78 | 0.3507 | 64 |
| `r10_pg40_adx24` | peak_r20_regime_filter_sweep | phase4_regime_filter_sweep_model1 | 0 | 5 | 5 | 389.31 | -61.65 | 7.79 | -6.19 | 12.78 | 0.3507 | 64 |
| `r10_pg40_atr_085_165` | peak_r20_regime_filter_sweep | phase4_regime_filter_sweep_model1 | 0 | 5 | 5 | 154.3 | -24.87 | 3.09 | -2.5 | 11.91 | 0.4667 | 57 |
| `r10_pg40_atr_090_155` | peak_r20_regime_filter_sweep | phase4_regime_filter_sweep_model1 | 0 | 5 | 5 | 109.48 | -24.87 | 2.19 | -2.5 | 11.91 | 0.4667 | 51 |
| `r10_pg40_base` | peak_r20_regime_filter_sweep | phase4_regime_filter_sweep_model1 | 0 | 5 | 5 | 389.31 | -61.65 | 7.79 | -6.19 | 12.78 | 0.3507 | 64 |
| `r10_pg40_no_diagfallback` | peak_r20_regime_filter_sweep | phase4_regime_filter_sweep_model1 | 0 | 5 | 5 | -18.01 | -72.35 | -0.36 | -7.26 | 10.54 | 0.4546 | 29 |
| `r10_pg40_session_exhaust` | peak_r20_regime_filter_sweep | phase4_regime_filter_sweep_model1 | 0 | 5 | 5 | 372.32 | -47.23 | 7.45 | -4.74 | 12.78 | 0.3507 | 61 |
| `r10_pg40_weak_bypass16` | peak_r20_regime_filter_sweep | phase4_regime_filter_sweep_model1 | 0 | 5 | 5 | 389.31 | -61.65 | 7.79 | -6.19 | 12.78 | 0.3507 | 64 |
| `r10_pg40_weak_bypass16_no_ls` | peak_r20_regime_filter_sweep | phase4_regime_filter_sweep_model1 | 0 | 5 | 5 | 354.74 | -62.05 | 7.1 | -6.23 | 12.78 | 0 | 72 |

## Missing Or Unparsed

All queued rows have report or log evidence.
