# First-Pass Validation Log Metrics

Generated from exported MT5 reports when present and hidden MT5 tester logs when no report was exported. No MT5 process was launched.

- Queue manifest: `.\outputs\PEAK_R20_REGIME_COMBO_MODEL4_2020_DIAG_QUEUE.csv`
- Hidden run CSV: `.\outputs\PEAK_R20_REGIME_COMBO_MODEL4_2020_DIAG_HIDDEN_RUN_PLAN.csv`
- Log files scanned: `1`
- Expected rows: `1`
- Parsed exported reports: `0`
- Parsed from tester log: `1`
- Missing reports/results: `0`
- Unparsed log rows: `0`

Log-parsed rows are enough to reject bad fast screens, but exported full reports are still required before any candidate can be trusted for promotion.

## Summary By Candidate

| Candidate | Source | Phase | Parsed Reports | Parsed Logs | Expected | Total Net | Worst Window | Avg Ann. Return % | Worst Ann. Return % | Worst DD % | Min PF | Trades |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `r10_pg40_atr085_adapt7` | peak_r20_oos_yearly | phase2_oos_yearly_model4_tradediag | 0 | 1 | 1 | -22.92 | -22.92 | -2.29 | -2.29 | 2.36 | 0 | 1 |

## Missing Or Unparsed

All queued rows have report or log evidence.
