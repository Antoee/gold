# First-Pass Validation Log Metrics

Generated from exported MT5 reports when present and hidden MT5 tester logs when no report was exported. No MT5 process was launched.

- Queue manifest: `.\outputs\PEAK_R20_DGF_PERF_RISK_YEARLY_QUEUE.csv`
- Hidden run CSV: `.\outputs\PEAK_R20_DGF_PERF_RISK_YEARLY_HIDDEN_RUN_PLAN.csv`
- Log files scanned: `1`
- Expected rows: `48`
- Parsed exported reports: `0`
- Parsed from tester log: `48`
- Missing reports/results: `0`
- Unparsed log rows: `0`

Log-parsed rows are enough to reject bad fast screens, but exported full reports are still required before any candidate can be trusted for promotion.

## Summary By Candidate

| Candidate | Source | Phase | Parsed Reports | Parsed Logs | Expected | Total Net | Worst Window | Avg Ann. Return % | Worst Ann. Return % | Worst DD % | Min PF | Trades |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `r10_a7_dgf_perf_3_2_40` | peak_r20_dgf_perf_risk_yearly | phase7_dgf_perf_risk_yearly_model1 | 0 | 8 | 8 | 292.4 | -13.62 | 4.28 | -1.36 | 6.22 | 0 | 28 |
| `r10_a7_dgf_perf_4_2_50` | peak_r20_dgf_perf_risk_yearly | phase7_dgf_perf_risk_yearly_model1 | 0 | 8 | 8 | 319.92 | -8.96 | 4.63 | -0.9 | 6.11 | 0 | 28 |
| `r10_a7_dgf_perf_5_2_50` | peak_r20_dgf_perf_risk_yearly | phase7_dgf_perf_risk_yearly_model1 | 0 | 8 | 8 | 297.06 | -8.96 | 4.34 | -0.9 | 6.22 | 0 | 28 |
| `r10_a7_dgf_perf_base` | peak_r20_dgf_perf_risk_yearly | phase7_dgf_perf_risk_yearly_model1 | 0 | 8 | 8 | 344.6 | 9.25 | 4.94 | 0.93 | 7.08 | 0 | 28 |
| `r10_a7_dgf_spread_perf_3_2_40` | peak_r20_dgf_perf_risk_yearly | phase7_dgf_perf_risk_yearly_model1 | 0 | 8 | 8 | 288.7 | -17.32 | 4.24 | -1.73 | 6.22 | 0 | 28 |
| `r10_a7_dgf_spread_perf_4_2_50` | peak_r20_dgf_perf_risk_yearly | phase7_dgf_perf_risk_yearly_model1 | 0 | 8 | 8 | 319.24 | -9.64 | 4.62 | -0.96 | 6.11 | 0 | 28 |

## Missing Or Unparsed

All queued rows have report or log evidence.
