# Independent M15 USD-Consensus Lead-Lag Discovery Decision

**Decision: REJECTED IN 2015-2020 DISCOVERY. No 2021+ holdout, Model 4 escalation, new best, or live approval was opened.**

The EA tested a date-independent cross-market premise: completed H1 EURUSD strength plus USDJPY weakness as a USD-weakness proxy for gold buys, the inverse for sells, a gold lag constraint, and completed M15 breakout confirmation. All profiles retained broker-native risk sizing, minimum-lot refusal, a `$10,000` contract, account-wide exposure protection, daily/equity loss caps, one trade per day, and disabled real trading.

- Source SHA-256: `B19A299AB040C2050E881A481B71EEF57CD2C35155CF0EB65E5535C53C9AD7AA`
- Exact report binary SHA-256: `CD53ADD8511D8AF12BE1B4A1DB270CA6730FE1C949A3430AD3D489B804A510EF`
- Controlled run: `45 / 45` reports, one worker, zero runner errors
- Risk per accepted trade: `0.10%` on a `$10,000` test deposit
- Discovery windows: `2015-2018`, `2019-2020`, and continuous `2015-2020`
- Numeric gate passes: `0 / 15`
- History feasibility: EURUSD and USDJPY aligned on at least `99.9023%` of yearly XAUUSD M15 bars; lookback readiness `100%`

| Candidate | 2015-18 | PF | Trades | 2019-20 | PF | Trades | Continuous | CAGR | PF | Trades | DD | Decision |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| `usdcll_breakout6` | -$150.51 | 0.73 | 106 | +$23.02 | 1.08 | 67 | -$128.09 | -0.21% | 0.84 | 173 | 2.74% | REJECT_BEFORE_HOLDOUT |
| `usdcll_goldmax20` | -$219.46 | 0.66 | 116 | +$39.03 | 1.17 | 59 | -$182.99 | -0.31% | 0.79 | 175 | 3.03% | REJECT_BEFORE_HOLDOUT |
| `usdcll_consensus35` | -$256.57 | 0.68 | 152 | +$54.83 | 1.16 | 82 | -$194.38 | -0.33% | 0.83 | 234 | 3.26% | REJECT_BEFORE_HOLDOUT |
| `usdcll_component15` | -$282.11 | 0.66 | 150 | +$70.31 | 1.21 | 81 | -$204.44 | -0.34% | 0.82 | 231 | 3.43% | REJECT_BEFORE_HOLDOUT |
| `usdcll_breakout3` | -$285.55 | 0.72 | 196 | +$73.46 | 1.16 | 111 | -$208.87 | -0.35% | 0.86 | 307 | 3.75% | REJECT_BEFORE_HOLDOUT |
| `usdcll_tp200` | -$279.95 | 0.67 | 158 | +$50.38 | 1.14 | 85 | -$231.18 | -0.39% | 0.81 | 243 | 3.89% | REJECT_BEFORE_HOLDOUT |
| `usdcll_buffer10` | -$339.12 | 0.57 | 141 | +$97.64 | 1.34 | 76 | -$238.86 | -0.4% | 0.78 | 217 | 3.9% | REJECT_BEFORE_HOLDOUT |
| `usdcll_goldmax50` | -$318.86 | 0.72 | 212 | +$70.59 | 1.15 | 111 | -$240.01 | -0.4% | 0.85 | 323 | 3.59% | REJECT_BEFORE_HOLDOUT |
| `usdcll_center` | -$292.67 | 0.66 | 158 | +$41.31 | 1.11 | 85 | -$248.97 | -0.42% | 0.79 | 243 | 3.81% | REJECT_BEFORE_HOLDOUT |
| `usdcll_proxy6` | -$283.87 | 0.63 | 142 | +$25.03 | 1.09 | 68 | -$251.11 | -0.42% | 0.76 | 210 | 3.3% | REJECT_BEFORE_HOLDOUT |
| `usdcll_proxy3` | -$267.69 | 0.74 | 198 | -$13.41 | 0.97 | 94 | -$270.89 | -0.46% | 0.8 | 292 | 3.19% | REJECT_BEFORE_HOLDOUT |
| `usdcll_component05` | -$321.04 | 0.64 | 167 | +$41.18 | 1.11 | 89 | -$272.50 | -0.46% | 0.78 | 256 | 4.02% | REJECT_BEFORE_HOLDOUT |
| `usdcll_buffer00` | -$340.51 | 0.64 | 172 | +$32.23 | 1.08 | 93 | -$304.63 | -0.51% | 0.77 | 265 | 4.44% | REJECT_BEFORE_HOLDOUT |
| `usdcll_consensus15` | -$326.60 | 0.63 | 163 | +$14.02 | 1.04 | 88 | -$312.52 | -0.53% | 0.75 | 251 | 4.24% | REJECT_BEFORE_HOLDOUT |
| `usdcll_tp150` | -$307.81 | 0.64 | 158 | -$4.26 | 0.99 | 85 | -$315.34 | -0.53% | 0.74 | 243 | 4.16% | REJECT_BEFORE_HOLDOUT |

## Interpretation

- Every profile lost money in 2015-2018; no parameter neighbor produced a broad-era plateau.
- Most profiles improved in 2019-2020, but continuous profit factors remained below `1.0`, so this is regime dependence rather than a durable edge.
- Reject this family without inspecting 2021-2026 or spending real-tick time on it. Keep Three-Lane Trade-Ready RC2 ATB150 as the research best.
