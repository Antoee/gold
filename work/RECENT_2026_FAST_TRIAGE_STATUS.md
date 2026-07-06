# Recent 2026 Fast Triage Status

Updated: 2026-07-06

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- Full EA source exists locally, but this note is the GitHub-safe status/evidence artifact.

## Latest Strategy-Code Change

Added optional EMA pullback-continuation entry confirmation:

- `InpUseEMAPullbackContinuation`
- `InpEMAPullbackMaxDistanceATR`
- `InpEMAPullbackMinBodyPercent`
- `InpWeightEMAPullback`
- `CEntryEngine::EMAPullbackContinuation()` detects a pullback to the fast entry EMA followed by a directional continuation candle.
- `CEntryEngine::Build()` now records `EMA pullback;` as an independent weighted entry reason when the feature is enabled.

This is a trend-continuation entry module for XAUUSD. It is intended to add a cleaner pullback-style entry path so the EA is not relying only on breakouts or late momentum candles. It stays optional, configurable, and disabled in the robust base profile. It adds no martingale, grid, averaging down, or recovery behavior.

## Fast Batch Impact

- Batch size stayed at 10 profiles and 30 runs.
- Estimated tester runtime stayed at about 10.5 minutes before platform overhead.
- `weighted_quality_confluence` enables EMA pullback continuation with max EMA distance `0.35 ATR`, minimum body `35.0%`, and weight `2`.
- `pa_full_confluence` enables a stricter EMA pullback continuation with max EMA distance `0.30 ATR` and minimum body `40.0%`.
- Generated configs confirmed the module is enabled in the strict research profiles and pinned disabled in the robust base profile.

## Quiet Validation Results

- `work\build_price_action_strategy_batch.ps1`: PASS, 10 profiles, 30 runs, estimated 10.5 minutes
- `work\sync_ea_source_artifacts.ps1`: PASS
- `work\test_price_action_strategy_modules.ps1`: PASS
- `work\test_price_action_strategy_batch.ps1`: PASS
- `work\test_ea_source_artifact_sync.ps1`: PASS
- `work\refresh_offline_validation_state.ps1`: PASS, 39 steps, 0 failed
- `work\build_external_mt5_validation_package.ps1`: PASS, package configs 20, profiles 9
- `work\test_external_mt5_validation_package.ps1`: PASS, 26 checks, 0 failed

## Latest Hashes

- `outputs\Professional_XAUUSD_EA.mq5`: `74B786AD429BECCE0113688A5E418B2EA5CD1630422F20C739F17F91FA7BA287`
- `Professional_XAUUSD_EA.mq5`: `74B786AD429BECCE0113688A5E418B2EA5CD1630422F20C739F17F91FA7BA287`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `CA159892D0BE120BB4A8AE16569897F9AC6677E54F6884FEF3203F37FF0B8BA3`
- `outputs\PRICE_ACTION_STRATEGY_BATCH.csv`: `903827B590601032A7A70DABEBD76776A74CDD40CD4C103FEB0574FC2D00BED6`
- `outputs\xauusd_micro_validation_package.zip`: `46ADFB9B330A0562BA0AFB5D434D724C6C3DA8CAD14C65A5A3C2C9D711D3F3D5`
- `work\test_price_action_strategy_modules.ps1`: `DBE28773D78DDAEF9B65FA518001C4D74BDD52099B98FDAFCDC5ECA2DE8F0117`
- `work\test_price_action_strategy_batch.ps1`: `D7A0A1AFD472F13FD635DBBD8E7B68160E3C34A25A28078ECAD31E3F6710700E`
- `work\build_price_action_strategy_batch.ps1`: `09754E61B25C5118915B19D716B63D712F9B7AEF831A059BE1F76087950524E1`

## Background-Safety Note

The stop marker remains expected at `work\STOP_MT5_FOCUS_WATCHDOG`. Any future MT5 validation should be treated as external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The status note is committed through the GitHub connector. The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that the status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.
