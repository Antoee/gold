# Recent 2026 Fast Triage Status

Updated: 2026-07-06

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- Full EA source exists locally, but this note is the GitHub-safe status/evidence artifact.

## Latest Risk-Code Change

Added optional Recent Performance Quality Gate for generated research profiles:

- `InpUseRecentPerformanceQualityGate`
- `InpRecentPerformanceQualityLookbackTrades`
- `InpRecentPerformanceQualityMaxNetPercent`
- `InpRecentPerformanceMinQualityScore`
- `RecentPerformanceQualityAllows()` reviews the last closed trades using the existing recent-performance sample.
- If recent net performance is weak, new entries must meet the configured minimum signal quality score.
- `OpenSignal()` now blocks weak-quality entries with `recent performance quality` before risk sizing.

This is risk/profit selectivity code, not only parameter tweaking. It complements the existing recent-performance throttle and pause by raising the entry-quality bar instead of only reducing risk or pausing. The baseline anchor remains disabled for clean comparison, while generated research profiles enable it. It adds no martingale, grid, averaging down, or recovery behavior.

## Fast Batch Impact

- Batch size stayed at 10 profiles and 30 runs.
- Estimated tester runtime stayed at about 10.5 minutes before platform overhead.
- Baseline anchor remains `InpUseRecentPerformanceQualityGate=false`.
- Generated research profiles use `InpUseRecentPerformanceQualityGate=true`.
- Research profiles use lookback `5`, weak-performance threshold `-0.20`, and minimum quality score `10`.

## Quiet Validation Results

- `work\test_price_action_strategy_modules.ps1`: PASS
- `work\sync_ea_source_artifacts.ps1`: PASS, hash `7D439B1A03E35BA57BE8440BF2B9963D17846D274C7D6952A942B4A4A8E97367`
- `work\build_price_action_strategy_batch.ps1`: PASS, 10 profiles, 30 runs, estimated 10.5 minutes
- `work\test_ea_source_artifact_sync.ps1`: PASS
- `work\test_price_action_strategy_batch.ps1`: PASS
- `work\build_external_mt5_validation_package.ps1`: PASS, package configs 20, profiles 9
- `work\test_external_mt5_validation_package.ps1`: PASS, 26 checks, 0 failed
- `work\refresh_offline_validation_state.ps1`: PASS, 39 steps, 0 failed

## Latest Hashes

- `outputs\Professional_XAUUSD_EA.mq5`: `7D439B1A03E35BA57BE8440BF2B9963D17846D274C7D6952A942B4A4A8E97367`
- `Professional_XAUUSD_EA.mq5`: `7D439B1A03E35BA57BE8440BF2B9963D17846D274C7D6952A942B4A4A8E97367`
- `outputs\external_mt5_validation_package\source\Professional_XAUUSD_EA.mq5`: `7D439B1A03E35BA57BE8440BF2B9963D17846D274C7D6952A942B4A4A8E97367`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `AAB2E887480D7D57F3584DA41D2D71C9860F039A10FF93B37EA4C5333E6C5AC4`
- `outputs\PRICE_ACTION_STRATEGY_BATCH.csv`: `903827B590601032A7A70DABEBD76776A74CDD40CD4C103FEB0574FC2D00BED6`
- `outputs\xauusd_micro_validation_package.zip`: `3F405B8CC16EE7CAB480C3327C9ECFD096A622AE22E6867C236E2E81E4A9F0C9`
- `work\test_price_action_strategy_modules.ps1`: `9D9E4307E71431A7A7B01E52DE2717FC844A9E3D1708A13B72C05332F8276B6F`
- `work\test_price_action_strategy_batch.ps1`: `44989DD9AD1A7B9F99E413C21B0BF32B8EAD7B44F235E79528A9A3028D655A19`
- `work\build_price_action_strategy_batch.ps1`: `8800ECD2EBE58B7730F0DC8B96586995893ACF47AFADB2DB30E05DCD035AD8A1`

## Background-Safety Note

The stop marker remains expected at `work\STOP_MT5_FOCUS_WATCHDOG`. Any future MT5 validation should be treated as external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The status note was committed through the GitHub connector. The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that the status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.
