# First-Pass Validation Log Metrics

Generated from exported MT5 reports when present and hidden MT5 tester logs when no report was exported. No MT5 process was launched.

- Queue manifest: `outputs\INDEPENDENT_H4_CHANNEL_TREND_HOLDOUT_MODEL1_QUEUE.csv`
- Hidden run CSV: `outputs\INDEPENDENT_H4_CHANNEL_TREND_HOLDOUT_MODEL1_RUN.csv`
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
| `h4ct_trail_40_20_l20_a25` | independent_h4_channel_trend | frozen_holdout_model1 | 9 | 0 | 9 | 71.85 | 0 | 0.04 | 0 | 0.16 | 0 | 3 |
| `h4ct_trail_55_20_l20_a25` | independent_h4_channel_trend | frozen_holdout_model1 | 9 | 0 | 9 | 80.52 | 0 | 0.05 | 0 | 0.16 | 0 | 3 |
| `h4ct_trail_55_20_l20_a30` | independent_h4_channel_trend | frozen_holdout_model1 | 9 | 0 | 9 | 71.01 | 0 | 0.04 | 0 | 0.19 | 0 | 3 |
| `h4ct_trail_80_40_l20_a30` | independent_h4_channel_trend | frozen_holdout_model1 | 9 | 0 | 9 | 71.01 | 0 | 0.04 | 0 | 0.19 | 0 | 3 |

## Missing Or Unparsed

All queued rows have report or log evidence.
