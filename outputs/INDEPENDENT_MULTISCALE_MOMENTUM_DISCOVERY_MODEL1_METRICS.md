# First-Pass Validation Log Metrics

Generated from exported MT5 reports when present and hidden MT5 tester logs when no report was exported. No MT5 process was launched.

- Queue manifest: `outputs/INDEPENDENT_MULTISCALE_MOMENTUM_DISCOVERY_MODEL1_QUEUE.csv`
- Hidden run CSV: `outputs\INDEPENDENT_MULTISCALE_MOMENTUM_DISCOVERY_MODEL1_RUN.csv`
- Log files scanned: `2`
- Expected rows: `21`
- Parsed exported reports: `21`
- Parsed from tester log: `0`
- Missing reports/results: `0`
- Unparsed log rows: `0`

Log-parsed rows are enough to reject bad fast screens, but exported full reports are still required before any candidate can be trusted for promotion.

## Summary By Candidate

| Candidate | Source | Phase | Parsed Reports | Parsed Logs | Expected | Total Net | Worst Window | Avg Ann. Return % | Worst Ann. Return % | Worst DD % | Min PF | Trades |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `mtsm_m126_e10_r150` | independent_multiscale_momentum | discovery_model1 | 3 | 0 | 3 | 634.95 | 42.69 | 0.47 | 0.21 | 1.53 | 1.09 | 887 |
| `mtsm_m126_e10_r200` | independent_multiscale_momentum | discovery_model1 | 3 | 0 | 3 | 815.68 | 65.03 | 0.62 | 0.33 | 1.54 | 1.14 | 871 |
| `mtsm_m126_e10_r250` | independent_multiscale_momentum | discovery_model1 | 3 | 0 | 3 | 769.47 | 65.89 | 0.59 | 0.33 | 1.96 | 1.14 | 853 |
| `mtsm_m126_e20_r200` | independent_multiscale_momentum | discovery_model1 | 3 | 0 | 3 | 676.48 | 82.12 | 0.54 | 0.41 | 0.6 | 1.38 | 395 |
| `mtsm_m126_e6_r200` | independent_multiscale_momentum | discovery_model1 | 3 | 0 | 3 | 550.34 | 56.32 | 0.43 | 0.28 | 2.72 | 1.08 | 1207 |
| `mtsm_m252_e10_r200` | independent_multiscale_momentum | discovery_model1 | 3 | 0 | 3 | 97.7 | -9.4 | 0.12 | -0.02 | 1.63 | 0.99 | 880 |
| `mtsm_m63_e10_r200` | independent_multiscale_momentum | discovery_model1 | 3 | 0 | 3 | 303.77 | 2.35 | 0.34 | 0.01 | 2.09 | 1 | 883 |

## Missing Or Unparsed

All queued rows have report or log evidence.
