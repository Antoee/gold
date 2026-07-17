# Professional XAUUSD EA

Research and validation repository for a risk-first MetaTrader 5 Expert Advisor on XAUUSD. No martingale, grid, averaging down, or recovery sizing.

## Current Status

**Best balanced executable: Transferable Portfolio v0.1**

**Forward-test candidate only. Real-account trading remains disabled.**

**2026-07-17 update: no new best was promoted. The first forward attachment remains invalid because the demo account has the wrong starting balance. An exact-source two-lane growth allocation ladder failed its improvement/drawdown gate; a new independent M15 daily-VWAP continuation family failed all pre-2021 broad windows; the M15 dual-regime portfolio also failed its recent holdout, and bounded inverse-volatility, lane-aware market-phase, no-follow-through exit, and two-bar confirmation forks failed pre-2021 discovery.**

The candidate combines two date-independent H1 strategies:

- Band/VWAP mean reversion at `0.45%` requested risk
- E20 multiscale momentum at `0.15%` requested risk
- Shared open-risk cap: `0.75%`
- Shared maximum equity drawdown guard: `5.00%`
- Hedging account required

Exact tested files and evidence are in [`release/transferable-portfolio-v0.1`](release/transferable-portfolio-v0.1/README.md).

## Frozen Forward Demo

The unchanged candidate was attached to a MetaQuotes demo hedging account on 2026-07-17, after the historical research cutoff. A new read-only sentinel then measured a `$100,000` balance while the frozen registration requires `$10,000`. Because lot caps make that difference alter effective risk, this attachment cannot count as forward evidence.

| Status | Calendar days | Closed trades | Net | Integrity |
|---|---:|---:|---:|---|
| [FAIL: invalid account and stopped monitor](outputs/TRANSFERABLE_PORTFOLIO_FORWARD_DEMO_STATUS.md) | Not started / 90 | 0 / 30 | $0.00 | Code/log identity PASS; account, terminal, and heartbeat FAIL |

No trades occurred, so no evidence was lost. The forward clock will restart only after the same frozen candidate is attached to a correctly capitalized `$10,000` demo hedging account. No performance decision is allowed until **both** 90 valid calendar days and 30 trades have closed. A first-stage pass requires positive net profit, profit factor at least `1.10`, closed-trade drawdown no more than `5.00%`, and no more than 12 consecutive losses. Even a pass authorizes only a second-broker demo test, not real-money trading.

The forward profile keeps the same trading and risk inputs as the released base profile. Only evidence logging, dashboard visibility, and the frozen run label differ. The sentinel cannot trade and publishes no account identifier. See the [registration](outputs/TRANSFERABLE_PORTFOLIO_FORWARD_DEMO_REGISTRATION.json), [profile](outputs/TRANSFERABLE_PORTFOLIO_FORWARD_DEMO_PROFILE.set), [sentinel registration](outputs/TRANSFERABLE_FORWARD_SENTINEL_REGISTRATION.json), and [monitor package](outputs/TRANSFERABLE_PORTFOLIO_FORWARD_DEMO_PACKAGE.md).

The replacement-account activation gate is prepared but has not been executed. Terminal-level and sentinel-chart algorithmic trading are now disabled, the account-creation dialog was canceled without accepting terms, and no registration timestamp was changed. The disabled-trading check passes; the gate still refuses registration because starting balance and equity are `$100,000` instead of the frozen `$10,000`. It also preserves the demo hedging, identity, flat-account, zero-risk, and empty-log requirements. A separate verification is required after trading is re-enabled. Creating the new virtual account still awaits explicit acceptance of MetaQuotes' terms. See the [activation procedure](outputs/TRANSFERABLE_PORTFOLIO_FORWARD_DEMO_ACTIVATION.md).

The terminal process later stopped during an interrupted isolated-research run. Restarting the same session preserved every frozen identity and the zero-trade account, but the read-only sentinel could not refresh while terminal-level algorithmic trading remained disabled. Re-enabling that switch would also wake the candidate on the invalid account, so the terminal was stopped again and the safety lock was retained. The stale heartbeat and stopped terminal are explicit failures, not forward evidence; valid days remain `0`.

## Latest Research Screens

The exact released two-lane source was tested at seven reversion/momentum risk allocations without changing entries, exits, stops, schedules, safety controls, or the `0.75%` shared open-risk cap. Four broad/continuous windows produced `28 / 28` identity-verified Model 1 reports. Every profile remained profitable in all three broad eras, but higher requested risk did not translate efficiently through broker lot steps and shared execution. The best `0.55% + 0.15%` row made `+$1,710.85`, only `+5.84%` above the released control's `+$1,616.49`; drawdown worsened from `3.24%` to `4.26%` and recovery fell from `4.56` to `3.67`. It failed the frozen 15% improvement, 4% drawdown, and 4.0 recovery gates, so no Model 4 test or candidate change was opened. See the [frozen contract](outputs/TRANSFERABLE_PORTFOLIO_GROWTH_DISCOVERY_CONTRACT.md) and [decision](outputs/TRANSFERABLE_PORTFOLIO_GROWTH_DISCOVERY_DECISION.md).

An independent M15 daily-anchored-VWAP continuation EA tested a return source distinct from the released reversion and momentum lanes: a completed-bar pullback through daily tick-volume-weighted VWAP, directional reclaim, H1 EMA 50/200 trend and slope, bounded H1 ADX, OHLC body/close-location/progress checks, optional volume, and a swing-structure stop. It compiled with `0 errors, 0 warnings`; `36 / 36` exact-source Model 1 reports parsed across 12 profiles and three 2015-2020 discovery windows. Every profile lost in both disjoint eras. The least-bad volume-filtered profile lost `-$43.85` continuously, PF `0.88`, with 63 trades and `1.15%` drawdown; the center lost `-$501.12`, PF `0.59`, with 198 trades. The family was rejected without opening 2021-2026 or Model 4, so the current best remains unchanged. See the [frozen contract](outputs/INDEPENDENT_M15_DAILY_VWAP_CONTINUATION_DISCOVERY_CONTRACT.md) and [decision](outputs/INDEPENDENT_M15_DAILY_VWAP_CONTINUATION_DISCOVERY_DECISION.md).

A separate two-bar confirmation fork kept released sizing, stops, targets, and position management. Reversion variants required a prior completed band extension followed by a reclaim; momentum variants required a channel breakout followed by a second completed close beyond the same channel. The source compiled with `0 errors, 0 warnings`; `24 / 24` pre-2021 Model 1 reports passed source identity. Prior-close-outside reversion confirmation reduced the protected 2019-2020 loss from `-$105.45` to `-$26.26`, but continuous net fell to `+$569.14` (`+5.69%` total, `+0.93%/yr` CAGR), PF `1.39`, 214 trades, and `2.03%` drawdown. Momentum confirmation was worse and its progress variants fell to 99-101 trades. No profile made 2019-2020 profitable or cleared all frozen quality/activity gates, so the family was rejected before 2021+ holdout and Model 4. See the [frozen contract](outputs/TWO_BAR_CONFIRMATION_PORTFOLIO_DISCOVERY_CONTRACT.md) and [decision](outputs/TWO_BAR_CONFIRMATION_PORTFOLIO_DISCOVERY_DECISION.md).

A separate early-failure fork retained the released entries, initial stops, targets, and risk, then allowed closed-H1-bar exits when a position had not made configured R progress after 2-6 bars. It could only close risk, never widen a stop or add size. The source compiled with `0 errors, 0 warnings`; `24 / 24` pre-2021 Model 1 reports passed source identity. The relaxed `-0.25R` profile improved continuous net to `+$801.22` (`+8.01%` total, `+1.29%/yr` CAGR), PF to `1.54`, and drawdown to `2.30%`, versus the fixed control's `+$694.13`, PF `1.42`, and `2.77%` drawdown. Reversion-only early exits reduced the protected 2019-2020 loss to `-$31.65`, but no profile made that era profitable; the highest-net row still lost `-$59.20` there at PF `0.90`. All profiles were rejected before 2021+ holdout and Model 4. See the [frozen contract](outputs/EARLY_FAILURE_PORTFOLIO_DISCOVERY_CONTRACT.md) and [decision](outputs/EARLY_FAILURE_PORTFOLIO_DISCOVERY_DECISION.md).

A separate market-phase fork retained the exact released entries/exits and used only a completed-H1-bar efficiency ratio to reduce reversion risk in strongly directional phases and momentum risk in strongly ranging phases. It could never increase either lane's base risk or exceed the existing `0.75%` open-risk cap. The source compiled with `0 errors, 0 warnings`; `24 / 24` pre-2021 Model 1 reports passed source identity. The best 12-bar variant improved continuous net to `+$747.49` (`+7.47%` total, `+1.21%/yr` CAGR), PF to `1.48`, and drawdown to `2.58%`, versus the fixed control's `+$694.13`, PF `1.42`, and `2.77%` drawdown. It nevertheless lost `-$61.36` at PF `0.90` in the protected 2019-2020 era, and every neighboring setting also left that era negative. The family was rejected before 2021+ holdout and Model 4. See the [frozen contract](outputs/MARKET_PHASE_PORTFOLIO_DISCOVERY_CONTRACT.md) and [decision](outputs/MARKET_PHASE_PORTFOLIO_DISCOVERY_DECISION.md).

A separate adaptive-volatility fork retained the exact released Band/VWAP-reversion and E20 momentum entries/exits while multiplying requested risk by a closed-H1-bar ATR/price ratio bounded to `0.75x-1.25x`. Maximum requested lane risk still fit the existing `0.75%` open-risk cap, and all real-account, drawdown, daily-loss, broker-sizing, and minimum-lot safeguards remained unchanged. The source compiled with `0 errors, 0 warnings`; `24 / 24` pre-2021 Model 1 reports passed source identity. Every adaptive profile lost in 2019-2020. The highest-net row made `+$715.75` (`+7.16%` total, `+1.16%/yr` CAGR), PF `1.38`, and `3.40%` drawdown, but lost `-$131.67` in the later era and improved net only `3.1%` over the fixed-risk control while worsening drawdown. The fixed control made `+$694.13`, PF `1.42`, and `2.77%` drawdown, with materially better return/drawdown efficiency. The fork was rejected before holdout and Model 4. See the [frozen contract](outputs/ADAPTIVE_VOLATILITY_PORTFOLIO_DISCOVERY_CONTRACT.md) and [decision](outputs/ADAPTIVE_VOLATILITY_PORTFOLIO_DISCOVERY_DECISION.md).

The profitable-but-low-activity M15 volatility-squeeze and volume-climax engines were combined under one shared risk manager, one-position cap, account-wide exposure guard, and lane-specific exits. The exact source compiled with `0 errors, 0 warnings`. In 2015-2020 discovery, `45 / 45` reports passed source identity and 12 dual-engine profiles met the frozen gate. The strongest row made `+$330.06` (`+3.30%` total, `+0.54%/yr` CAGR), PF `1.32`, 218 trades, and `1.02%` drawdown. All 12 exact profile hashes then entered an untouched 2021-2026 YTD Model 1 holdout: `36 / 36` reports passed identity, but every profile lost in 2024-2026 YTD. The least-bad continuous row made `+$115.53` (`+1.16%` total, `+0.21%/yr` CAGR), PF `1.15`, and 174 trades, while its recent window lost `-$66.41` at PF `0.76`. The family was rejected before Model 4, with no new best or live approval. See the [discovery decision](outputs/INDEPENDENT_M15_DUAL_REGIME_PORTFOLIO_DISCOVERY_DECISION.md) and [holdout decision](outputs/INDEPENDENT_M15_DUAL_REGIME_PORTFOLIO_HOLDOUT_DECISION.md).

An independent M15 volume-climax reversal EA was implemented around tick-volume expansion, ATR-sized rejection candles, fresh local extremes, the day anchored VWAP, and H1 range-phase filtering. It compiled with `0 errors, 0 warnings`, uses broker-native `OrderCalcProfit` sizing at `0.10%` risk, never forces minimum lot, and caps stop-price distance at `$6`. The initial exact-source Model 1 screen parsed `45 / 45` reports on 2015-2020 only. Its strongest 1.30x-volume row made `+$107.17`, PF `1.27`, with both eras positive and `0.95%` drawdown, but only 84 trades against the frozen 120-trade floor. One separately named final activity screen parsed another `45 / 45` unchanged-source reports. Its highest-activity near miss made `+$112.20`, PF `1.20`, and `0.91%` drawdown on 117 trades, but missed the activity floor, had only PF `1.06` in 2015-2018, and lacked a passing neighbor. The family was closed with no 2021-2026 holdout or Model 4 exposure. See the [base decision](outputs/INDEPENDENT_M15_VOLUME_CLIMAX_REVERSAL_DISCOVERY_DECISION.md) and [activity decision](outputs/INDEPENDENT_M15_VOLUME_CLIMAX_REVERSAL_ACTIVITY_DISCOVERY_DECISION.md).

An independent M15 Bollinger/Keltner volatility-squeeze continuation EA was implemented and compiled with `0 errors, 0 warnings`. Its first exact-source Model 1 screen parsed `45 / 45` reports on 2015-2020 only. Ten of 15 profiles were profitable in both eras; the strongest 8-bar breakout made `+$177.89`, PF `1.44`, and `0.48%` drawdown, but placed only 88 trades against the frozen 120-trade floor. A separately named final activity screen kept the source unchanged and tested 4/6/8/10-bar breakouts plus squeeze, expansion, trend, and session neighbors. Profiles reaching 137-168 trades fell below PF `1.20` or lost the older era, while the robust 8-bar row remained at 88 trades. Both screens were rejected before any 2021-2026 holdout or Model 4 data was opened. See the [base decision](outputs/INDEPENDENT_M15_VOLATILITY_SQUEEZE_DISCOVERY_DECISION.md) and [activity decision](outputs/INDEPENDENT_M15_VOLATILITY_SQUEEZE_ACTIVITY_DISCOVERY_DECISION.md).

An independent M30 compression-expansion family was screened on Model 1 using only 2015-2020 discovery data. The source combines a closed-candle compression box and breakout, OHLC expansion/body/close-location tests, optional tick volume, H1 EMA trend and ADX filters, a structure stop capped at `$8`, broker-native risk sizing, and `0.10%` requested risk. All `45 / 45` reports passed the exact embedded source-identity check. The best continuous variant made `+$48.17`, PF `3.59`, and `0.22%` drawdown, but produced only 7 trades against the frozen 100-trade floor. The only other active variant made `+$9.05` continuously but lost `-$9.43` in 2015-2018; the other 13 variants made no trades. With zero eligible profiles, the family was rejected before any 2021-2026 holdout or Model 4 data was opened. See [the decision](outputs/INDEPENDENT_M30_COMPRESSION_EXPANSION_DISCOVERY_DECISION.md).

This screen exposed and fixed a tester-integrity flaw: portable workers could reuse an executable from the previous package. The first M30 batch was therefore quarantined and excluded completely. Every worker now installs and compiles the package's exact source inside its own portable runtime, caches the source/binary identity, and rejects cached or fresh reports unless the embedded evidence source hash matches. The correct-source rerun reproduced all 45 reports and the rejection above; the safety fix is retained even though the strategy failed.

An independent M15 trend-pullback family was screened on Model 1 using only 2015-2020 discovery data. It combined H1 EMA 50/200 alignment and slope, bounded H1 ADX, a prior M15 impulse, an EMA pullback, OHLC rejection-body/wick/close-location tests, optional tick volume, a swing-structure stop, and `0.10%` risk. All `30 / 30` reports parsed, but every one of the ten variants lost money in both the 2019-2020 era and the continuous 2015-2020 window. Continuous PF ranged from `0.22` to `0.52`; even the most selective variant lost `-$49.02` with only 19 trades. The family was rejected before any 2021-2026 holdout or Model 4 data was opened. See [the decision](outputs/INDEPENDENT_M15_TREND_PULLBACK_DISCOVERY_DECISION.md).

This screen also validated a faster local workflow: four isolated portable workers produced 30 reports in roughly two minutes, while preserving the main forward terminal and its installed frozen source/binary after every run. The multi-gigabyte terminal copies and raw reports remain local; only the source, exact profiles/configs, parsed metrics, hashes, safety-guarded runners, and decision are published. The shared report parser now correctly handles MT5 grouped deposits such as `10 000.00`, with a regression test.

The four-worker launcher is now strategy-agnostic. `work/run_mt5_portable_parallel_manifest.ps1` validates any package manifest, derives the expected report count instead of assuming 30 rows, partitions unique queue ranks across isolated workers, retains the explicit focus authorization and CPU/timeout controls, and reports incomplete or errored runs. Its no-MT5 regression test passes, and the complete local safety audit remains `44 / 44`. This makes later research screens faster to start; it does **not** change the frozen candidate or constitute a new performance best.

The preregistered all-Model4 three-lane screen also produced **no new best**. Adding the daily Donchian stream to the same `0.45%` reversion and `0.15%` momentum allocation raised simulated net from `$2,289.01` to `$2,400.22` (`+4.86%`) and slightly reduced risk-floor drawdown from `3.62%` to `3.56%`, but PF fell from `1.605` to `1.582`. The center missed its frozen `5%` improvement threshold, only `1 / 3` Donchian-weight neighbors passed, and only `3 / 7` structural neighbors passed. It was rejected without implementation or post-result tuning. See [the decision](outputs/CLEAN_MODEL4_THREE_LANE_PORTFOLIO_DECISION.md).

## Continuous Result

MT5 Strategy Tester, XAUUSD, Model 4 real ticks, $10,000 initial balance, 2015-01-01 through 2026-07-16:

| Net | Total return | CAGR | Profit factor | Trades | Max equity DD | Recovery |
|---:|---:|---:|---:|---:|---:|---:|
| +$1,615.36 | +16.15% | +1.31%/yr | 1.58 | 362 | 2.83% | 5.22 |

Model 1 produced `+$1,616.49`, PF `1.58`, 370 trades, and `3.24%` drawdown. Every combined Model 1 and Model 4 lane entry and exit exactly matches its independently tested source strategy.

This is the current balanced candidate, not the largest raw historical headline. Earlier `+$10,127.76` and other high-profit figures came from experimental Model 1 profiles with weaker transfer evidence and are not live candidates. The 2015-2026 history selected this candidate; it cannot prove that the same behavior will continue in future market regimes.

## Annual Returns

Percentages use each year's actual starting balance. 2026 is partial through July 16.

| Year | Trades | Net | Return | End balance |
|---|---:|---:|---:|---:|
| 2015 | 21 | +$155.07 | +1.551% | $10,155.07 |
| 2016 | 36 | +$209.32 | +2.061% | $10,364.39 |
| 2017 | 46 | +$170.94 | +1.649% | $10,535.33 |
| 2018 | 50 | +$270.77 | +2.570% | $10,806.10 |
| 2019 | 33 | -$38.30 | -0.354% | $10,767.80 |
| 2020 | 31 | -$44.44 | -0.413% | $10,723.36 |
| 2021 | 30 | +$359.78 | +3.355% | $11,083.14 |
| 2022 | 36 | +$40.07 | +0.362% | $11,123.21 |
| 2023 | 40 | +$144.99 | +1.303% | $11,268.20 |
| 2024 | 31 | +$132.90 | +1.179% | $11,401.10 |
| 2025 | 6 | +$5.08 | +0.045% | $11,406.18 |
| 2026 YTD | 2 | +$209.18 | +1.834% | $11,615.36 |

Broad-era net remains positive: 2015-2018 `+$806.10`, 2019-2022 `+$317.11`, and 2023-2026 `+$492.15`.

## Fresh Starts

Each real-tick window resets the account to $10,000 with the same frozen source and profile:

| Start | Net | CAGR | PF | Trades | DD | Status |
|---|---:|---:|---:|---:|---:|---|
| 2019-01-01 | +$776.17 | +1.00%/yr | 1.47 | 209 | 3.16% | Capital pass; 11 trades below the preregistered activity floor |
| 2021-01-01 | +$854.52 | +1.49%/yr | 1.78 | 145 | 1.49% | Pass |
| 2024-01-01 | +$353.89 | +1.38%/yr | 1.97 | 39 | 1.56% | Pass |

These checks reduce start-date dependence. They do not prove future profitability.

## Stress Evidence

- Extreme added execution cost still returns `+$726.62`, PF `1.222`, with `3.671%` closed-trade drawdown and all broad eras positive.
- Standard 10,000-trial Monte Carlo: 5th-percentile net `+$896.54`, median PF `1.378`, 95th-percentile closed drawdown `4.366%`, no red trials.
- Severe 10,000-trial Monte Carlo: 5th-percentile net `+$286.74`, median PF `1.178`, 95th-percentile closed drawdown `5.770%`, `0.090%` red trials.
- Open warning: randomized 95th-percentile loss streaks reached 14 and 16 trades, above advisory limits of 12 and 14.

## Frozen Identity

| Artifact | SHA-256 |
|---|---|
| EA source | `5BADDE1BC7C1E8020E64F00793058AD5C6174370A866F5D3002FA1FA12248FC3` |
| Base profile | `ECBD1693D09AF6A04CB92F2756442DF8BF0B604118834D1C5E0F50CC57FFEC3E` |
| Model 4 trade ledger | `2F7A8A8854F8F33325498AE0F194202E7BB15F28F2644FC4F9B08DE8B740413B` |
| Continuous Model 4 report | `2354EAD1526FA308211BF9E09167200BFC87313F3575E995A6D2C5B2A116BFFE` |

The source compiles with `0 errors, 0 warnings`. Both published source snapshots are now byte-preserved and independently hash to the manifest's `5BAD...` identity instead of relying on platform line-ending conversion. The profile keeps `InpAllowRealAccountTrading=false` and the real-account safety lock enabled.

## What Remains

1. Provision a `$10,000` demo hedging account, re-register the unchanged candidate, then collect at least 90 calendar days and 30 closed trades.
2. Reproduce the frozen profile on a second broker's XAUUSD specification.
3. Review forward slippage, missed trades, disconnect handling, and the loss-streak warning.
4. Keep live trading disabled until a manual review accepts all remaining evidence.

No backtest can make an EA work forever without monitoring. The future process is to freeze this candidate, observe it without retuning, detect drift, and stop for review when safety limits or expected behavior break.

## Repository Map

- [`release/transferable-portfolio-v0.1`](release/transferable-portfolio-v0.1/README.md): current source, profile, reports, ledgers, stress results, and SHA-256 manifest
- [`outputs/TRANSFERABLE_PORTFOLIO_FORWARD_DEMO_STATUS.md`](outputs/TRANSFERABLE_PORTFOLIO_FORWARD_DEMO_STATUS.md): current frozen forward-demo progress and integrity gates
- [`outputs/TRANSFERABLE_FORWARD_SENTINEL_REGISTRATION.json`](outputs/TRANSFERABLE_FORWARD_SENTINEL_REGISTRATION.json): read-only operational/account contract monitor identity
- [`outputs/TRANSFERABLE_PORTFOLIO_FORWARD_DEMO_ACTIVATION.md`](outputs/TRANSFERABLE_PORTFOLIO_FORWARD_DEMO_ACTIVATION.md): disabled-trading account-switch and clock-start gate
- [`outputs/ADAPTIVE_VOLATILITY_PORTFOLIO_DISCOVERY_DECISION.md`](outputs/ADAPTIVE_VOLATILITY_PORTFOLIO_DISCOVERY_DECISION.md): fixed-control comparison and pre-holdout rejection of bounded inverse-volatility sizing
- [`outputs/ADAPTIVE_VOLATILITY_PORTFOLIO_DISCOVERY_CONTRACT.md`](outputs/ADAPTIVE_VOLATILITY_PORTFOLIO_DISCOVERY_CONTRACT.md): preregistered source identity and control-relative gate
- [`outputs/MARKET_PHASE_PORTFOLIO_DISCOVERY_DECISION.md`](outputs/MARKET_PHASE_PORTFOLIO_DISCOVERY_DECISION.md): fixed-control comparison and pre-holdout rejection of lane-aware phase sizing
- [`outputs/MARKET_PHASE_PORTFOLIO_DISCOVERY_CONTRACT.md`](outputs/MARKET_PHASE_PORTFOLIO_DISCOVERY_CONTRACT.md): preregistered source identity and broad-era repair gate
- [`outputs/EARLY_FAILURE_PORTFOLIO_DISCOVERY_DECISION.md`](outputs/EARLY_FAILURE_PORTFOLIO_DISCOVERY_DECISION.md): fixed-control comparison and pre-holdout rejection of no-follow-through exits
- [`outputs/EARLY_FAILURE_PORTFOLIO_DISCOVERY_CONTRACT.md`](outputs/EARLY_FAILURE_PORTFOLIO_DISCOVERY_CONTRACT.md): preregistered source identity and exit-behavior gate
- [`outputs/TWO_BAR_CONFIRMATION_PORTFOLIO_DISCOVERY_DECISION.md`](outputs/TWO_BAR_CONFIRMATION_PORTFOLIO_DISCOVERY_DECISION.md): fixed-control comparison and pre-holdout rejection of two-bar entry confirmation
- [`outputs/TWO_BAR_CONFIRMATION_PORTFOLIO_DISCOVERY_CONTRACT.md`](outputs/TWO_BAR_CONFIRMATION_PORTFOLIO_DISCOVERY_CONTRACT.md): preregistered source identity and entry-confirmation gate
- [`outputs/TRANSFERABLE_PORTFOLIO_GROWTH_DISCOVERY_DECISION.md`](outputs/TRANSFERABLE_PORTFOLIO_GROWTH_DISCOVERY_DECISION.md): exact-source allocation-efficiency rejection against the released control
- [`outputs/TRANSFERABLE_PORTFOLIO_GROWTH_DISCOVERY_CONTRACT.md`](outputs/TRANSFERABLE_PORTFOLIO_GROWTH_DISCOVERY_CONTRACT.md): frozen growth, broad-era, and drawdown gate
- [`outputs/INDEPENDENT_M15_DAILY_VWAP_CONTINUATION_DISCOVERY_DECISION.md`](outputs/INDEPENDENT_M15_DAILY_VWAP_CONTINUATION_DISCOVERY_DECISION.md): exact-source 36-report rejection of daily-VWAP trend continuation
- [`outputs/INDEPENDENT_M15_DAILY_VWAP_CONTINUATION_DISCOVERY_CONTRACT.md`](outputs/INDEPENDENT_M15_DAILY_VWAP_CONTINUATION_DISCOVERY_CONTRACT.md): frozen pre-holdout broad-era and risk gate
- [`outputs/INDEPENDENT_M15_DUAL_REGIME_PORTFOLIO_HOLDOUT_DECISION.md`](outputs/INDEPENDENT_M15_DUAL_REGIME_PORTFOLIO_HOLDOUT_DECISION.md): untouched 2021-2026 YTD rejection for the combined M15 portfolio
- [`outputs/INDEPENDENT_M15_DUAL_REGIME_PORTFOLIO_DISCOVERY_DECISION.md`](outputs/INDEPENDENT_M15_DUAL_REGIME_PORTFOLIO_DISCOVERY_DECISION.md): pre-2021 discovery pass and frozen survivor table
- [`outputs/INDEPENDENT_M15_VOLUME_CLIMAX_REVERSAL_ACTIVITY_DISCOVERY_DECISION.md`](outputs/INDEPENDENT_M15_VOLUME_CLIMAX_REVERSAL_ACTIVITY_DISCOVERY_DECISION.md): final pre-holdout activity rejection for the exact-source M15 volume-climax family
- [`outputs/INDEPENDENT_M15_VOLUME_CLIMAX_REVERSAL_DISCOVERY_DECISION.md`](outputs/INDEPENDENT_M15_VOLUME_CLIMAX_REVERSAL_DISCOVERY_DECISION.md): initial M15 volume-climax/VWAP-reversion discovery rejection and full table
- [`outputs/INDEPENDENT_M15_VOLATILITY_SQUEEZE_ACTIVITY_DISCOVERY_DECISION.md`](outputs/INDEPENDENT_M15_VOLATILITY_SQUEEZE_ACTIVITY_DISCOVERY_DECISION.md): final pre-holdout activity rejection for the exact-source M15 squeeze family
- [`outputs/INDEPENDENT_M15_VOLATILITY_SQUEEZE_DISCOVERY_DECISION.md`](outputs/INDEPENDENT_M15_VOLATILITY_SQUEEZE_DISCOVERY_DECISION.md): initial independent M15 squeeze discovery rejection and full table
- [`outputs/INDEPENDENT_M30_COMPRESSION_EXPANSION_DISCOVERY_DECISION.md`](outputs/INDEPENDENT_M30_COMPRESSION_EXPANSION_DISCOVERY_DECISION.md): exact-source independent M30 rejection and discovery table
- [`outputs/INDEPENDENT_M15_TREND_PULLBACK_DISCOVERY_DECISION.md`](outputs/INDEPENDENT_M15_TREND_PULLBACK_DISCOVERY_DECISION.md): latest independent strategy-family rejection and full discovery table
- [`outputs/CLEAN_MODEL4_THREE_LANE_PORTFOLIO_DECISION.md`](outputs/CLEAN_MODEL4_THREE_LANE_PORTFOLIO_DECISION.md): latest rejected diversification screen
- [`research`](research): dated research notes and rejected strategy branches
- [`outputs`](outputs): historical generated evidence
- [`work`](work): local validation and analysis tooling
- [`patches`](patches): historical experimental patches
- [`.github/workflows/static-safety.yml`](.github/workflows/static-safety.yml): manual-only static checks; no automatic Actions runs

## Risk Notice

This repository is research software, not financial advice. Backtests can be wrong, market regimes change, broker execution differs, and losses can exceed modeled results. Do not fund the candidate based only on these historical tests.
