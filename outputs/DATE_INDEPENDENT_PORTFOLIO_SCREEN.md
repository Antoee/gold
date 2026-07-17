# Date-Independent Portfolio Screen

This is an exact realized-R analytical screen, not a combined MT5 result or live approval.
The allocations and gate were frozen before the screen was run.

- Exact Donchian trades: `51`
- Exact H1 reversion trades: `41`
- Allocation rows: `5`
- Eligible rows: `0`
- Desired total initial risk: `0.50%`
- Open-risk cap: `1.00%`
- Execution stress: `0.05R` deducted per trade

## Relationship

| Monthly R correlation | Same-side entries | Overlap pairs | Opposite overlaps |
| ---: | ---: | ---: | ---: |
| -0.0753 | 0 | 9 | 4 |

## Results

| Profile | Eligible | Net | CAGR | PF | Risk-floor DD | Recovery | Red years | Stress red years | Worst 12m |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `dd0.175_rv0.325` | False | `$1,072.14` | 0.89% | 1.833 | 2.20% | 4.77 | 2 | 2 | `$-162.19` |
| `dd0.250_rv0.250` | False | `$928.72` | 0.77% | 1.698 | 2.44% | 3.72 | 2 | 2 | `$-181.84` |
| `dd0.100_rv0.400` | False | `$1,215.49` | 1.00% | 1.977 | 2.14% | 5.51 | 3 | 3 | `$-142.54` |
| `dd0.325_rv0.175` | False | `$785.27` | 0.66% | 1.571 | 2.69% | 2.85 | 2 | 2 | `$-206.32` |
| `dd0.400_rv0.100` | False | `$641.85` | 0.54% | 1.453 | 3.25% | 1.92 | 4 | 5 | `$-254.55` |

## Frozen Gate

A row needs zero red years in base and stress, activity in every year, at least 80 trades, positive older/middle/recent eras in base and stress, PF at least 1.30, stressed PF at least 1.10, conservative drawdown no higher than 5%, recovery at least 2.0, and no year supplying more than 40% of profit.

A passing row would only justify building and testing a combined EA on MT5 real ticks.
