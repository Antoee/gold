# Recent 2026 Fast Triage Status

Updated: 2026-07-06

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- Full EA source exists locally, but this note is the GitHub-safe status/evidence artifact.

## Latest Strategy-Code Change

Added optional Recent Swing Level Proximity Guard inside the existing level proximity filter:

- `InpLevelGuardUseRecentSwings`
- `InpLevelGuardSwingLookbackBars`
- `OpposingLevelDistanceAllows()` now optionally scans confirmed recent swing highs and swing lows.
- Buy signals can be blocked when the close is too close below a recent swing high resistance.
- Sell signals can be blocked when the close is too close above a recent swing low support.

This is strategy/risk logic using existing swing-structure helpers, not only settings. It expands the previous day/week/month opposing-level guard so entries avoid nearby local market-structure levels where XAUUSD often stalls or reverses. It adds no martingale, grid, averaging down, or recovery behavior.

## Fast Batch Impact

- Batch size stayed at 10 profiles and 30 runs.
- Estimated tester runtime stayed at about 10.5 minutes before platform overhead.
- Baseline anchor remains `InpLevelGuardUseRecentSwings=false`.
- Generated research profiles use `InpLevelGuardUseRecentSwings=true` with `InpLevelGuardSwingLookbackBars=30`.
- Research profiles that enable level proximity now test both higher-timeframe opposing levels and recent swing opposing levels.

## Quiet Validation Results

- `work\test_price_action_strategy_modules.ps1`: PASS
- `work\sync_ea_source_artifacts.ps1`: PASS, hash `74A1D99EEB6A962BCD0124B5B5C6FA6E2E357C79C29C91AA21E55BF551946A47`
- `work\build_price_action_strategy_batch.ps1`: PASS, 10 profiles, 30 runs, estimated 10.5 minutes
- `work\test_ea_source_artifact_sync.ps1`: PASS
- `work\test_price_action_strategy_batch.ps1`: PASS
- `work\build_external_mt5_validation_package.ps1`: PASS, package configs 20, profiles 9
- `work\test_external_mt5_validation_package.ps1`: PASS, 26 checks, 0 failed
- `work\refresh_offline_validation_state.ps1`: PASS, 39 steps, 0 failed

## Latest Hashes

- `outputs\Professional_XAUUSD_EA.mq5`: `74A1D99EEB6A962BCD0124B5B5C6FA6E2E357C79C29C91AA21E55BF551946A47`
- `Professional_XAUUSD_EA.mq5`: `74A1D99EEB6A962BCD0124B5B5C6FA6E2E357C79C29C91AA21E55BF551946A47`
- `outputs\external_mt5_validation_package\source\Professional_XAUUSD_EA.mq5`: `74A1D99EEB6A962BCD0124B5B5C6FA6E2E357C79C29C91AA21E55BF551946A47`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `D70DCE426BCE87A7AAD61245FB2DC5794CD22A246BB4891266EB854AFB50F7A2`
- `outputs\PRICE_ACTION_STRATEGY_BATCH.csv`: `903827B590601032A7A70DABEBD76776A74CDD40CD4C103FEB0574FC2D00BED6`
- `outputs\xauusd_micro_validation_package.zip`: `18634557FED0EC48C758590944A831259B36EE67FEE1DAFEBCF273AB4F03E484`
- `work\test_price_action_strategy_modules.ps1`: `99D1E5E786E45A9DA41CFEF9AE714A6FE3165918EB51CBFFFFBC90AD7BB40D77`
- `work\test_price_action_strategy_batch.ps1`: `0559D0557F3D0352E5C174AE09C2FBEF284EF10780BC26A423ABC29923C0A146`
- `work\build_price_action_strategy_batch.ps1`: `2CB9C6B3621693697362CD7BFEDABAC5B14E772603D850C647E2FD738AF94465`

## Background-Safety Note

The stop marker remains expected at `work\STOP_MT5_FOCUS_WATCHDOG`. Any future MT5 validation should be treated as external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The status note was committed through the GitHub connector. The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that the status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.
