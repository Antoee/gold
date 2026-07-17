# Independent M15 Volume-Climax Reversal Activity Discovery Decision

**Decision: REJECTED IN 2015-2020 DISCOVERY. No 2021+ holdout, Model 4 escalation, new best, or live approval was opened.**

The exact source was unchanged from the initial screen. This final pre-holdout extension varied only volume activity, minimum range, local-extreme strictness, session width, per-day activity, and one ADX neighbor around the volume-1.30 lead. The target remained the pre-signal daily VWAP capped by R and rejected below minimum RR. Stops remained beyond the climax wick, capped at `$6`, broker-sized at `0.10%` risk, with no forced minimum volume.

- Source SHA-256: `914C5F3832D61DFD3AD2E4F885C70EFBF35E35B6CFFFFE1B8387EDA96AC56A36`
- Compile: `0 errors, 0 warnings`
- Correct-source Model 1 reports: `45 / 45`; report/source identity: `45 / 45`
- Stale portable exports reproduced unchanged on alternate workers: `3`; all final reports contain the correct source identity
- Discovery profiles with at least one continuous trade: `15 / 15`
- Numeric gate passes: `0 / 15`
- Eligible profiles with a passing adjacent neighbor: `0 / 15`

| Candidate | 2015-18 | PF | Trades | 2019-20 | PF | Trades | Continuous | CAGR | PF | Trades | DD | Decision |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| `m15vcra_noext` | +$20.87 | 1.06 | 73 | +$91.33 | 1.48 | 44 | +$112.20 | 0.19% | 1.2 | 117 | 0.91% | REJECT_BEFORE_HOLDOUT |
| `m15vcra_max3` | +$73.23 | 1.31 | 50 | +$35.37 | 1.22 | 34 | +$107.17 | 0.18% | 1.27 | 84 | 0.95% | REJECT_BEFORE_HOLDOUT |
| `m15vcra_center` | +$73.23 | 1.31 | 50 | +$35.37 | 1.22 | 34 | +$107.17 | 0.18% | 1.27 | 84 | 0.95% | REJECT_BEFORE_HOLDOUT |
| `m15vcra_adx30` | +$71.79 | 1.27 | 56 | +$29.02 | 1.16 | 37 | +$101.02 | 0.17% | 1.22 | 93 | 0.95% | REJECT_BEFORE_HOLDOUT |
| `m15vcra_session422` | +$66.30 | 1.24 | 58 | +$33.96 | 1.19 | 37 | +$98.83 | 0.16% | 1.22 | 95 | 0.9% | REJECT_BEFORE_HOLDOUT |
| `m15vcra_ext4` | +$67.48 | 1.27 | 53 | +$27.36 | 1.16 | 35 | +$93.41 | 0.16% | 1.22 | 88 | 0.71% | REJECT_BEFORE_HOLDOUT |
| `m15vcra_vol140` | +$77.19 | 1.38 | 44 | +$13.53 | 1.09 | 31 | +$90.93 | 0.15% | 1.25 | 75 | 0.82% | REJECT_BEFORE_HOLDOUT |
| `m15vcra_vol120` | +$41.44 | 1.16 | 50 | +$38.02 | 1.2 | 40 | +$79.46 | 0.13% | 1.18 | 90 | 1.04% | REJECT_BEFORE_HOLDOUT |
| `m15vcra_vol150` | +$60.74 | 1.3 | 43 | +$0.93 | 1.01 | 30 | +$61.88 | 0.1% | 1.17 | 73 | 0.82% | REJECT_BEFORE_HOLDOUT |
| `m15vcra_session024` | +$37.59 | 1.13 | 61 | +$25.48 | 1.13 | 38 | +$61.64 | 0.1% | 1.13 | 99 | 0.9% | REJECT_BEFORE_HOLDOUT |
| `m15vcra_vol110` | +$19.10 | 1.07 | 55 | +$15.05 | 1.07 | 45 | +$34.15 | 0.06% | 1.07 | 100 | 1.12% | REJECT_BEFORE_HOLDOUT |
| `m15vcra_range100` | -$1.97 | 0.99 | 53 | +$29.55 | 1.16 | 37 | +$27.58 | 0.05% | 1.06 | 90 | 0.95% | REJECT_BEFORE_HOLDOUT |
| `m15vcra_vol100` | +$2.34 | 1.01 | 59 | +$15.05 | 1.07 | 45 | +$17.39 | 0.03% | 1.03 | 104 | 1.12% | REJECT_BEFORE_HOLDOUT |
| `m15vcra_range090` | -$29.27 | 0.9 | 56 | -$34.38 | 0.85 | 40 | -$64.29 | -0.11% | 0.88 | 96 | 1.03% | REJECT_BEFORE_HOLDOUT |
| `m15vcra_range080` | -$76.08 | 0.78 | 61 | -$70.24 | 0.73 | 44 | -$144.34 | -0.24% | 0.76 | 105 | 1.76% | REJECT_BEFORE_HOLDOUT |

The highest continuous row was `m15vcra_noext` at +$112.20, PF `1.2`, `117` trades, and `0.91%` drawdown. It did not satisfy the frozen broad-era, PF, activity, drawdown, and adjacent-neighbor contract, so recent data cannot be opened to rescue it.
