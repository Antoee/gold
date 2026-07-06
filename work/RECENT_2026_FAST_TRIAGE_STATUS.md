# Recent 2026 Fast Triage Status

Updated: 2026-07-06

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- Full EA source exists locally, but this note is the GitHub-safe status/evidence artifact.

## Latest Strategy-Code Change

Added optional raw price-action and tick-pressure entry confirmations:

- `InpUseDisplacementCandle`
- `InpDisplacementMinRangeATR`
- `InpDisplacementMinBodyPercent`
- `InpDisplacementMaxOppositeWickPercent`
- `InpUseTickPressureCandle`
- `InpTickPressureLookbackBars`
- `InpTickPressureMinVolumeRatio`
- `InpTickPressureMinCloseLocation`
- `InpWeightDisplacementCandle`
- `InpWeightTickPressureCandle`
- `CEntryEngine::DisplacementCandle()` scores directional OHLC displacement using candle range, body size, ATR expansion, and opposite-wick rejection.
- `CEntryEngine::TickPressureCandle()` scores tick-volume pressure using volume ratio and close location inside the candle range.
- `CEntryEngine::Build()` now records `Displacement candle;` and `Tick pressure candle;` as independent entry reasons.

This expands the strategy code beyond settings-only optimization. The new modules use data available inside MT5 Strategy Tester without requiring unsupported feeds such as DOM, DXY, bond yields, or news sentiment.

## Fast Batch Impact

- Batch size stayed at 10 profiles and 30 runs.
- Estimated tester runtime stayed at about 10.5 minutes before platform overhead.
- `weighted_quality_confluence` enables displacement candle and tick-pressure candle confirmations with weights of `2` each.
- `pa_full_confluence` enables stricter displacement and tick-pressure thresholds.
- Generated configs confirmed both modules are enabled in the strict research profiles and pinned disabled in the robust base profile.

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

- `outputs\Professional_XAUUSD_EA.mq5`: `00F366237AC8D32B6C64BC4783E212279F2EE93F3B12C0A6EE47D824AEED91BC`
- `Professional_XAUUSD_EA.mq5`: `00F366237AC8D32B6C64BC4783E212279F2EE93F3B12C0A6EE47D824AEED91BC`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `22DA7EA81EB791F2EFD20FF195EBE179363FE3AE8CDAEE3DBD916A71031E9A50`
- `outputs\PRICE_ACTION_STRATEGY_BATCH.csv`: `903827B590601032A7A70DABEBD76776A74CDD40CD4C103FEB0574FC2D00BED6`
- `outputs\xauusd_micro_validation_package.zip`: `B6F3985CA6A7B57E8F692E444BF1FCD25A65313E8E82DA8B6190A8775AB33E67`
- `work\test_price_action_strategy_modules.ps1`: `AD3F031FB145D41D8C8156D4A0B0C3E6C510D327CF53C95F9F3D695551AA22DB`
- `work\test_price_action_strategy_batch.ps1`: `AF234526E60BC260438AA7457DB6D811D07FE7225EF86EF6863A8443A547D00E`
- `work\build_price_action_strategy_batch.ps1`: `2E5C7EC875FC1D7EFB9B11D1EA2F35B09F69D2B28FBA6E154C99E2C22CC493F1`

## Background-Safety Note

The stop marker remains expected at `work\STOP_MT5_FOCUS_WATCHDOG`. Any future MT5 validation should be treated as external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The status note is committed through the GitHub connector. The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that the status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.
