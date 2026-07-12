# High Efficiency Trend Model 0 Rejection Note

Date: 2026-07-11

## Decision

Do not promote the High Efficiency Trend lane variants.

The current research-best remains:

```text
outputs/CANDIDATE_PRIMARY_AUG40_REVERSE_OFF_FSD_STRICT_MICRO_JULOCT_PROFILE.set
```

## Purpose

This probe tested whether the inactive High Efficiency Trend lane could add robust structure-based momentum trades without re-enabling Adaptive Reverse or increasing the proven March/May/August risk profile.

The run used Model 0 and included strict engine-only, moderate engine-only, and strict flat-month-bypass variants.

## Evidence

Source: `outputs/CURRENT_BEST_HET_MODEL0_PROBE_LOG_SUMMARY.csv`

| Profile | Parsed | Total Net | Continuous | Worst Window | Losing Windows |
| --- | ---: | ---: | ---: | ---: | ---: |
| `base` | `8 / 8` | `9580.99` | `6222.35` | `0.00` | `0` |
| `het_engine_strict` | `8 / 8` | `8816.44` | `5457.80` | `0.00` | `0` |
| `het_engine_mid` | `8 / 8` | `8816.44` | `5457.80` | `0.00` | `0` |
| `het_flat_strict` | `8 / 8` | `8804.00` | `5445.36` | `0.00` | `0` |

Single engine-month checks were unchanged:

```text
2024_03: 1497.84
2024_05:  214.91
2025_03:  214.30
2026_03:  945.67
2026_05:  485.92
```

Flat guard months stayed inactive:

```text
2025_04: 0.00
2026_01: 0.00
```

## Interpretation

HET did not improve the known engine months and did not rescue the dormant guard months. Its only material effect was to reduce the full continuous Model 0 run by roughly `764.55` to `776.99`.

That suggests the lane is adding weaker trades or creating unfavorable interactions outside the core month slices. Since it lowers continuous profit without improving any targeted validation window, it should not be promoted.

## Next Direction

The next useful test should avoid broad momentum add-ons and focus on a narrowly isolated source of additional edge:

- month-specific entry unlocks only where the full run has unused opportunity,
- lane-specific structural stop placement that does not remove March/May winners,
- or a compact Model 0-first test of session/range breakout features with explicit inactive-month guard windows.
