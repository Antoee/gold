# Recent 2026 Fast Triage Status

Updated: 2026-07-06

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- Full EA source exists locally, but this note is the GitHub-safe status/evidence artifact.

## Latest Strategy-Code Change

Added optional opposing major-level proximity guard:

- `InpUseLevelProximityGuard`
- `InpLevelGuardUsePreviousDay`
- `InpLevelGuardUsePreviousWeek`
- `InpLevelGuardUsePreviousMonth`
- `InpMinDistanceFromLevelATR`
- `InpMinDistanceFromLevelPoints`
- `CEntryEngine::OpposingLevelDistanceAllows()` blocks buy entries when price is still below a nearby previous high, and blocks sell entries when price is still above a nearby previous low.
- `CEntryEngine::Build()` now rejects those bad-location setups with `Level proximity reject;` before confirmation scoring.

This is a real strategy-code addition from the requested price-action/market-structure/risk-feature list. It is designed to avoid entries with poor space to the next major support/resistance level, without martingale, grid, averaging down, or recovery behavior.

## Fast Batch Impact

- Batch size stayed at 10 profiles and 30 runs.
- Estimated tester runtime stayed at about 10.5 minutes before platform overhead.
- `weighted_quality_confluence` enables the level proximity guard with `0.30 ATR` / `70 points` minimum distance.
- `pa_full_confluence` enables the level proximity guard with `0.35 ATR` / `80 points` minimum distance.
- Generated configs confirmed the module is enabled only in strict research profiles and pinned disabled in the robust base profile.

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

- `outputs\Professional_XAUUSD_EA.mq5`: `E5DE90692124B685B88EC280F064B4984CD7D6703E148E0F62D6AC8943597A76`
- `Professional_XAUUSD_EA.mq5`: `E5DE90692124B685B88EC280F064B4984CD7D6703E148E0F62D6AC8943597A76`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `2C2F60DA9E964B149BFFC23E989C1CFD168FAF26AA6DD120EC5C9EE4C95D4232`
- `outputs\PRICE_ACTION_STRATEGY_BATCH.csv`: `903827B590601032A7A70DABEBD76776A74CDD40CD4C103FEB0574FC2D00BED6`
- `outputs\xauusd_micro_validation_package.zip`: `03D6C17F1CE8111E6C368E261AECBE2978E2A0EABC474A5ECF287D47D2AC84EC`
- `work\test_price_action_strategy_modules.ps1`: `22A9AEEA54C0B5470565ED9ED7064D42F4771F9E0C5AAECA62B9C592CE8D4E39`
- `work\test_price_action_strategy_batch.ps1`: `80852C1F3CE7BD27E4D98F5010661FE294753B4FDB0CFAF5C5E5B31EFA82C557`
- `work\build_price_action_strategy_batch.ps1`: `2A3167836EC7C304E20595C6DDA4F9E0F8C7C0F350B4F5BF29DA9051C3A254BF`

## Background-Safety Note

The stop marker remains expected at `work\STOP_MT5_FOCUS_WATCHDOG`. Any future MT5 validation should be treated as external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The status note is committed through the GitHub connector. The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that the status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.
