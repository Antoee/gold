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
- Current synced source SHA256: `ECD6FB47D76CCA4CE87C233E10B8B62D500B0D188939F1D2707E5469E386AB1D`.

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
- Regime-quality confirmation using ADX, EMA slope, and ATR regime.

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

The feature is default-off so the promoted baseline remains reproducible, but optimization profiles can now test whether trend/volatility context filters out low-quality XAUUSD entries.

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

The `weighted_quality_confluence` research profile now enables weighted scoring, quality risk scaling, tick microstructure, and regime-quality scoring.

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
- `indicator_phase_filter` now includes regime-quality scoring.
- `weighted_quality_confluence` now includes regime-quality scoring and quality risk scaling.
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

- EA source: `ECD6FB47D76CCA4CE87C233E10B8B62D500B0D188939F1D2707E5469E386AB1D`.
- Base profile: `795950EE752557D37DCA3F4035150F006C94A9E9149D92E1E25DC3710744E97C`.
- Price-action batch CSV: `903827B590601032A7A70DABEBD76776A74CDD40CD4C103FEB0574FC2D00BED6`.
- Price-action handoff zip: `CBDDDF96C5110D59CA24C849AD1D8F6F6CF4E08BB475AC03CBFCE85A88754E4C`.
- Price-action parallel lanes zip: `A642CE2B3FAB6B46AAE6B38E7AA8938FA74B6A66F65B674E531532BE249FD767`.
- External validation package zip: `CAE642E51D2928549849A1A831EC881467359A5DEE39820F93000963DCB803AF`.
- Price-action modules smoke: `7EB980A9117509C541A0F49DDDE31AF7D42A115F06249465825FD20B15938534`.
- Price-action batch smoke: `7EDC664E694DD1F50F7662284D7C3948B9104DD215C3F0BCF8D19076FAA4A8F8`.
- Price-action batch builder: `1A3C6DD6FC79AFCB0A711BDB041E1D80B72E82F5F6C094308C952F9C827AEE9D`.

## Caveat

No profit claim is made from this update. Compile/test evidence is intentionally stale because MT5 and MetaEditor were not launched to avoid interrupting normal PC usage. Next performance step is a controlled external or truly non-interactive MT5 compile and backtest run using the rebuilt package or the new price-action lane zips, followed by importing reports through the decision gate.