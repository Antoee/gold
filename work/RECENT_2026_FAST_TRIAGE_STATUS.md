# Recent 2026 Fast Triage Status

Updated locally on 2026-07-06.

## Safety

- Local MT5/MetaEditor/Strategy Tester launch remains locked.
- Current work was done with hidden/no-window PowerShell only.
- Final local scan before this status update: no `terminal`, `terminal64`, `metatester`, `metatester64`, `MetaEditor`, or `metaeditor64` processes found.
- Quiet stop marker remains present: `work/STOP_MT5_FOCUS_WATCHDOG`.

## Current EA Source

- Canonical source: `outputs/Professional_XAUUSD_EA.mq5`.
- Root/package source sync: PASS.
- Current synced source SHA256: `458611765C9AA13BEF42EBAF5B9987CCD5534A5C9E94A2B985895C87FACBC8CD`.

## Strategy-Code Work

The EA now includes optional, independently configurable strategy modules for actual price-action, market-state, tick-tape, and weighted setup-quality logic:

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

## Weighted Entry-Quality Addition

Added optional weighted setup scoring beside the existing confirmation count:

- `SSignal` now tracks `qualityScore`.
- Every enabled confirmation can add a configurable weight.
- `InpUseWeightedEntryScore=false` by default, so promoted baseline behavior stays unchanged.
- When enabled, `InpMinimumEntryScore` can reject setups that have enough raw confirmations but not enough high-quality evidence.
- New weight inputs cover BOS, liquidity sweep, CHoCH, FVG, order block, equal levels, previous/session levels, VWAP, momentum, volume, indicators, candles, ATR expansion, and tick microstructure.

This allows research profiles to prefer strong structure/tick/imbalance evidence over many weak indicator-only confirmations.

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
- `indicator_phase_filter`
- `weighted_quality_confluence`
- `pa_full_confluence`

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

- Full offline refresh: PASS, 39 steps, 0 failed.
- `PRICE_ACTION_STRATEGY_MODULES_SMOKE_PASS`.
- `PRICE_ACTION_STRATEGY_BATCH_SMOKE_PASS`.
- `PRICE_ACTION_STRATEGY_HANDOFF_SMOKE_PASS`.
- `PRICE_ACTION_STRATEGY_DECISION_SMOKE_PASS`.
- Report import preflight: source hash PASS, price-action decision `COMPILE_REQUIRED` with 27 waiting report decisions.
- Local pipeline manifest: PASS, 72 artifacts tracked, 0 missing.
- External MT5 package audit: PASS, 26 checks passed, 0 failed.

## Hashes

- EA source: `458611765C9AA13BEF42EBAF5B9987CCD5534A5C9E94A2B985895C87FACBC8CD`.
- Price-action batch CSV: `AB602CA98DDC931A4C890A834EF8596AA00DC0B34ECFE133A2916FE0C06373F4`.
- Price-action handoff zip: `1AA24B7639F8DF0EDB5164EC2BE29B16844A229C8FE5EBE38B5548E67DFC48D8`.
- Price-action parallel lanes zip: `A14EAE9B9CBB5D0EA9EEC6B82B74EA219A0BD0BC845B8C2BDC6404CDB3A2BF26`.
- External validation package zip: `2A8CCC0AD569BDCAFDD9CB6FE5D52D72E47DF694E52885AFAC2B12463B3F6AD2`.
- Price-action modules smoke: `16AFF9CAD888D16E191D74CD66D6DD5A091698FCED1ECBD194CC48D1586F248C`.
- Price-action batch builder: `E0A41F9A9B3CFE7EBA8E014ABD29420A1A38303CA0B05B35B454BACC68D9FBBA`.

## Caveat

No profit claim is made from this update. Compile/test evidence is intentionally stale because MT5 and MetaEditor were not launched to avoid interrupting normal PC usage. Next performance step is a controlled external or truly non-interactive MT5 compile and backtest run using the rebuilt package or the new price-action lane zips, followed by importing reports through the decision gate.