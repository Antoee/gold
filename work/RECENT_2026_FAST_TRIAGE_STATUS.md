# Recent 2026 Fast Triage Status

Updated: 2026-07-06

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- Full EA source exists locally, but this note is the GitHub-safe status/evidence artifact.

## Latest Strategy-Code Change

Added optional cumulative-delta proxy entry confirmation:

- `InpUseCumulativeDeltaProxy`
- `InpCumulativeDeltaLookbackBars`
- `InpCumulativeDeltaMinRatio`
- `InpCumulativeDeltaMinBarsAligned`
- `InpWeightCumulativeDelta`
- `CEntryEngine::CumulativeDeltaProxy()` sums signed tick volume over recent candles and requires directional volume imbalance plus a minimum number of aligned candles.
- `CEntryEngine::Build()` now records `Cumulative delta proxy;` as an independent weighted entry reason when the feature is enabled.

This is an order-flow style proxy for XAUUSD tester data. MT5 brokers often do not expose true bid/ask delta or centralized futures volume inside spot-gold Strategy Tester data, so this module uses candle direction multiplied by tick volume as a conservative, configurable approximation. It stays optional, configurable, and disabled in the robust base profile. It adds no martingale, grid, averaging down, or recovery behavior.

## Fast Batch Impact

- Batch size stayed at 10 profiles and 30 runs.
- Estimated tester runtime stayed at about 10.5 minutes before platform overhead.
- `tick_vwap_momentum` enables cumulative-delta proxy with lookback `12`, minimum signed-volume ratio `0.18`, and minimum aligned bars `7`.
- `indicator_phase_filter` enables cumulative-delta proxy with lookback `12`, minimum signed-volume ratio `0.16`, and minimum aligned bars `7`.
- `weighted_quality_confluence` enables cumulative-delta proxy with lookback `12`, minimum signed-volume ratio `0.18`, minimum aligned bars `7`, and weight `2`.
- `pa_full_confluence` enables a stricter cumulative-delta proxy with lookback `14`, minimum signed-volume ratio `0.20`, and minimum aligned bars `8`.
- Generated configs confirmed the module is enabled in order-flow/strict research profiles and pinned disabled in the robust base profile.

## Quiet Validation Results

- `work\test_price_action_strategy_modules.ps1`: PASS
- `work\build_price_action_strategy_batch.ps1`: PASS, 10 profiles, 30 runs, estimated 10.5 minutes
- `work\sync_ea_source_artifacts.ps1`: PASS
- `work\test_price_action_strategy_batch.ps1`: PASS
- `work\test_ea_source_artifact_sync.ps1`: PASS
- `work\refresh_offline_validation_state.ps1`: PASS, 39 steps, 0 failed
- `work\build_external_mt5_validation_package.ps1`: PASS, package configs 20, profiles 9
- `work\test_external_mt5_validation_package.ps1`: PASS, 26 checks, 0 failed

## Latest Hashes

- `outputs\Professional_XAUUSD_EA.mq5`: `BD7F859C57136DB501179784562960AE2CB9E04922599A0954BCB5518A806B6D`
- `Professional_XAUUSD_EA.mq5`: `BD7F859C57136DB501179784562960AE2CB9E04922599A0954BCB5518A806B6D`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `E462CB763364CB5FE3251DA90FA8BED2A692CB0AFCE078DB0097F0CC22BCD2FF`
- `outputs\PRICE_ACTION_STRATEGY_BATCH.csv`: `903827B590601032A7A70DABEBD76776A74CDD40CD4C103FEB0574FC2D00BED6`
- `outputs\xauusd_micro_validation_package.zip`: `82D10BD7D6B5FBBE5A54E1D018659484C19208C66607858DE3D4EE92C6BB6542`
- `work\test_price_action_strategy_modules.ps1`: `9E6934E0CFA35432A72A18822527DF6A4BADD2BC725F21E72C74E64F64DBE1DA`
- `work\test_price_action_strategy_batch.ps1`: `B4687F30023CAF48E6F476B478A34C35240EA74C53779497EC53A115036606EB`
- `work\build_price_action_strategy_batch.ps1`: `1EF14853A4D4B06A1BF537DF169FFFC278A918C0DFB5A964029068407FF1F248`

## Background-Safety Note

The stop marker remains expected at `work\STOP_MT5_FOCUS_WATCHDOG`. Any future MT5 validation should be treated as external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The status note is committed through the GitHub connector. The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that the status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.
