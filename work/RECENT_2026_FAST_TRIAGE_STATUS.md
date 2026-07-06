# Recent 2026 Fast Triage Status

Updated: 2026-07-06

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- Full EA source exists locally, but this note is the GitHub-safe status/evidence artifact.

## Latest Strategy-Code Change

Added a realized-balance profit-lock floor. This lets the protected-floor system lock part of closed profit, not only floating peak-equity gains.

New inputs and logic:

- `InpUseBalanceProfitLock`
- `InpBalanceProfitLockStartPercent`
- `InpBalanceProfitLockPercent`
- `BalanceProfitLockFloor()`
- `ProtectedEquityFloor()` now uses the maximum of starting-equity floor, equity peak-profit lock, and realized-balance profit lock.

Generated aggressive research profiles enable this at the same 2.00% start and 50.0% lock settings as the equity profit lock. That means once realized balance profit is large enough, the EA can protect part of it through the same lot-sizing/protected-floor controls already used by the rest of the risk manager. Baseline keeps it disabled for clean comparison. This adds no martingale, grid, averaging down, or recovery behavior.

## Fast Batch Impact

- Batch size stayed at 10 profiles and 30 runs.
- Estimated tester runtime stayed at about 10.5 minutes before platform overhead.
- Baseline anchor keeps `InpUseBalanceProfitLock=false`.
- Generated research profiles use `InpUseBalanceProfitLock=true`.

## Quiet Validation Results

- `work\test_price_action_strategy_modules.ps1`: PASS
- `work\sync_ea_source_artifacts.ps1`: PASS, hash `9E2787D78F48C736EB292880180B2DE626F674CE23F9E732509B6DF1F8B4BE0D`
- `work\build_price_action_strategy_batch.ps1`: PASS, 10 profiles, 30 runs, estimated 10.5 minutes
- `work\test_ea_source_artifact_sync.ps1`: PASS
- `work\test_price_action_strategy_batch.ps1`: PASS
- `work\build_external_mt5_validation_package.ps1`: PASS, package configs 20, profiles 9
- `work\test_external_mt5_validation_package.ps1`: PASS, 26 checks, 0 failed
- `work\test_price_action_strategy_decision.ps1`: PASS
- `work\test_loss_streak_risk_reduction.ps1`: PASS
- `work\refresh_offline_validation_state.ps1`: PASS, 39 steps, 0 failed

## Latest Hashes

- `outputs\Professional_XAUUSD_EA.mq5`: `9E2787D78F48C736EB292880180B2DE626F674CE23F9E732509B6DF1F8B4BE0D`
- `Professional_XAUUSD_EA.mq5`: `9E2787D78F48C736EB292880180B2DE626F674CE23F9E732509B6DF1F8B4BE0D`
- `outputs\external_mt5_validation_package\source\Professional_XAUUSD_EA.mq5`: `9E2787D78F48C736EB292880180B2DE626F674CE23F9E732509B6DF1F8B4BE0D`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `ED3D5DD2A7DFD0C9EF19DACE15A718E6AE3AD029083DDE1FDCA0F32AAD4F9FC3`
- `outputs\PRICE_ACTION_STRATEGY_BATCH.csv`: `6887C7B2EE4D4D91A5BB05D817F303AA608F807C276142686247ED0AB5998D99`
- `outputs\xauusd_micro_validation_package.zip`: `5AD0C2AAE5C275D24208C9C32D47EFCED6A9C91DCD7E2563E177E4DF58235E09`
- `work\test_price_action_strategy_modules.ps1`: `A2B9CA1D80F75672360151E085690EF63F0604E6819E123DB0F540D7B7D73DC1`
- `work\test_price_action_strategy_batch.ps1`: `D546C9556DD34AC509EDC8706D57B7D5CDD7B9B0AECFB6BD1097B28F962C4874`
- `work\build_price_action_strategy_batch.ps1`: `3914FEAB2C42102D9AD0FED5FA7AC8179ED2B0ED2095E56D0A39D6B61D0D285C`

## Background-Safety Note

The stop marker remains expected at `work\STOP_MT5_FOCUS_WATCHDOG`. Any future MT5 validation should be treated as external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The status note was committed through the GitHub connector. The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that the status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.