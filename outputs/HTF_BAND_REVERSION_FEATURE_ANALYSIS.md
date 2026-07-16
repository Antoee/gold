# H1 Band Reversion Feature Analysis

This is a hypothesis-generation screen over exact Model4 trades, not promotion evidence.

- Exact joined trades: `41`
- Baseline: `26.7375R`, PF `2.1861`, red years `4`
- Baseline 0.05R stress: `24.6875R`, PF `2.0442`, red years `4`
- One-factor gates screened: `86`
- Diagnostic gate passes: `0`

## Feature Separation

| Feature | All median | Winner median | Loser median | Red-year median | Winner mean | Loser mean |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| RSI | 60.4 | 39.8 | 60.4 | 60.4 | 49.8474 | 53.7727 |
| BandWidthATR | 3.15 | 3.19 | 3.1 | 2.82 | 3.1921 | 3.0886 |
| ADX | 20.07 | 20.3 | 19.235 | 19.02 | 19.2679 | 19.6486 |
| ADXDelta | -0.42 | -0.59 | 0.135 | 0.35 | -1.2116 | -0.9214 |
| DIEdge | -7.78 | -7.44 | -9.875 | -10.07 | -6.9305 | -9.055 |
| ATRRatio | 1.176 | 1.231 | 1.1085 | 1.263 | 1.2996 | 1.1458 |
| TrendDistATR | -4.03 | -3.048 | -4.828 | -4.043 | -2.9715 | -4.4208 |
| TrendSlopeATR | -0.168 | -0.139 | -0.2335 | -0.182 | -0.1233 | -0.2025 |
| FastTrendDistATR | -3.31 | -2.63 | -3.719 | -3.252 | -2.9521 | -3.4811 |
| MTFDistATR | -4.03 | -3.048 | -4.828 | -4.043 | -2.9715 | -4.4208 |
| BodyPct | 26.8 | 33.2 | 20.95 | 21.4 | 34.1263 | 22.85 |
| WickPct | 49.7 | 48.3 | 51.75 | 54.3 | 44.3 | 51.4773 |
| CloseLoc | 0.407 | 0.559 | 0.371 | 0.419 | 0.5292 | 0.4439 |
| StopATR | 0.968 | 1.086 | 0.907 | 0.945 | 1.1817 | 0.9169 |
| TargetATR | 2.467 | 2.454 | 2.5985 | 2.269 | 2.8972 | 2.5595 |
| TradeRR | 2.613 | 2.236 | 2.615 | 2.297 | 2.6072 | 2.8802 |
| SpreadATRPct | 2.63 | 1.61 | 3.525 | 3.45 | 3.8316 | 5.3014 |
| RSIDepth | 12.2 | 12.7 | 11.75 | 12.2 | 12.5947 | 12.2727 |
| AbsTrendDistATR | 4.043 | 3.048 | 5.1305 | 4.512 | 3.0588 | 5.2102 |
| AbsTrendSlopeATR | 0.182 | 0.139 | 0.2425 | 0.185 | 0.1435 | 0.2522 |

## Top One-Factor Gates

| Gate | Diagnostic pass | Trades | Net R | PF | Red years | Stress red years | Discovery R | Recent R |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `DIEdge>=0` | False | 1 | 1.8899 | inf | 0 | 0 | 1.8899 | 0 |
| `DIEdge>=5` | False | 0 | 0 | inf | 0 | 0 | 0 | 0 |
| `DIEdge>=-10` | False | 27 | 29.4476 | 3.5666 | 1 | 1 | 20.4397 | 9.0079 |
| `AbsTrendSlopeATR<=0.2` | False | 23 | 26.2103 | 3.7908 | 1 | 1 | 17.6615 | 8.5488 |
| `BodyPct>=30` | False | 18 | 20.1817 | 4.3322 | 1 | 1 | 16.705 | 3.4766 |
| `ADXDelta<=0` | False | 24 | 22.7619 | 3.0038 | 1 | 1 | 19.1838 | 3.5782 |
| `TargetATR>=2` | False | 31 | 23.1457 | 2.326 | 1 | 1 | 13.8538 | 9.2918 |
| `RSIDepth>=12` | False | 21 | 21.7214 | 3.0802 | 1 | 1 | 14.3192 | 7.4022 |
| `ADX<=18` | False | 8 | 17.0259 | 9.2523 | 1 | 1 | 9.0994 | 7.9265 |
| `StopATR>=0.8` | False | 32 | 21.3517 | 2.2976 | 1 | 1 | 10.8102 | 10.5415 |
| `BandWidthATR<=3.5` | False | 26 | 21.3676 | 2.5133 | 1 | 1 | 15.1695 | 6.1981 |
| `RSIDepth>=13` | False | 15 | 17.8724 | 3.4047 | 1 | 1 | 9.9327 | 7.9397 |
| `TradeRR<=2` | False | 10 | 11.3666 | 6.569 | 1 | 1 | 5.8802 | 5.4864 |
| `TargetATR>=2.5` | False | 20 | 17.3449 | 2.5217 | 1 | 1 | 14.3274 | 3.0175 |
| `RSIDepth>=15` | False | 5 | 4.646 | 2.382 | 1 | 1 | 4.646 | 0 |
| `ADXDelta<=-10` | False | 2 | -2.2829 | 0.0 | 1 | 1 | -2.2829 | 0 |
| `AbsTrendSlopeATR<=0.3` | False | 30 | 30.6031 | 3.2793 | 2 | 2 | 18.1823 | 12.4208 |
| `AbsTrendDistATR<=8` | False | 37 | 30.8319 | 2.6713 | 2 | 2 | 19.4243 | 11.4076 |
| `AbsTrendSlopeATR<=0.4` | False | 37 | 30.8319 | 2.6713 | 2 | 2 | 19.4243 | 11.4076 |
| `StopATR>=1` | False | 19 | 24.3319 | 4.9797 | 2 | 2 | 17.2471 | 7.0848 |
| `TargetATR>=1.75` | False | 38 | 29.7751 | 2.5266 | 2 | 2 | 18.3344 | 11.4407 |
| `RSIDepth>=11` | False | 30 | 29.133 | 3.0152 | 2 | 2 | 16.6791 | 12.4539 |
| `AbsTrendDistATR<=6` | False | 29 | 27.1981 | 3.0257 | 2 | 2 | 18.1823 | 9.0158 |
| `ADXDelta<=1` | False | 29 | 26.703 | 2.8468 | 2 | 2 | 16.0843 | 10.6187 |
| `AbsTrendDistATR<=4` | False | 19 | 22.8738 | 4.096 | 2 | 2 | 16.9606 | 5.9133 |

Any selected gate must be predeclared as a small neighboring MT5 parameter test and pass continuous plus yearly Model4. Offline filtering alone cannot change the strategy decision.
