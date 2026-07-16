# DGF Adverse-R Failure Trade Diagnostic

Model 1 diagnostic evidence only. Failed years are compared with profitable controls; calendar labels are not proposed as trading rules.

## Report Reconciliation

| Window | Class | Trades | Logged net | MT5 net | Difference | PF | Win rate |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `2019_good` | good | 7 | 427.27 | 427.27 | 0 | 1.61 | 42.86% |
| `2020_good` | good | 27 | 4945.49 | 4945.49 | 0 | 3.35 | 51.85% |
| `2021_fail` | fail | 13 | -752.15 | -752.15 | 0 | 0.42 | 30.77% |
| `2022_good` | good | 17 | 412.46 | 412.46 | 0 | 1.31 | 41.18% |
| `2023_fail` | fail | 22 | -787.59 | -787.59 | 0 | 0.6 | 36.36% |
| `2024_good` | good | 20 | 3135.04 | 3135.04 | 0 | 2.14 | 40% |
| `2025_fail` | fail | 16 | -635.39 | -635.39 | 0 | 0.57 | 43.75% |

## entry family By Year Class

| Class | Value | Trades | Net | PF | Win rate | Average |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| fail | `dgf_only` | 24 | 656.6 | 1.79 | 45.83% | 27.36 |
| fail | `liquidity_only` | 25 | -3036.87 | 0.23 | 24% | -121.47 |
| fail | `other` | 2 | 205.14 | INF | 100% | 102.57 |
| good | `dgf_only` | 55 | 7637.54 | 2.49 | 45.45% | 138.86 |
| good | `liquidity_only` | 16 | 1282.72 | 1.72 | 43.75% | 80.17 |

## side By Year Class

| Class | Value | Trades | Net | PF | Win rate | Average |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| fail | `buy` | 23 | -1389.57 | 0.38 | 34.78% | -60.42 |
| fail | `sell` | 28 | -785.56 | 0.69 | 39.29% | -28.06 |
| good | `buy` | 49 | 8323.16 | 3.16 | 46.94% | 169.86 |
| good | `sell` | 22 | 597.1 | 1.2 | 40.91% | 27.14 |

## hour block By Year Class

| Class | Value | Trades | Net | PF | Win rate | Average |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| fail | `06_11` | 28 | -1296.1 | 0.47 | 32.14% | -46.29 |
| fail | `12_17` | 23 | -879.03 | 0.62 | 43.48% | -38.22 |
| good | `06_11` | 53 | 3361.95 | 1.59 | 41.51% | 63.43 |
| good | `12_17` | 18 | 5558.31 | 5.79 | 55.56% | 308.79 |

## exit type By Year Class

| Class | Value | Trades | Net | PF | Win rate | Average |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| fail | `adverse_r` | 10 | -1370.6 | 0 | 0% | -137.06 |
| fail | `mfe_giveback` | 1 | 81.9 | INF | 100% | 81.9 |
| fail | `stop_loss` | 32 | -2341.48 | 0.31 | 31.25% | -73.17 |
| fail | `take_profit` | 8 | 1455.05 | INF | 100% | 181.88 |
| good | `adverse_r` | 11 | -2439.49 | 0 | 0% | -221.77 |
| good | `mfe_giveback` | 1 | 272.7 | INF | 100% | 272.7 |
| good | `stop_loss` | 40 | -2185.72 | 0.51 | 30% | -54.64 |
| good | `take_profit` | 19 | 13272.77 | INF | 100% | 698.57 |

## Guardrail

A next-step feature must describe market state, improve failed and profitable controls together, retain adequate activity, and pass the broad and annual gates. Removing losing calendar years directly is rejected as overfit.
