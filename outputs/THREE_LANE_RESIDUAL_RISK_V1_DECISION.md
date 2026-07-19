# Three-Lane Residual-Risk V1 Decision

**Decision: REJECTED AFTER PAIRED MODEL 4 REAL TICKS. NO NEW BEST.**

Residual-risk V1 was a strategy-code change, not a static risk preset. When enabled, it used currently unused protected account risk up to fixed per-lane ceilings while preserving the `0.75%` account-wide cap, initial stops, daily/weekly/monthly limits, `5%` equity-drawdown limit, post-fill reconciliation, and real-account lock. It never used prior wins, losses, or drawdown to size a trade.

- Source SHA-256: `6FCAF941E0BA5BFD30C7286CFD9037D31912232D3BF40E020F672A67433ED53E`
- Exact portable EX5 SHA-256: `F943AF92289FE250632D3CE718EB29A51D284A63EA7773522B5A72C744596F0F`
- Compile: `0 errors, 0 warnings`
- Controlled evidence: `56 / 56` reports, one worker per matrix, one pinned binary, zero runner errors
- Feature default: disabled

## Calibration

The pre-2021 Model 1 calibration selected RV maximum `0.45%`, momentum maximum `0.20%`, adaptive-trend maximum `0.30%`, and residual reserve `0.05%`.

| Profile | Net | Total increase | CAGR | PF | Trades | Max DD | Recovery | Return/DD |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Disabled control | +$1,191.69 | +11.92% | +1.89%/yr | 1.77 | 265 | 1.02% | 10.58 | 11.69 |
| Selected V1 | +$1,710.62 | +17.11% | +2.67%/yr | 1.69 | 290 | 1.45% | 11.14 | 11.80 |

Adaptive ceilings from `0.25%` through `0.325%` and reserve values from `0.025%` through `0.075%` supplied local calibration support.

## Later Period

The 2021-2026 Model 1 historical cross-period check was profitable but mixed.

| Window | Control net | Selected net | Control CAGR | Selected CAGR | Control PF | Selected PF | Control DD | Selected DD |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| 2021-2022 | +$345.09 | +$313.42 | +1.71%/yr | +1.56%/yr | 1.77 | 1.38 | 1.15% | 1.61% |
| 2023-2026 | +$601.99 | +$1,046.43 | +1.67%/yr | +2.86%/yr | 2.28 | 2.32 | 1.20% | 1.74% |
| 2021-2026 continuous | +$944.62 | +$1,421.71 | +1.65%/yr | +2.44%/yr | 2.01 | 1.88 | 1.23% | 1.77% |

These dates have informed earlier portfolio research, so this is historical cross-period evidence rather than pristine out-of-sample evidence.

## Model 4 Rejection

Paired real-tick testing used identical eras, `$10,000` restarts, the same source, and one exact EX5 identity.

| Window | Profile | Net | Total increase | CAGR | PF | Trades | Max DD | Recovery | Return/DD |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|
| 2015-2018 | Control | +$856.18 | +8.56% | +2.08%/yr | 1.79 | 187 | 1.01% | 8.07 | 8.48 |
| 2015-2018 | V1 | +$1,012.80 | +10.13% | +2.44%/yr | 1.58 | 204 | 1.46% | 6.57 | 6.94 |
| 2019-2022 | Control | +$572.09 | +5.72% | +1.40%/yr | 1.68 | 131 | 1.17% | 4.80 | 4.89 |
| 2019-2022 | V1 | +$640.18 | +6.40% | +1.56%/yr | 1.45 | 167 | 1.60% | 3.86 | 4.00 |
| 2023-2026 | Control | +$602.11 | +6.02% | +1.67%/yr | 2.28 | 76 | 1.24% | 4.79 | 4.85 |
| 2023-2026 | V1 | +$1,046.62 | +10.47% | +2.86%/yr | 2.31 | 98 | 1.74% | 6.02 | 6.02 |
| 2015-2026 continuous | Control | +$2,105.08 | +21.05% | +1.67%/yr | 1.81 | 404 | 1.15% | 15.67 | 18.30 |
| 2015-2026 continuous | V1 | +$2,935.46 | +29.35% | +2.26%/yr | 1.68 | 475 | 1.94% | 12.85 | 15.13 |

V1 added `$830.38` and `0.59` percentage points of CAGR, but it failed the fixed risk-first gate: PF, maximum drawdown, recovery, and return/drawdown all worsened on the continuous real-tick path. Expanded sizing also made 71 additional minimum-lot signals tradable, changing the trade universe and weakening the middle era to PF `1.45`.

ATB150 remains the historical champion. No annual, stress, release, forward-registration, or real-account gate is open for V1. The frozen forward candidate and its invalid `$100,000` demo attachment are unchanged and count as zero valid forward days/trades.
