# First-Pass Validation Log Metrics

Generated from exported MT5 reports when present and hidden MT5 tester logs when no report was exported. No MT5 process was launched.

- Queue manifest: `outputs\RC2_MOMENTUM_FEATURE_TELEMETRY_MODEL1_QUEUE.csv`
- Hidden run CSV: `outputs\RC2_MOMENTUM_FEATURE_TELEMETRY_MODEL1_RUN.csv`
- Log files scanned: `2`
- Expected rows: `1`
- Parsed exported reports: `1`
- Parsed from tester log: `0`
- Missing reports/results: `0`
- Unparsed log rows: `0`

Log-parsed rows are enough to reject bad fast screens, but exported full reports are still required before any candidate can be trusted for promotion.

## Summary By Candidate

| Candidate | Source | Phase | Parsed Reports | Parsed Logs | Expected | Total Net | Worst Window | Avg Ann. Return % | Worst Ann. Return % | Worst DD % | Min PF | Trades |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `rc2_momentum_feature_telemetry` | behavior_preserving_telemetry_fork | feature_telemetry_model1 | 1 | 0 | 1 | 814.7 | 814.7 | 2.04 | 2.04 | 1.01 | 1.87 | 152 |

## Missing Or Unparsed

All queued rows have report or log evidence.
