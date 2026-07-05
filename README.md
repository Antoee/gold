# Professional XAUUSD EA

This repository contains a professional-grade MetaTrader 5 XAUUSD Expert Advisor research project.

The EA is modular and risk-first. It is designed for repeated Strategy Tester optimization, training/out-of-sample checks, walk-forward testing, and research notes rather than one-off curve fitting.

## Current Status

The promoted default is the robust no-date BOS + liquidity-sweep profile at `1.60%` risk with a `1.80` ATR stop multiplier and `3.50` ATR take-profit multiplier. It sacrifices raw historical profit to improve start-date robustness and remove hard-coded calendar blocks.

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

- `Professional_XAUUSD_EA.mq5` - GitHub EA source for the modular XAUUSD MT5 Expert Advisor; compile/test status still needs controlled verification.
- `SOURCE_MANIFEST.md` - EA source fingerprint and static verification state.
- `BACKTEST_RESULTS.md` - detailed validation notes and rejected candidate results.
- `NEXT_VALIDATION_QUEUE.md` - candidates waiting for full validation before promotion.
- `NEXT_VALIDATION_RUNBOOK.md` - safe validation order and promotion gate.
- `PROMOTION_GATE_REPORT.md` - offline promotion-readiness check for queued profiles.
- `PROFILE_INPUT_AUDIT.md` - offline check that active `.set` files pin all critical inputs.
- `ROBUST_CANDIDATE_RANKING.md` - offline robust-candidate ranking from existing CSV results.
- `LOSS_CONTROL_REPORT.md` - offline loss-control ranking from existing CSV windows.
- `outputs/CONTROLLED_PROFIT_TEST_RUNBOOK.md` - no-popup testing policy and current validation workflow.
- `outputs/micro_test_handoff/` - 8-config paired stress micro handoff for fast candidate-vs-baseline validation.
- `outputs/recent_oos_handoff/` - 8-config paired recent out-of-sample handoff for 2025_Q4 and 2026 freshness checks.
- `work/MT5_LOCAL_LAUNCH_DISABLED.lock` - active hard lock that prevents guarded local MT5 launches.
- `work/stop_mt5_stray_processes.ps1` - cleanup-only helper for stopping already-running MT5/MetaTester/MetaEditor processes.
- `ROBUST_BOS_SWEEP_PROFILE.set` - promoted robust BOS/sweep MT5 settings profile.
- `CANDIDATE_RISK16_SL18_TP38_PROFILE.set` - queued candidate: risk `1.60`, stop ATR `1.80`, TP ATR `3.80`, equity drawdown guard `4.00%`.
- `CANDIDATE_RISK16_SL16_TP38_PROFILE.set` - queued candidate: risk `1.60`, stop ATR `1.60`, TP ATR `3.80`, equity drawdown guard `4.00%`.
- `CANDIDATE_RISK16_SL18_TP35_GIVEBACK_PROFILE.set` - queued loss-control candidate with the profit giveback guard enabled.
- `RISK16_NEIGHBORHOOD_SUMMARY.csv` - latest stress-window sweep summary around the promoted profile.
- `BOS_SWEEP_WINDOWS_risk1p6_sl18_tp35.csv` - promoted robust profile quarterly/monthly windows.
- `BOS_SWEEP_WINDOW_SUMMARY_risk1p6_sl18_tp35.csv` - promoted robust profile quarterly/monthly summary.
- `BOS_SWEEP_SPLITS_risk1p6_sl18_tp35.csv` - promoted robust profile yearly/half/full windows.
- `BOS_SWEEP_SPLIT_SUMMARY_risk1p6_sl18_tp35.csv` - promoted robust profile split summary.
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
- Profit giveback guard disabled by default.

## Profit Giveback Guard

The EA source includes an optional profit giveback guard for loss-control research.

- `InpUseProfitGivebackGuard` enables or disables the module.
- The guard tracks daily, weekly, and monthly peak closed profit.
- It blocks new entries if current period profit gives back too much of that peak.
- It does not close existing positions by itself.
- The promoted profile keeps it disabled; `CANDIDATE_RISK16_SL18_TP35_GIVEBACK_PROFILE.set` enables it for validation.

## Optimization Scoring

The EA source includes an `OnTester()` custom optimization score for MT5 Strategy Tester.

- Default mode is `FITNESS_ROBUST_PROFIT`, which rewards net profit and profit factor while penalizing low trade count and excessive equity drawdown.
- `FITNESS_NET_PROFIT` is available when raw-profit sorting is needed for comparison.
- `FITNESS_RECOVERY_SHARPE` is available for research passes that should emphasize recovery factor and Sharpe ratio.
- The promoted and queued `.set` profiles pin these optimizer inputs.
- This does not change live trade behavior; it only changes the custom criterion returned to MT5 Strategy Tester optimization.

## Latest Research

Queued candidates from the latest risk/stop/target neighborhood stress sweep:

- `risk160_sl18_tp38`: stress-window total `+$798.00`, worst `$0.00`, 2 profitable, 5 flat, 0 losing. Needs stress micro, recent out-of-sample, then full monthly/quarter/split validation before promotion.
- `risk160_sl16_tp38`: stress-window total `+$798.00`, worst `$0.00`, 2 profitable, 5 flat, 0 losing. Needs stress micro, recent out-of-sample, then full monthly/quarter/split validation before promotion.
- `risk160_sl18_tp35_giveback`: same core as the promoted profile, with the profit giveback guard enabled. Needs full loss-control validation before promotion.

Best no-date profiles found so far:

- Robust BOS+sweep at `1.60%` risk, `1.80` stop ATR, `3.50` TP ATR: full period `+$866.59`, monthly `+$744.03`, 0 losing months, promoted default.
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

## Background Testing Safety

Local MT5 launch is intentionally hard-locked because terminal/metatester windows can still flash and steal focus on this PC.

- Do not run local MT5 tests from this active desktop while normal PC use must remain uninterrupted.
- `work/MT5_LOCAL_LAUNCH_DISABLED.lock` must stay in place. Guarded scripts refuse to launch MT5 while it exists.
- The launch guard and background helper stop `terminal`, `terminal64`, `metatester`, `metatester64`, `MetaEditor`, and `metaeditor64` before failing closed.
- `work/stop_mt5_stray_processes.ps1` is cleanup-only. It starts no tester process.
- Future backtests should run on a Windows VM, spare machine, VPS, or a deliberate controlled local session where focus stealing is acceptable.
- Until exported reports are available from a non-interrupting tester environment, repository/documentation/offline analysis work can continue without launching MT5.

## Research Direction

Next work should focus on increasing profit from the robust no-date profile without bringing back losing monthly windows.

1. Run the paired stress micro handoff, then the recent out-of-sample handoff through 2026, before spending time on the full validation queue.
2. Fully validate surviving `3.80` TP candidates and the giveback candidate across monthly, quarterly, yearly, half-year, and full-period windows on a non-interrupting tester environment.
3. Rerun `work/audit_profile_inputs.ps1` after changing `.set` files so MT5 cannot reuse stale cached inputs unnoticed.
4. Rerun `work/analyze_promotion_gate.ps1` and promote only candidates that pass full, split, quarterly, and monthly gates.
5. Test on additional broker/history sources.
6. Use the custom optimization criterion to rank candidates by robustness, not only raw net profit.
7. Keep the date-block profile as a benchmark, not the default.
