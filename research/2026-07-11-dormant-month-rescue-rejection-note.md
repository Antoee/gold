# Dormant Month Rescue Rejection Note

Date: 2026-07-11

## Decision

Do not promote the dormant-month rescue variants tested in `work/build_current_best_dormant_month_rescue_package.ps1`.

The best broad-window variant, `dormant_fmr_probe`, increased continuous net profit, but it introduced a losing guard month and did not wake up the actual dormant target months.

## Evidence

Source: `outputs/CURRENT_BEST_DORMANT_MONTH_RESCUE_LOG_SUMMARY.csv`

| Profile | Continuous | 2026 YTD | Full 2025 | Full 2024 | Worst Window | Losing Windows |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `base` | `6125.57` | `1107.90` | `214.18` | `2381.09` | `0.00` | `0` |
| `dormant_fmr_probe` | `9027.02` | `1583.86` | `214.18` | `3127.85` | `-11.40` | `1` |
| `dormant_combo` | `9027.02` | `1583.86` | `214.18` | `3127.85` | `-11.40` | `1` |
| `dormant_fsd_relaxed` | `6125.57` | `1107.90` | `214.18` | `2381.09` | `0.00` | `0` |

Target dormant months remained inactive:

| Window | Base | Best Rescue |
| --- | ---: | ---: |
| `2025_01` | `0.00` | `0.00` |
| `2025_04` | `0.00` | `0.00` |
| `2025_06` | `0.00` | `0.00` |
| `2026_01` | `0.00` | `0.00` |

The only losing guard window was April 2024:

| Profile | Window | Net |
| --- | --- | ---: |
| `dormant_fmr_probe` | `2024_04` | `-11.40` |
| `dormant_combo` | `2024_04` | `-11.40` |

## Follow-Up Check

Source: `outputs/CURRENT_BEST_DORMANT_NO_APRIL_LOG_SUMMARY.csv`

Removing April from the micro-reversion month filter eliminated the losing window, but also removed the profit lift:

| Profile | Continuous | 2026 YTD | Full 2025 | Full 2024 | Worst Window | Losing Windows |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `base` | `6125.57` | `1107.90` | `214.18` | `2381.09` | `0.00` | `0` |
| `dormant_fmr_probe` | `9027.02` | `1583.86` | `214.18` | `3127.85` | `-11.40` | `1` |
| `dormant_fmr_probe_no_april` | `5746.10` | `1107.90` | `214.18` | `2282.98` | `0.00` | `0` |

## Interpretation

The apparent rescue gain is April-sensitive and does not solve the requested dormant target months. Promoting it would add a known losing guard month without fixing the inactivity problem.

Current research-best remains:

```text
outputs/CANDIDATE_PRIMARY_AUG40_REVERSE_OFF_FSD_STRICT_MICRO_JULOCT_PROFILE.set
```

Next useful work should target a different dormant-month mechanism rather than relaxing the existing micro-reversion lane further.
