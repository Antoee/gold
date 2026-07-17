# First-Pass Validation Log Metrics

Generated from exported MT5 reports when present and hidden MT5 tester logs when no report was exported. No MT5 process was launched.

- Queue manifest: `outputs\INDEPENDENT_M30_STRUCTURE_CHANNEL_HOLDOUT_MODEL1_QUEUE.csv`
- Hidden run CSV: `outputs\INDEPENDENT_M30_STRUCTURE_CHANNEL_HOLDOUT_MODEL1_RUN.csv`
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
| `m30sc_48_24_channel` | independent_m30_structure_channel | frozen_holdout_model1 | 9 | 0 | 9 | -679.08 | -231.05 | -0.4 | -1.1 | 5.06 | 0 | 826 |
| `m30sc_48_24_stop5` | independent_m30_structure_channel | frozen_holdout_model1 | 9 | 0 | 9 | -182.94 | -119 | -0.09 | -0.6 | 2.95 | 0 | 592 |
| `m30sc_48_24_tp25` | independent_m30_structure_channel | frozen_holdout_model1 | 9 | 0 | 9 | -587.56 | -227.51 | -0.35 | -1.23 | 4.87 | 0 | 832 |
| `m30sc_72_36_tp20` | independent_m30_structure_channel | frozen_holdout_model1 | 9 | 0 | 9 | -420.78 | -296.23 | -0.24 | -1.45 | 4.45 | 0 | 741 |

## Missing Or Unparsed

All queued rows have report or log evidence.
