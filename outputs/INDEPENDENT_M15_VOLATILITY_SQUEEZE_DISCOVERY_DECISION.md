# Independent M15 Volatility-Squeeze Discovery Decision

**Decision: REJECTED IN 2015-2020 DISCOVERY. No 2021+ holdout, Model 4 escalation, new best, or live approval was opened.**

The standalone EA required consecutive M15 Bollinger bands inside a Keltner channel, then a closed fresh channel breakout with range, body, close-location, and expansion confirmation. H1 EMA alignment was the center regime; squeeze duration, Keltner width, breakout lookback, channel width, payoff, and trend length were isolated neighbors. Stops sat beyond the breakout candle, were capped at `$6`, used broker-native `OrderCalcProfit` sizing at `0.10%` risk, and never forced minimum volume.

- Source SHA-256: `A47F7A8ED05916A07A7CCF713340C64B1DFF950504E28744212EA8FD5CA94F29`
- Compile: `0 errors, 0 warnings`
- Correct-source Model 1 reports: `45 / 45`; report/source identity: `45 / 45`
- Empty M0 exports reproduced unchanged: `4`; all final reports contain the correct source identity
- Discovery profiles with at least one continuous trade: `15 / 15`
- Numeric gate passes: `0 / 15`
- Eligible profiles with a passing adjacent neighbor: `0 / 15`

| Candidate | 2015-18 | PF | Trades | 2019-20 | PF | Trades | Continuous | CAGR | PF | Trades | DD | Decision |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| `m15sq_break8` | +$98.71 | 1.38 | 55 | +$81.19 | 1.57 | 33 | +$177.89 | 0.29% | 1.44 | 88 | 0.48% | REJECT_BEFORE_HOLDOUT |
| `m15sq_tp200` | +$79.63 | 1.41 | 39 | +$71.30 | 1.9 | 21 | +$149.04 | 0.25% | 1.55 | 60 | 0.66% | REJECT_BEFORE_HOLDOUT |
| `m15sq_channel275` | +$51.89 | 1.32 | 34 | +$70.41 | 2.34 | 17 | +$122.16 | 0.2% | 1.56 | 51 | 0.35% | REJECT_BEFORE_HOLDOUT |
| `m15sq_center` | +$52.02 | 1.27 | 39 | +$58.13 | 1.74 | 21 | +$110.01 | 0.18% | 1.4 | 60 | 0.44% | REJECT_BEFORE_HOLDOUT |
| `m15sq_tp125` | +$56.70 | 1.31 | 40 | +$37.48 | 1.42 | 22 | +$95.74 | 0.16% | 1.35 | 62 | 0.46% | REJECT_BEFORE_HOLDOUT |
| `m15sq_kc140` | +$62.00 | 1.49 | 28 | +$27.35 | 1.64 | 11 | +$89.21 | 0.15% | 1.52 | 39 | 0.37% | REJECT_BEFORE_HOLDOUT |
| `m15sq_kc160` | +$41.80 | 1.18 | 46 | +$43.48 | 1.4 | 25 | +$85.28 | 0.14% | 1.25 | 71 | 0.62% | REJECT_BEFORE_HOLDOUT |
| `m15sq_trend50` | +$61.84 | 1.34 | 38 | +$20.94 | 1.24 | 20 | +$84.65 | 0.14% | 1.31 | 58 | 0.57% | REJECT_BEFORE_HOLDOUT |
| `m15sq_exp130` | +$61.60 | 1.65 | 22 | +$14.34 | 1.18 | 16 | +$77.81 | 0.13% | 1.44 | 38 | 0.72% | REJECT_BEFORE_HOLDOUT |
| `m15sq_break16` | +$28.43 | 1.2 | 29 | +$38.38 | 1.86 | 12 | +$66.81 | 0.11% | 1.35 | 41 | 0.57% | REJECT_BEFORE_HOLDOUT |
| `m15sq_trend200` | -$3.62 | 0.98 | 40 | +$64.79 | 1.75 | 23 | +$61.17 | 0.1% | 1.2 | 63 | 0.72% | REJECT_BEFORE_HOLDOUT |
| `m15sq_sq4` | +$31.73 | 1.2 | 30 | +$9.94 | 1.1 | 20 | +$41.67 | 0.07% | 1.16 | 50 | 0.6% | REJECT_BEFORE_HOLDOUT |
| `m15sq_sq2` | -$22.33 | 0.9 | 39 | +$12.67 | 1.12 | 21 | -$9.66 | -0.02% | 0.97 | 60 | 0.81% | REJECT_BEFORE_HOLDOUT |
| `m15sq_exp090` | -$80.32 | 0.76 | 55 | +$16.16 | 1.12 | 31 | -$64.26 | -0.11% | 0.86 | 86 | 1.5% | REJECT_BEFORE_HOLDOUT |
| `m15sq_notrend` | -$153.11 | 0.68 | 76 | +$27.62 | 1.12 | 49 | -$127.72 | -0.21% | 0.82 | 125 | 2.22% | REJECT_BEFORE_HOLDOUT |

The highest continuous row was `m15sq_break8` at +$177.89, PF `1.44`, `88` trades, and `0.48%` drawdown. It did not satisfy the frozen broad-era, PF, activity, drawdown, and adjacent-neighbor contract, so recent data cannot be opened to rescue it.
