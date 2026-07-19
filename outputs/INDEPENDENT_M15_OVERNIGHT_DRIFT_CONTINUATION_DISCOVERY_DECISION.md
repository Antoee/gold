# Independent M15 Overnight-Drift Continuation Discovery Decision

**Decision: 2015-2020 DISCOVERY GATE PASSED. A frozen holdout run is permitted, but no new best, Model 4 promotion, or live approval exists yet.**

The standalone EA tested whether a directional, high-efficiency prior day continues after a bounded Asian-session drift. It enters only during a fixed morning window after a completed M15 direction/body confirmation, uses the opposite Asian range for its stop, and forces an intraday exit. It retained a `$10,000` initial-balance contract, broker-native `OrderCalcProfit` sizing, minimum-lot refusal, account-wide exposure limits, drawdown locks, and disabled real-account trading.

- Source SHA-256: `B74E61CC7B473C03FCA79E1D8DC0C73C4512FCCF9596E439971E1D7C82149684`
- Compile: `0 errors, 0 warnings`
- Risk per accepted trade: `0.10%` on a `$10,000` test deposit
- Exported Model 1 reports: `45 / 45`
- Discovery windows: `2015-2018`, `2019-2020`, and continuous `2015-2020`
- Numeric gate passes: `9 / 15`
- Neighbor-supported eligible profiles: `9 / 15`

| Candidate | 2015-18 | PF | Trades | 2019-20 | PF | Trades | Continuous | CAGR | PF | Trades | DD | Decision |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| `odc_signal25` | +$127.97 | 1.29 | 128 | +$43.05 | 1.31 | 44 | +$171.41 | 0.28% | 1.3 | 172 | 0.68% | DISCOVERY_ELIGIBLE |
| `odc_entry8` | +$94.43 | 1.27 | 120 | +$49.02 | 1.45 | 41 | +$155.24 | 0.26% | 1.33 | 162 | 0.67% | DISCOVERY_ELIGIBLE |
| `odc_tp175` | +$119.30 | 1.28 | 120 | +$27.54 | 1.21 | 39 | +$153.68 | 0.25% | 1.28 | 159 | 0.9% | DISCOVERY_ELIGIBLE |
| `odc_prior020` | +$114.44 | 1.27 | 125 | +$33.18 | 1.24 | 41 | +$148.01 | 0.25% | 1.26 | 166 | 0.73% | DISCOVERY_ELIGIBLE |
| `odc_asian065` | +$94.94 | 1.23 | 119 | +$25.43 | 1.19 | 39 | +$120.76 | 0.2% | 1.22 | 158 | 0.73% | DISCOVERY_ELIGIBLE |
| `odc_driftminus025` | +$91.70 | 1.22 | 120 | +$25.43 | 1.19 | 39 | +$117.52 | 0.19% | 1.21 | 159 | 0.73% | DISCOVERY_ELIGIBLE |
| `odc_center` | +$90.87 | 1.22 | 120 | +$25.43 | 1.19 | 39 | +$116.69 | 0.19% | 1.21 | 159 | 0.73% | DISCOVERY_ELIGIBLE |
| `odc_priorbody35` | +$78.66 | 1.17 | 140 | +$38.84 | 1.23 | 49 | +$116.20 | 0.19% | 1.18 | 189 | 0.82% | REJECT_BEFORE_HOLDOUT |
| `odc_drift000` | +$114.12 | 1.36 | 98 | +$4.27 | 1.04 | 35 | +$115.04 | 0.19% | 1.26 | 133 | 0.67% | DISCOVERY_ELIGIBLE |
| `odc_tp125` | +$86.79 | 1.21 | 120 | +$19.62 | 1.15 | 39 | +$106.18 | 0.18% | 1.19 | 159 | 0.75% | REJECT_BEFORE_HOLDOUT |
| `odc_prior040` | +$72.46 | 1.19 | 111 | +$28.46 | 1.25 | 35 | +$100.92 | 0.17% | 1.2 | 146 | 0.59% | DISCOVERY_ELIGIBLE |
| `odc_asian045` | +$84.59 | 1.21 | 109 | +$9.31 | 1.07 | 37 | +$94.29 | 0.16% | 1.18 | 146 | 0.75% | REJECT_BEFORE_HOLDOUT |
| `odc_entry6` | +$87.31 | 1.27 | 103 | -$6.10 | 0.96 | 46 | +$84.95 | 0.14% | 1.17 | 149 | 0.78% | REJECT_BEFORE_HOLDOUT |
| `odc_priorbody55` | +$82.30 | 1.27 | 91 | -$7.12 | 0.93 | 27 | +$71.83 | 0.12% | 1.17 | 118 | 0.54% | REJECT_BEFORE_HOLDOUT |
| `odc_signal45` | +$94.62 | 1.24 | 114 | -$20.85 | 0.83 | 33 | +$67.23 | 0.11% | 1.13 | 144 | 0.93% | REJECT_BEFORE_HOLDOUT |

## Action

- Freeze the eligible profile identities before opening the 2021-2026 holdout.
- Require the holdout to remain profitable and preserve acceptable PF, activity, and drawdown before Model 4.
- Keep the released transferable portfolio unchanged until all escalation gates pass.
- Preserve the portable runner and exact report/source identity evidence.
