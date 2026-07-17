# First-Pass Validation Log Metrics

Generated from exported MT5 reports when present and hidden MT5 tester logs when no report was exported. No MT5 process was launched.

- Queue manifest: `outputs/H4_CHANNEL_CAPITAL_FEASIBLE_MODEL1_QUEUE.csv`
- Hidden run CSV: `outputs\H4_CHANNEL_CAPITAL_FEASIBLE_MODEL1_RUN.csv`
- Log files scanned: `2`
- Expected rows: `12`
- Parsed exported reports: `12`
- Parsed from tester log: `0`
- Missing reports/results: `0`
- Unparsed log rows: `0`

Log-parsed rows are enough to reject bad fast screens, but exported full reports are still required before any candidate can be trusted for promotion.

## Summary By Candidate

| Candidate | Source | Phase | Parsed Reports | Parsed Logs | Expected | Total Net | Worst Window | Avg Ann. Return % | Worst Ann. Return % | Worst DD % | Min PF | Trades |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `h4cf_40_20_l20_a25` | h4_channel_capital_feasible | capital_feasible_model1 | 3 | 0 | 3 | 2752.74 | -477.88 | 1.15 | -0.86 | 5.65 | 0.47 | 543 |
| `h4cf_55_20_l20_a25` | h4_channel_capital_feasible | capital_feasible_model1 | 3 | 0 | 3 | 3246.96 | -473.37 | 1.36 | -0.86 | 5.76 | 0.41 | 460 |
| `h4cf_55_20_l20_a30` | h4_channel_capital_feasible | capital_feasible_model1 | 3 | 0 | 3 | 3764.63 | -501.7 | 1.58 | -0.91 | 5.95 | 0.25 | 395 |
| `h4cf_80_40_l20_a30` | h4_channel_capital_feasible | capital_feasible_model1 | 3 | 0 | 3 | 3819.76 | -490.21 | 1.61 | -0.89 | 5.85 | 0.2 | 324 |

## Missing Or Unparsed

All queued rows have report or log evidence.
