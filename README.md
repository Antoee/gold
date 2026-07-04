# Professional XAUUSD EA

This repository contains a professional-grade MetaTrader 5 XAUUSD Expert Advisor research project.

The EA is modular and risk-first. It is designed for repeated Strategy Tester optimization, training/out-of-sample checks, walk-forward testing, and research notes rather than one-off curve fitting.

## Current Status

The promoted default is now the robust no-date BOS + liquidity-sweep profile at `1.60%` risk with a `1.80` ATR stop multiplier. It sacrifices raw historical profit to improve start-date robustness and remove hard-coded calendar blocks.

Latest promoted real-tick validation, XAUUSD M15, deposit `$1,000`, period `2024.01.01` to `2026.07.02`:

- Full period net profit: `+$866.59`
- Final balance: `$1,866.59`
- Yearly windows: `2024 +$483.59`, `2025 +$260.44`, `2026 YTD $0.00`
- Half-year windows: no losing windows; `2024 H2 +$483.59`, `2025 H2 +$260.44`, other tested half-years flat
- Quarterly windows: `+$744.03`, 2 profitable, 8 flat, 0 losing
- Monthly windows: `+$744.03`, 2 profitable, 28 flat, 0 losing
- Worst month/quarter/split window: `$0.00`

This replaces the previous `1.50%` risk / `1.80` stop ATR profile, which made `+$521.12` full-period and still had one losing monthly/quarter/split window.

The previous date-block profile remains an aggressive research benchmark: full period `+$4,153.12`, but 17 losing months out of 30 and hard-coded calendar filters.

## Included Files

- `BACKTEST_RESULTS.md` - detailed validation notes and rejected candidate results.
- `ROBUST_BOS_SWEEP_PROFILE.set` - promoted robust BOS/sweep MT5 settings profile.
- `BOS_SWEEP_WINDOWS_risk1p6_sl18_tp35.csv` - promoted robust profile quarterly/monthly windows.
- `BOS_SWEEP_WINDOW_SUMMARY_risk1p6_sl18_tp35.csv` - promoted robust profile quarterly/monthly summary.
- `BOS_SWEEP_SPLITS_risk1p6_sl18_tp35.csv` - promoted robust profile yearly/half/full windows.
- `BOS_SWEEP_SPLIT_SUMMARY_risk1p6_sl18_tp35.csv` - promoted robust profile split summary.
- `BOS_SWEEP_WINDOWS_risk1p5_sl18_tp35.csv` - previous robust profile quarterly/monthly windows.
- `BOS_SWEEP_WINDOW_SUMMARY_risk1p5_sl18_tp35.csv` - previous robust profile quarterly/monthly summary.
- `BOS_SWEEP_SPLITS_risk1p5_sl18_tp35.csv` - previous robust profile yearly/half/full windows.
- `BOS_SWEEP_SPLIT_SUMMARY_risk1p5_sl18_tp35.csv` - previous robust profile split summary.
- `BOS_SWEEP_PROFIT_EXTENSION_SUMMARY.csv` - focused profit-extension sweep around the prior robust profile.
- `GENERAL_REGIME_STRESS_SUMMARY.csv` - no-date general regime stress sweep summary.
- `BOS_SWEEP_VARIANT_SUMMARY.csv` - BOS/sweep variant stress summary.
- `MONTHLY_REAL_TICK_SUMMARY.csv` - previous aggressive date-block monthly validation summary.
- `QUARTERLY_REAL_TICK_SUMMARY.csv` - previous aggressive date-block quarterly summary metrics.

## Strategy Rules

No martingale. No grid. No averaging down. No recovery systems.

Current promoted defaults include:

- Risk per trade: `1.60%`.
- Adaptive reverse enabled.
- Adaptive slope threshold: `500` points.
- Minimum risk/reward: `1.50`.
- Stop-loss ATR multiplier: `1.80`.
- Take-profit ATR multiplier: `3.50`.
- Break-even disabled.
- Daily loss limit: `1.00%`.
- Weekly loss limit: `2.50%`.
- Monthly loss limit: `4.00%`.
- Date buy/sell blocks disabled.
- EMA cross, momentum candle, and engulfing confirmations disabled.
- BOS and liquidity sweep enabled with `InpMinimumConfirmations=2`.

## Latest Research

Best no-date profiles found so far:

- Robust BOS+sweep at `1.60%` risk, `1.80` stop ATR: full period `+$866.59`, monthly `+$744.03`, 0 losing months, promoted default.
- Robust BOS+sweep at `1.50%` risk, `1.80` stop ATR: full period `+$521.12`, monthly `+$540.51`, 1 losing month, previous default.
- Robust BOS+sweep at `1.50%` risk, `2.20` stop ATR: full period `+$452.75`, monthly `+$487.46`, 1 losing month, older default.
- Robust BOS+sweep at `2.00%` risk: full period `+$321.72`, 0 losing monthly/quarterly/split windows, safer but lower profit.
- Momentum+sweep no-date: full period `+$664.59`, but still 17 losing months, not promoted.

Rejected or non-promoted paths:

- Risk `1.75%` made more in one stress sweep, but worsened the worst loss in that earlier profile, so it was not promoted.
- Monthly ADX filters reduced profit without improving losing-month count.
- No-trail improved worst quarter but reduced quarterly net too much.
- Directional confirmation `buy2_sell3_ny` made 2025 losing.
- Equity drawdown guard `dd4` cut full-period net to only `+$85.45`.
- H4 no-date signal timeframe avoided trades but did not make profit.

## Background Testing

The local project includes PowerShell automation scripts that run MT5 in the background:

- Hidden MT5 launch through a Windows `CreateProcess` wrapper.
- Active window hiding for MT5/tester windows during runs.
- Strategy Tester visual mode disabled.
- Dashboard disabled during tests.
- MT5/tester audio sessions muted while tests run.
- MT5/tester processes lowered to below-normal priority.
- Validators wait for MT5's tester-log completion marker instead of process exit, which avoids stale result rows.

## Research Direction

Next work should focus on increasing profit from the robust no-date profile without bringing back losing monthly windows.

1. Tune BOS/sweep entry filters and risk conservatively.
2. Test on additional broker/history sources.
3. Add drawdown/profit-factor extraction from reports, not only final balance.
4. Keep the date-block profile as a benchmark, not the default.
