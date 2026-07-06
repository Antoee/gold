# Recent 2026 Fast Triage Status

Updated: 2026-07-06

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- Full EA source exists locally, but this note is the GitHub-safe status/evidence artifact.

## Latest Strategy-Code Change

Added an optional Adaptive Regime Confidence Gate:

- `InpUseAdaptiveRegimeConfidenceGate`
- `InpAdaptiveRegimeMinScore`
- `InpAdaptiveRegimeLookbackBars`
- `InpAdaptiveRegimeMinEfficiency`
- `InpAdaptiveRegimeMinAlignedBars`
- `CEntryEngine::AdaptiveRegimeConfidenceAllows()` scores ADX strength, ADX strengthening, EMA slope, ATR regime fit, directional efficiency, and candle alignment.
- Entry rejection logs `Adaptive regime reject score ...` with the contributing regime reasons.

This changes strategy logic instead of only changing settings. The goal is to avoid trading XAUUSD when the broader condition is too mixed: not cleanly trending, not directionally efficient, not aligned by candles, or sitting outside the acceptable ATR regime. It is disabled in the robust base profile and enabled only in strict research profiles. It adds no martingale, grid, averaging down, or recovery behavior.

## Fast Batch Impact

- Batch size stayed at 10 profiles and 30 runs.
- Estimated tester runtime stayed at about 10.5 minutes before platform overhead.
- `weighted_quality_confluence` enables Adaptive Regime Confidence Gate with minimum score `5`, lookback `12`, minimum efficiency `0.35`, and minimum aligned bars `6`.
- `pa_full_confluence` enables a stricter version with minimum score `6`, lookback `14`, minimum efficiency `0.40`, and minimum aligned bars `7`.
- Generated configs confirmed the module is enabled in strict price-action research profiles and pinned disabled in the robust base profile.

## Quiet Validation Results

- `work\test_price_action_strategy_modules.ps1`: PASS
- `work\build_price_action_strategy_batch.ps1`: PASS, 10 profiles, 30 runs, estimated 10.5 minutes
- `work\sync_ea_source_artifacts.ps1`: PASS
- `work\test_price_action_strategy_batch.ps1`: PASS
- `work\test_ea_source_artifact_sync.ps1`: PASS
- `work\build_external_mt5_validation_package.ps1`: PASS, package configs 20, profiles 9
- `work\test_external_mt5_validation_package.ps1`: PASS, 26 checks, 0 failed
- `work\refresh_offline_validation_state.ps1`: PASS, 39 steps, 0 failed

## Latest Hashes

- `outputs\Professional_XAUUSD_EA.mq5`: `80C25EFDA70A93EE6D7C82308A9A6FE0FE64135B4AC8233BE8E1EB5FB187D3F3`
- `Professional_XAUUSD_EA.mq5`: `80C25EFDA70A93EE6D7C82308A9A6FE0FE64135B4AC8233BE8E1EB5FB187D3F3`
- `outputs\external_mt5_validation_package\source\Professional_XAUUSD_EA.mq5`: `80C25EFDA70A93EE6D7C82308A9A6FE0FE64135B4AC8233BE8E1EB5FB187D3F3`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `7BEB3BF7BFE5A560E6B34BD1D74D0D47B12B4396B2A8E0BCD4756869A321842B`
- `outputs\PRICE_ACTION_STRATEGY_BATCH.csv`: `903827B590601032A7A70DABEBD76776A74CDD40CD4C103FEB0574FC2D00BED6`
- `outputs\xauusd_micro_validation_package.zip`: `773757A20ABE58DA8A5956397BCBACF58C2B8A1E12241DE794E9D760976D80D0`
- `work\test_price_action_strategy_modules.ps1`: `C588FDC062A56903B387BE9F157EFE0385A019BDC7D4AB8C1DB625E9EA6E9E1D`
- `work\test_price_action_strategy_batch.ps1`: `E0D8771155BA5157F63D6C64115B08CB7F1A9D9007CFE174B1ADE726739845BB`
- `work\build_price_action_strategy_batch.ps1`: `CD40A15D39C0EF79A6CC03CE9385738A932314F36FCCAEE7236178079B31C38E`

## Background-Safety Note

The stop marker remains expected at `work\STOP_MT5_FOCUS_WATCHDOG`. Any future MT5 validation should be treated as external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The status note can be committed through the GitHub connector. The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that the status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.
