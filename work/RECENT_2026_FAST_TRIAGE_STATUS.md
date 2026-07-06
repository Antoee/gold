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
- Current synced source SHA256: `F8538DE547B8C14D60CA15766574E9378ECD3881D60FD6144F0EB44C2B55DA26`.

## Strategy-Code Work

The EA now includes optional, independently configurable strategy modules for actual price-action, market-state, tick-tape, weighted setup-quality logic, profit protection, and early loss control:

- CHoCH confirmation.
- Fair Value Gap confirmation.
- Order Block retest confirmation.
- Equal high/low liquidity sweep confirmation.
- Previous day/week/month level rejection.
- Session high/low sweep confirmation.
- VWAP confluence using tick volume.
- Candle anatomy using body and wick percentages.
- Market phase filter using ADX thresholds.
- RSI confirmation.
- MACD confirmation.
- Bollinger Band confirmation.
- Tick microstructure confirmation.
- Weighted entry-quality score.
- Quality-based risk scaling.
- Regime-quality confirmation using ADX, EMA slope, and ATR regime.
- ATR-based profit-lock stop.
- Adverse-R early exit.

## Adverse-R Early Exit Addition

Added an optional early-loss exit so a clearly failing trade can be cut before the full stop loss is reached:

- `InpUseAdverseRExit=false` by default.
- `InpAdverseExitR=0.75`.
- The position manager calculates current open profit/loss in R using the entry price and current SL distance.
- When enabled, if open R drops below `-InpAdverseExitR`, the EA closes the position and logs `adverse R exit`.
- Selected high-confluence research profiles enable this with `0.75R` to `0.80R` thresholds.

This is risk-first: it can reduce average losing trade size, but it still needs real tester reports because cutting losers too early can also close trades that would have recovered.

## Profit-Lock Stop Addition

Added an optional profit-protection stop for trades that have already moved in favor:

- `InpUseProfitLockStop=false` by default.
- `InpProfitLockTriggerATR=1.50`.
- `InpProfitLockATR=0.35`.
- When enabled, the position manager waits until price has moved at least `InpProfitLockTriggerATR * ATR` from entry.
- It then moves SL into protected profit by `InpProfitLockATR * ATR` from entry.
- It works as another stop candidate alongside break-even, ATR trailing, and structure trailing.

## Regime-Quality Addition

Added optional regime scoring so the EA can reward setups only when trend strength, directional slope, and volatility regime agree:

- `InpUseRegimeQualityScore=false` by default.
- `InpRegimeSlopeLookbackBars=8`.
- `InpRegimeMinSlopePoints=35.0`.
- `InpRegimeMinATRPercentile=0.85`.
- `InpRegimeMaxATRPercentile=1.75`.
- `InpWeightRegimeQuality=2`.
- `RegimeQuality()` checks ADX, EMA slope direction, and current ATR versus the recent ATR average.
- The entry engine adds `Regime quality;` as a normal confirmation and quality-score contributor when enabled.

## Weighted Entry-Quality And Risk Scaling

The EA also includes optional weighted setup scoring and risk scaling:

- `SSignal` tracks `qualityScore`.
- Every enabled confirmation can add a configurable weight.
- `InpUseWeightedEntryScore=false` by default.
- `InpMinimumEntryScore` can reject setups that have enough raw confirmations but not enough high-quality evidence.
- `InpUseQualityRiskScaling=false` by default.
- `QualityRiskMultiplier()` maps setup quality to a bounded risk multiplier.
- `CRiskManager::LotsForRisk()` accepts the multiplier and applies it to `EffectiveRiskPercent()`.
- Trade logs include the quality risk multiplier when enabled.

The `weighted_quality_confluence` research profile now enables weighted scoring, quality risk scaling, tick microstructure, regime-quality scoring, profit-lock stops, and adverse-R early exits.

## Price-Action Research Batch

Fast research batch for actual strategy-code variants:

- Batch: `outputs/PRICE_ACTION_STRATEGY_BATCH.csv`.
- Profiles: 10.
- Runs: 30.
- Windows: `2026_Q2`, `2026_ytd`, `2025_Q2`.
- Estimated tester runtime: about 10.5 minutes before platform overhead.
- Handoff zip: `outputs/price_action_strategy_handoff.zip`.
- Parallel lanes zip: `outputs/price_action_parallel_lanes.zip`.
- Lanes: 3 independent windows.
  - `2026_Q2`: 10 configs, about 2 minutes.
  - `2026_ytd`: 10 configs, about 5.83 minutes.
  - `2025_Q2`: 10 configs, about 2.67 minutes.

Research profiles:

- `baseline_promoted`
- `fvg_sweep_confluence`
- `choch_bos_shift`
- `orderblock_fvg_retest`
- `liquidity_level_reversal`
- `vwap_momentum_phase`
- `tick_vwap_momentum`
- `indicator_phase_filter` includes regime-quality scoring.
- `weighted_quality_confluence` includes regime-quality scoring, quality risk scaling, profit-lock stops, and adverse-R exits.
- `pa_full_confluence` includes profit-lock stops and adverse-R exits.

## Price-Action Decision Gate

The offline decision gate remains active:

- Importer: `work/import_price_action_strategy_reports.ps1`.
- Decision builder: `work/build_price_action_strategy_decision.ps1`.
- Smoke test: `work/test_price_action_strategy_decision.ps1`.
- Metrics output: `outputs/PRICE_ACTION_STRATEGY_REPORT_METRICS.csv`.
- Decision output: `outputs/PRICE_ACTION_STRATEGY_DECISION.csv`.

Current decision state:

- Overall: `COMPILE_REQUIRED`.
- Decisions: 27.
- Pass: 0.
- Reject: 0.
- Waiting: 27.
- Compile trust: `STALE`.

## Offline Evidence

- Focused smokes passed:
  - `PRICE_ACTION_STRATEGY_MODULES_SMOKE_PASS`.
  - `PRICE_ACTION_STRATEGY_BATCH_SMOKE_PASS`.
  - `EA_SOURCE_ARTIFACT_SYNC_SMOKE_PASS`.
- Full offline refresh: PASS, 39 steps, 0 failed.
- Report import preflight rows:
  - Open risk exposure guard smoke: PASS.
  - Max stop ATR guard smoke: PASS.
  - Price-action strategy modules smoke: PASS.
  - Price-action strategy batch smoke: PASS.
  - Price-action strategy handoff smoke: PASS.
  - Source hash status smoke: PASS.
  - Local safety: PASS, 39 safety checks pass.
  - Price-action strategy decision: `COMPILE_REQUIRED`, with 27 waiting report decisions and stale compile trust.
  - Compile status: `STALE`.
- Local pipeline manifest: PASS, 72 artifacts tracked, 0 missing.
- External MT5 package audit: PASS, 26 checks passed, 0 failed.

## Hashes

- EA source: `F8538DE547B8C14D60CA15766574E9378ECD3881D60FD6144F0EB44C2B55DA26`.
- Base profile: `46E889F90E55A3732A5694CE02CFA1C6AE4887BD22792B7B405DB0521896D6E3`.
- Price-action batch CSV: `903827B590601032A7A70DABEBD76776A74CDD40CD4C103FEB0574FC2D00BED6`.
- Price-action handoff zip: `8AEE623E5064103C5ECD048B5920DB83ABBB2DB5BE83D34F038880D6CC05205D`.
- Price-action parallel lanes zip: `17FE9B42863F070EF46CBA0C6A30C7A10C5F77C2CF737FBB2CBA23377A78D5A6`.
- External validation package zip: `2703D121F8FCE538347FFF7E0662A81B208DB43730BC44BAFA13054B2704F230`.
- Price-action modules smoke: `4B048FFE95120AED3C59A72716F9F042FB9F3578BE393AAF2625B640523D792D`.
- Price-action batch smoke: `301947BDCCFAC731EA3CF22232210876A37C7EAAE88CDE6409FC04C55A528558`.
- Price-action batch builder: `DAF8EAB0B63FC19FA6CAB75893D1EC626F5FE7677C18F7BEA01C298BBD96C9DF`.

## Caveat

No profit claim is made from this update. Compile/test evidence is intentionally stale because MT5 and MetaEditor were not launched to avoid interrupting normal PC usage. Next performance step is a controlled external or truly non-interactive MT5 compile and backtest run using the rebuilt package or the new price-action lane zips, followed by importing reports through the decision gate.