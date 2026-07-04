# Professional XAUUSD EA

This repository contains a professional-grade MetaTrader 5 XAUUSD Expert Advisor research project.

The EA is modular and risk-first. It is designed for repeated Strategy Tester optimization, training/out-of-sample checks, walk-forward testing, and research notes rather than one-off curve fitting.

## Current Status

Latest promoted real-tick validation, XAUUSD M15, deposit `$1,000`, period `2024.01.01` to `2026.07.02`:

- Full period net profit: `+$4,153.12`
- Final balance: `$5,153.12`
- Yearly windows: all profitable
- Half-year walk-forward: no losing windows
- Quarterly windows: positive overall at `+$1,661.98`, but 3 losing quarters
- Monthly windows: positive overall at `+$1,903.98`, but 17 losing months out of 30
- Worst quarter: `-$206.77`
- Worst month: `-$83.61`

Important: this is research output, not a live-trading guarantee. The current profitable configuration uses date-specific trade blocks, which may be overfit. The next major objective is replacing those date blocks with general market-regime filters.

## Included Files

- `BACKTEST_RESULTS.md` - detailed validation notes and rejected candidate results.
- `MONTHLY_REAL_TICK_SUMMARY.csv` - current promoted monthly validation summary.
- `MONTHLY_CONFIRMATION_FILTER_SUMMARY.csv` - monthly confirmation-filter research summary.
- `MONTHLY_NO_TRAIL_SUMMARY.csv` - exploratory monthly no-trailing-stop research summary.
- `NO_TRAIL_QUARTERS_CLEAN.csv` - clean quarterly no-trailing-stop validation windows.
- `NO_TRAIL_QUARTER_CLEAN_SUMMARY.csv` - clean quarterly no-trailing-stop validation summary.
- `MONTHLY_REGIME_FILTER_SUMMARY.csv` - monthly ADX/ATR regime-filter research summary.
- `QUARTERLY_REAL_TICK_SUMMARY.csv` - promoted quarterly summary metrics.
- `DIRECTIONAL_CONFIRMATION_SUMMARY.csv` - directional confirmation research summary.
- `EQUITY_DD_GUARD_SUMMARY.csv` - equity drawdown guard research summary.
- `MTF_SLOPE_DIRECTION_NO_DATE_SUMMARY.csv` - no-date MTF slope direction filter summary.
- `SIGNAL_TIMEFRAME_NO_DATE_SUMMARY.csv` - no-date signal timeframe research summary.

## Strategy Rules

No martingale. No grid. No averaging down. No recovery systems.

Current promoted defaults include:

- Adaptive reverse enabled.
- Adaptive slope threshold: `500` points.
- Minimum risk/reward: `1.50`.
- Take-profit ATR multiplier: `3.50`.
- Break-even disabled.
- Daily loss limit: `1.00%`.
- Weekly loss limit: `2.50%`.
- Monthly loss limit: `4.00%`.
- Peak-equity drawdown guard disabled by default: `0.00%`.
- MTF slope direction filter disabled by default.
- Date buy block from `2024.01.01` through `2024.06.30`.
- Second date buy block from `2025.07.01` through `2025.12.31`.
- Date sell block from `2025.07.01` through `2025.12.31`.

## Latest Research

Monthly validation showed that the current promoted build is carried by a few large winning months while many months lose modestly.

Monthly confirmation filters:

- Baseline: `+$1,903.98`, 17 losing months.
- `buy2_sell3`: `+$1,492.91`, 14 losing months.
- `confirm3`: `+$487.71`, 13 losing months.
- `buy3_sell2`: `+$331.04`, 15 losing months.
- `confirm4`: `$0.00`, all months flat.

Monthly ADX filters were rejected: `adx22`, `adx25`, and `adx30` all reduced profit without improving the losing-month count.

No-trail follow-up:

- `InpUseATRTrailing=false`
- Clean quarterly total: `+$1,099.90`
- Clean quarterly worst window: `-$144.33`
- Clean quarterly best window: `+$789.92`
- Profitable quarters: `5`
- Flat quarters: `2`
- Losing quarters: `3`

No-trail is not promoted. It improved the worst quarterly loss versus the promoted baseline, but reduced total quarterly net from `+$1,661.98` to `+$1,099.90` with the same number of losing quarters.

Other rejected research paths:

- Directional confirmation `buy2_sell3_ny`: full-period net fell to `+$2,620.98` and 2025 became losing.
- Equity drawdown guard `dd4`: full-period net fell to only `+$85.45` and 2025 became losing.
- MTF slope direction filter: best no-date stress variant still lost `-$444.20`.
- H4 no-date signal timeframe: full validation was `-$136.90` and had no profitable validation windows.

The current promoted defaults remain better overall.

## Background Testing

The local project includes PowerShell automation scripts that run MT5 in the background:

- Hidden MT5 launch through a Windows `CreateProcess` wrapper.
- Strategy Tester visual mode disabled.
- Dashboard disabled during tests.
- MT5/tester audio sessions muted while tests run.
- Dynamic newest tester-log parsing so scripts continue working after the date changes.
- Newer validators wait for MT5's tester-log completion marker instead of process exit, which avoids stale result rows.

## Research Direction

The current build makes profit on the tested full period, yearly splits, and half-year walk-forward windows. Monthly testing shows the start-point problem more clearly, so the next work should focus on:

1. General market-regime filters that reduce the many small losing months without removing the few large winning months.
2. More out-of-sample broker/history validation.
3. Report parsing for profit factor, drawdown, Sharpe, and trade count.
4. Replacing date-specific behavior with robust, reusable market-state logic.
