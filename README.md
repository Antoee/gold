# Professional XAUUSD EA

Research and validation repository for a risk-first MetaTrader 5 Expert Advisor on XAUUSD. No martingale, grid, averaging down, or recovery sizing.

## Current Status

**Best balanced executable: Transferable Portfolio v0.1**

**Forward-test candidate only. Real-account trading remains disabled.**

**2026-07-17 update: no new best was promoted. The first forward attachment was invalidated before its first trade because the demo account had the wrong starting balance, and a new independent M15 trend-pullback family failed discovery.**

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
| [FAIL: capital mismatch](outputs/TRANSFERABLE_PORTFOLIO_FORWARD_DEMO_STATUS.md) | Not started / 90 | 0 / 30 | $0.00 | Code/log identity PASS; account contract FAIL |

No trades occurred, so no evidence was lost. The forward clock will restart only after the same frozen candidate is attached to a correctly capitalized `$10,000` demo hedging account. No performance decision is allowed until **both** 90 valid calendar days and 30 trades have closed. A first-stage pass requires positive net profit, profit factor at least `1.10`, closed-trade drawdown no more than `5.00%`, and no more than 12 consecutive losses. Even a pass authorizes only a second-broker demo test, not real-money trading.

The forward profile keeps the same trading and risk inputs as the released base profile. Only evidence logging, dashboard visibility, and the frozen run label differ. The sentinel cannot trade and publishes no account identifier. See the [registration](outputs/TRANSFERABLE_PORTFOLIO_FORWARD_DEMO_REGISTRATION.json), [profile](outputs/TRANSFERABLE_PORTFOLIO_FORWARD_DEMO_PROFILE.set), [sentinel registration](outputs/TRANSFERABLE_FORWARD_SENTINEL_REGISTRATION.json), and [monitor package](outputs/TRANSFERABLE_PORTFOLIO_FORWARD_DEMO_PACKAGE.md).

The replacement-account activation gate is prepared but has not been executed. Terminal-level and sentinel-chart algorithmic trading are now disabled, the account-creation dialog was canceled without accepting terms, and no registration timestamp was changed. The disabled-trading check passes; the gate still refuses registration because starting balance and equity are `$100,000` instead of the frozen `$10,000`. It also preserves the demo hedging, identity, flat-account, zero-risk, and empty-log requirements. A separate verification is required after trading is re-enabled. Creating the new virtual account still awaits explicit acceptance of MetaQuotes' terms. See the [activation procedure](outputs/TRANSFERABLE_PORTFOLIO_FORWARD_DEMO_ACTIVATION.md).

## Latest Research Screens

An independent M15 trend-pullback family was screened on Model 1 using only 2015-2020 discovery data. It combined H1 EMA 50/200 alignment and slope, bounded H1 ADX, a prior M15 impulse, an EMA pullback, OHLC rejection-body/wick/close-location tests, optional tick volume, a swing-structure stop, and `0.10%` risk. All `30 / 30` reports parsed, but every one of the ten variants lost money in both the 2019-2020 era and the continuous 2015-2020 window. Continuous PF ranged from `0.22` to `0.52`; even the most selective variant lost `-$49.02` with only 19 trades. The family was rejected before any 2021-2026 holdout or Model 4 data was opened. See [the decision](outputs/INDEPENDENT_M15_TREND_PULLBACK_DISCOVERY_DECISION.md).

This screen also validated a faster local workflow: four isolated portable workers produced 30 reports in roughly two minutes, while preserving the main forward terminal and its installed frozen source/binary after every run. The multi-gigabyte terminal copies and raw reports remain local; only the source, exact profiles/configs, parsed metrics, hashes, safety-guarded runners, and decision are published. The shared report parser now correctly handles MT5 grouped deposits such as `10 000.00`, with a regression test.

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
- [`outputs/INDEPENDENT_M15_TREND_PULLBACK_DISCOVERY_DECISION.md`](outputs/INDEPENDENT_M15_TREND_PULLBACK_DISCOVERY_DECISION.md): latest independent strategy-family rejection and full discovery table
- [`outputs/CLEAN_MODEL4_THREE_LANE_PORTFOLIO_DECISION.md`](outputs/CLEAN_MODEL4_THREE_LANE_PORTFOLIO_DECISION.md): latest rejected diversification screen
- [`research`](research): dated research notes and rejected strategy branches
- [`outputs`](outputs): historical generated evidence
- [`work`](work): local validation and analysis tooling
- [`patches`](patches): historical experimental patches
- [`.github/workflows/static-safety.yml`](.github/workflows/static-safety.yml): manual-only static checks; no automatic Actions runs

## Risk Notice

This repository is research software, not financial advice. Backtests can be wrong, market regimes change, broker execution differs, and losses can exceed modeled results. Do not fund the candidate based only on these historical tests.
