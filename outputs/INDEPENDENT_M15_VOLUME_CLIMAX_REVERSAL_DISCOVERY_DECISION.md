# Independent M15 Volume-Climax Reversal Discovery Decision

**Decision: REJECTED IN 2015-2020 DISCOVERY. No 2021+ holdout, Model 4 escalation, new best, or live approval was opened.**

The standalone EA required an M15 tick-volume climax, ATR-sized rejection candle, fresh local extreme, and meaningful deviation from the day anchored VWAP. The center avoided strongly trending H1 ADX/EMA-distance phases; volume, range, wick, deviation, ADX, extreme lookback, payoff, and phase use were isolated neighbors. The target was the pre-signal daily VWAP capped by R and rejected below minimum RR. Stops sat beyond the climax wick, were capped at `$6`, used broker-native `OrderCalcProfit` sizing at `0.10%` risk, and never forced minimum volume.

- Source SHA-256: `914C5F3832D61DFD3AD2E4F885C70EFBF35E35B6CFFFFE1B8387EDA96AC56A36`
- Compile: `0 errors, 0 warnings`
- Correct-source Model 1 reports: `45 / 45`; report/source identity: `45 / 45`
- Stale portable exports reproduced unchanged on alternate workers: `5`; all final reports contain the correct source identity
- Discovery profiles with at least one continuous trade: `15 / 15`
- Numeric gate passes: `0 / 15`
- Eligible profiles with a passing adjacent neighbor: `0 / 15`

| Candidate | 2015-18 | PF | Trades | 2019-20 | PF | Trades | Continuous | CAGR | PF | Trades | DD | Decision |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| `m15vcr_vol130` | +$73.23 | 1.31 | 50 | +$35.37 | 1.22 | 34 | +$107.17 | 0.18% | 1.27 | 84 | 0.95% | REJECT_BEFORE_HOLDOUT |
| `m15vcr_rr125` | +$69.69 | 1.4 | 39 | +$18.69 | 1.13 | 29 | +$88.59 | 0.15% | 1.28 | 68 | 0.71% | REJECT_BEFORE_HOLDOUT |
| `m15vcr_wick55` | +$67.28 | 1.36 | 40 | +$20.20 | 1.15 | 28 | +$87.69 | 0.15% | 1.27 | 68 | 0.68% | REJECT_BEFORE_HOLDOUT |
| `m15vcr_dev060` | +$60.74 | 1.3 | 43 | +$0.93 | 1.01 | 30 | +$61.88 | 0.1% | 1.17 | 73 | 0.82% | REJECT_BEFORE_HOLDOUT |
| `m15vcr_center` | +$60.74 | 1.3 | 43 | +$0.93 | 1.01 | 30 | +$61.88 | 0.1% | 1.17 | 73 | 0.82% | REJECT_BEFORE_HOLDOUT |
| `m15vcr_dev030` | +$60.74 | 1.3 | 43 | +$0.93 | 1.01 | 30 | +$61.88 | 0.1% | 1.17 | 73 | 0.82% | REJECT_BEFORE_HOLDOUT |
| `m15vcr_ext12` | +$69.84 | 1.36 | 42 | -$10.27 | 0.93 | 29 | +$59.78 | 0.1% | 1.17 | 71 | 0.82% | REJECT_BEFORE_HOLDOUT |
| `m15vcr_ext4` | +$54.99 | 1.25 | 46 | -$7.08 | 0.96 | 31 | +$48.12 | 0.08% | 1.12 | 77 | 0.81% | REJECT_BEFORE_HOLDOUT |
| `m15vcr_range130` | +$39.63 | 1.27 | 31 | +$7.95 | 1.08 | 20 | +$46.58 | 0.08% | 1.19 | 51 | 0.85% | REJECT_BEFORE_HOLDOUT |
| `m15vcr_adx22` | +$47.36 | 1.37 | 28 | -$3.70 | 0.96 | 17 | +$43.87 | 0.07% | 1.2 | 45 | 0.65% | REJECT_BEFORE_HOLDOUT |
| `m15vcr_adx34` | +$44.25 | 1.18 | 50 | -$33.02 | 0.83 | 37 | +$9.38 | 0.02% | 1.02 | 87 | 1.14% | REJECT_BEFORE_HOLDOUT |
| `m15vcr_vol170` | +$51.54 | 1.31 | 35 | -$43.63 | 0.67 | 23 | +$4.42 | 0.01% | 1.01 | 58 | 0.79% | REJECT_BEFORE_HOLDOUT |
| `m15vcr_wick35` | +$25.29 | 1.11 | 47 | -$23.29 | 0.87 | 32 | +$3.64 | 0.01% | 1.01 | 79 | 0.99% | REJECT_BEFORE_HOLDOUT |
| `m15vcr_range090` | -$21.62 | 0.92 | 47 | -$3.33 | 0.98 | 35 | -$23.95 | -0.04% | 0.95 | 82 | 1.05% | REJECT_BEFORE_HOLDOUT |
| `m15vcr_nophase` | -$219.44 | 0.8 | 201 | +$26.80 | 1.05 | 103 | -$180.50 | -0.3% | 0.89 | 304 | 3.2% | REJECT_BEFORE_HOLDOUT |

The highest continuous row was `m15vcr_vol130` at +$107.17, PF `1.27`, `84` trades, and `0.95%` drawdown. It did not satisfy the frozen broad-era, PF, activity, drawdown, and adjacent-neighbor contract, so recent data cannot be opened to rescue it.
