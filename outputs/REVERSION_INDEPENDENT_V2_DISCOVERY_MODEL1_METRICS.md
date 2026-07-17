# First-Pass Validation Log Metrics

Generated from exported MT5 reports when present and hidden MT5 tester logs when no report was exported. No MT5 process was launched.

- Queue manifest: `outputs\REVERSION_INDEPENDENT_V2_DISCOVERY_MODEL1_QUEUE.csv`
- Hidden run CSV: `outputs\REVERSION_INDEPENDENT_V2_DISCOVERY_MODEL1_RUN.csv`
- Log files scanned: `2`
- Expected rows: `45`
- Parsed exported reports: `45`
- Parsed from tester log: `0`
- Missing reports/results: `0`
- Unparsed log rows: `0`

Log-parsed rows are enough to reject bad fast screens, but exported full reports are still required before any candidate can be trusted for promotion.

## Summary By Candidate

| Candidate | Source | Phase | Parsed Reports | Parsed Logs | Expected | Total Net | Worst Window | Avg Ann. Return % | Worst Ann. Return % | Worst DD % | Min PF | Trades |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `ri2_control` | reversion_independent_v2 | corrected_discovery_model1 | 9 | 0 | 9 | 700.07 | -3.29 | 0.33 | -0.03 | 0.77 | 0 | 45 |
| `ri2_m10_r30` | reversion_independent_v2 | corrected_discovery_model1 | 9 | 0 | 9 | 747.14 | -17.15 | 0.35 | -0.17 | 0.72 | 0 | 59 |
| `ri2_m10_r40` | reversion_independent_v2 | corrected_discovery_model1 | 9 | 0 | 9 | 736.12 | -24.42 | 0.34 | -0.25 | 0.78 | 0 | 59 |
| `ri2_m12_r30` | reversion_independent_v2 | corrected_discovery_model1 | 9 | 0 | 9 | 707.15 | -17.15 | 0.33 | -0.17 | 0.72 | 0 | 63 |
| `ri2_m12_r40` | reversion_independent_v2 | corrected_discovery_model1 | 9 | 0 | 9 | 693.31 | -24.42 | 0.31 | -0.25 | 0.78 | 0 | 65 |

## Missing Or Unparsed

All queued rows have report or log evidence.
