# Validation Report Metrics

Generated from exported MT5 report files only. No MT5 process was launched.

- Manifest: `work\generated_validation\VALIDATION_MANIFEST.csv`
- Expected reports: 196
- Parsed reports: 0
- Missing reports: 196
- Unparsed reports: 0

## Summary By Profile And Set

| Profile | Set | Parsed/Expected | Total Net | Worst Window | Losing | Worst DD | Avg PF | Complete |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| `promoted_risk160_sl18_tp35` | month | 0/30 |  |  | 0 |  |  | False |
| `promoted_risk160_sl18_tp35` | quarter | 0/10 |  |  | 0 |  |  | False |
| `promoted_risk160_sl18_tp35` | split | 0/9 |  |  | 0 |  |  | False |
| `risk160_sl16_tp38` | month | 0/30 |  |  | 0 |  |  | False |
| `risk160_sl16_tp38` | quarter | 0/10 |  |  | 0 |  |  | False |
| `risk160_sl16_tp38` | split | 0/9 |  |  | 0 |  |  | False |
| `risk160_sl18_tp35_giveback` | month | 0/30 |  |  | 0 |  |  | False |
| `risk160_sl18_tp35_giveback` | quarter | 0/10 |  |  | 0 |  |  | False |
| `risk160_sl18_tp35_giveback` | split | 0/9 |  |  | 0 |  |  | False |
| `risk160_sl18_tp38` | month | 0/30 |  |  | 0 |  |  | False |
| `risk160_sl18_tp38` | quarter | 0/10 |  |  | 0 |  |  | False |
| `risk160_sl18_tp38` | split | 0/9 |  |  | 0 |  |  | False |

## Missing Or Unparsed Reports

All 196 expected reports are currently missing because local MT5 validation is locked until the hidden-desktop runner is deliberately verified. Run `work/collect_validation_results.ps1` after exported reports exist to refresh this file.
