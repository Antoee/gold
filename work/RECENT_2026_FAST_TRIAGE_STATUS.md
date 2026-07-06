# Recent 2026 Fast Triage Status

Updated: 2026-07-06

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- Full EA source exists locally, but this note is the GitHub-safe status/evidence artifact.

## Latest Strategy-Code Change

Added optional swing-recency structure filter:

- `InpUseSwingRecencyFilter`
- `InpSwingLeftBars`
- `InpSwingRightBars`
- `InpMaxBarsSinceSwing`
- `CMarketStructure::IsSwingHigh()` and `CMarketStructure::IsSwingLow()` detect completed swing points.
- `CMarketStructure::RecentSwingAllows()` requires a recent directional swing before entry when enabled.
- `CEntryEngine::Build()` now rejects stale structure setups with `Swing recency reject;` before counting confirmations.

This is a market-structure/time-since-swing module from the requested strategy-code expansion. It is intended to reduce late entries after old structure has already played out, without increasing risk or adding any recovery logic.

## Fast Batch Impact

- Batch size stayed at 10 profiles and 30 runs.
- Estimated tester runtime stayed at about 10.5 minutes before platform overhead.
- `weighted_quality_confluence` enables swing recency with left/right `2/2` and max bars since swing `30`.
- `pa_full_confluence` enables swing recency with left/right `2/2` and max bars since swing `24`.
- Generated configs confirmed the module is enabled in those strict profiles and pinned disabled in the robust base profile.

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

- `outputs\Professional_XAUUSD_EA.mq5`: `8BAB261DAB60477DFB090850A12BA70C022A50C21AFF34BC20CADEA0FE1A3FBA`
- `Professional_XAUUSD_EA.mq5`: `8BAB261DAB60477DFB090850A12BA70C022A50C21AFF34BC20CADEA0FE1A3FBA`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `19B5966AEA24DB8E9418469E48695CECBC2FD9E910CE4AF1F43628D5EEB79C53`
- `outputs\PRICE_ACTION_STRATEGY_BATCH.csv`: `903827B590601032A7A70DABEBD76776A74CDD40CD4C103FEB0574FC2D00BED6`
- `outputs\price_action_strategy_handoff.zip`: `33AAE77CB0303B60851CD33E01BDEDF0FA92FF0D5C8B431E4585015F36F056DC`
- `outputs\price_action_parallel_lanes.zip`: `C20CD8DE4F5594E8BFEC7F1CF09D184FED07AB98AF82BF3D73284957CF4BACB9`
- `outputs\xauusd_micro_validation_package.zip`: `459B9B788E577E5F9572DAAA10F58423FC0727B55683C016AB0AD4ADE92C8E7C`
- `work\test_price_action_strategy_modules.ps1`: `8FFF22EF6682F8313C34B42AAAB629C79EEE5EAEC07FE994154E4EC52232BFA2`
- `work\test_price_action_strategy_batch.ps1`: `4B9B4747F2872AA3617E1804D5610FDB5709664D06F52635B5DF7F393697B0DC`
- `work\build_price_action_strategy_batch.ps1`: `63D099C80ACAD2110ECF375565B914BD434165908809FCEC3F2DA39776A2A353`

## Background-Safety Note

The stop marker remains expected at `work\STOP_MT5_FOCUS_WATCHDOG`. Any future MT5 validation should be treated as external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The status note is committed through the GitHub connector. The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that the status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.
