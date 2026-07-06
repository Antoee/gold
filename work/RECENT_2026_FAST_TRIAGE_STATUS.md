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
- Current synced source SHA256: `D3B7E5B38F0483E32283A1F88A2FF4DC03D2E3D6E79AB180356E8BA71760A99D`.

## Underwater Time Exit Addition

Added an optional underwater time exit so the EA can cut trades that stay negative for too long instead of only waiting for full stop loss or the adverse-R exit:

- `InpUseUnderwaterTimeExit=false` by default.
- `InpUnderwaterExitBars=12`.
- `InpUnderwaterExitMaxR=-0.25`.
- When enabled, the position manager closes a trade if its current R is at or below `InpUnderwaterExitMaxR` after at least `InpUnderwaterExitBars` signal-timeframe bars.
- Exit logs use event `exit`, bias `underwater_time`, and reason `underwater time exit`.
- This is risk-control strategy code, not a settings-only change.

The `weighted_quality_confluence` and `pa_full_confluence` research profiles now enable underwater time exit for fast-triage testing.

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
- Correlated-market confirmation.
- Weighted entry-quality score.
- Quality-based risk scaling.
- Quality-based take-profit scaling.
- Regime-quality confirmation using ADX, EMA slope, and ATR regime.
- ATR-based profit-lock stop.
- Adverse-R early exit.
- Underwater time exit.

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

- EA source: `D3B7E5B38F0483E32283A1F88A2FF4DC03D2E3D6E79AB180356E8BA71760A99D`.
- Base profile: `0BE9399A315EE2D091F67521FB975D1A7508CCD1174CFDCF9D8B95823B62397E`.
- Price-action batch CSV: `903827B590601032A7A70DABEBD76776A74CDD40CD4C103FEB0574FC2D00BED6`.
- Price-action handoff zip: `2C073050E54FDEAB2E08A3F92DE33677DB31F9AD07DB9DE1CB2B4ED4C9491A93`.
- Price-action parallel lanes zip: `BA33F1ED2535E03C84AAC67EF804A5122C642F537D2C0E92F956FDE8C3491363`.
- External validation package zip: `A284B08C01042D8B5129A8B9CF3078F134488429FAF75D0FBD5E538965B4083A`.
- Price-action modules smoke: `8BAFC01CC47F1C7BDAC9641C4448F4FACA7C74C5AE5A233EA6BF9C75E6C67681`.
- Price-action batch smoke: `D537AB82D89B3C8F388BB80D1010EA69B3640B9698D45CADAE1BA87A1205E53B`.
- Price-action batch builder: `502F350D8755EC1C35CE5752A7FECAB497314393EE8D5074219060FF3A01356F`.

## Caveat

No profit claim is made from this update. Compile/test evidence is intentionally stale because MT5 and MetaEditor were not launched to avoid interrupting normal PC usage. Next performance step is a controlled external or truly non-interactive MT5 compile and backtest run, then importing reports through the stricter multi-window decision gate.