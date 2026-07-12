# Engine Month Expansion Rejection Note

Date: 2026-07-11

## Decision

Do not promote the March/May engine-month expansion tests.

The current research-best remains:

```text
outputs/CANDIDATE_PRIMARY_AUG40_REVERSE_OFF_FSD_STRICT_MICRO_JULOCT_PROFILE.set
```

## Purpose

The strategy's reliable production is concentrated in March, May, August, July, and October. This test tried to increase return by expanding risk and exits only where the EA already has proven edge, instead of forcing new trades into dormant months.

## Package

- Builder: `work/build_current_best_engine_month_expansion_package.ps1`
- Broad summary: `outputs/CURRENT_BEST_ENGINE_MONTH_EXPANSION_LOG_SUMMARY.csv`
- Fine May ladder summary: `outputs/CURRENT_BEST_MAY_FINE_LADDER_LOG_SUMMARY.csv`

## Broad Expansion Results

| Profile | Continuous | 2026 YTD | Full 2025 | Full 2024 | Worst Window | Losing Windows |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `base` | `6125.57` | `1107.90` | `214.18` | `2381.09` | `0.00` | `0` |
| `may_r300` | `6648.63` | `1116.41` | `214.18` | `2374.19` | `-37.31` | `1` |
| `may_r320` | `963.34` | `4292.89` | `214.18` | `963.34` | `-207.86` | `1` |
| `march_r125` | `198.47` | `692.82` | `262.01` | `-42.50` | `-122.22` | `2` |
| `march_r150` | `397.07` | `901.63` | `-5.66` | `397.07` | `-5.66` | `2` |
| `march_tp120` | `6125.57` | `1107.90` | `214.18` | `2381.09` | `0.00` | `0` |
| `march_may_tp120` | `6125.57` | `1107.90` | `214.18` | `2381.09` | `0.00` | `0` |
| `runner_stretch` | `6125.57` | `1107.90` | `214.18` | `2381.09` | `0.00` | `0` |

`may_r300` was the only broad improvement, but it flipped May 2024 from profit to loss:

```text
base 2024_05:     209.80
may_r300 2024_05: -37.31
```

## Fine May Ladder Results

| Profile | Continuous | 2026 YTD | Full 2025 | Full 2024 | Worst Window | Losing Windows |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `base` | `6125.57` | `1107.90` | `214.18` | `2381.09` | `0.00` | `0` |
| `may_r285` | `6088.09` | `1107.90` | `214.18` | `2380.18` | `-35.49` | `1` |
| `may_r290` | `6084.63` | `1128.69` | `214.18` | `2379.67` | `-36.40` | `1` |
| `may_r295` | `6088.57` | `1122.55` | `214.18` | `2375.10` | `-37.31` | `1` |
| `may_r300` | `6648.63` | `1116.41` | `214.18` | `2374.19` | `-37.31` | `1` |

No May risk value above the current `2.80` survived the no-losing-window gate.

## Interpretation

The current March/May month-day window is already narrow (`MarchMaxDay=10`, `MayMaxDay=10`). Raising March risk damages 2024 and 2025. Raising May risk introduces a May 2024 loss. Quality TP and runner stretch did not improve the tested windows.

The next useful direction is not a simple risk multiplier increase. It should be either:

- a new entry source with independent positive evidence, or
- a structural exit/stop improvement that changes trade path quality without increasing exposure.
