# Professional XAUUSD EA

This deliverable is a first professional scaffold for an MT5 XAUUSD Expert Advisor. It is intentionally modular and research-oriented: every major behavior is exposed as an input so you can optimize features independently and run training, out-of-sample, and walk-forward tests.

## Files

- `Professional_XAUUSD_EA.mq5` - MT5 Expert Advisor source.
- `README_Professional_XAUUSD_EA.md` - this guide.
- `BACKTEST_RESULTS.md` - current validation notes.
- `PROMOTION_GATE_REPORT.md` - offline promotion readiness check for queued profiles.
- `PROFILE_INPUT_AUDIT.md` - offline check that active `.set` files pin all critical inputs.
- `VALIDATION_REPORT_METRICS.md` - offline parser summary for exported MT5 reports, including drawdown and profit-factor fields when available.
- `ADAPTIVE_REAL_TICK_WINDOWS.csv` - latest adaptive real-tick split results.
- `ADAPTIVE_REAL_TICK_SUMMARY.csv` - latest adaptive real-tick summary.
- `REAL_TICK_WINDOW_RESULTS.csv` - promoted default split-window validation.
- `FULL_REAL_TICK_DEFAULT.csv` - promoted default full-period validation.
- `WALK_FORWARD_REAL_TICK_WINDOWS.csv` - promoted default half-year walk-forward validation.
- `QUARTERLY_REAL_TICK_WINDOWS.csv` - promoted default quarterly validation.
- `LOSING_QUARTER_COMBO_PROBES.csv` - latest weak-quarter research probes.

## Background Testing Safety

Local MT5 launch is currently hard-locked because `terminal64.exe` can still flash and steal focus on this PC. The shared launcher and legacy MT5 runner scripts refuse to start unless both of these are deliberately set after a controlled test:

- `ALLOW_MT5_FOCUS_RISK=1`
- `work\ALLOW_MT5_LOCAL_LAUNCH.unlock`

Do not run local MT5 validation until the hidden-desktop runner has been deliberately verified.

## Current Promoted Defaults

The current promoted defaults prioritize start-date robustness over maximum historical profit. This is still research output, not a live-trading guarantee.

- Adaptive reverse enabled.
- Adaptive slope threshold: `500` points.
- Risk per trade: `1.60%`.
- Minimum risk/reward: `1.50`.
- Stop-loss ATR multiplier: `1.80`.
- Take-profit ATR multiplier: `3.50`.
- Break-even disabled.
- Daily loss limit: `1.00%`.
- Weekly loss limit: `2.50%`.
- Monthly loss limit: `4.00%`.
- Peak-equity drawdown guard disabled by default: `0.00%`.
- Date buy/sell blocks disabled by default.
- EMA cross, momentum candle, and engulfing confirmations disabled by default.
- BOS and liquidity-sweep confirmations enabled with `InpMinimumConfirmations=2`.
- Optional MTF up-slope sell block is included for research, but disabled by default.

Latest real-tick validation:

- Full period `2024.01.01` to `2026.07.02`: `+$866.59` from `$1,000`.
- Yearly windows: `2024 +$483.59`, `2025 +$260.44`, `2026 YTD $0.00`.
- Half-year windows: no losing windows; `2024 H2 +$483.59`, `2025 H2 +$260.44`, other tested half-years flat.
- Quarterly validation: `+$744.03`, worst quarter `$0.00`, 2 profitable, 8 flat, 0 losing.
- Monthly validation: `+$744.03`, worst month `$0.00`, 2 profitable, 28 flat, 0 losing.

Aggressive high-profit research profile:

- The previous date-block profile made `+$4,153.12` on the full period, but it used date-specific blocks and had 17 losing months out of 30.
- Keep it as a research profile only until it can be replaced by general market-regime rules.

## Validation Workflow

1. Compile with default settings.
2. Run XAUUSD M15 on a training window.
3. Export the Strategy Tester report.
4. Run the exact same settings on an out-of-sample window.
5. Disable one confirmation/filter at a time to identify which modules add value.
6. Rerun `work\audit_profile_inputs.ps1` after changing any `.set` file.
7. Rerun `work\collect_validation_results.ps1` after exporting MT5 reports.
8. Rerun `work\analyze_promotion_gate.ps1` before promoting any candidate.
9. Optimize narrow ranges only after the default behavior is understood.

## Validation Report Collector

`work\collect_validation_results.ps1` parses exported MT5 reports without launching MT5 and writes:

- `outputs\VALIDATION_REPORT_METRICS.csv`
- `outputs\VALIDATION_REPORT_SUMMARY.csv`
- `outputs\VALIDATION_REPORT_METRICS.md`

It normalizes net profit, derived final balance, profit factor, expected payoff, total trades, maximal drawdown, and recovery factor. Missing or unparsed reports are marked explicitly so incomplete validation cannot be mistaken for a complete pass.

## Optimization Scoring

The EA includes an optional `OnTester()` custom optimization score.

- Default mode is `FITNESS_ROBUST_PROFIT`, which rewards net profit and profit factor while penalizing low trade count and excessive equity drawdown.
- `FITNESS_NET_PROFIT` is available when raw-profit sorting is needed for comparison.
- `FITNESS_RECOVERY_SHARPE` is available for research passes that should emphasize recovery factor and Sharpe ratio.
- This does not change live trade behavior; it only changes the custom criterion returned to MT5 Strategy Tester optimization.

Avoid optimizing all parameters at once. That will almost certainly overfit.
