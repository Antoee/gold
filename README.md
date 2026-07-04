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
- Worst quarter: `-$206.77`

Important: this is research output, not a live-trading guarantee. The current profitable configuration uses date-specific trade blocks, which may be overfit. The next major objective is replacing those date blocks with general market-regime filters.

## Included Files

- `BACKTEST_RESULTS.md` - detailed validation notes and rejected candidate results.
- `QUARTERLY_REAL_TICK_WINDOWS.csv` - current promoted quarterly validation.
- `QUARTERLY_REAL_TICK_SUMMARY.csv` - quarterly summary metrics.
- `LOSING_QUARTER_COMBO_SUMMARY.csv` - weak-quarter combo probe summary.
- `DIRECTIONAL_CONFIRMATION_SUMMARY.csv` - directional confirmation research summary.
- `EQUITY_DD_GUARD_SUMMARY.csv` - equity drawdown guard research summary.
- `MTF_SLOPE_DIRECTION_NO_DATE_SUMMARY.csv` - no-date MTF slope direction filter summary.

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

Optional directional-confirmation module:

- `InpUseDirectionalConfirmations=false` by default.
- `InpBuyMinimumConfirmations=2`.
- `InpSellMinimumConfirmations=2`.

Best tested candidate, `buy2_sell3_ny`, improved weak-quarter total to `+$109.70`, but it was rejected as a promoted default because full-period net fell to `+$2,620.98` and 2025 became losing.

Optional equity drawdown guard:

- `InpMaxEquityDrawdownPercent=0.00` by default.

Best weak-quarter threshold, `dd4`, improved worst quarter to `-$87.32`, but it was rejected as a promoted default because full-period net fell to only `+$85.45` and 2025 became losing.

Optional MTF slope direction filter:

- `InpUseMTFSlopeDirectionFilter=false` by default.

No-date stress tests failed across all tested slope variants. Best tested variant still lost `-$444.20` across the stress set, so it is not a date-block replacement.

The current promoted defaults remain better overall.

## Background Testing

The local project includes PowerShell automation scripts that run MT5 in the background:

- Hidden MT5 launch through a Windows `CreateProcess` wrapper.
- Strategy Tester visual mode disabled.
- Dashboard disabled during tests.
- MT5/tester audio sessions muted while tests run.
- Dynamic newest tester-log parsing so scripts continue working after the date changes.

## Research Direction

The current build makes profit on the tested full period, yearly splits, and half-year walk-forward windows. Quarterly testing still reveals weak regimes, so the next work should focus on:

1. General market-regime filters for the weak quarters.
2. More out-of-sample broker/history validation.
3. Report parsing for profit factor, drawdown, Sharpe, and trade count.
4. Fast sweeps first, then real-tick validation only for promising candidates.
