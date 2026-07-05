# Loss-Control Ranking

Generated from existing CSV result windows only. No MT5 process was launched.

This report prioritizes profiles that make money while avoiding losing windows. Headline tables require at least 7 windows, so one-off probes cannot outrank validated profiles.

## Best General No-Loss Profiles

| Rank | Profile | Set | Total | Worst | Losing | Max Seq DD | Profit/DD | Windows |
| ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 2 | `BOS_SWEEP_SPLITS_risk1p6_sl18_tp35` | split | 2354.65 | 0 | 0 | 0 | 999 | 9 |
| 3 | `BOS_SWEEP_SPLITS_risk2` | split | 965.16 | 0 | 0 | 0 | 999 | 9 |
| 4 | `BOS_SWEEP_WINDOWS_risk1p6_sl18_tp35` | quarter | 744.03 | 0 | 0 | 0 | 999 | 10 |
| 5 | `BOS_SWEEP_WINDOWS_risk1p6_sl18_tp35` | month | 744.03 | 0 | 0 | 0 | 999 | 30 |
| 6 | `BOS_SWEEP_WINDOWS_risk2` | quarter | 321.72 | 0 | 0 | 0 | 999 | 10 |
| 7 | `BOS_SWEEP_WINDOWS_risk2` | month | 321.72 | 0 | 0 | 0 | 999 | 30 |

## Best Low-Loss Research Profiles

| Rank | Profile | Set | Total | Worst | Losing | Gross Loss | Profit/Loss | Windows |
| ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 2 | `BOS_SWEEP_SPLITS_risk1p6_sl18_tp35` | split | 2354.65 | 0 | 0 | 0 | 999 | 9 |
| 3 | `BOS_SWEEP_SPLITS_risk2` | split | 965.16 | 0 | 0 | 0 | 999 | 9 |
| 4 | `BOS_SWEEP_WINDOWS_risk1p6_sl18_tp35` | quarter | 744.03 | 0 | 0 | 0 | 999 | 10 |
| 5 | `BOS_SWEEP_WINDOWS_risk1p6_sl18_tp35` | month | 744.03 | 0 | 0 | 0 | 999 | 30 |
| 6 | `BOS_SWEEP_WINDOWS_risk2` | quarter | 321.72 | 0 | 0 | 0 | 999 | 10 |
| 7 | `BOS_SWEEP_WINDOWS_risk2` | month | 321.72 | 0 | 0 | 0 | 999 | 30 |
| 30 | `MOMENTUM_SWEEP` | split | 2113.53 | -15.49 | 1 | 15.49 | 136.44 | 9 |
| 32 | `BOS_SWEEP` | quarter | 157.38 | -49.92 | 1 | 49.92 | 3.15 | 10 |
| 33 | `BOS_SWEEP` | month | 157.38 | -49.92 | 1 | 49.92 | 3.15 | 30 |
| 34 | `BOS_SWEEP_SPLITS_risk1` | split | 922.64 | -99.84 | 1 | 99.84 | 9.24 | 9 |
| 35 | `BOS_SWEEP_WINDOWS_risk1` | quarter | 314.76 | -99.84 | 1 | 99.84 | 3.15 | 10 |
| 36 | `BOS_SWEEP_WINDOWS_risk1` | month | 314.76 | -99.84 | 1 | 99.84 | 3.15 | 30 |

## Date-Block Benchmarks

These can be useful profit references, but they should not be promoted unless replaced by general market-regime rules.

| Rank | Profile | Set | Total | Worst | Losing | Windows |
| ---: | --- | --- | ---: | ---: | ---: | ---: |
| 1 | `SECOND_BUY_BLOCK_STANDARD_REAL_TICK` | window | 8290.89 | 0 | 0 | 9 |
| 31 | `DATE_BUY_BLOCK_STANDARD_REAL_TICK` | window | 8385.9 | -15.93 | 1 | 9 |

## Thin-Coverage Benchmarks

These are useful clues, not promotion candidates, because they have too few windows.

| Rank | Profile | Set | Total | Worst | Losing | Windows |
| ---: | --- | --- | ---: | ---: | ---: | ---: |
| 8 | `block_sells_2025h2_full` | window | 2989.54 | 2989.54 | 0 | 1 |
| 9 | `slope250_full` | window | 2861.98 | 2861.98 | 0 | 1 |
| 10 | `slope500_full` | window | 2367.92 | 2367.92 | 0 | 1 |
| 11 | `conf3` | window | 607.25 | 607.25 | 0 | 1 |
| 12 | `REAL_TICK_WINDOW_RESULTS` | window | 2084.68 | 448.56 | 0 | 3 |
| 13 | `NO_BE_STRICT_LOSS_YEARLY_FULL_REAL_TICK` | window | 3605.04 | 231.16 | 0 | 4 |
| 14 | `adapt500_london_only` | window | 98.78 | 98.78 | 0 | 1 |
| 15 | `adapt500_sl18_tp27` | window | 486.11 | 91.05 | 0 | 3 |

## Rule Of Thumb

For the updated goal, do not promote a profile with any losing monthly, quarterly, or split windows unless it clearly beats the no-loss profile on profit and has a very small worst loss.
