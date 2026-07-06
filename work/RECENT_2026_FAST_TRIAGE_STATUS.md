# Recent 2026 Fast Triage Status

Updated: 2026-07-06

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- Full EA source exists locally, but this note is the GitHub-safe status/evidence artifact.

## Latest Strategy-Code Change

Added optional opposite-wick rejection guard:

- `InpUseOppositeWickGuard`
- `InpMaxOppositeWickPercent`
- `CEntryEngine::OppositeWickAllows()` blocks buy entries after large upper rejection wicks and sell entries after large lower rejection wicks.
- `CEntryEngine::Build()` now rejects these price-action failures with `Opposite wick reject;`.

This is a price-action/risk module from the requested strategy-code expansion. It is intended to avoid entries after the candle has already rejected the intended direction, without increasing risk or adding any recovery logic.

## Fast Batch Impact

- Batch size stayed at 10 profiles and 30 runs.
- Estimated tester runtime stayed at about 10.5 minutes before platform overhead.
- `pa_full_confluence` enables opposite-wick rejection with max opposite wick `45.0%`.
- Generated configs confirmed the module is enabled in that strict candle-anatomy profile and pinned disabled in the robust base profile.

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

- `outputs\Professional_XAUUSD_EA.mq5`: `F6D8450685C9F4ECA558C163754B7FF3AFB695CA46C168CD9DF480FAA38C2E8B`
- `Professional_XAUUSD_EA.mq5`: `F6D8450685C9F4ECA558C163754B7FF3AFB695CA46C168CD9DF480FAA38C2E8B`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `1A7153D40FBBC0D0F4D921B715C4451B170D2C2C3B82EA0585B2190CE5967222`
- `outputs\PRICE_ACTION_STRATEGY_BATCH.csv`: `903827B590601032A7A70DABEBD76776A74CDD40CD4C103FEB0574FC2D00BED6`
- `outputs\price_action_strategy_handoff.zip`: `37FE6D24D02B8D081B2BE1B6A82665E345EC715D372A2FAB1C84CD91E04232C2`
- `outputs\price_action_parallel_lanes.zip`: `F0E3325D95B583D365D2C4AA1D4090354EB2369A15BC65EA3046CB35A0947F57`
- `outputs\xauusd_micro_validation_package.zip`: `4D615E90E7EC7290E043E3D205328B78548C8B91FF68D242C1EBDFBA7544C4F7`
- `work\test_price_action_strategy_modules.ps1`: `9AD7377EE70E91768718477DECBE6FE91EC686AE027ED2C316D75F34CA8D682A`
- `work\test_price_action_strategy_batch.ps1`: `4B9B4747F2872AA3617E1804D5610FDB5709664D06F52635B5DF7F393697B0DC`
- `work\build_price_action_strategy_batch.ps1`: `7C3B02607780F7634E793D1A714A2B129BECD8BF1C36865BEA77CB66D5008EF0`

## Background-Safety Note

The stop marker remains expected at `work\STOP_MT5_FOCUS_WATCHDOG`. Any future MT5 validation should be treated as external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The status note is committed through the GitHub connector. The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that the status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.
