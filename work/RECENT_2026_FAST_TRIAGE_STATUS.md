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
- Current synced source SHA256: `745C07041CAD41F0F2481E3C2A16C571F6346EA7F906CCDDD973C8D6708E2470`.

## Opening-Range Breakout Addition

Added optional opening-range breakout confirmation so the EA can test London/New York-style momentum entries:

- `InpUseOpeningRangeBreakout=false` by default.
- `InpOpeningRangeStartHour=7`.
- `InpOpeningRangeStartMinute=0`.
- `InpOpeningRangeMinutes=60`.
- `InpOpeningRangeMaxBarsAfter=16`.
- `InpOpeningRangeBufferPoints=20.0`.
- `InpWeightOpeningRangeBreakout=2`.
- `CMarketStructure::OpeningRangeBreakout()` builds the configured daily opening range and confirms a buffered breakout after the range closes.
- The entry engine adds `Opening range;` as a normal confirmation and quality-score contributor when enabled.

The `vwap_momentum_phase` and `pa_full_confluence` research profiles now enable opening-range breakout confirmation for testing without increasing the 30-run batch size.

## Current EA Strategy Features

The EA includes optional, independently configurable strategy modules for actual price-action, market-state, tick-tape, intermarket confirmation, weighted setup-quality logic, profit targeting, profit protection, and early loss control:

- CHoCH, FVG, order-block retest, liquidity sweep, previous/session levels, session sweeps, opening-range breakouts, VWAP, candle anatomy, market phase, RSI, MACD, Bollinger, and tick microstructure confirmations.
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

Research profiles with opening-range enabled:

- `vwap_momentum_phase`.
- `pa_full_confluence`.

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

- EA source: `745C07041CAD41F0F2481E3C2A16C571F6346EA7F906CCDDD973C8D6708E2470`.
- Base profile: `17A53C2663D6C8C2369183FD01EF94FB59CDD447F27E710360AF22ED5F85BB69`.
- Price-action batch CSV: `903827B590601032A7A70DABEBD76776A74CDD40CD4C103FEB0574FC2D00BED6`.
- Price-action handoff zip: `FE405594EE58960B0079F045CB8E5F5BD5CF74A538B26BCC38F2AB730FF1A318`.
- Price-action parallel lanes zip: `39507CB37A76903C1325389EA183E5258ACB43E31A73B6DD3780726C81DDB837`.
- External validation package zip: `0EACA7FEF04C28F2606A43149031E482279B6F59B96DD038CEEF489140965BB4`.
- Price-action modules smoke: `1BA2698E2AD252FE0ECD53FEB5E943D939BF9E969E9F5AA83E8B2F0326822F69`.
- Price-action batch smoke: `CDC5524A2C198643B739A9DE9D4D51F836E1B688FA48D3FB1D5CB7FEAE378E15`.
- Price-action batch builder: `46B24F2D461EA7C3F7A994AC080C7CDCA84088BE35A982A28D06692F247A9489`.

## Caveat

No profit claim is made from this update. Compile/test evidence is intentionally stale because MT5 and MetaEditor were not launched to avoid interrupting normal PC usage. Next performance step is a controlled external or truly non-interactive MT5 compile and backtest run, then importing reports through the stricter multi-window decision gate.