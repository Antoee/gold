# Promotion Gate Status

Generated from existing local CSV evidence only. No MT5 process was launched.

A profile passes only when full, split, quarter, and month evidence are present; each set must be profitable, have no losing windows, and have a worst window of at least $0.00.

## Profile Status

| Profile | Status | Passed Sets | Missing | Failed | Worst Observed |
| --- | --- | ---: | --- | --- | ---: |
| `promoted_risk160_sl18_tp35` | PASS | 4/4 |  |  | 0 |
| `risk160_sl18_tp38` | MISSING_EVIDENCE | 0/4 | full,split,quarter,month |  |  |
| `risk160_sl16_tp38` | MISSING_EVIDENCE | 0/4 | full,split,quarter,month |  |  |
| `risk160_sl18_tp35_giveback` | MISSING_EVIDENCE | 0/4 | full,split,quarter,month |  |  |

## Evidence Detail

| Profile | Set | Windows | Required | Total | Worst | Losing | Pass | Source |
| --- | --- | ---: | ---: | ---: | ---: | ---: | --- | --- |
| `promoted_risk160_sl18_tp35` | full | 1 | 1 | 866.59 | 866.59 | 0 | True | `BOS_SWEEP_SPLITS_risk1p6_sl18_tp35.csv` |
| `promoted_risk160_sl18_tp35` | split | 9 | 9 | 2354.65 | 0 | 0 | True | `BOS_SWEEP_SPLITS_risk1p6_sl18_tp35.csv` |
| `promoted_risk160_sl18_tp35` | quarter | 10 | 10 | 744.03 | 0 | 0 | True | `BOS_SWEEP_WINDOWS_risk1p6_sl18_tp35.csv` |
| `promoted_risk160_sl18_tp35` | month | 30 | 30 | 744.03 | 0 | 0 | True | `BOS_SWEEP_WINDOWS_risk1p6_sl18_tp35.csv` |
| `risk160_sl18_tp38` | full | 0 | 1 | 0 |  | 0 | False | `` |
| `risk160_sl18_tp38` | split | 0 | 9 | 0 |  | 0 | False | `` |
| `risk160_sl18_tp38` | quarter | 0 | 10 | 0 |  | 0 | False | `` |
| `risk160_sl18_tp38` | month | 0 | 30 | 0 |  | 0 | False | `` |
| `risk160_sl16_tp38` | full | 0 | 1 | 0 |  | 0 | False | `` |
| `risk160_sl16_tp38` | split | 0 | 9 | 0 |  | 0 | False | `` |
| `risk160_sl16_tp38` | quarter | 0 | 10 | 0 |  | 0 | False | `` |
| `risk160_sl16_tp38` | month | 0 | 30 | 0 |  | 0 | False | `` |
| `risk160_sl18_tp35_giveback` | full | 0 | 1 | 0 |  | 0 | False | `` |
| `risk160_sl18_tp35_giveback` | split | 0 | 9 | 0 |  | 0 | False | `` |
| `risk160_sl18_tp35_giveback` | quarter | 0 | 10 | 0 |  | 0 | False | `` |
| `risk160_sl18_tp35_giveback` | month | 0 | 30 | 0 |  | 0 | False | `` |

## Next Action

Keep the promoted profile as default. The TP-extension and giveback candidates still need full/month/quarter/split validation before they can replace it.
