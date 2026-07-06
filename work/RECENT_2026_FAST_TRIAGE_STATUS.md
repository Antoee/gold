# Recent 2026 Fast Triage Status

Updated: 2026-07-06

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- Full EA source exists locally, but this note is the GitHub-safe status/evidence artifact.

## Latest Risk-Code Change

Activated and validated Open Exposure Risk Control for generated research profiles:

- `InpMaxOpenRiskPercent`
- `InpBlockUnprotectedExposure`
- `OpenRiskPercent()` calculates total stop-loss risk across current EA positions.
- `ExposureAllows()` blocks new entries when existing open risk plus the candidate trade exceeds the configured cap.
- Unprotected positions with no valid stop loss are blocked when `InpBlockUnprotectedExposure=true`.
- Dashboard now displays `Open Risk` and whether an unprotected position exists.

This is risk-management strategy wiring, not only parameter tweaking. The baseline anchor remains `InpMaxOpenRiskPercent=0.00` for clean comparison, while generated research profiles use `InpMaxOpenRiskPercent=2.00` with unprotected exposure blocking enabled. It adds no martingale, grid, averaging down, or recovery behavior.

## Fast Batch Impact

- Batch size stayed at 10 profiles and 30 runs.
- Estimated tester runtime stayed at about 10.5 minutes before platform overhead.
- Baseline anchor remains `InpMaxOpenRiskPercent=0.00` for clean comparison.
- Generated research profiles use `InpMaxOpenRiskPercent=2.00`.
- Generated research profiles keep `InpBlockUnprotectedExposure=true`.

## Quiet Validation Results

- `work\test_price_action_strategy_modules.ps1`: PASS
- `work\sync_ea_source_artifacts.ps1`: PASS, hash `99B2F2725E76D633F2E86C0A232B19AA0F9FE1CD2C5A329CE6C15DF1557985FC`
- `work\build_price_action_strategy_batch.ps1`: PASS, 10 profiles, 30 runs, estimated 10.5 minutes
- `work\test_ea_source_artifact_sync.ps1`: PASS
- `work\test_price_action_strategy_batch.ps1`: PASS
- `work\build_external_mt5_validation_package.ps1`: PASS, package configs 20, profiles 9
- `work\test_external_mt5_validation_package.ps1`: PASS, 26 checks, 0 failed
- `work\refresh_offline_validation_state.ps1`: PASS, 39 steps, 0 failed

## Latest Hashes

- `outputs\Professional_XAUUSD_EA.mq5`: `99B2F2725E76D633F2E86C0A232B19AA0F9FE1CD2C5A329CE6C15DF1557985FC`
- `Professional_XAUUSD_EA.mq5`: `99B2F2725E76D633F2E86C0A232B19AA0F9FE1CD2C5A329CE6C15DF1557985FC`
- `outputs\external_mt5_validation_package\source\Professional_XAUUSD_EA.mq5`: `99B2F2725E76D633F2E86C0A232B19AA0F9FE1CD2C5A329CE6C15DF1557985FC`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `D54334BE90867F16519480DAEA027B73F3E026B9405CC20F7FD2E8E04FB685BB`
- `outputs\PRICE_ACTION_STRATEGY_BATCH.csv`: `903827B590601032A7A70DABEBD76776A74CDD40CD4C103FEB0574FC2D00BED6`
- `outputs\xauusd_micro_validation_package.zip`: `453695DB221BF59FA11C49A1CA215D6B87333264FC16E7A2B5C1D94343AD09AD`
- `work\test_price_action_strategy_modules.ps1`: `5A374534C737C654A45CDA59546B12CB509600C56A1BB27D4FDF3F21887CB5B7`
- `work\test_price_action_strategy_batch.ps1`: `18D063B508907974A67DD788F180EE02FE7CCA23980F981F6B50720B59D90C7C`
- `work\build_price_action_strategy_batch.ps1`: `E9C1F5F536302D4BD94D351EB29F63EA7C9AA4846ACB324EFE3DCBB0B587F396`

## Background-Safety Note

The stop marker remains expected at `work\STOP_MT5_FOCUS_WATCHDOG`. Any future MT5 validation should be treated as external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The status note was committed through the GitHub connector. The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that the status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.
