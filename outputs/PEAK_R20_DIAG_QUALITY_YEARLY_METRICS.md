# First-Pass Validation Log Metrics

Generated from exported MT5 reports when present and hidden MT5 tester logs when no report was exported. No MT5 process was launched.

- Queue manifest: `.\outputs\PEAK_R20_DIAG_QUALITY_YEARLY_QUEUE.csv`
- Hidden run CSV: `.\outputs\PEAK_R20_DIAG_QUALITY_YEARLY_HIDDEN_RUN_PLAN.csv`
- Log files scanned: `1`
- Expected rows: `40`
- Parsed exported reports: `0`
- Parsed from tester log: `40`
- Missing reports/results: `0`
- Unparsed log rows: `0`

Log-parsed rows are enough to reject bad fast screens, but exported full reports are still required before any candidate can be trusted for promotion.

## Summary By Candidate

| Candidate | Source | Phase | Parsed Reports | Parsed Logs | Expected | Total Net | Worst Window | Avg Ann. Return % | Worst Ann. Return % | Worst DD % | Min PF | Trades |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `r10_a7_diagq_default` | peak_r20_diag_quality_yearly | phase5_diag_quality_yearly_model1 | 0 | 8 | 8 | 328.37 | -20.84 | 4.73 | -2.09 | 6.47 | 0 | 22 |
| `r10_a7_diagq_liq` | peak_r20_diag_quality_yearly | phase5_diag_quality_yearly_model1 | 0 | 8 | 8 | 241.28 | -17.6 | 3.64 | -1.76 | 5.63 | 0 | 17 |
| `r10_a7_diagq_struct` | peak_r20_diag_quality_yearly | phase5_diag_quality_yearly_model1 | 0 | 8 | 8 | 195.55 | -17.6 | 3.07 | -1.76 | 4.79 | 0 | 9 |
| `r10_a7_diagq_struct_liq` | peak_r20_diag_quality_yearly | phase5_diag_quality_yearly_model1 | 0 | 8 | 8 | 195.55 | -17.6 | 3.07 | -1.76 | 4.79 | 0 | 9 |
| `r10_a7_no_diagfallback` | peak_r20_diag_quality_yearly | phase5_diag_quality_yearly_model1 | 0 | 8 | 8 | 123.15 | -23.4 | 2.16 | -2.35 | 4.79 | 0 | 8 |

## Missing Or Unparsed

All queued rows have report or log evidence.
