# First-Pass Validation Log Metrics

Generated from exported MT5 reports when present and hidden MT5 tester logs when no report was exported. No MT5 process was launched.

- Queue manifest: `outputs\INDEPENDENT_MULTISCALE_MOMENTUM_HOLDOUT_MODEL1_QUEUE.csv`
- Hidden run CSV: `outputs\INDEPENDENT_MULTISCALE_MOMENTUM_HOLDOUT_MODEL1_RUN.csv`
- Log files scanned: `2`
- Expected rows: `16`
- Parsed exported reports: `16`
- Parsed from tester log: `0`
- Missing reports/results: `0`
- Unparsed log rows: `0`

Log-parsed rows are enough to reject bad fast screens, but exported full reports are still required before any candidate can be trusted for promotion.

## Summary By Candidate

| Candidate | Source | Phase | Parsed Reports | Parsed Logs | Expected | Total Net | Worst Window | Avg Ann. Return % | Worst Ann. Return % | Worst DD % | Min PF | Trades |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `mtsm_m126_e10_r150` | independent_multiscale_momentum | frozen_holdout_model1 | 4 | 0 | 4 | -16.85 | -206.87 | -0.07 | -0.69 | 3.04 | 0.76 | 1280 |
| `mtsm_m126_e10_r200` | independent_multiscale_momentum | frozen_holdout_model1 | 4 | 0 | 4 | 329.05 | -158.3 | 0.07 | -0.53 | 2.32 | 0.81 | 1271 |
| `mtsm_m126_e10_r250` | independent_multiscale_momentum | frozen_holdout_model1 | 4 | 0 | 4 | 330.85 | -126.84 | 0.08 | -0.42 | 2.33 | 0.85 | 1256 |
| `mtsm_m126_e20_r200` | independent_multiscale_momentum | frozen_holdout_model1 | 4 | 0 | 4 | 460.94 | -74.79 | 0.16 | -0.25 | 1.27 | 0.8 | 564 |

## Missing Or Unparsed

All queued rows have report or log evidence.
