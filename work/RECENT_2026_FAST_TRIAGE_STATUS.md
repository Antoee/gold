# Recent 2026 Fast Triage Status

Updated: 2026-07-06

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- Full EA source exists locally, but this note is the GitHub-safe status/evidence artifact.

## Latest Entry-Code Change

Added optional sweep rejection confirmation:

- `InpUseSweepRejection`
- `InpSweepRejectionMinWickPercent`
- `InpSweepRejectionMinCloseLocation`
- `InpWeightSweepRejection`
- `CMarketStructure::SweepRejection()` requires the latest closed candle to take liquidity beyond the prior swing level, close back through that level, close in the trade direction, and show a configurable rejection wick plus close-location quality.
- `CEntryEngine::Build()` now records `Sweep rejection;` as an independent weighted entry reason when the feature is enabled.

This is a price-action selectivity module for liquidity-sweep setups. The existing liquidity sweep confirmation can detect a stop-run through prior structure; sweep rejection requires evidence that price rejected the run instead of simply continuing through it. It is disabled in the robust base profile and enabled only in liquidity/confluence research profiles. It adds no martingale, grid, averaging down, or recovery behavior.

## Fast Batch Impact

- Batch size stayed at 10 profiles and 30 runs.
- Estimated tester runtime stayed at about 10.5 minutes before platform overhead.
- `liquidity_level_reversal` enables sweep rejection with minimum wick `35%` and close-location threshold `0.60`.
- `weighted_quality_confluence` enables sweep rejection with minimum wick `35%`, close-location threshold `0.60`, and weight `2`.
- `pa_full_confluence` enables a stricter version with minimum wick `40%` and close-location threshold `0.62`.
- Generated configs confirmed the module is enabled in liquidity/confluence research profiles and pinned disabled in the robust base profile.

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

- `outputs\Professional_XAUUSD_EA.mq5`: `294168E5339771C23566F98712CBFF507F309BAA9CDEBC51545167D1607CC6DC`
- `Professional_XAUUSD_EA.mq5`: `294168E5339771C23566F98712CBFF507F309BAA9CDEBC51545167D1607CC6DC`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `2022665AB38DC64F0F214FDCA058CED168F9AF465D12710D4104BFDF68163CD5`
- `outputs\PRICE_ACTION_STRATEGY_BATCH.csv`: `903827B590601032A7A70DABEBD76776A74CDD40CD4C103FEB0574FC2D00BED6`
- `outputs\xauusd_micro_validation_package.zip`: `F940CB87E31C1288DFC5AF6669D25F31BD74C1042AD4C3318D7DB11B08D5CFEC`
- `work\test_price_action_strategy_modules.ps1`: `E572BFBDA84E08F914361AE9CAB4658955BD0D6E97BF7F02F0CB6E73404C3ECD`
- `work\test_price_action_strategy_batch.ps1`: `0AF4C0E8DDBABAFDE1895CCC52443834D9FF4AEB5486ABFB0676B6027AAE2D61`
- `work\build_price_action_strategy_batch.ps1`: `32107935D8C9EEF6089684445FDED363EB19CB4816C577722293E54AF220F248`

## Background-Safety Note

The stop marker remains expected at `work\STOP_MT5_FOCUS_WATCHDOG`. Any future MT5 validation should be treated as external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The status note is committed through the GitHub connector. The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that the status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.
