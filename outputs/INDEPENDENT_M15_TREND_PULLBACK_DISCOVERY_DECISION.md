# Independent M15 Trend-Pullback Discovery Decision

**Decision: REJECTED IN 2015-2020 DISCOVERY. No 2021+ holdout, Model 4 escalation, new best, or live approval was opened.**

The standalone EA tested H1 50/200 EMA alignment and slope, bounded H1 ADX, a prior M15 impulse, an M15 EMA pullback, and an OHLC rejection candle using body, wick, close-location, optional tick volume, and a swing-structure stop. It retained broker-native `OrderCalcProfit` sizing, minimum-lot refusal, account-wide exposure limits, drawdown locks, and disabled real-account trading.

- Source SHA-256: `2452BA2254D7848F768EF729C09D615DB6147D100318F4D72B73C86525CF0636`
- Compile: `0 errors, 0 warnings`
- Risk per accepted trade: `0.10%` on a `$10,000` test deposit
- Exported Model 1 reports: `30 / 30`
- Discovery windows: `2015-2018`, `2019-2020`, and continuous `2015-2020`
- Numeric gate passes: `0 / 10`

| Candidate | 2015-18 | PF | Trades | 2019-20 | PF | Trades | Continuous | CAGR | PF | Trades | DD | Decision |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| `m15tpb_volume105` | +$14.17 | 1.37 | 11 | -$63.19 | 0.01 | 8 | -$49.02 | -0.08% | 0.52 | 19 | 1.15% | REJECT_BEFORE_HOLDOUT |
| `m15tpb_ema30` | -$137.78 | 0.33 | 32 | -$108.96 | 0.15 | 19 | -$241.47 | -0.41% | 0.27 | 51 | 2.62% | REJECT_BEFORE_HOLDOUT |
| `m15tpb_pb2` | -$158.80 | 0.39 | 43 | -$89.17 | 0.29 | 21 | -$243.86 | -0.41% | 0.36 | 64 | 2.52% | REJECT_BEFORE_HOLDOUT |
| `m15tpb_tp150` | -$119.04 | 0.53 | 43 | -$152.30 | 0.27 | 31 | -$266.07 | -0.45% | 0.41 | 74 | 3.26% | REJECT_BEFORE_HOLDOUT |
| `m15tpb_adx22` | -$149.37 | 0.27 | 32 | -$153.10 | 0.15 | 26 | -$297.20 | -0.5% | 0.22 | 58 | 3.13% | REJECT_BEFORE_HOLDOUT |
| `m15tpb_center` | -$146.31 | 0.42 | 43 | -$164.58 | 0.21 | 31 | -$305.62 | -0.52% | 0.33 | 74 | 3.58% | REJECT_BEFORE_HOLDOUT |
| `m15tpb_tp200` | -$114.03 | 0.55 | 43 | -$201.96 | 0.06 | 31 | -$313.19 | -0.53% | 0.32 | 74 | 3.86% | REJECT_BEFORE_HOLDOUT |
| `m15tpb_adx14` | -$205.59 | 0.34 | 51 | -$140.69 | 0.4 | 37 | -$339.78 | -0.57% | 0.37 | 88 | 3.93% | REJECT_BEFORE_HOLDOUT |
| `m15tpb_ema15` | -$234.26 | 0.38 | 65 | -$149.60 | 0.4 | 40 | -$378.91 | -0.64% | 0.39 | 105 | 4.13% | REJECT_BEFORE_HOLDOUT |
| `m15tpb_pb4` | -$218.51 | 0.33 | 50 | -$200.28 | 0.24 | 36 | -$417.72 | -0.71% | 0.28 | 86 | 4.24% | REJECT_BEFORE_HOLDOUT |

Every variant lost money in the continuous window and every variant lost in 2019-2020. Continuous PF ranged only from `0.22` to `0.52`; the most selective volume profile made `19` trades and still lost. The family failed expectancy, both-era consistency, PF, and activity requirements before neighbor support could matter.

The first fresh-worker export for the center 2019-2020 row contained zero trades. The exact unchanged config was rerun on a warmed isolated worker, produced `31` trades, and returned `-$164.58` at PF `0.21`; that reproducible report replaced the initialization artifact before this decision was built.

## Action

- Reject the trend-pullback continuation family without inspecting 2021-2026.
- Do not tune its filters against these losses or spend real-tick time on it.
- Keep the frozen transferable portfolio unchanged and continue searching through genuinely different economic hypotheses.
- Preserve the portable runner because it reduced a 30-report screen to roughly two minutes without interrupting the forward terminal.
