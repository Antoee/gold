# Professional XAUUSD EA

Risk-first MetaTrader 5 research for XAUUSD. No martingale, grid, averaging down, or recovery sizing.

## Current Verdict

| Lane | Status |
|---|---|
| Best historical/trade-ready candidate | **Three-Lane Trade-Ready RC2 ATB150** |
| Latest research result | **Inside-day breakout rejected before holdout.** ATB150 remains the best; no recent-activity breakthrough yet. |
| Registered forward candidate | Operational Hardening v0.2-rc2, unchanged |
| Valid forward evidence | **None**. The attached $100,000 demo violates the frozen $10,000 contract and counts as zero days/trades. |
| Real-money approval | **No. Real-account trading remains disabled.** |

Three-Lane Trade-Ready RC2 ATB150 uses the exact hardened RC2 source and raises only the adaptive-trend lane risk from `0.10%` to `0.15%`. Reversion, momentum, total open risk, and every portfolio loss limit remain unchanged. It is the strongest exact historical profile, but it is not a promise of future profit and is not the registered forward bot.

## Best Result

Continuous MT5 Model 4 real ticks, XAUUSD, `$10,000` restart, `2015-01-01` through `2026-07-12`:

| Metric | Result |
|---|---:|
| Net profit | **+$2,105.08** |
| Ending balance | **$12,105.08** |
| Total increase | **+21.05%** |
| CAGR | **+1.67% per year** |
| Profit factor | **1.81** |
| Trades | **404** |
| Win rate | **44.31%** |
| Maximum equity drawdown | **$134.35 / 1.15%** |
| Recovery factor | **15.67** |

The previous RC2 center profile independently supports the same source at `+$1,994.62`, PF `1.82`, 367 trades, and no losing broad era. ATB150 adds `$110.46`, reduces money drawdown by `$4.76`, and improves recovery by `9.28%`. Every promoted number above comes from Model 4 real ticks.

## Latest Research Update

The standalone M15 inside-day compression breakout finished on `2026-07-19` and was rejected before recent data. All 42 source-identity-valid Model 1 reports parsed, but every profile lost in 2019-2020. Its best continuous row made only `+$12.79` on 25 trades at PF `1.11`, so no 2021-2026 holdout or Model 4 run was opened.

[Read the inside-day rejection](outputs/INDEPENDENT_M15_INSIDE_DAY_BREAKOUT_DISCOVERY_DECISION.md).

The preceding M15 ADR-exhaustion/VWAP-reversion experiment was also rejected before holdout: ten profiles made zero trades in 2015-2018 and its best continuous row made only `+$20.08` on six trades. [Read the ADR-exhaustion rejection](outputs/INDEPENDENT_M15_ADR_EXHAUSTION_REVERSION_DISCOVERY_DECISION.md).

The earlier source-identical lane decomposition remains the latest promotion. Portfolio-wide scaling was rejected, but ATB-only `1.50x` improved risk-adjusted results and became the historical best.

| Profile | Model 4 net | Increase | CAGR | PF | Max DD | Recovery | Result |
|---|---:|---:|---:|---:|---:|---:|---|
| Previous RC2 | +$1,994.62 | +19.95% | +1.59%/yr | 1.82 | 1.19% | 14.34 | Supported baseline |
| ATB-only `1.25x` | +$2,018.88 | +20.19% | +1.61%/yr | 1.81 | 1.19% | 14.51 | Neighbor support |
| ATB-only `1.50x` | **+$2,105.08** | **+21.05%** | **+1.67%/yr** | **1.81** | **1.15%** | **15.67** | **Promoted** |

ATB150 passed 12/12 positive annual restarts, 404/404 hard-risk rows, 4/4 cost scenarios, and 8/8 Monte Carlo scenarios. Its weakest severe block P05 improved to `+$238.64`, worst P95 drawdown improved to `4.225%`, and worst red trials improved to `1.35%`. The prior portfolio-wide growth ladder remains rejected because it weakened adverse-path robustness.

[Read the ATB150 decision](outputs/THREE_LANE_TRADE_READY_RC2_ATB150_DECISION.md) and [the rejected portfolio-growth decision](outputs/THREE_LANE_TRADE_READY_RC2_GROWTH_LADDER_DECISION.md).

## Increase By Year

Each row is a separate `$10,000` Model 4 restart. Percentages are window returns, not a compounded account history.

| Window | Net | Increase | PF | Trades | Max DD |
|---|---:|---:|---:|---:|---:|
| 2015 | +$170.78 | +1.71% | 2.06 | 26 | 0.87% |
| 2016 | +$256.58 | +2.57% | 2.19 | 42 | 0.52% |
| 2017 | +$111.65 | +1.12% | 1.29 | 55 | 1.08% |
| 2018 | +$281.65 | +2.82% | 1.96 | 63 | 0.51% |
| 2019 | +$13.01 | +0.13% | 1.07 | 36 | 1.08% |
| 2020 | +$194.64 | +1.95% | 1.99 | 29 | 0.65% |
| 2021 | +$313.13 | +3.13% | 2.36 | 30 | 1.16% |
| 2022 | +$16.22 | +0.16% | 1.07 | 36 | 0.96% |
| 2023 | +$181.54 | +1.82% | 1.75 | 41 | 1.24% |
| 2024 | +$233.81 | +2.34% | 2.44 | 29 | 1.08% |
| 2025 | +$17.78 | +0.18% | 2.91 | 3 | 0.12% |
| 2026 YTD | +$209.18 | +2.09% | no losing trades | 2 | 1.19% |

All 12 windows were profitable. Recent activity remains sparse and unchanged at three trades in 2025 and two in 2026 YTD, so forward evidence is still essential.

## Strategy

Three independent, capped lanes share one account-wide safety manager:

| Lane | Risk cap | Model 4 continuous contribution |
|---|---:|---:|
| H1 Band/VWAP reversion with DI and completed-D1 momentum gates | 0.45% | +$1,366.48, 38 trades |
| Original H1/D1 multiscale momentum | 0.15% | +$661.79, 314 trades |
| H4 Donchian breakout with D1 EMA trend and ADX/price-action quality | 0.15% | +$76.81, 52 trades |

The tested profile caps total open risk at `0.75%`, permits at most three account positions, requires initial stops, sizes through broker-valued `OrderCalcProfit`, locks symbol/currency/starting capital, rejects real accounts, and enforces daily/weekly/monthly/equity loss limits.

## Robustness

- Critical Model 4: center and DI-11 were profitable in both prior failure years, 2019 and 2022.
- Broad Model 4: older 2015-2018 `+$856.18`, middle 2019-2022 `+$572.09`, recent 2023-2026 `+$602.11`.
- Annual Model 4: 12/12 profitable annual/YTD restarts.
- Hard-risk audit: 404/404 entries passed; maximum conservative portfolio initial risk was `0.4448%`.
- Severe deterministic cost: `0.10R` added per trade retained `+$1,506.55`, PF `1.515`, and all eras positive.
- Monte Carlo: 8/8 seeded 10,000-trial block/year scenarios passed. The weakest severe block P05 was `+$238.64`; worst P95 drawdown was `4.225%`; worst red trials were `1.35%`.

## Exact Candidate

- [ATB150 release package](release/three-lane-trade-ready-rc2-atb150/README.md)
- [ATB150 decision](outputs/THREE_LANE_TRADE_READY_RC2_ATB150_DECISION.md)
- [ATB150 broad metrics](outputs/THREE_LANE_TRADE_READY_RC2_GROWTH_DECOMP_MODEL4_METRICS.md)
- [ATB150 annual metrics](outputs/THREE_LANE_TRADE_READY_RC2_ATB150_ANNUAL_MODEL4_METRICS.md)
- [ATB150 safety suite](outputs/THREE_LANE_TRADE_READY_RC2_ATB150_STATIC_SAFETY.md)
- [ATB150 risk audit](outputs/THREE_LANE_TRADE_READY_RC2_ATB150_MODEL4_RISK_AUDIT.md)
- [ATB150 cost and Monte Carlo stress](outputs/THREE_LANE_TRADE_READY_RC2_ATB150_MODEL4_STRESS_DECISION.md)

Source SHA-256: `2F1C1C74067DA6173EB4133DB75C0B0DB4DE7BE46F2BB7A453AEE044536B2158`

Profile SHA-256: `705E2154CF6D123151B67757FFCA3EBF7D8BD525CD859E8237F89674CF70DC4E`

## Forward Boundary

The current demo attachment is invalid before its first trade because its `$100,000` balance does not match the frozen `$10,000 +/- $1` contract. Its elapsed time and trades must never be counted. The registered Operational Hardening candidate, profile, source, binary identity, evidence logs, and real-account lock remain unchanged.

Three-Lane RC2 ATB150 passed its historical promotion review, but it still needs broker-specification variation and a correctly capitalized untouched demo sample before any forward substitution can be considered. Real-money funding is not recommended.

## Repository Map

| Path | Purpose |
|---|---|
| `release/` | Small, exact candidate packages |
| `outputs/` | Contracts, parsed evidence, decisions, and historical research |
| `work/` | Offline builders, analyzers, safety tests, and EA research source |
| `docs/archive/` | Preserved long-form research timeline |
| `.github/workflows/static-safety.yml` | Manual-only static checks; no scheduled or push-triggered Actions |

The old detailed landing-page timeline is preserved at [docs/archive/RESEARCH_TIMELINE_THROUGH_2026-07-18.md](docs/archive/RESEARCH_TIMELINE_THROUGH_2026-07-18.md).
