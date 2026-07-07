# Recent 2026 Fast Triage Status

Updated: 2026-07-07 15:53:51 -05:00

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- Full EA source exists locally, but this note is the GitHub-safe status/evidence artifact.

## Latest Strategy-Code Change

Added a house-money winner scale-in risk ramp. This optional add-on sizing layer keeps normal winner scale-ins conservative, but can increase scale-in risk only after the house-money gate passes and the account has built a protected-floor cushion.

New inputs and logic:

- `InpUseHouseMoneyScaleInRiskRamp`
- `InpHouseMoneyScaleInRiskStartCushionPercent`
- `InpHouseMoneyScaleInRiskFullCushionPercent`
- `InpMaxHouseMoneyScaleInRiskMultiplier`
- `WinnerScaleInRiskMultiplier()` ramps add-on risk from `InpWinnerScaleInRiskMultiplier` toward the configured cap only when `HouseMoneyAccelerationAllowed()` is true.
- Entry logging now records the actual ramped winner scale-in risk multiplier.

This supports the goal by letting the EA press already-protected winners harder without raising first-entry risk. It does not add martingale, grid, averaging down, or recovery behavior.

## Fast Batch Impact

- Batch size stayed at 10 profiles and 30 runs.
- Estimated tester runtime stayed at about 10.5 minutes before platform overhead.
- Baseline anchor keeps the house-money scale-in risk ramp disabled.
- Generated research profiles use:
  - `InpUseHouseMoneyScaleInRiskRamp=true`
  - `InpHouseMoneyScaleInRiskStartCushionPercent=6.0`
  - `InpHouseMoneyScaleInRiskFullCushionPercent=18.0`
  - `InpMaxHouseMoneyScaleInRiskMultiplier=0.85`

## Quiet Validation Results

- `work\test_price_action_strategy_modules.ps1`: PASS
- `work\sync_ea_source_artifacts.ps1`: PASS, hash `0D0538718FE15C55F35A6920E924A4F36C17AC5EB2781C64A16BE58A7BBE8B2E`
- `work\build_price_action_strategy_batch.ps1`: PASS, 10 profiles, 30 runs, estimated 10.5 minutes
- `work\test_open_risk_exposure_guard.ps1`: PASS
- `work\test_price_action_strategy_decision.ps1`: PASS
- `work\test_loss_streak_risk_reduction.ps1`: PASS
- `work\test_ea_source_artifact_sync.ps1`: PASS
- `work\test_price_action_strategy_batch.ps1`: PASS
- `work\build_external_mt5_validation_package.ps1`: PASS, package configs 20, profiles 9
- `work\test_external_mt5_validation_package.ps1`: PASS, 26 checks, 0 failed
- `work\refresh_offline_validation_state.ps1`: PASS, 40 steps, 0 failed
- MT5-family process scan: empty
- Stop marker: present at `work\STOP_MT5_FOCUS_WATCHDOG`

## Latest Evidence

- `outputs\Professional_XAUUSD_EA.mq5`: `0D0538718FE15C55F35A6920E924A4F36C17AC5EB2781C64A16BE58A7BBE8B2E`
- `Professional_XAUUSD_EA.mq5`: `0D0538718FE15C55F35A6920E924A4F36C17AC5EB2781C64A16BE58A7BBE8B2E`
- `outputs\external_mt5_validation_package\source\Professional_XAUUSD_EA.mq5`: `0D0538718FE15C55F35A6920E924A4F36C17AC5EB2781C64A16BE58A7BBE8B2E`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `4F42ACB6244BB1E82F218E78AF8281B9D4D753D5E4329DDC0A0D2C8AD4C79587`
- `outputs\xauusd_micro_validation_package.zip`: `7661B0CE45948912E066C2C6AE40D107323EC9135A067E316214C62AB6BFC9F4`
- `work\build_price_action_strategy_batch.ps1`: `CF98AA3A8723D9CB98DE63A6A20325775CA0252366CC8B94A849A376E20F9F4C`
- `work\test_price_action_strategy_modules.ps1`: `160903B0C314B0C8FA0CA101920FE5B47B874BB3FD1FD175EAB1435CE0980CEE`
- `work\test_price_action_strategy_batch.ps1`: `791FC6BBE0AF89EC24475190501861C89B0B6D3DC8EE3EAB9FDBF15E81DD3C31`
- `outputs\OFFLINE_VALIDATION_REFRESH.csv`: `620EC2D50FAE93DC1FE3F515FFFD4B0156795F7D99DD8A748FDA8AD3FB8CB49D`

## Background-Safety Note

The stop marker remains present at `work\STOP_MT5_FOCUS_WATCHDOG`. Any future MT5 validation should be treated as external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The status note is committed through the GitHub connector. The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that the status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.
