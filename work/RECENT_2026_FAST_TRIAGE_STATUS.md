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
- Root/package source sync: PASS.
- Current synced source SHA256: `4EE1484812ED6148B154D0B0CB2807A110F1A1846C47673083CF7AA8F12E1E34`.

## Strategy-Code Work

The EA includes optional, independently configurable strategy modules for actual price-action, market-state, tick-tape, intermarket confirmation, weighted setup-quality logic, profit targeting, profit protection, and early loss control:

- CHoCH, FVG, order-block retest, liquidity sweep, previous/session levels, VWAP, candle anatomy, market phase, RSI, MACD, Bollinger, and tick microstructure confirmations.
- Correlated-market confirmation using configurable same-direction or inverse-direction symbol momentum.
- Weighted entry-quality score.
- Quality-based risk scaling.
- Quality-based take-profit scaling.
- Regime-quality confirmation using ADX, EMA slope, and ATR regime.
- ATR-based profit-lock stop.
- Adverse-R early exit.

## Quality Take-Profit Scaling Addition

Added optional quality-based TP scaling so stronger setups can target more while weaker qualifying setups can stay more conservative:

- `InpUseQualityTakeProfitScaling=false` by default.
- `InpQualityTPMinScore=7`.
- `InpQualityTPFullScore=12`.
- `InpMinQualityTPMultiplier=0.85`.
- `InpMaxQualityTPMultiplier=1.35`.
- `QualityTakeProfitMultiplier()` maps setup quality to a bounded TP multiplier.
- `OpenSignal()` applies the multiplier after final stop-distance calculation, so the minimum-RR check uses the actual structure-adjusted stop.
- Trade logs append `Quality TP x...` when enabled.

The `weighted_quality_confluence` research profile now enables quality TP scaling with a `0.90x` to `1.35x` TP range.

## Correlated-Market Confirmation

Intermarket confirmation remains available for testing:

- `InpUseCorrelationConfirmation=false` by default.
- `InpCorrelationSymbol=XAGUSD` by default.
- Same-direction and inverse-direction modes are supported.
- `vwap_momentum_phase` and `weighted_quality_confluence` enable XAGUSD same-direction confirmation.

## Decision Gate Discipline

The offline price-action decision gate rejects or reviews aggressively before any candidate can pass fast triage:

- `MinTradesPerWindow=5`.
- `MinProfitFactor=1.10`.
- `MinRecoveryFactor=1.00`.
- `MaxProfitFactorDegradation=0.05`.
- Higher net profit alone is not enough when PF, recovery, drawdown, compile proof, or report coverage is weak.

## Recent EA Risk Features

Adverse-R early exit:

- `InpUseAdverseRExit=false` by default.
- `InpAdverseExitR=0.75`.
- Selected high-confluence research profiles enable this with `0.75R` to `0.80R` thresholds.

Profit-lock stop:

- `InpUseProfitLockStop=false` by default.
- `InpProfitLockTriggerATR=1.50`.
- `InpProfitLockATR=0.35`.
- Selected high-confluence research profiles enable this for testing.

Regime-quality score:

- `InpUseRegimeQualityScore=false` by default.
- Uses ADX, EMA slope direction, and current ATR versus recent ATR average.

## Price-Action Research Batch

Fast research batch for actual strategy-code variants:

- Batch: `outputs/PRICE_ACTION_STRATEGY_BATCH.csv`.
- Profiles: 10.
- Runs: 30.
- Windows: `2026_Q2`, `2026_ytd`, `2025_Q2`.
- Estimated tester runtime: about 10.5 minutes before platform overhead.
- Handoff zip: `outputs/price_action_strategy_handoff.zip`.
- Parallel lanes zip: `outputs/price_action_parallel_lanes.zip`.

Research profiles:

- `baseline_promoted`
- `fvg_sweep_confluence`
- `choch_bos_shift`
- `orderblock_fvg_retest`
- `liquidity_level_reversal`
- `vwap_momentum_phase`
- `tick_vwap_momentum`
- `indicator_phase_filter`
- `weighted_quality_confluence` includes quality TP scaling.
- `pa_full_confluence`

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

- EA source: `4EE1484812ED6148B154D0B0CB2807A110F1A1846C47673083CF7AA8F12E1E34`.
- Base profile: `B4CA8C7BCF63CFD2979D4A7569405CE3D4783EB310402E596FD5AFA8F7B50783`.
- Price-action batch CSV: `903827B590601032A7A70DABEBD76776A74CDD40CD4C103FEB0574FC2D00BED6`.
- Price-action handoff zip: `082D661BA27ABC46004C2D62E0316CD701A3CDCA0028FF435CEF61655A0F598F`.
- Price-action parallel lanes zip: `8E75CE333DF6A674A23742451EBD7FDDC492AD8C55B215CB4D13FC9F0397F266`.
- External validation package zip: `DB922F94C68665613AEE028F0CCEDD60449CB57B6D6071CFB250964F2CC59634`.
- Price-action modules smoke: `A654B7670F6264E3CE1E51F8356636CCB8415005DAC8EA3ACBE07BBA05C06135`.
- Price-action batch smoke: `DA333983D5E86547EB7A77BDFD4EBD94574FD232304208A30F8BE883722D2E72`.
- Price-action batch builder: `D598CF75807789375F69CAA2C984C2956AF8E98DB3A281C730DE44214E276672`.

## Caveat

No profit claim is made from this update. Compile/test evidence is intentionally stale because MT5 and MetaEditor were not launched to avoid interrupting normal PC usage. Next performance step is a controlled external or truly non-interactive MT5 compile and backtest run using the rebuilt package or the new price-action lane zips, followed by importing reports through the stricter decision gate.