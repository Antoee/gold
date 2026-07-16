# Strategy Portfolio With H1 DI -10 Reversion

This is an analytical realized-R screen, not a combined MT5 backtest or live approval.

- Grid rows: `700`
- Eligible rows: `0`
- Open-risk cap: `3.00%`
- Stress: `0.05R` deducted from every trade
- Reversion stream: `outputs\HTF_BAND_REVERSION_DI_M10_MODEL4_TRADES.csv`
- Exact reversion trades: `28`

## Stream Relationships

| Left | Right | Monthly R correlation | Same-side entries | Overlap pairs | Opposite overlaps |
| --- | --- | ---: | ---: | ---: | ---: |
| donchian | highprofit | 0.1433 | 0 | 32 | 6 |
| donchian | money | -0.0101 | 0 | 8 | 2 |
| donchian | reversion | -0.0168 | 0 | 6 | 3 |
| highprofit | money | -0.0740 | 0 | 1 | 0 |
| highprofit | reversion | -0.0511 | 0 | 0 | 0 |
| money | reversion | 0.0435 | 0 | 0 | 0 |

## Top Rows

| Profile | Eligible | Net | CAGR | PF | Risk-floor DD | Recovery | Red years | Stress red years | Worst 12m |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `hp1.00_mr1.50_dd0.00_rv0.50` | False | `$12,592.78` | 7.33% | 2.318 | 5.98% | 14.60 | 1 | 1 | `$-107.29` |
| `hp1.00_mr1.50_dd0.00_rv0.40` | False | `$11,972.11` | 7.07% | 2.301 | 5.98% | 14.20 | 1 | 1 | `$-96.25` |
| `hp1.00_mr1.25_dd0.00_rv0.50` | False | `$11,609.46` | 6.91% | 2.294 | 5.74% | 14.35 | 1 | 1 | `$-109.42` |
| `hp1.00_mr1.50_dd0.20_rv0.50` | False | `$12,977.15` | 7.48% | 2.253 | 6.06% | 14.79 | 2 | 2 | `$-180.14` |
| `hp1.00_mr1.50_dd0.10_rv0.50` | False | `$12,785.85` | 7.41% | 2.285 | 6.02% | 14.69 | 2 | 2 | `$-122.72` |
| `hp1.00_mr1.50_dd0.00_rv0.30` | False | `$11,365.71` | 6.81% | 2.282 | 5.98% | 13.80 | 1 | 1 | `$-85.37` |
| `hp1.00_mr1.50_dd0.30_rv0.50` | False | `$13,166.62` | 7.56% | 2.224 | 6.42% | 14.12 | 2 | 2 | `$-237.93` |
| `hp1.00_mr1.25_dd0.00_rv0.40` | False | `$11,015.80` | 6.66% | 2.275 | 5.74% | 13.93 | 1 | 1 | `$-96.25` |
| `hp1.00_mr1.00_dd0.00_rv0.50` | False | `$10,659.92` | 6.50% | 2.266 | 5.50% | 14.07 | 1 | 1 | `$-164.98` |
| `hp0.75_mr1.50_dd0.00_rv0.50` | False | `$10,480.21` | 6.42% | 2.376 | 5.58% | 10.59 | 1 | 1 | `$-92.72` |
| `hp1.00_mr1.25_dd0.20_rv0.50` | False | `$11,976.85` | 7.07% | 2.227 | 5.83% | 14.53 | 2 | 2 | `$-180.14` |
| `hp0.75_mr1.25_dd0.00_rv0.50` | False | `$9,588.71` | 6.01% | 2.351 | 4.89% | 11.52 | 1 | 1 | `$-92.72` |
| `hp1.00_mr1.50_dd0.20_rv0.40` | False | `$12,346.46` | 7.23% | 2.235 | 6.14% | 14.19 | 2 | 2 | `$-166.26` |
| `hp1.00_mr1.50_dd0.10_rv0.40` | False | `$12,160.14` | 7.15% | 2.267 | 6.02% | 14.30 | 2 | 2 | `$-110.35` |
| `hp1.00_mr1.25_dd0.10_rv0.50` | False | `$11,794.00` | 6.99% | 2.259 | 5.78% | 14.44 | 2 | 2 | `$-136.89` |
| `hp1.00_mr1.25_dd0.30_rv0.50` | False | `$12,157.95` | 7.15% | 2.197 | 6.09% | 14.14 | 2 | 2 | `$-237.93` |
| `hp1.00_mr1.50_dd0.00_rv0.20` | False | `$10,773.33` | 6.55% | 2.262 | 5.98% | 13.38 | 1 | 1 | `$-74.64` |
| `hp1.00_mr1.50_dd0.30_rv0.40` | False | `$12,531.00` | 7.30% | 2.206 | 6.40% | 13.77 | 2 | 2 | `$-223.78` |
| `hp1.00_mr1.25_dd0.00_rv0.30` | False | `$10,435.79` | 6.40% | 2.255 | 5.74% | 13.50 | 1 | 1 | `$-85.37` |
| `hp0.75_mr1.00_dd0.00_rv0.50` | False | `$8,727.85` | 5.59% | 2.321 | 4.39% | 14.81 | 1 | 1 | `$-92.72` |

## Gate

Eligibility requires zero red active years in base and stress, activity in every calendar year, at least 100 trades, PF at least 1.30, recovery at least 2.0, conservative drawdown no higher than 10%, and no single year supplying more than half of net profit.

A passing row would justify a true combined-EA Model4 test; it would not constitute live approval.
