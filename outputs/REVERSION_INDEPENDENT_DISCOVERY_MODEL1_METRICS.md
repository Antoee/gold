# First-Pass Validation Log Metrics

Generated from exported MT5 reports when present and hidden MT5 tester logs when no report was exported. No MT5 process was launched.

- Queue manifest: `outputs\REVERSION_INDEPENDENT_DISCOVERY_MODEL1_QUEUE.csv`
- Hidden run CSV: `outputs\REVERSION_INDEPENDENT_DISCOVERY_MODEL1_RUN.csv`
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
| `ri_control` | reversion_independent | discovery_model1 | 9 | 0 | 9 | 700.07 | -3.29 | 0.33 | -0.03 | 0.77 | 0 | 45 |
| `ri_m10_r30` | reversion_independent | discovery_model1 | 9 | 0 | 9 | 753.52 | -17.15 | 0.36 | -0.17 | 1.09 | 0 | 65 |
| `ri_m10_r40` | reversion_independent | discovery_model1 | 9 | 0 | 9 | 740.75 | -24.42 | 0.35 | -0.25 | 1.06 | 0 | 67 |
| `ri_m12_r30` | reversion_independent | discovery_model1 | 9 | 0 | 9 | 713.53 | -17.15 | 0.34 | -0.17 | 1.09 | 0 | 69 |
| `ri_m12_r40` | reversion_independent | discovery_model1 | 9 | 0 | 9 | 697.94 | -24.42 | 0.32 | -0.25 | 1.06 | 0 | 73 |

## Missing Or Unparsed

All queued rows have report or log evidence.
