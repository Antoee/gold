# Path Quality Exit Rejection Note

Date: 2026-07-11

## Decision

Do not promote the no-follow-through, MFE-failure, or underwater-time exit variants.

Model 2 found a promising no-follow-through result, but Model 0 confirmation contradicted it sharply. The current research-best remains:

```text
outputs/CANDIDATE_PRIMARY_AUG40_REVERSE_OFF_FSD_STRICT_MICRO_JULOCT_PROFILE.set
```

## Purpose

This test tried to improve trade path quality without increasing exposure, adding dormant-month entries, or re-enabling Adaptive Reverse. The goal was to move beyond raw ATR stop behavior by exiting trades that failed to move favorably after entry.

## Model 2 Evidence

Source: `outputs/CURRENT_BEST_PATH_QUALITY_EXIT_LOG_SUMMARY.csv`

| Profile | Continuous | 2026 YTD | Full 2025 | Full 2024 | Worst Window | Losing Windows |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `base` | `6125.57` | `1107.90` | `214.18` | `2381.09` | `0.00` | `0` |
| `no_follow_soft` | `6928.70` | `1342.94` | `214.18` | `2138.88` | `0.00` | `0` |
| `mfe_failure_fast` | `6883.38` | `1150.65` | `214.18` | `2393.45` | `0.00` | `0` |
| `underwater_fast` | `6692.31` | `1339.09` | `214.18` | `2073.32` | `0.00` | `0` |

Model 2 initially made `no_follow_soft` look promotable.

## Model 0 Confirmation

Source: `outputs/CURRENT_BEST_NO_FOLLOW_MODEL0_PROBE_LOG_SUMMARY.csv`

| Profile | Parsed | Total Net | Continuous | Worst Window | Losing Windows |
| --- | ---: | ---: | ---: | ---: | ---: |
| `base` | `6 / 6` | `9580.99` | `6222.35` | `214.30` | `0` |
| `no_follow_soft` | `6 / 6` | `2684.59` | `485.92` | `0.00` | `0` |

Important Model 0 per-window contradiction:

```text
base 2024_to_2026:           6222.35
no_follow_soft 2024_to_2026:  485.92
```

The no-follow-through exit also removed March 2025 and March 2026 contribution in the Model 0 probe:

```text
no_follow_soft 2025_03: 0.00
no_follow_soft 2026_03: 0.00
```

## Interpretation

The Model 2 gain did not survive higher-fidelity confirmation. Promoting it would overfit to a faster tester mode and damage the current engine months.

Next direction should remain structural, but not via simple early-exit timers. Better candidates are:

- entry-specific structural stop placement,
- trade-lane-specific stop conflict handling,
- or a new entry source with independent Model 0 confirmation.
