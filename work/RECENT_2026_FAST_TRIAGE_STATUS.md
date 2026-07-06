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
- Current synced source SHA256: `6CA7AD334AC5466CD7D20B823EBFFA3EA5E522204157386654317E435BF4A037`.

## Strategy-Code Work

The EA now includes optional, independently configurable strategy modules for actual price-action, market-state, tick-tape, weighted setup-quality logic, and profit protection:

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

## Profit-Lock Stop Addition

Added an optional profit-protection stop for trades that have already moved in favor:

- `InpUseProfitLockStop=false` by default.
- `InpProfitLockTriggerATR=1.50`.
- `InpProfitLockATR=0.35`.
- When enabled, the position manager waits until price has moved at least `InpProfitLockTriggerATR * ATR` from entry.
- It then moves SL into protected profit by `InpProfitLockATR * ATR` from entry.
- It works as another stop candidate alongside break-even, ATR trailing, and structure trailing.

This is designed for XAUUSD reversals where a trade reaches open profit but gives it back before the standard trailing stop catches up. The base profile keeps it disabled; selected high-confluence research profiles enable it for testing.

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

The `weighted_quality_confluence` research profile now enables weighted scoring, quality risk scaling, tick microstructure, regime-quality scoring, and profit-lock stops.

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
- `weighted_quality_confluence` includes regime-quality scoring, quality risk scaling, and profit-lock stops.
- `pa_full_confluence` includes profit-lock stops.

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

- EA source: `6CA7AD334AC5466CD7D20B823EBFFA3EA5E522204157386654317E435BF4A037`.
- Base profile: `5F2CDD96A35AB83CB7FB9605CA2D3AEAA07E734D883A112264F7A415885A0DCA`.
- Price-action batch CSV: `903827B590601032A7A70DABEBD76776A74CDD40CD4C103FEB0574FC2D00BED6`.
- Price-action handoff zip: `4D3A3CCC2006B984BDB4269B84E5D18DD41E49805903CAB3029698FFCA6D5F38`.
- Price-action parallel lanes zip: `7CBD72052940E82D65EBD75C26312C21A4F14DBA3EF706C4179C0473453B664F`.
- External validation package zip: `A8A67AB58D47369AF216029BD0B0261C917BD659A788A778D5D8E6279AA34D42`.
- Price-action modules smoke: `1FA203F7E4013185CE971071F7BB08C8E13BDBBE21E596B67B62019E56AA173C`.
- Price-action batch smoke: `07C93FBD1E99A82F3A05FBA5287F4E3CCAE5659078076256605FB60E109FA1AC`.
- Price-action batch builder: `D057DAA7B6D19977836FE67F7E84E286A623A28D8D6EC1174D7EDC5C2772120B`.

## Caveat

No profit claim is made from this update. Compile/test evidence is intentionally stale because MT5 and MetaEditor were not launched to avoid interrupting normal PC usage. Next performance step is a controlled external or truly non-interactive MT5 compile and backtest run using the rebuilt package or the new price-action lane zips, followed by importing reports through the decision gate.