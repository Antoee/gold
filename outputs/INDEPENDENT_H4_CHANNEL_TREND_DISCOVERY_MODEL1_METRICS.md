# First-Pass Validation Log Metrics

Generated from exported MT5 reports when present and hidden MT5 tester logs when no report was exported. No MT5 process was launched.

- Queue manifest: `outputs\INDEPENDENT_H4_CHANNEL_TREND_DISCOVERY_MODEL1_QUEUE.csv`
- Hidden run CSV: `outputs\INDEPENDENT_H4_CHANNEL_TREND_DISCOVERY_MODEL1_RUN.csv`
- Log files scanned: `2`
- Expected rows: `24`
- Parsed exported reports: `24`
- Parsed from tester log: `0`
- Missing reports/results: `0`
- Unparsed log rows: `0`

Log-parsed rows are enough to reject bad fast screens, but exported full reports are still required before any candidate can be trusted for promotion.

## Summary By Candidate

| Candidate | Source | Phase | Parsed Reports | Parsed Logs | Expected | Total Net | Worst Window | Avg Ann. Return % | Worst Ann. Return % | Worst DD % | Min PF | Trades |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `h1ct_80_40_raw` | independent_h4_channel_trend | discovery_model1 | 3 | 0 | 3 | -394.37 | -192.72 | -0.3 | -0.44 | 3.47 | 0.76 | 416 |
| `h4ct_20_10_raw` | independent_h4_channel_trend | discovery_model1 | 3 | 0 | 3 | 358.97 | 56.19 | 0.35 | 0.14 | 1.34 | 1.13 | 225 |
| `h4ct_40_20_raw` | independent_h4_channel_trend | discovery_model1 | 3 | 0 | 3 | 194.08 | -8.92 | 0.13 | -0.04 | 1.47 | 0.93 | 160 |
| `h4ct_55_20_adx16` | independent_h4_channel_trend | discovery_model1 | 3 | 0 | 3 | 24.72 | 4.58 | 0.02 | 0.01 | 1.11 | 1.02 | 132 |
| `h4ct_55_20_chandelier` | independent_h4_channel_trend | discovery_model1 | 3 | 0 | 3 | 655.62 | 157.71 | 0.6 | 0.39 | 0.76 | 1.7 | 152 |
| `h4ct_55_20_d1ema100` | independent_h4_channel_trend | discovery_model1 | 3 | 0 | 3 | -120.02 | -64.94 | -0.08 | -0.16 | 1.5 | 0.67 | 88 |
| `h4ct_55_20_raw` | independent_h4_channel_trend | discovery_model1 | 3 | 0 | 3 | 24.72 | 4.58 | 0.02 | 0.01 | 1.11 | 1.02 | 132 |
| `h4ct_80_40_raw` | independent_h4_channel_trend | discovery_model1 | 3 | 0 | 3 | 157.99 | 16.16 | 0.16 | 0.04 | 1.17 | 1.09 | 93 |

## Missing Or Unparsed

All queued rows have report or log evidence.
