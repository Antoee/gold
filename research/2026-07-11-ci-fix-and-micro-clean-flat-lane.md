# 2026-07-11 CI Fix And Micro-Clean Flat Lane Probe

## CI Fix

GitHub Actions failed in `Static Safety Audit / Report and MT5 safety smoke tests` because the remote checkout did not contain `outputs/risk_adjusted_micro_handoff/HANDOFF_MANIFEST.csv`.

Local reproduction passed because that generated handoff folder existed in the workspace. The package builder now regenerates the risk-adjusted handoff from `outputs/RISK_ADJUSTED_MICRO_BATCH.csv` when the folder is missing.

- Remote commit: `6648dcdbbad572324d336367f6488a296207b5ef`
- Local verification: external package build passed and `work/test_external_mt5_validation_package.ps1` passed 26/26 after deleting the local handoff folder.
- MT5 local safety audit after runs: 39/39 pass.

## Archived Flat-Lane Retest

Retested archived standalone flat-month lanes against the current source.

| Profile | Continuous | YTD | Full2025 | Full2024 | WorstWindow | LosingWindows |
|---|---:|---:|---:|---:|---:|---:|
| base_mar10_may10 | 3746.45 | 1194.44 | -348.16 | 0.00 | -348.16 | 1 |
| micro_reversion_low | 1262.72 | 8.62 | 159.06 | 1262.72 | 4.82 | 0 |
| jan_combo_strict | 975.70 | 64.06 | 220.34 | 975.70 | -18.10 | 2 |
| jan_session_balanced | 972.79 | 28.72 | 173.27 | 972.79 | -20.68 | 2 |
| jan_session_anatomy | 971.57 | 64.06 | 217.74 | 971.57 | -10.69 | 2 |
| lowrisk_unlock | 26.38 | 51.37 | 2100.07 | 26.38 | 0.00 | 0 |

Conclusion: no standalone archived flat lane replaces the promoted base. `micro_reversion_low` has the cleanest no-loss window profile, but its 2026 YTD is too weak by itself.

## Clean Micro Add-On Probe

Built `work/build_mar10_may10_micro_clean_package.ps1` to test a cleaner blend:

- keep promoted March/May settings untouched
- add only flat-month micro-reversion lane parameters
- avoid the broad month-risk multiplier changes that hurt the earlier flat add-on test

Fast-screen results:

| Profile | Continuous | YTD | Full2025 | Full2024 | WorstWindow | LosingWindows |
|---|---:|---:|---:|---:|---:|---:|
| micro_clean | 5046.57 | 8.17 | 159.48 | 2046.01 | 2.90 | 0 |
| base_mar10_may10 | 3746.45 | 1107.93 | 214.30 | 1409.57 | 0.00 | 0 |
| micro_clean_jul_oct | 966.00 | 1107.93 | 214.30 | 966.00 | 0.00 | 0 |
| micro_clean_core_jul_oct | 966.00 | 1107.93 | 214.30 | 966.00 | 0.00 | 0 |

Conclusion: `micro_clean` is promising for 2024/continuous profit but not promotable because it destroys 2026 YTD. The month-filtered variants preserve 2026 but damage 2024 too much. Next useful test is a monthly attribution run for `micro_clean` to identify exactly which months create the 2024 gain and which 2026 months cause the YTD collapse.