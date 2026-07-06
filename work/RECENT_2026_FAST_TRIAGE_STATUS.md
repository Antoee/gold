# Recent 2026 Fast Triage Status

Updated: 2026-07-06

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- Full EA source exists locally, but this note is the GitHub-safe status/evidence artifact.

## Latest Strategy-Code Change

Added optional psychological round-number rejection:

- `InpUseRoundNumberRejection`
- `InpRoundNumberStepPoints`
- `InpRoundNumberBufferPoints`
- `InpWeightRoundNumberRejection`
- `CMarketStructure::RoundNumberRejection()` checks whether the latest closed candle swept/rejected the nearest configured round-number level.
- Entry reasons add `Round number;` when the confirmation is active and passes.

This is a price-action/market-structure feature aimed at XAUUSD behavior around large figure levels. It is independently configurable and can be optimized without increasing risk.

## Fast Batch Impact

- Batch size stayed at 10 profiles and 30 runs.
- Estimated tester runtime stayed at about 10.5 minutes before platform overhead.
- `liquidity_level_reversal` enables round-number rejection with 1000-point step and 80-point buffer.
- `pa_full_confluence` enables round-number rejection with 1000-point step and 70-point buffer.
- Generated configs confirmed the feature is enabled in those profiles and pinned disabled in other profiles.

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

- `outputs\Professional_XAUUSD_EA.mq5`: `3EAFD26773E21F021B4EF1722FAFA5FD59723800691B2CEAE0333CB4D7641FDB`
- `Professional_XAUUSD_EA.mq5`: `3EAFD26773E21F021B4EF1722FAFA5FD59723800691B2CEAE0333CB4D7641FDB`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `C1467D1BADF479D271C9A9BA202A2D695ECC479166ADC67E878E0BE0581C7207`
- `outputs\PRICE_ACTION_STRATEGY_BATCH.csv`: `903827B590601032A7A70DABEBD76776A74CDD40CD4C103FEB0574FC2D00BED6`
- `outputs\price_action_strategy_handoff.zip`: `899B32FF134B4A65BF0088A258C46BB7E8E9C7FDD216803E5D06C8BF8484BE39`
- `outputs\price_action_parallel_lanes.zip`: `00DA622B91BA093899693A1AF3C312F0466A77339DEA963A3000F671BCA39281`
- `outputs\xauusd_micro_validation_package.zip`: `6CE985E6A2CF6AC7CDD2D2BF65D75B9D2727F7731AA146D8ACD1682187D5EB80`
- `work\test_price_action_strategy_modules.ps1`: `A7BD91519627BB7EC31DB71AEBA00445BD9BACD7A7A4845BC24DD60435BC7E1D`
- `work\test_price_action_strategy_batch.ps1`: `4B9B4747F2872AA3617E1804D5610FDB5709664D06F52635B5DF7F393697B0DC`
- `work\build_price_action_strategy_batch.ps1`: `545929D2D8FDBAD70CE117EA20006F806F04BC35B6D7AAC845DF94D74E2D46C4`

## Background-Safety Note

The stop marker remains expected at `work\STOP_MT5_FOCUS_WATCHDOG`. Any future MT5 validation should be treated as external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The status note is committed through the GitHub connector. The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that the status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.
