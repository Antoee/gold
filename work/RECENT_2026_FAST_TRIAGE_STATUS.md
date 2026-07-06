# Recent 2026 Fast Triage Status

Updated: 2026-07-06

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- Full EA source exists locally, but this note is the GitHub-safe status/evidence artifact.

## Latest Risk-Code Change

Added optional Monthly Loss Pressure Risk Scaling:

- `InpUseMonthlyLossRiskScaling`
- `InpMonthlyLossRiskStartFraction`
- `InpMinMonthlyLossRiskMultiplier`
- `MonthlyLossPressureRiskMultiplier()` uses current-month realized P/L and `InpMaxMonthlyLossPercent` to taper risk before the hard monthly loss limit is reached.
- `OpenSignal()` now multiplies monthly-loss pressure risk into final lot sizing and logs `Monthly loss risk x...` when enabled.

This is strategy/risk code, not only setting changes. It extends the daily and weekly loss-pressure idea to the monthly risk budget, reducing exposure as a bad month develops instead of waiting for the monthly hard stop. The baseline anchor remains pinned disabled for comparison, while generated research profiles enable it. It adds no martingale, grid, averaging down, or recovery behavior.

## Fast Batch Impact

- Batch size stayed at 10 profiles and 30 runs.
- Estimated tester runtime stayed at about 10.5 minutes before platform overhead.
- Baseline anchor remains `InpUseMonthlyLossRiskScaling=false` for clean comparison.
- Generated research profiles enable `InpUseMonthlyLossRiskScaling=true`.
- Research profiles use start fraction `0.35` and minimum multiplier `0.50`, so risk starts tapering after 35% of the monthly loss budget is used.

## Quiet Validation Results

- `work\test_price_action_strategy_modules.ps1`: PASS
- `work\sync_ea_source_artifacts.ps1`: PASS, hash `67FE21DA53BA76BF81CFBBEF08CACCB0BC86F2A29D836B84D5286A309DCF5000`
- `work\build_price_action_strategy_batch.ps1`: PASS, 10 profiles, 30 runs, estimated 10.5 minutes
- `work\test_ea_source_artifact_sync.ps1`: PASS
- `work\test_price_action_strategy_batch.ps1`: PASS
- `work\build_external_mt5_validation_package.ps1`: PASS, package configs 20, profiles 9
- `work\test_external_mt5_validation_package.ps1`: PASS, 26 checks, 0 failed
- `work\refresh_offline_validation_state.ps1`: PASS, 39 steps, 0 failed

## Latest Hashes

- `outputs\Professional_XAUUSD_EA.mq5`: `67FE21DA53BA76BF81CFBBEF08CACCB0BC86F2A29D836B84D5286A309DCF5000`
- `Professional_XAUUSD_EA.mq5`: `67FE21DA53BA76BF81CFBBEF08CACCB0BC86F2A29D836B84D5286A309DCF5000`
- `outputs\external_mt5_validation_package\source\Professional_XAUUSD_EA.mq5`: `67FE21DA53BA76BF81CFBBEF08CACCB0BC86F2A29D836B84D5286A309DCF5000`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `A706C360A300657213C54EE7C2A1752C308C5D2559854CAB501F0B5D4D6A3881`
- `outputs\PRICE_ACTION_STRATEGY_BATCH.csv`: `903827B590601032A7A70DABEBD76776A74CDD40CD4C103FEB0574FC2D00BED6`
- `outputs\xauusd_micro_validation_package.zip`: `5ABEAD7B64D330AEE77A6BD1E32F9B6249F571824C3F9635B93BBEF69AF9FDB5`
- `work\test_price_action_strategy_modules.ps1`: `A47FA50955BEA0A9B3522391B337C88F5502863E5D0E5E5F72837B3E742775AE`
- `work\test_price_action_strategy_batch.ps1`: `DD9829AF058071D814423A40A605C6EFC2AD8149E16BF798DC6556538113037D`
- `work\build_price_action_strategy_batch.ps1`: `A474EC6CBC2976AE76C09B23C64FF108479948F8E1627E84A51A07CDA6C38894`

## Background-Safety Note

The stop marker remains expected at `work\STOP_MT5_FOCUS_WATCHDOG`. Any future MT5 validation should be treated as external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The status note was committed through the GitHub connector. The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that the status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.
