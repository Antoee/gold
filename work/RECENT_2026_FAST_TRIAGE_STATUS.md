# Recent 2026 Fast Triage Status

Updated: 2026-07-06

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- Full EA source exists locally, but this note is the GitHub-safe status/evidence artifact.

## Latest Strategy-Code Change

Added optional impulse-exhaustion entry guard:

- `InpUseImpulseExhaustionGuard`
- `InpImpulseExhaustionLookbackBars`
- `InpImpulseExhaustionMaxMoveATR`
- `InpImpulseExhaustionClosePercent`
- `CEntryEngine::ImpulseExhaustionAllows()` detects when recent price has already moved too far in the intended direction and closed near the range extreme.
- `CEntryEngine::Build()` now rejects late chase entries with `Impulse exhaustion reject;` when the feature is enabled.

This is a price-action quality filter for XAUUSD. It is intended to avoid buying after an already-stretched bullish impulse or selling after an already-stretched bearish impulse. It stays optional, configurable, and disabled in the robust base profile. It adds no martingale, grid, averaging down, or recovery behavior.

## Fast Batch Impact

- Batch size stayed at 10 profiles and 30 runs.
- Estimated tester runtime stayed at about 10.5 minutes before platform overhead.
- `weighted_quality_confluence` enables impulse exhaustion guard with lookback `6`, max move `1.80 ATR`, and close extreme `80.0%`.
- `pa_full_confluence` enables stricter impulse exhaustion guard with lookback `8`, max move `1.60 ATR`, and close extreme `82.0%`.
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

- `outputs\Professional_XAUUSD_EA.mq5`: `073C353E7D77ECDCCA45E1E65AFE3834BD3255DBB013046FFCBB0DD4AA82C823`
- `Professional_XAUUSD_EA.mq5`: `073C353E7D77ECDCCA45E1E65AFE3834BD3255DBB013046FFCBB0DD4AA82C823`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `BDC512950CE5772F60F4972DB9797546C476392FC6BDC257BE689B994B8D9F73`
- `outputs\PRICE_ACTION_STRATEGY_BATCH.csv`: `903827B590601032A7A70DABEBD76776A74CDD40CD4C103FEB0574FC2D00BED6`
- `outputs\xauusd_micro_validation_package.zip`: `6F305C3D1128E0E71CD3D73B91F9B57DAA377CAE220852F7A0E799001D9608B1`
- `work\test_price_action_strategy_modules.ps1`: `3D2AE0B2124B708F3227D328CFCC949AAD769F47C302AE6C939DE3103D88FE5A`
- `work\test_price_action_strategy_batch.ps1`: `3D57242DBBF443C77FE1FEF6E0C03204DE8D96C25917AFA6EABCA524D11B8E76`
- `work\build_price_action_strategy_batch.ps1`: `01C33DB9DACA5F91EC3C9DE46523E9314EC8F44E68C9B98821B0D53CB9954BB6`

## Background-Safety Note

The stop marker remains expected at `work\STOP_MT5_FOCUS_WATCHDOG`. Any future MT5 validation should be treated as external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The status note is committed through the GitHub connector. The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that the status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.
