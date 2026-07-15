# First-Pass Validation Log Metrics

Generated from exported MT5 reports when present and hidden MT5 tester logs when no report was exported. No MT5 process was launched.

- Queue manifest: `outputs\DGF_HIGHPROFIT_RISK_SHAPE_QUEUE.csv`
- Hidden run CSV: `outputs\DGF_HIGHPROFIT_RISK_SHAPE_RUN.csv`
- Log files scanned: `2`
- Expected rows: `11`
- Parsed exported reports: `11`
- Parsed from tester log: `0`
- Missing reports/results: `0`
- Unparsed log rows: `0`

Log-parsed rows are enough to reject bad fast screens, but exported full reports are still required before any candidate can be trusted for promotion.

## Summary By Candidate

| Candidate | Source | Phase | Parsed Reports | Parsed Logs | Expected | Total Net | Worst Window | Avg Ann. Return % | Worst Ann. Return % | Worst DD % | Min PF | Trades |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `dgf_hp_control` | dgf_highprofit_risk_shape | continuous_model4 | 1 | 0 | 1 | 1915.83 | 1915.83 | 25.45 | 25.45 | 24.58 | 1.72 | 127 |
| `dgf_hp_peaktrail_20p70gb` | dgf_highprofit_risk_shape | continuous_model4 | 1 | 0 | 1 | 75.9 | 75.9 | 1.01 | 1.01 | 22.26 | 1.14 | 35 |
| `dgf_hp_peaktrail_35p70gb` | dgf_highprofit_risk_shape | continuous_model4 | 1 | 0 | 1 | 1915.83 | 1915.83 | 25.45 | 25.45 | 24.58 | 1.72 | 127 |
| `dgf_hp_risk050` | dgf_highprofit_risk_shape | continuous_model4 | 1 | 0 | 1 | -158.03 | -158.03 | -2.1 | -2.1 | 31.26 | 0.78 | 92 |
| `dgf_hp_risk060` | dgf_highprofit_risk_shape | continuous_model4 | 1 | 0 | 1 | -117.89 | -117.89 | -1.57 | -1.57 | 32.18 | 0.84 | 91 |
| `dgf_hp_risk060_loss_scale` | dgf_highprofit_risk_shape | continuous_model4 | 1 | 0 | 1 | -124.07 | -124.07 | -1.65 | -1.65 | 27.5 | 0.82 | 93 |
| `dgf_hp_risk070` | dgf_highprofit_risk_shape | continuous_model4 | 1 | 0 | 1 | -96.99 | -96.99 | -1.29 | -1.29 | 32.73 | 0.87 | 84 |
| `dgf_hp_risk080` | dgf_highprofit_risk_shape | continuous_model4 | 1 | 0 | 1 | -63.91 | -63.91 | -0.85 | -0.85 | 32.47 | 0.92 | 84 |
| `dgf_hp_risk080_dd12` | dgf_highprofit_risk_shape | continuous_model4 | 1 | 0 | 1 | -96.91 | -96.91 | -1.29 | -1.29 | 15.49 | 0.57 | 20 |
| `dgf_hp_risk080_loss_scale` | dgf_highprofit_risk_shape | continuous_model4 | 1 | 0 | 1 | 238.06 | 238.06 | 3.16 | 3.16 | 20.13 | 1.24 | 101 |
| `dgf_hp_risk080_peaktrail_20p70gb` | dgf_highprofit_risk_shape | continuous_model4 | 1 | 0 | 1 | -63.91 | -63.91 | -0.85 | -0.85 | 32.47 | 0.92 | 84 |

## Missing Or Unparsed

All queued rows have report or log evidence.
