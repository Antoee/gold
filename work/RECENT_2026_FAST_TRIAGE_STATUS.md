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
- Current synced source SHA256: `A2F7101E8378C67AC258420C9F886E5ACB38554F4CB22D958AA20099074CC487`.

## Breakout-Retest Confirmation Addition

Added optional breakout-retest confirmation so the EA can test structure breaks that pull back to the broken level before continuation:

- `InpUseBreakoutRetest=false` by default.
- `InpBreakoutRetestLookbackBars=20`.
- `InpBreakoutRetestATR=0.25`.
- `InpBreakoutRetestCloseBufferPoints=10.0`.
- `InpWeightBreakoutRetest=2`.
- `CMarketStructure::BreakoutRetest()` checks that the prior bar broke the structure level, the current bar retested near that level, and the current close continued back through the level with a buffer.
- The entry engine adds `Breakout retest;` as a normal confirmation and quality-score contributor when enabled.

The `orderblock_fvg_retest` and `weighted_quality_confluence` research profiles now enable breakout-retest confirmation without increasing the 30-run batch size.

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

- EA source: `A2F7101E8378C67AC258420C9F886E5ACB38554F4CB22D958AA20099074CC487`.
- Base profile: `E4DADF47CB9096B3345D56A72C97EED4B1CFAAC0AFD99F4FBC5C0C7F140D83D4`.
- Price-action batch CSV: `903827B590601032A7A70DABEBD76776A74CDD40CD4C103FEB0574FC2D00BED6`.
- Price-action handoff zip: `C871097671A34BB23A6A2EB82E5E2E3FC7A21BB6BEDA7C010FE974C55EEDEC58`.
- Price-action parallel lanes zip: `FB10BAA9CFDAF8E9567987152230ABC7C4A8C9E7CA30E5B3F54A7B69745857A2`.
- External validation package zip: `92320EBE0246B06D637E6EB7420708451A24068B38F5F73815BE7D58865C1145`.
- Price-action modules smoke: `2A1A1438B93FBFAA52822FA786023F51058251B2B5EB718ACD6F6CE868FB24C0`.
- Price-action batch smoke: `A3BB7DC0CFB2B243ED884F1C9BE5220D6334860BAC16B6302A8316659C4466D9`.
- Price-action batch builder: `0B591D508451712F505D07C4413999009AC17A04659BB5DAF30FC6B55CE7C4B7`.

## Caveat

No profit claim is made from this update. Compile/test evidence is intentionally stale because MT5 and MetaEditor were not launched to avoid interrupting normal PC usage. Next performance step is a controlled external or truly non-interactive MT5 compile and backtest run, then importing reports through the stricter multi-window decision gate.