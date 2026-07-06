# Recent 2026 Fast Triage Status

Updated locally on 2026-07-06.

## Safety

- Local MT5/MetaEditor/Strategy Tester launch remains locked.
- Current work was done with hidden/no-window PowerShell only.
- Final local scan before this status update: no `terminal`, `terminal64`, `metatester`, `metatester64`, `MetaEditor`, or `metaeditor64` processes found.
- Quiet stop marker remains present: `work/STOP_MT5_FOCUS_WATCHDOG`.
- No watchdog process is intentionally running right now; the repo is in quiet no-resident-helper mode.

## Current EA Source

- Canonical source: `outputs/Professional_XAUUSD_EA.mq5`.
- Current synced source SHA256: `40AED19C3BAE268D94DEFE6EF71A26F278224895A56485EE9A6091D0D4306892`.

## Recent-Performance Risk Throttle Addition

Added an optional recent-performance risk throttle so the risk manager can reduce position risk after a weak recent trade sample:

- `InpUseRecentPerformanceRiskThrottle=false` by default.
- `InpRecentPerformanceLookbackTrades=5`.
- `InpRecentPerformanceMinNetPercent=0.00`.
- `InpRecentPerformanceRiskFactor=0.50`.
- When enabled, the risk manager sums the last configured number of closed trades for the EA symbol/magic and reduces effective risk if net profit as a percent of balance is at or below the threshold.
- This is risk throttling, not martingale, grid, averaging down, or recovery logic; it reduces exposure after weak performance instead of increasing it.

The `weighted_quality_confluence` and `pa_full_confluence` research profiles now enable recent-performance risk throttle for fast-triage testing.

## Dynamic ATR Regime Guard Addition

Added an optional dynamic ATR regime guard so the entry engine can reject setups when current ATR is too compressed or too expanded versus recent ATR average:

- `InpUseDynamicATRRegimeGuard=false` by default.
- `InpATRRegimeLookbackBars=20`.
- `InpMinATRRegimeRatio=0.75`.
- `InpMaxATRRegimeRatio=1.80`.
- When enabled, the entry engine compares current ATR to the average ATR over the configured lookback and rejects entries outside the ratio band.
- Rejected setups log the internal reason `ATR regime reject;`.
- This is strategy/risk-control code intended to avoid dead chop and extreme volatility regimes without relying only on static ATR point limits.

The `weighted_quality_confluence` and `pa_full_confluence` research profiles enable dynamic ATR regime guard for fast-triage testing.

## Entry Shock Guard Addition

Added an optional entry shock guard so the entry engine can reject setups immediately after oversized or low-body signal candles:

- `InpUseEntryShockGuard=false` by default.
- `InpMaxEntryCandleATR=2.20`.
- `InpMinEntryBodyPercent=30.0`.
- When enabled, the entry engine rejects a setup if the most recent closed signal candle range is too large versus ATR or has too little body relative to total range.
- Rejected setups log the internal reason `Entry shock reject;`.
- This is strategy/risk-control code intended to avoid chasing XAUUSD spike candles, poor fills, and immediate liquidity reversals.

The `weighted_quality_confluence` and `pa_full_confluence` research profiles enable entry shock guard for fast-triage testing.

## Stagnation Exit Addition

Added an optional stagnation exit so the position manager can close trades that have been open for a configurable number of bars but still have not reached a minimum R threshold:

- `InpUseStagnationExit=false` by default.
- `InpStagnationExitBars=24`.
- `InpStagnationExitMaxR=0.10`.
- When enabled, the position manager closes a trade if `r <= InpStagnationExitMaxR` after at least `InpStagnationExitBars` signal-timeframe bars.
- Exit logs use event `exit`, bias `stagnation`, and reason `stagnation exit`.
- This is strategy/risk-control code intended to reduce dead-time exposure and slow loss drift, not a settings-only change.

The `weighted_quality_confluence` and `pa_full_confluence` research profiles enable stagnation exit for fast-triage testing.

## Reversal-Pressure Exit Addition

Added an optional reversal-pressure exit so the position manager can protect trades when fresh opposite price-action evidence appears after the trade has reached a configurable minimum R:

- `InpUseReversalPressureExit=false` by default.
- `InpReversalPressureMinR=0.25`.
- `InpReversalPressureLookbackBars=12`.
- `InpReversalPressureMinSignals=2`.
- Opposite pressure can come from opposite BOS, CHoCH, liquidity sweep, equal-level sweep, or breakout-retest evidence.
- Exit logs use event `exit`, bias `reversal_pressure`, and the detected opposite-pressure reasons.
- This is strategy/risk-control code, not a settings-only change.

The `weighted_quality_confluence` and `pa_full_confluence` research profiles enable reversal-pressure exit for fast-triage testing.

## Underwater Time Exit Addition

Added an optional underwater time exit so the EA can cut trades that stay negative for too long instead of only waiting for full stop loss or the adverse-R exit:

- `InpUseUnderwaterTimeExit=false` by default.
- `InpUnderwaterExitBars=12`.
- `InpUnderwaterExitMaxR=-0.25`.
- When enabled, the position manager closes a trade if its current R is at or below `InpUnderwaterExitMaxR` after at least `InpUnderwaterExitBars` signal-timeframe bars.
- Exit logs use event `exit`, bias `underwater_time`, and reason `underwater time exit`.
- This is risk-control strategy code, not a settings-only change.

The `weighted_quality_confluence` and `pa_full_confluence` research profiles enable underwater time exit for fast-triage testing.

## Breakout-Retest Confirmation Addition

Added optional breakout-retest confirmation so the EA can test structure breaks that pull back to the broken level before continuation:

- `InpUseBreakoutRetest=false` by default.
- `InpBreakoutRetestLookbackBars=20`.
- `InpBreakoutRetestATR=0.25`.
- `InpBreakoutRetestCloseBufferPoints=10.0`.
- `InpWeightBreakoutRetest=2`.
- `CMarketStructure::BreakoutRetest()` checks that the prior bar broke the structure level, the current bar retested near that level, and the current close continued back through the level with a buffer.
- The entry engine adds `Breakout retest;` as a normal confirmation and quality-score contributor when enabled.

The `orderblock_fvg_retest` and `weighted_quality_confluence` research profiles enable breakout-retest confirmation without increasing the 30-run batch size.

## Current EA Strategy Features

The EA includes optional, independently configurable strategy modules for actual price-action, market-state, tick-tape, intermarket confirmation, weighted setup-quality logic, profit targeting, profit protection, and early loss control:

- CHoCH, BOS, breakout retests, FVG, order-block retest, liquidity sweep, previous/session levels, session sweeps, opening-range breakouts, VWAP, candle anatomy, market phase, RSI, MACD, Bollinger, and tick microstructure confirmations.
- Entry shock guard.
- Dynamic ATR regime guard.
- Correlated-market confirmation.
- Weighted entry-quality score.
- Quality-based risk scaling.
- Recent-performance risk throttle.
- Quality-based take-profit scaling.
- Regime-quality confirmation using ADX, EMA slope, and ATR regime.
- ATR-based profit-lock stop.
- Adverse-R early exit.
- Underwater time exit.
- Stagnation exit.
- Reversal-pressure exit.

## Decision Gate Discipline

The offline price-action decision gate rejects or reviews aggressively before any candidate can pass fast triage:

- Complete parsed coverage across recent and stress windows is required for `PASS_FAST_TRIAGE`.
- At least one passing recent window and one passing stress window are required.
- `MinTradesPerWindow=5`.
- `MinProfitFactor=1.10`.
- `MinRecoveryFactor=1.00`.
- `MaxProfitFactorDegradation=0.05`.
- Higher net profit alone is not enough when PF, recovery, drawdown, compile proof, report coverage, or recent/stress consistency is weak.

## Price-Action Research Batch

Fast research batch for actual strategy-code variants:

- Batch: `outputs/PRICE_ACTION_STRATEGY_BATCH.csv`.
- Profiles: 10.
- Runs: 30.
- Windows: `2026_Q2`, `2026_ytd`, `2025_Q2`.
- Estimated tester runtime: about 10.5 minutes before platform overhead.
- Handoff zip: `outputs/price_action_strategy_handoff.zip`.
- Parallel lanes zip: `outputs/price_action_parallel_lanes.zip`.

Research profiles with recent-performance risk throttle enabled:

- `weighted_quality_confluence`.
- `pa_full_confluence`.

Research profiles with dynamic ATR regime guard enabled:

- `weighted_quality_confluence`.
- `pa_full_confluence`.

Research profiles with entry shock guard enabled:

- `weighted_quality_confluence`.
- `pa_full_confluence`.

Research profiles with stagnation exit enabled:

- `weighted_quality_confluence`.
- `pa_full_confluence`.

Research profiles with reversal-pressure exit enabled:

- `weighted_quality_confluence`.
- `pa_full_confluence`.

Research profiles with underwater time exit enabled:

- `weighted_quality_confluence`.
- `pa_full_confluence`.

Research profiles with breakout retest enabled:

- `orderblock_fvg_retest`.
- `weighted_quality_confluence`.

## Current Decision State

- Overall: `COMPILE_REQUIRED`.
- Decisions: 27.
- Pass: 0.
- Reject: 0.
- Waiting: 27.
- Compile trust: `STALE`.
- No profit claim is made.

## Offline Evidence

- `PRICE_ACTION_STRATEGY_MODULES_SMOKE_PASS`.
- `PRICE_ACTION_STRATEGY_BATCH_SMOKE_PASS`.
- `EA_SOURCE_ARTIFACT_SYNC_SMOKE_PASS`.
- Full offline refresh: PASS, 39 steps, 0 failed.
- Report import preflight rows:
  - Price-action strategy modules smoke: PASS.
  - Price-action strategy batch smoke: PASS.
  - Price-action strategy handoff smoke: PASS.
  - Price-action strategy decision: `COMPILE_REQUIRED`, with 27 waiting report decisions and stale compile trust.
  - Source hash status smoke: PASS.
  - Local safety: PASS, 39 safety checks pass.
  - Compile status: `STALE`.
  - External MT5 package: PASS, 26 package checks pass.
- External MT5 package audit: PASS, 26 checks passed, 0 failed.

## Hashes

- EA source: `40AED19C3BAE268D94DEFE6EF71A26F278224895A56485EE9A6091D0D4306892`.
- Base profile: `4BDAE4FA98637426CF85A834F8242A102713DAE9D228D1898D37D6087199166F`.
- Price-action batch CSV: `903827B590601032A7A70DABEBD76776A74CDD40CD4C103FEB0574FC2D00BED6`.
- Price-action handoff zip: `81E2AE53C9D16D8064E56D74F477200D9068B68E08AC0548897C523D4031EA33`.
- Price-action parallel lanes zip: `B7D3BCEE3C6814497E5DC0962AC9A929E1C818F6620BBE132F052BFECDDC246D`.
- External validation package zip: `FD4D0F3590D4FF9DB0C3CE8D20AB0506832DEDC2ABDDC42B761DA7B8FA09A445`.
- Price-action modules smoke: `8AED1DEF8E9EAA7679061C285004BD2A2BFF5FC8A33C97A6C46BBC4BA2892EB7`.
- Price-action batch smoke: `4B42D2E634F58DD974FAD0AB321125E45F2753E7F4D52676912F1B8DE62159BB`.
- Price-action batch builder: `74EED380A7A7F13D94014C6F31C00AE5F1B429EA455ED521E0B5EBB4E54CDB29`.

## GitHub Source Caveat

The status note is committed through the GitHub connector. The local shell still has no `git`, no `gh`, and no GitHub token exposed, and the 103 KB EA source is too large to safely pass through connector text parameters without risking truncation. The authoritative local artifacts and hashes above should be used for source integrity until a normal git push or non-truncated upload path is available.

## Caveat

No profit claim is made from this update. Compile/test evidence is intentionally stale because MT5 and MetaEditor were not launched to avoid interrupting normal PC usage. Next performance step is a controlled external or truly non-interactive MT5 compile and backtest run, then importing reports through the stricter multi-window decision gate.