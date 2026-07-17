# Independent M15 Daily-VWAP Continuation Discovery Decision

**Decision: REJECTED IN 2015-2020 DISCOVERY. No 2021+ holdout, Model 4 escalation, new best, or live approval was opened.**

The standalone EA tested H1 50/200 EMA alignment and slope, bounded H1 ADX, a pullback through the current day anchored VWAP, and a completed M15 reclaim candle using body, close-location, previous-bar progress, optional tick volume, and a swing-structure stop. It retained broker-native `OrderCalcProfit` sizing, minimum-lot refusal, account-wide exposure limits, drawdown locks, and disabled real-account trading.

- Source SHA-256: `7EE4CD1CF4D47FA4EB34D33FF101A2C66323B8212047E4C4D5692C18A28A5849`
- Compile: `0 errors, 0 warnings`
- Risk per accepted trade: `0.10%` on a `$10,000` test deposit
- Exported Model 1 reports: `36 / 36`
- Discovery windows: `2015-2018`, `2019-2020`, and continuous `2015-2020`
- Numeric gate passes: `0 / 12`
- Neighbor-supported eligible profiles: `0 / 12`

| Candidate | 2015-18 | PF | Trades | 2019-20 | PF | Trades | Continuous | CAGR | PF | Trades | DD | Decision |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| `m15dvc_volume105` | -$22.70 | 0.9 | 38 | -$24.80 | 0.85 | 25 | -$43.85 | -0.07% | 0.88 | 63 | 1.15% | REJECT_BEFORE_HOLDOUT |
| `m15dvc_session7_17` | -$199.11 | 0.71 | 106 | -$110.23 | 0.73 | 70 | -$306.54 | -0.52% | 0.72 | 176 | 3.61% | REJECT_BEFORE_HOLDOUT |
| `m15dvc_adx22` | -$247.53 | 0.66 | 108 | -$70.45 | 0.81 | 62 | -$306.93 | -0.52% | 0.71 | 169 | 3.94% | REJECT_BEFORE_HOLDOUT |
| `m15dvc_body45` | -$242.42 | 0.69 | 126 | -$149.75 | 0.64 | 68 | -$387.86 | -0.66% | 0.67 | 194 | 4.52% | REJECT_BEFORE_HOLDOUT |
| `m15dvc_tp250` | -$266.74 | 0.7 | 142 | -$155.67 | 0.67 | 78 | -$395.44 | -0.67% | 0.7 | 219 | 4.53% | REJECT_BEFORE_HOLDOUT |
| `m15dvc_adx20` | -$308.43 | 0.61 | 120 | -$129.24 | 0.7 | 72 | -$414.15 | -0.7% | 0.65 | 191 | 4.89% | REJECT_BEFORE_HOLDOUT |
| `m15dvc_pb4` | -$287.47 | 0.62 | 119 | -$111.23 | 0.74 | 72 | -$415.82 | -0.71% | 0.64 | 191 | 4.73% | REJECT_BEFORE_HOLDOUT |
| `m15dvc_touch_only` | -$252.14 | 0.76 | 163 | -$220.85 | 0.6 | 92 | -$476.74 | -0.81% | 0.69 | 255 | 4.99% | REJECT_BEFORE_HOLDOUT |
| `m15dvc_pb2` | -$298.35 | 0.72 | 172 | -$250.52 | 0.57 | 95 | -$500.02 | -0.85% | 0.64 | 226 | 5.02% | REJECT_BEFORE_HOLDOUT |
| `m15dvc_adx16` | -$306.39 | 0.67 | 150 | -$179.53 | 0.64 | 84 | -$500.12 | -0.85% | 0.58 | 191 | 5.02% | REJECT_BEFORE_HOLDOUT |
| `m15dvc_center` | -$309.60 | 0.65 | 142 | -$174.28 | 0.63 | 78 | -$501.12 | -0.85% | 0.59 | 198 | 5.06% | REJECT_BEFORE_HOLDOUT |
| `m15dvc_tp150` | -$306.23 | 0.65 | 142 | -$236.21 | 0.5 | 78 | -$504.74 | -0.86% | 0.6 | 212 | 5.07% | REJECT_BEFORE_HOLDOUT |

## Action

- Reject this daily-VWAP continuation family without inspecting 2021-2026.
- Do not tune its filters against discovery losses or spend real-tick time on it.
- Keep the frozen transferable portfolio unchanged and continue searching through genuinely different economic hypotheses.
- Preserve the portable runner and exact report/source identity evidence.
