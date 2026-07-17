# Professional XAUUSD EA

Research and validation repository for a risk-first MetaTrader 5 Expert Advisor on XAUUSD. No martingale, grid, averaging down, or recovery sizing.

## Current Status

**Best balanced executable: Transferable Portfolio v0.1**

**Forward-test candidate only. Real-account trading remains disabled.**

The candidate combines two date-independent H1 strategies:

- Band/VWAP mean reversion at `0.45%` requested risk
- E20 multiscale momentum at `0.15%` requested risk
- Shared open-risk cap: `0.75%`
- Shared maximum equity drawdown guard: `5.00%`
- Hedging account required

Exact tested files and evidence are in [`release/transferable-portfolio-v0.1`](release/transferable-portfolio-v0.1/README.md).

## Continuous Result

MT5 Strategy Tester, XAUUSD, Model 4 real ticks, $10,000 initial balance, 2015-01-01 through 2026-07-16:

| Net | Total return | CAGR | Profit factor | Trades | Max equity DD | Recovery |
|---:|---:|---:|---:|---:|---:|---:|
| +$1,615.36 | +16.15% | +1.31%/yr | 1.58 | 362 | 2.83% | 5.22 |

Model 1 produced `+$1,616.49`, PF `1.58`, 370 trades, and `3.24%` drawdown. Every combined Model 1 and Model 4 lane entry and exit exactly matches its independently tested source strategy.

This is the current balanced candidate, not the largest raw historical headline. Earlier `+$10,127.76` and other high-profit figures came from experimental Model 1 profiles with weaker transfer evidence and are not live candidates.

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

The source compiles with `0 errors, 0 warnings`. The profile keeps `InpAllowRealAccountTrading=false` and the real-account safety lock enabled.

## What Remains

1. Demo/forward test for at least 90 calendar days and until at least 30 trades close.
2. Reproduce the frozen profile on a second broker's XAUUSD specification.
3. Review forward slippage, missed trades, disconnect handling, and the loss-streak warning.
4. Keep live trading disabled until a manual review accepts all remaining evidence.

No backtest can make an EA work forever without monitoring. The future process is to freeze this candidate, observe it without retuning, detect drift, and stop for review when safety limits or expected behavior break.

## Repository Map

- [`release/transferable-portfolio-v0.1`](release/transferable-portfolio-v0.1/README.md): current source, profile, reports, ledgers, stress results, and SHA-256 manifest
- [`research`](research): dated research notes and rejected strategy branches
- [`outputs`](outputs): historical generated evidence
- [`work`](work): local validation and analysis tooling
- [`patches`](patches): historical experimental patches
- [`.github/workflows/static-safety.yml`](.github/workflows/static-safety.yml): manual-only static checks; no automatic Actions runs

## Risk Notice

This repository is research software, not financial advice. Backtests can be wrong, market regimes change, broker execution differs, and losses can exceed modeled results. Do not fund the candidate based only on these historical tests.
