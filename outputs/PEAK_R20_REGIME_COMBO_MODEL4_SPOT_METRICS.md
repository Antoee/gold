# First-Pass Validation Log Metrics

Generated from exported MT5 reports when present and hidden MT5 tester logs when no report was exported. No MT5 process was launched.

- Queue manifest: `.\outputs\PEAK_R20_REGIME_COMBO_MODEL4_SPOT_QUEUE.csv`
- Hidden run CSV: `.\outputs\PEAK_R20_REGIME_COMBO_MODEL4_SPOT_HIDDEN_RUN_PLAN.csv`
- Log files scanned: `1`
- Expected rows: `5`
- Parsed exported reports: `0`
- Parsed from tester log: `5`
- Missing reports/results: `0`
- Unparsed log rows: `0`

Log-parsed rows are enough to reject bad fast screens, but exported full reports are still required before any candidate can be trusted for promotion.

## Summary By Candidate

| Candidate | Source | Phase | Parsed Reports | Parsed Logs | Expected | Total Net | Worst Window | Avg Ann. Return % | Worst Ann. Return % | Worst DD % | Min PF | Trades |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `r10_pg40_atr085_adapt7` | peak_r20_oos_yearly | phase2_oos_yearly_model4 | 0 | 5 | 5 | 185.33 | 0 | 3.72 | 0 | 7.09 | 0 | 11 |

## Missing Or Unparsed

All queued rows have report or log evidence.
