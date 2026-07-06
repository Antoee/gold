# Recent 2026 Fast Triage Status

Updated: 2026-07-06

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- Full EA source exists locally, but this note is the GitHub-safe status/evidence artifact.

## Latest Strategy-Code Change

Added optional winner-only scale-in behavior for aggressive growth without martingale, grid, or averaging down:

- `InpUseWinnerScaleIn`
- `InpWinnerScaleInMinProfitR`
- `InpWinnerScaleInRequireProtectedStop`
- `InpWinnerScaleInMinQualityScore`
- `InpWinnerScaleInRiskMultiplier`
- `InpWinnerScaleInMinMinutesSincePosition`
- `CountPositionsByBias()` counts existing same-direction exposure.
- `WinnerScaleInAllows()` permits add-on entries only when existing exposure is same-direction, already profitable, meets the minimum R threshold, passes the quality threshold, satisfies spacing, and has a protected stop when required.
- Add-on entries use a reduced risk multiplier and are logged with `Winner scale-in risk x...`.

The existing aggressive risk framework remains in place:

- `StartingEquityFloor()` can halt/close risk when equity reaches the configured starting-equity floor.
- `EquityProfitLockFloor()` locks a configurable percentage of peak account profit after the profit threshold is reached.
- `ProtectedEquityFloor()` combines the starting-equity floor and dynamic profit-lock floor.
- `LotsForRisk()` caps new trade risk so theoretical stop risk does not exceed the protected equity floor.
- `EffectiveRiskPercent()` can increase risk only after account equity is already above the configured profit threshold.

The generated aggressive research profiles now use 2.50% base risk, max 2 simultaneous positions, 6 max trades per day, 15-minute minimum trade spacing, winner scale-in enabled at 0.80R minimum open profit, protected stop required, quality score >= 10, 0.50 scale-in risk multiplier, 30-minute minimum since the newest same-direction position, starting-equity protection enabled at a 0.00% buffer, profit-only risk boost after +1.00% equity growth, full boost at +12.00%, max boost multiplier 3.00, equity profit lock after +2.00% peak equity growth, 50.0% peak-profit lock, 6.00% max equity drawdown, and 8.00% max open-risk cap. The baseline profile remains anchored at 1.60% risk, 1 max position, 4 trades/day, 30-minute spacing, and winner scale-in disabled.

This is intentionally more aggressive than the earlier conservative settings, but it still avoids martingale, grid, averaging down, and recovery mechanics. It is not proven profitable until a real MT5 backtest/forward-test report exists.

## Fast Batch Impact

- Batch size stayed at 10 profiles and 30 runs.
- Estimated tester runtime stayed at about 10.5 minutes before platform overhead.
- Baseline anchor remains `InpUseWinnerScaleIn=false`, `InpUseStartingEquityProtection=false`, `InpUseProfitOnlyRiskBoost=false`, and `InpUseEquityProfitLock=false`.
- Generated research profiles use `InpUseWinnerScaleIn=true`, `InpUseStartingEquityProtection=true`, `InpUseProfitOnlyRiskBoost=true`, and `InpUseEquityProfitLock=true`.
- Generated research profiles are now designed to push upside harder by pressing only protected winners while keeping account-level risk floors active.

## Quiet Validation Results

- `work\test_price_action_strategy_modules.ps1`: PASS
- `work\sync_ea_source_artifacts.ps1`: PASS, hash `CFB1EFE26E616E257B5F45EC7B8554825C5F22FF48730772E41A1EC73C26A135`
- `work\build_price_action_strategy_batch.ps1`: PASS, 10 profiles, 30 runs, estimated 10.5 minutes
- `work\test_ea_source_artifact_sync.ps1`: PASS
- `work\test_price_action_strategy_batch.ps1`: PASS
- `work\build_external_mt5_validation_package.ps1`: PASS
- `work\test_external_mt5_validation_package.ps1`: PASS, 26 checks, 0 failed
- `work\test_price_action_strategy_decision.ps1`: PASS
- `work\test_loss_streak_risk_reduction.ps1`: PASS
- `work\refresh_offline_validation_state.ps1`: PASS in output and artifact, 39 steps, 0 failed. The wrapper timed out after result emission, so the CSV artifact was verified directly.

## Latest Hashes

- `outputs\Professional_XAUUSD_EA.mq5`: `CFB1EFE26E616E257B5F45EC7B8554825C5F22FF48730772E41A1EC73C26A135`
- `Professional_XAUUSD_EA.mq5`: `CFB1EFE26E616E257B5F45EC7B8554825C5F22FF48730772E41A1EC73C26A135`
- `outputs\external_mt5_validation_package\source\Professional_XAUUSD_EA.mq5`: `CFB1EFE26E616E257B5F45EC7B8554825C5F22FF48730772E41A1EC73C26A135`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `EA399ED1CE2184DC4E79D92AFF82A145E1637FAE290765ECCDA49799F6CE3A54`
- `outputs\PRICE_ACTION_STRATEGY_BATCH.csv`: `7929ABFB54EB6550CF83CD2234D89177775CD96E86A4AD2CA0224BFA812995E9`
- `outputs\xauusd_micro_validation_package.zip`: `E306AD4FA5B279D590632678BA832766B9724F43A8E7389C83A6FAF79FD36CBB`
- `work\test_price_action_strategy_modules.ps1`: `4C33431ED0CDE079930FD927708BC0B5D772A7F13F54957062DED0C07DEBABAB`
- `work\test_price_action_strategy_batch.ps1`: `F404A038F485C85114361F607CD3534BD56E32BB866DE949B78AC59863129DE1`
- `work\build_price_action_strategy_batch.ps1`: `772459B87921968AFB5692D6976FB6ABE31E1C099C2EEF4450A7C6AD2D8A0D4E`

## Background-Safety Note

The stop marker remains expected at `work\STOP_MT5_FOCUS_WATCHDOG`. Any future MT5 validation should be treated as external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The status note was committed through the GitHub connector. The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that the status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.
