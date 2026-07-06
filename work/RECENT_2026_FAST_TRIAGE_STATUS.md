# Recent 2026 Fast Triage Status

Updated: 2026-07-06

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- Full EA source exists locally, but this note is the GitHub-safe status/evidence artifact.

## Latest Risk-Code Change

Added optional Weekly Profit Protection Risk Scaling for generated research profiles:

- `InpUseWeeklyProfitRiskScaling`
- `InpWeeklyProfitRiskStartFraction`
- `InpMinWeeklyProfitRiskMultiplier`
- `WeeklyProfitProtectionRiskMultiplier()` uses current-week realized profit and `InpWeeklyProfitLockPercent` to taper risk as the EA approaches the weekly profit lock.
- `OpenSignal()` now multiplies weekly-profit protection risk into final lot sizing and logs `Weekly profit risk x...` when enabled.

This is profit-preservation risk code, not only parameter tweaking. It reduces new-trade exposure after the EA has built weekly profit, helping protect good weeks before a hard profit lock or giveback guard is reached. The baseline anchor remains disabled for clean comparison, while generated research profiles enable it. It adds no martingale, grid, averaging down, or recovery behavior.

## Fast Batch Impact

- Batch size stayed at 10 profiles and 30 runs.
- Estimated tester runtime stayed at about 10.5 minutes before platform overhead.
- Baseline anchor remains `InpUseWeeklyProfitRiskScaling=false`.
- Generated research profiles use `InpUseWeeklyProfitRiskScaling=true`.
- Research profiles start tapering at `0.50` of the weekly profit-lock target and taper toward minimum multiplier `0.50`.

## Quiet Validation Results

- `work\test_price_action_strategy_modules.ps1`: PASS
- `work\sync_ea_source_artifacts.ps1`: PASS, hash `81F8C22FD3509A688FA96DBA0B714EB2D28D9574FCF0052EF6EE3EA36A099B63`
- `work\build_price_action_strategy_batch.ps1`: PASS, 10 profiles, 30 runs, estimated 10.5 minutes
- `work\test_ea_source_artifact_sync.ps1`: PASS
- `work\test_price_action_strategy_batch.ps1`: PASS
- `work\build_external_mt5_validation_package.ps1`: PASS, package configs 20, profiles 9
- `work\test_external_mt5_validation_package.ps1`: PASS, 26 checks, 0 failed
- `work\refresh_offline_validation_state.ps1`: PASS, 39 steps, 0 failed

## Latest Hashes

- `outputs\Professional_XAUUSD_EA.mq5`: `81F8C22FD3509A688FA96DBA0B714EB2D28D9574FCF0052EF6EE3EA36A099B63`
- `Professional_XAUUSD_EA.mq5`: `81F8C22FD3509A688FA96DBA0B714EB2D28D9574FCF0052EF6EE3EA36A099B63`
- `outputs\external_mt5_validation_package\source\Professional_XAUUSD_EA.mq5`: `81F8C22FD3509A688FA96DBA0B714EB2D28D9574FCF0052EF6EE3EA36A099B63`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `9DB371988D9E0D774EF9EDA1FFF0D9CFCCF832272597DF1A7F0613F2DA5AD70B`
- `outputs\PRICE_ACTION_STRATEGY_BATCH.csv`: `903827B590601032A7A70DABEBD76776A74CDD40CD4C103FEB0574FC2D00BED6`
- `outputs\xauusd_micro_validation_package.zip`: `52F1C2EF161502CB0780D1E48194BA54A507FC69D7410645A37DC4951A673C74`
- `work\test_price_action_strategy_modules.ps1`: `842DDBDD5C81364250CD60CC004198D30751F466498F35DEB62EC88BD6AD4C90`
- `work\test_price_action_strategy_batch.ps1`: `CC6C0D604CBBA84A1E4D576A7EB29A444BF3964F1E5AF7DA13E272E0A6BF3E16`
- `work\build_price_action_strategy_batch.ps1`: `3B09A473440B58A3AE5FA970F7FDE76A3FC887CFA27BBCE193691F4259D2B6B2`

## Background-Safety Note

The stop marker remains expected at `work\STOP_MT5_FOCUS_WATCHDOG`. Any future MT5 validation should be treated as external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The status note was committed through the GitHub connector. The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that the status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.
