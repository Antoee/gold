# Professional XAUUSD EA

This deliverable is a first professional scaffold for an MT5 XAUUSD Expert Advisor. It is intentionally modular and research-oriented: every major behavior is exposed as an input so you can optimize features independently and run training, out-of-sample, and walk-forward tests.

## Files

- `Professional_XAUUSD_EA.mq5` - MT5 Expert Advisor source.
- `README_Professional_XAUUSD_EA.md` - this guide.
- `BACKTEST_RESULTS.md` - current validation notes.
- `PROMOTION_GATE_REPORT.md` - offline promotion readiness check for queued profiles.
- `PROFILE_INPUT_AUDIT.md` - offline check that active `.set` files pin all critical inputs.
- `ADAPTIVE_REAL_TICK_WINDOWS.csv` - latest adaptive real-tick split results.
- `ADAPTIVE_REAL_TICK_SUMMARY.csv` - latest adaptive real-tick summary.
- `REAL_TICK_WINDOW_RESULTS.csv` - promoted default split-window validation.
- `FULL_REAL_TICK_DEFAULT.csv` - promoted default full-period validation.
- `WALK_FORWARD_REAL_TICK_WINDOWS.csv` - promoted default half-year walk-forward validation.
- `QUARTERLY_REAL_TICK_WINDOWS.csv` - promoted default quarterly validation.
- `LOSING_QUARTER_COMBO_PROBES.csv` - latest weak-quarter research probes.

## Installation

1. Copy `Professional_XAUUSD_EA.mq5` into your MT5 data folder:
   `MQL5/Experts/Professional_XAUUSD_EA.mq5`
2. Open MetaEditor.
3. Compile the EA.
4. Attach it to XAUUSD, preferably starting with M15.
5. Run Strategy Tester with visual mode off first, then inspect journal/log output.

## Background Testing

The automation scripts in `work/` are configured for background testing:

- MT5 starts through a hidden Windows process-creation wrapper to avoid popup flashes.
- Strategy Tester visual mode is disabled.
- Dashboard rendering is disabled in tester configs.
- MT5/tester audio sessions are muted while the scripts run.

Local MT5 launch is currently hard-locked because `terminal64.exe` can still flash and steal focus on this PC. The shared launcher and legacy MT5 runner scripts refuse to start unless both of these are deliberately set after a controlled test:

- `ALLOW_MT5_FOCUS_RISK=1`
- `work\ALLOW_MT5_LOCAL_LAUNCH.unlock`

When the launcher is deliberately unlocked, use the PowerShell scripts from the project root for unattended tests, for example:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File work\run_real_tick_windows.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File work\run_adaptive_real_tick_windows.ps1
```

## What Is Included

- Symbol guard for XAUUSD.
- Optional trend filters:
  - 200 EMA.
  - 100 EMA.
  - EMA slope.
  - higher-timeframe EMA.
  - optional higher-timeframe EMA slope direction filter.
  - ADX threshold.
  - ATR volatility bounds.
- Optional entry confirmations:
  - EMA cross.
  - break of structure.
  - liquidity sweep.
  - momentum candle.
  - engulfing candle.
  - pin bar.
  - ATR expansion.
  - tick-volume confirmation.
  - optional buy/sell-specific minimum confirmation thresholds.
- Risk controls:
  - percent-risk lot sizing.
  - daily, weekly, and monthly loss limits.
  - optional peak-equity drawdown circuit breaker.
  - max consecutive losses.
  - cooldown after losses.
  - max simultaneous positions.
  - spread guard.
  - slippage/deviation setting.
  - minimum RR filter.
- Position management:
  - ATR stop.
  - optional structure stop.
  - take profit by ATR multiple.
  - break-even.
  - ATR trailing.
  - structure trailing.
  - partial close.
  - time exit.
  - EMA exit.
  - opposite-signal exit.
  - volatility exit.
- Dashboard:
  - trend.
  - session.
  - spread.
  - ATR.
  - ADX.
  - risk.
  - open positions.
  - profit factor.
  - win rate.
  - expectancy.
  - drawdown estimate.
  - consecutive wins/losses.
- CSV logging in the common files folder:
  `Professional_XAUUSD_EA_Trades.csv`

## Important Notes

The smart-money-style concepts are implemented conservatively:

- BOS is a close beyond the previous lookback high/low.
- Liquidity sweep is a wick beyond a prior high/low followed by a close back through that level.
- Order blocks and FVG are not hard-coded yet because poor definitions tend to create optimizer traps. Add them only after defining exact measurable rules.

The current promoted defaults now prioritize start-date robustness over maximum historical profit. This is still research output, not a live-trading guarantee.

Promoted defaults:

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
- This replaces the `1.50%` risk profile, which made `+$521.12` full-period and still had one losing monthly/quarter/split window.

Aggressive high-profit research profile:

- The previous date-block profile made `+$4,153.12` on the full period, but it used date-specific blocks and had 17 losing months out of 30.
- Keep it as a research profile only until it can be replaced by general market-regime rules.

Latest rejected research candidates:

- `no_date_buy_only`: reduced the weak-quarter losses but failed all-quarter validation with five losing quarters.
- `confirm3_ny`: reduced the worst weak-quarter loss to `-$53.83`, but all-quarter net fell to `+$531.02`.
- `adx25_no_trail`: had the best weak-quarter total among combo probes, but still left two losing weak quarters.
- `buy2_sell3_ny`: improved weak-quarter total to `+$109.70`, but full-period net fell to `+$2,620.98` and 2025 became losing.
- `dd4` equity drawdown guard: improved worst quarter to `-$87.32`, but full-period net fell to only `+$85.45` and 2025 became losing.
- No-date MTF slope direction filter: all tested stress-window variants lost money, so it failed as a date-block replacement.
- H4 no-date signal timeframe: reduced weak-regime activity, but full-period validation was `-$136.90`, so it failed as a profit profile.
- Monthly `buy2_sell3` confirmation profile: reduced losing months from 17 to 14, but lowered monthly net from `+$1,903.98` to `+$1,492.91`, so it was not promoted.
- Monthly ADX filters: reduced total profit sharply and did not improve losing-month count, so they were rejected.
- No-trail profile (`InpUseATRTrailing=false`): clean quarterly validation improved the worst quarter from `-$206.77` to `-$144.33`, but reduced total quarterly net from `+$1,661.98` to `+$1,099.90`, so it was not promoted.
- Momentum+sweep no-date profile: full period `+$664.59`, but still had 17 losing months, so it was not promoted.
- BOS+sweep no-date profile at `1.60%` risk with a `1.80` stop ATR multiplier: promoted as the robust default because monthly/quarter/split validation showed zero losing windows while improving full-period profit versus the previous `1.50%` risk profile.
- Candidate `risk160_sl18_tp38`: stress-window result `+$798.00`, worst window `$0.00`, 0 losing windows. It is queued for full validation, not promoted.
- Candidate `risk160_sl16_tp38`: stress-window result `+$798.00`, worst window `$0.00`, 0 losing windows. It is queued for full validation, not promoted.
- Candidate `risk160_sl18_tp35_giveback`: enables the new profit giveback guard on the promoted profile. It is queued for loss-control validation, not promoted.

Profit giveback guard:

- Optional module controlled by `InpUseProfitGivebackGuard`.
- Tracks daily, weekly, and monthly peak closed profit.
- Blocks new entries if current period profit gives back too much of that peak.
- Does not close existing positions by itself; it prevents adding new risk after a profitable period deteriorates.
- Defaults are pinned in profiles but disabled unless a giveback candidate explicitly enables the guard.

Optimization scoring:

- The EA now includes an optional `OnTester()` custom optimization score.
- Default mode is `FITNESS_ROBUST_PROFIT`, which rewards net profit and profit factor while penalizing low trade count and excessive equity drawdown.
- `FITNESS_NET_PROFIT` is available when raw-profit sorting is needed for comparison.
- `FITNESS_RECOVERY_SHARPE` is available for research passes that should emphasize recovery factor and Sharpe ratio.
- This does not change live trade behavior; it only changes the custom criterion returned to MT5 Strategy Tester optimization.

## Suggested First Testing Workflow

1. Compile with default settings.
2. Run XAUUSD M15 on a training window.
3. Export the Strategy Tester report.
4. Run the exact same settings on an out-of-sample window.
5. Disable one confirmation/filter at a time to identify which modules add value.
6. Rerun `work\audit_profile_inputs.ps1` after changing any `.set` file.
7. Rerun `work\analyze_promotion_gate.ps1` before promoting any candidate.
8. Optimize narrow ranges only after the default behavior is understood.

## Recommended Optimization Order

1. Risk and spread limits.
2. Session windows.
3. Trend filters.
4. Entry confirmation count.
5. Stop and target ATR multipliers.
6. Break-even and trailing behavior.
7. Optional exits.

Avoid optimizing all parameters at once. That will almost certainly overfit.
