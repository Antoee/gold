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
- Current synced source SHA256: `1CF2FC9D0B93B4B3511F06729089A92780F87C7C71D13B0F8A4626E67D023113`.

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
- Quality-based risk scaling.

## Weighted Entry-Quality Addition

Added optional weighted setup scoring beside the existing confirmation count:

- `SSignal` now tracks `qualityScore`.
- Every enabled confirmation can add a configurable weight.
- `InpUseWeightedEntryScore=false` by default, so promoted baseline behavior stays unchanged.
- When enabled, `InpMinimumEntryScore` can reject setups that have enough raw confirmations but not enough high-quality evidence.
- New weight inputs cover BOS, liquidity sweep, CHoCH, FVG, order block, equal levels, previous/session levels, VWAP, momentum, volume, indicators, candles, ATR expansion, and tick microstructure.

This lets research profiles prefer strong structure/tick/imbalance evidence over many weak indicator-only confirmations.

## Quality Risk Scaling Addition

Added optional quality-based risk sizing so the EA can risk less on marginal setups and only use full allowed risk on high-quality setups:

- `InpUseQualityRiskScaling=false` by default.
- `InpQualityRiskMinScore=5`.
- `InpQualityRiskFullScore=10`.
- `InpMinQualityRiskMultiplier=0.50`.
- `InpMaxQualityRiskMultiplier=1.00`.
- `QualityRiskMultiplier()` maps setup quality to a bounded risk multiplier.
- `CRiskManager::LotsForRisk()` now accepts the multiplier and applies it to `EffectiveRiskPercent()`.
- Trade logs include the quality risk multiplier when enabled.

The `weighted_quality_confluence` research profile now enables both weighted scoring and quality risk scaling:

- `InpUseWeightedEntryScore=true`.
- `InpMinimumEntryScore=7`.
- `InpUseQualityRiskScaling=true`.
- `InpQualityRiskMinScore=7`.
- `InpQualityRiskFullScore=11`.
- `InpMinQualityRiskMultiplier=0.50`.
- `InpMaxQualityRiskMultiplier=1.00`.

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

- EA source: `1CF2FC9D0B93B4B3511F06729089A92780F87C7C71D13B0F8A4626E67D023113`.
- Price-action batch CSV: `AB602CA98DDC931A4C890A834EF8596AA00DC0B34ECFE133A2916FE0C06373F4`.
- Price-action handoff zip: `C9A59E96CFD8720A9E5E5C63FFBAB5DEDF0D0747B05EB42F7BE7A5683622FBD1`.
- Price-action parallel lanes zip: `BF51ACAA9A47205F05C025693B6DA3383DE4740BAEBF1D7B67EB050E433317CB`.
- External validation package zip: `64716D17BBC5342E861D352A0E2B2CBBBFF6FA6FC21C4080667F726C5C0DE3ED`.
- Open risk exposure guard smoke: `305BF7920A750147F218F9A1ADB16BDF7B2858B8EEAE3CEF1462C6EFD9913DDE`.
- Max stop ATR guard smoke: `145DFCBCB3D977F33D2B88D1518E0D76D96715FCFA171E66588E2D2866528C04`.
- Price-action modules smoke: `FA4A47F3D2D4B733628449E6BDF7F3794CBC6DFB8C1D459D023FBBEF772A3289`.
- Price-action batch builder: `0E4D601E150523232A0D9407231A054372100F79ED08F1DC5188E6DDAA96666D`.

## Caveat

No profit claim is made from this update. Compile/test evidence is intentionally stale because MT5 and MetaEditor were not launched to avoid interrupting normal PC usage. Next performance step is a controlled external or truly non-interactive MT5 compile and backtest run using the rebuilt package or the new price-action lane zips, followed by importing reports through the decision gate.