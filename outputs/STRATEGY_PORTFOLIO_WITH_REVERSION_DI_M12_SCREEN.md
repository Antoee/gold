# Strategy Portfolio With H1 DI -12 Reversion

This is an analytical realized-R screen, not a combined MT5 backtest or live approval.

- Grid rows: `700`
- Eligible rows: `0`
- Open-risk cap: `3.00%`
- Stress: `0.05R` deducted from every trade
- Reversion stream: `outputs\HTF_BAND_REVERSION_DI_M12_MODEL4_TRADES.csv`
- Exact reversion trades: `36`

## Stream Relationships

| Left | Right | Monthly R correlation | Same-side entries | Overlap pairs | Opposite overlaps |
| --- | --- | ---: | ---: | ---: | ---: |
| donchian | highprofit | 0.1433 | 0 | 32 | 6 |
| donchian | money | -0.0101 | 0 | 8 | 2 |
| donchian | reversion | -0.0833 | 0 | 9 | 4 |
| highprofit | money | -0.0740 | 0 | 1 | 0 |
| highprofit | reversion | -0.1578 | 0 | 2 | 2 |
| money | reversion | 0.1779 | 0 | 0 | 0 |

## Top Rows

| Profile | Eligible | Net | CAGR | PF | Risk-floor DD | Recovery | Red years | Stress red years | Worst 12m |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `hp1.00_mr1.50_dd0.00_rv0.50` | False | `$12,690.63` | 7.37% | 2.303 | 5.98% | 14.90 | 1 | 1 | `$-106.75` |
| `hp1.00_mr1.50_dd0.00_rv0.40` | False | `$12,049.52` | 7.10% | 2.288 | 5.98% | 14.44 | 1 | 1 | `$-95.86` |
| `hp1.00_mr1.25_dd0.00_rv0.50` | False | `$11,703.05` | 6.95% | 2.276 | 5.74% | 14.64 | 1 | 1 | `$-106.75` |
| `hp1.00_mr1.50_dd0.20_rv0.50` | False | `$13,078.35` | 7.53% | 2.241 | 6.06% | 15.09 | 2 | 2 | `$-180.14` |
| `hp1.00_mr1.50_dd0.10_rv0.50` | False | `$12,885.38` | 7.45% | 2.271 | 6.02% | 15.00 | 2 | 2 | `$-122.72` |
| `hp1.00_mr1.50_dd0.00_rv0.30` | False | `$11,423.10` | 6.83% | 2.272 | 5.98% | 13.97 | 1 | 1 | `$-85.11` |
| `hp1.00_mr1.50_dd0.30_rv0.50` | False | `$13,269.50` | 7.60% | 2.213 | 6.42% | 14.41 | 2 | 2 | `$-237.93` |
| `hp1.00_mr1.25_dd0.00_rv0.40` | False | `$11,089.84` | 6.69% | 2.260 | 5.74% | 14.16 | 1 | 1 | `$-95.86` |
| `hp1.00_mr1.00_dd0.00_rv0.50` | False | `$10,749.39` | 6.54% | 2.247 | 5.50% | 14.36 | 1 | 1 | `$-106.75` |
| `hp0.75_mr1.50_dd0.00_rv0.50` | False | `$10,567.98` | 6.46% | 2.350 | 5.58% | 10.81 | 1 | 1 | `$-92.25` |
| `hp1.00_mr1.25_dd0.20_rv0.50` | False | `$12,073.64` | 7.11% | 2.213 | 5.83% | 14.83 | 2 | 2 | `$-180.14` |
| `hp0.75_mr1.25_dd0.00_rv0.50` | False | `$9,672.66` | 6.05% | 2.322 | 4.89% | 11.76 | 1 | 1 | `$-92.25` |
| `hp1.00_mr1.25_dd0.10_rv0.50` | False | `$11,889.19` | 7.03% | 2.244 | 5.78% | 14.74 | 2 | 2 | `$-122.72` |
| `hp1.00_mr1.50_dd0.10_rv0.40` | False | `$12,238.87` | 7.18% | 2.255 | 6.02% | 14.53 | 2 | 2 | `$-109.91` |
| `hp1.00_mr1.50_dd0.20_rv0.40` | False | `$12,426.50` | 7.26% | 2.225 | 6.14% | 14.43 | 2 | 2 | `$-166.26` |
| `hp1.00_mr1.25_dd0.30_rv0.50` | False | `$12,256.35` | 7.19% | 2.185 | 6.09% | 14.43 | 2 | 2 | `$-237.93` |
| `hp1.00_mr1.50_dd0.30_rv0.40` | False | `$12,612.35` | 7.34% | 2.197 | 6.40% | 14.00 | 2 | 2 | `$-223.78` |
| `hp1.00_mr1.50_dd0.00_rv0.20` | False | `$10,811.13` | 6.57% | 2.255 | 5.98% | 13.50 | 1 | 1 | `$-74.49` |
| `hp1.00_mr1.25_dd0.00_rv0.30` | False | `$10,490.68` | 6.42% | 2.243 | 5.74% | 13.67 | 1 | 1 | `$-85.11` |
| `hp0.75_mr1.00_dd0.00_rv0.50` | False | `$8,808.11` | 5.63% | 2.289 | 4.39% | 15.14 | 1 | 1 | `$-92.25` |

## Gate

Eligibility requires zero red active years in base and stress, activity in every calendar year, at least 100 trades, PF at least 1.30, recovery at least 2.0, conservative drawdown no higher than 10%, and no single year supplying more than half of net profit.

A passing row would justify a true combined-EA Model4 test; it would not constitute live approval.
