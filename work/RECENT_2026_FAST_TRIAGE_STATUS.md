# Recent 2026 Fast Triage Status

Updated: 2026-07-06

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- Full EA source exists locally, but this note is the GitHub-safe status/evidence artifact.

## Latest Risk-Code Change

Added optional Weekly Loss Pressure Risk Scaling:

- `InpUseWeeklyLossRiskScaling`
- `InpWeeklyLossRiskStartFraction`
- `InpMinWeeklyLossRiskMultiplier`
- `WeeklyLossPressureRiskMultiplier()` uses current-week realized P/L and `InpMaxWeeklyLossPercent` to taper risk before the hard weekly loss limit is reached.
- `OpenSignal()` now multiplies weekly-loss pressure risk into final lot sizing and logs `Weekly loss risk x...` when enabled.

This is strategy/risk code, not only setting changes. It extends the daily loss-pressure idea to the weekly risk budget, reducing exposure as a bad week develops instead of waiting for the weekly hard stop. The baseline anchor remains pinned disabled for comparison, while generated research profiles enable it. It adds no martingale, grid, averaging down, or recovery behavior.

## Fast Batch Impact

- Batch size stayed at 10 profiles and 30 runs.
- Estimated tester runtime stayed at about 10.5 minutes before platform overhead.
- Baseline anchor remains `InpUseWeeklyLossRiskScaling=false` for clean comparison.
- Generated research profiles enable `InpUseWeeklyLossRiskScaling=true`.
- Research profiles use start fraction `0.35` and minimum multiplier `0.50`, so risk starts tapering after 35% of the weekly loss budget is used.

## Quiet Validation Results

- `work\test_price_action_strategy_modules.ps1`: PASS
- `work\sync_ea_source_artifacts.ps1`: PASS, hash `86ADC5C6D6EAD590BC360CFA5AFB7A983D9B9597385A17FC69E163FF5F124F00`
- `work\build_price_action_strategy_batch.ps1`: PASS, 10 profiles, 30 runs, estimated 10.5 minutes
- `work\test_ea_source_artifact_sync.ps1`: PASS
- `work\test_price_action_strategy_batch.ps1`: PASS
- `work\build_external_mt5_validation_package.ps1`: PASS, package configs 20, profiles 9
- `work\test_external_mt5_validation_package.ps1`: PASS, 26 checks, 0 failed
- `work\refresh_offline_validation_state.ps1`: PASS, 39 steps, 0 failed

## Latest Hashes

- `outputs\Professional_XAUUSD_EA.mq5`: `86ADC5C6D6EAD590BC360CFA5AFB7A983D9B9597385A17FC69E163FF5F124F00`
- `Professional_XAUUSD_EA.mq5`: `86ADC5C6D6EAD590BC360CFA5AFB7A983D9B9597385A17FC69E163FF5F124F00`
- `outputs\external_mt5_validation_package\source\Professional_XAUUSD_EA.mq5`: `86ADC5C6D6EAD590BC360CFA5AFB7A983D9B9597385A17FC69E163FF5F124F00`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `E864D142A8AF9BD70D028425E957C261C8668C24311EFCE8A56E3F6938D86177`
- `outputs\PRICE_ACTION_STRATEGY_BATCH.csv`: `903827B590601032A7A70DABEBD76776A74CDD40CD4C103FEB0574FC2D00BED6`
- `outputs\xauusd_micro_validation_package.zip`: `9EE6B1F325FB52759CBA162B54760FB66281444B423D57A44CE802BF5B491CDE`
- `work\test_price_action_strategy_modules.ps1`: `30403A3B72C8A3262C88AE014455BE60C6294ABB663B4A69693B85B98D534298`
- `work\test_price_action_strategy_batch.ps1`: `DCB84BCF9753F4A5AE7FD7E3178A870D4E7271D4524411F3F8A8963737DC07DB`
- `work\build_price_action_strategy_batch.ps1`: `55A899F233161A0E48784FA384179A8982FFE341DF890D709B1E3FDC068E7868`

## Background-Safety Note

The stop marker remains expected at `work\STOP_MT5_FOCUS_WATCHDOG`. Any future MT5 validation should be treated as external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The status note was committed through the GitHub connector. The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that the status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.
