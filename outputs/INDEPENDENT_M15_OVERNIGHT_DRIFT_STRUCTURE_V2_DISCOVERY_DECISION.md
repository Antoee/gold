# Independent M15 Overnight-Drift Structure V2 Discovery Decision

**Decision: REJECTED IN 2015-2020 DISCOVERY. No 2021+ holdout, Model 4 escalation, new best, or live approval was opened.**

The v2 standalone EA keeps the frozen prior-day and Asian-drift entry premise, but replaces the full Asian-range stop with a recent completed-M15 structure stop. The neighborhood varies only stop geometry plus three previously frozen signal/exit neighbors. It retains the `$8` affordability cap, broker-native `OrderCalcProfit` sizing, minimum-lot refusal, a `$10,000` balance contract, account-wide exposure limits, drawdown locks, and disabled real-account trading.

- Source SHA-256: `2E98481FBE42F58B61CB824652CA58FED62C0A005FD14EEB6C5B4110D4C56AE6`
- Compile: `0 errors, 0 warnings`
- Risk per accepted trade: `0.10%` on a `$10,000` test deposit
- Exported Model 1 reports: `39 / 39`
- Discovery windows: `2015-2018`, `2019-2020`, and continuous `2015-2020`
- Numeric gate passes: `0 / 13`
- Neighbor-supported eligible profiles: `0 / 13`

| Candidate | 2015-18 | PF | Trades | 2019-20 | PF | Trades | Continuous | CAGR | PF | Trades | DD | Decision |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| `ods2_entry8` | +$60.36 | 1.11 | 122 | +$63.13 | 1.33 | 51 | +$136.89 | 0.23% | 1.19 | 174 | 0.77% | REJECT_BEFORE_HOLDOUT |
| `ods2_lookback6` | +$102.56 | 1.19 | 124 | +$9.25 | 1.05 | 46 | +$114.17 | 0.19% | 1.15 | 170 | 1.02% | REJECT_BEFORE_HOLDOUT |
| `ods2_buffer08` | +$38.22 | 1.07 | 125 | +$20.15 | 1.11 | 44 | +$58.37 | 0.1% | 1.08 | 169 | 1.28% | REJECT_BEFORE_HOLDOUT |
| `ods2_tp175` | +$14.13 | 1.02 | 123 | +$30.55 | 1.16 | 48 | +$50.51 | 0.08% | 1.06 | 171 | 1.61% | REJECT_BEFORE_HOLDOUT |
| `ods2_maxstop25` | +$22.28 | 1.04 | 122 | +$13.31 | 1.07 | 48 | +$39.34 | 0.07% | 1.05 | 170 | 1.57% | REJECT_BEFORE_HOLDOUT |
| `ods2_maxstop45` | +$16.16 | 1.03 | 123 | +$13.31 | 1.07 | 48 | +$34.47 | 0.06% | 1.04 | 171 | 1.63% | REJECT_BEFORE_HOLDOUT |
| `ods2_center` | +$16.16 | 1.03 | 123 | +$13.31 | 1.07 | 48 | +$34.47 | 0.06% | 1.04 | 171 | 1.63% | REJECT_BEFORE_HOLDOUT |
| `ods2_minstop03` | +$16.16 | 1.03 | 123 | +$13.31 | 1.07 | 48 | +$34.47 | 0.06% | 1.04 | 171 | 1.63% | REJECT_BEFORE_HOLDOUT |
| `ods2_minstop08` | +$16.16 | 1.03 | 123 | +$11.91 | 1.06 | 48 | +$33.07 | 0.06% | 1.04 | 171 | 1.63% | REJECT_BEFORE_HOLDOUT |
| `ods2_signal25` | -$6.30 | 0.99 | 131 | +$9.77 | 1.04 | 54 | -$1.53 | 0% | 1 | 185 | 1.64% | REJECT_BEFORE_HOLDOUT |
| `ods2_tp125` | -$40.08 | 0.93 | 123 | +$11.04 | 1.06 | 48 | -$29.04 | -0.05% | 0.96 | 171 | 1.69% | REJECT_BEFORE_HOLDOUT |
| `ods2_lookback3` | -$80.76 | 0.87 | 123 | +$23.51 | 1.12 | 49 | -$56.15 | -0.09% | 0.93 | 172 | 1.64% | REJECT_BEFORE_HOLDOUT |
| `ods2_buffer02` | -$136.66 | 0.78 | 121 | +$41.47 | 1.21 | 48 | -$100.56 | -0.17% | 0.88 | 169 | 2.33% | REJECT_BEFORE_HOLDOUT |

## Action

- Reject this overnight-drift structure-v2 family without inspecting 2021-2026.
- Do not tune its filters against discovery losses or spend real-tick time on it.
- Keep the frozen transferable portfolio unchanged and continue searching through genuinely different economic hypotheses.
- Preserve the portable runner and exact report/source identity evidence.
