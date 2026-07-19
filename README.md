# Professional XAUUSD EA

Risk-first MetaTrader 5 research for XAUUSD. No martingale, grid, averaging down, or recovery sizing.

## Current Verdict

| Lane | Status |
|---|---|
| Best historical/trade-ready candidate | **Three-Lane Trade-Ready RC2** |
| Latest growth-ladder result | **No new best promoted.** The 1.25x neighbor earned more but weakened PF, recovery, and adverse-path robustness. |
| Registered forward candidate | Operational Hardening v0.2-rc2, unchanged |
| Valid forward evidence | **None**. The attached $100,000 demo violates the frozen $10,000 contract and counts as zero days/trades. |
| Real-money approval | **No. Real-account trading remains disabled.** |

Three-Lane Trade-Ready RC2 exactly preserves RC1's validated strategy behavior while adding confirmed trade results, ownership-checked close/modify/delete operations, post-fill risk reconciliation, residual-order cleanup, verified persistent safety state, and live environment guards. It is the strongest exact historical candidate, but it is not a promise of future profit and is not yet the registered forward bot.

## Best Result

Continuous MT5 Model 4 real ticks, XAUUSD, `$10,000` restart, `2015-01-01` through `2026-07-12`:

| Metric | Result |
|---|---:|
| Net profit | **+$1,994.62** |
| Ending balance | **$11,994.62** |
| Total increase | **+19.95%** |
| CAGR | **+1.59% per year** |
| Profit factor | **1.82** |
| Trades | **367** |
| Win rate | **44.14%** |
| Maximum equity drawdown | **$139.11 / 1.19%** |
| Recovery factor | **14.34** |

The DI-11 neighboring profile independently supported the result at `+$1,805.70`, PF `1.77`, 359 trades, and no losing broad era. Model 1 was used only for fast rejection; every promoted number above comes from Model 4 real ticks.

## Latest Research Update

The source-identical RC2 growth ladder finished on `2026-07-19`. No new stable best was promoted.

| Profile | Model 4 net | Increase | CAGR | PF | Max DD | Recovery | Result |
|---|---:|---:|---:|---:|---:|---:|---|
| Stable RC2 `1.00x` | +$1,994.62 | +19.95% | +1.59%/yr | 1.82 | 1.19% | 14.34 | Remains best |
| Growth `1.25x` | +$2,317.95 | +23.18% | +1.83%/yr | 1.73 | 1.48% | 12.75 | Research only |
| Growth `1.50x` | +$2,702.79 | +27.03% | +2.10%/yr | 1.69 | 1.91% | 11.15 | Rejected |

The 1.25x neighbor passed 12/12 positive annual restarts and hard-risk/cost checks, but raised continuous drawdown by `30.73%` for only `16.21%` more profit. Severe Monte Carlo block paths reached `5.05%-5.87%` P95 drawdown and `3.85%-4.53%` red trials, materially worse than stable RC2. The 1.50x profile also failed the middle-era PF gate at `1.45`; the 2.00x diagnostic failed it in Model 1 at `1.38`.

[Read the exact growth-ladder decision](outputs/THREE_LANE_TRADE_READY_RC2_GROWTH_LADDER_DECISION.md).

## Increase By Year

Each row is a separate `$10,000` Model 4 restart. Percentages are window returns, not a compounded account history.

| Window | Net | Increase | PF | Trades | Max DD |
|---|---:|---:|---:|---:|---:|
| 2015 | +$171.91 | +1.72% | 2.15 | 22 | 0.87% |
| 2016 | +$214.49 | +2.14% | 2.10 | 36 | 0.52% |
| 2017 | +$154.66 | +1.55% | 1.45 | 49 | 1.06% |
| 2018 | +$256.79 | +2.57% | 1.98 | 53 | 0.57% |
| 2019 | +$15.07 | +0.15% | 1.09 | 33 | 0.85% |
| 2020 | +$183.77 | +1.84% | 2.00 | 27 | 0.65% |
| 2021 | +$313.13 | +3.13% | 2.36 | 30 | 1.16% |
| 2022 | +$16.22 | +0.16% | 1.07 | 36 | 0.96% |
| 2023 | +$160.80 | +1.61% | 1.66 | 40 | 1.24% |
| 2024 | +$233.81 | +2.34% | 2.44 | 29 | 1.08% |
| 2025 | +$17.78 | +0.18% | 2.91 | 3 | 0.12% |
| 2026 YTD | +$209.18 | +2.09% | no losing trades | 2 | 1.19% |

All 12 windows were profitable. Recent activity is sparse, especially in 2025 and 2026, so forward evidence is still essential.

## Strategy

Three independent, capped lanes share one account-wide safety manager:

| Lane | Risk cap | Model 4 continuous contribution |
|---|---:|---:|
| H1 Band/VWAP reversion with DI and completed-D1 momentum gates | 0.45% | +$1,414.60, PF 4.12, 38 trades |
| Original H1/D1 multiscale momentum | 0.15% | +$475.66, PF 1.25, 314 trades |
| New H4 Donchian breakout with D1 EMA trend and ADX/price-action quality | 0.10% | +$104.36, PF 3.28, 15 trades |

The tested profile caps total open risk at `0.75%`, permits at most three account positions, requires initial stops, sizes through broker-valued `OrderCalcProfit`, locks symbol/currency/starting capital, rejects real accounts, and enforces daily/weekly/monthly/equity loss limits.

## Robustness

- Critical Model 4: center and DI-11 were profitable in both prior failure years, 2019 and 2022.
- Broad Model 4: older 2015-2018 `+$832.95`, middle 2019-2022 `+$557.33`, recent 2023-2026 `+$594.03`.
- Annual Model 4: 12/12 profitable annual/YTD restarts.
- Hard-risk audit: 367/367 entries passed; maximum conservative portfolio initial risk was `0.4453%`.
- Severe deterministic cost: `0.10R` added per trade retained `+$1,449.21`, PF `1.53`, and all eras positive.
- Monte Carlo: 8/8 seeded 10,000-trial block/year scenarios passed. The weakest severe block case retained positive P05 net `+$197.56`; red trials were `1.74%`.

## Exact Candidate

- [Trade-ready RC2 release package](release/three-lane-trade-ready-rc2/README.md)
- [RC2 decision](outputs/THREE_LANE_TRADE_READY_RC2_DECISION.md)
- [RC2 broad metrics](outputs/THREE_LANE_TRADE_READY_RC2_MODEL4_BROAD_METRICS.md)
- [RC2 annual metrics](outputs/THREE_LANE_TRADE_READY_RC2_MODEL4_ANNUAL_METRICS.md)
- [RC2 safety suite](outputs/THREE_LANE_TRADE_READY_RC2_STATIC_SAFETY.md)
- [Risk audit](outputs/THREE_LANE_ADAPTIVE_TREND_MODEL4_RISK_AUDIT.md)
- [Cost and Monte Carlo stress](outputs/THREE_LANE_ADAPTIVE_TREND_MODEL4_STRESS_DECISION.md)

Source SHA-256: `2F1C1C74067DA6173EB4133DB75C0B0DB4DE7BE46F2BB7A453AEE044536B2158`

Profile SHA-256: `60BF5D013153E3A38A6BD932E88CB41BD8FEAB5108648DDCBA1CCCCDD4D737F3`

## Forward Boundary

The current demo attachment is invalid before its first trade because its `$100,000` balance does not match the frozen `$10,000 +/- $1` contract. Its elapsed time and trades must never be counted. The registered Operational Hardening candidate, profile, source, binary identity, evidence logs, and real-account lock remain unchanged.

Three-Lane RC2 passed its hardened release review and exact historical equivalence gates. It still needs broker-specification variation and a correctly capitalized untouched demo sample before any forward substitution can be considered. Real-money funding is not recommended.

## Repository Map

| Path | Purpose |
|---|---|
| `release/` | Small, exact candidate packages |
| `outputs/` | Contracts, parsed evidence, decisions, and historical research |
| `work/` | Offline builders, analyzers, safety tests, and EA research source |
| `docs/archive/` | Preserved long-form research timeline |
| `.github/workflows/static-safety.yml` | Manual-only static checks; no scheduled or push-triggered Actions |

The old detailed landing-page timeline is preserved at [docs/archive/RESEARCH_TIMELINE_THROUGH_2026-07-18.md](docs/archive/RESEARCH_TIMELINE_THROUGH_2026-07-18.md).
