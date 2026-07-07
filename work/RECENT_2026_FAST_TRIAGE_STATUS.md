# Recent 2026 Fast Triage Status

Updated: 2026-07-07 15:39:34 -05:00

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- Full EA source exists locally, but this note is the GitHub-safe status/evidence artifact.

## Latest Strategy-Code Change

Added a house-money acceleration gate. This optional health check lets the EA pursue larger upside through existing growth modules only after closed profit and protected-floor cushion are present, while blocking acceleration during realized-profit or equity-peak giveback.

New inputs and logic:

- `InpUseHouseMoneyAccelerationGate`
- `InpHouseMoneyMinClosedProfitPercent`
- `InpHouseMoneyMinProtectedCushionPercent`
- `InpHouseMoneyMaxRealizedGivebackPercent`
- `InpHouseMoneyMaxEquityPeakGivebackPercent`
- `InpHouseMoneyRequireEquityAboveStarting`
- `HouseMoneyAccelerationAllowed()` gates profit-only risk boosts, hot-streak/recent-PF growth boosts, daily/closed-profit opportunity boosts, trend-regime risk boosts, TP expansion, and protected unlimited runners.

This supports the goal by allowing bigger upside only when the EA is trading with a protected profit cushion. It does not add martingale, grid, averaging down, or recovery behavior.

## Fast Batch Impact

- Batch size stayed at 10 profiles and 30 runs.
- Estimated tester runtime stayed at about 10.5 minutes before platform overhead.
- Baseline anchor keeps the house-money acceleration gate disabled.
- Generated research profiles use:
  - `InpUseHouseMoneyAccelerationGate=true`
  - `InpHouseMoneyMinClosedProfitPercent=1.00`
  - `InpHouseMoneyMinProtectedCushionPercent=3.00`
  - `InpHouseMoneyMaxRealizedGivebackPercent=25.0`
  - `InpHouseMoneyMaxEquityPeakGivebackPercent=25.0`
  - `InpHouseMoneyRequireEquityAboveStarting=true`

## Quiet Validation Results

- `work\test_price_action_strategy_modules.ps1`: PASS
- `work\sync_ea_source_artifacts.ps1`: PASS, hash `B425DAB00D7E11AD652D3559E666ABD6555072F017F4BD055A3EFFBEA21901F2`
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

- `outputs\Professional_XAUUSD_EA.mq5`: `B425DAB00D7E11AD652D3559E666ABD6555072F017F4BD055A3EFFBEA21901F2`
- `Professional_XAUUSD_EA.mq5`: `B425DAB00D7E11AD652D3559E666ABD6555072F017F4BD055A3EFFBEA21901F2`
- `outputs\external_mt5_validation_package\source\Professional_XAUUSD_EA.mq5`: `B425DAB00D7E11AD652D3559E666ABD6555072F017F4BD055A3EFFBEA21901F2`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `6036D2A31401D3725BF1351BF6F96E591ED37D531CEC03DE7DD99805D2A76894`
- `outputs\xauusd_micro_validation_package.zip`: `9D075DC428CA913AEB71C92BE8E82C5F25C242B33CA3C124CCA044EAB5CEB949`
- `work\build_price_action_strategy_batch.ps1`: `2A8DE9DC240C6F2F969A23CFE20CF4667D9483BB24BC0106FF2B53362AB0E9C8`
- `work\test_price_action_strategy_modules.ps1`: `F23449AF1AE4B10BE95C008FF15B0DE83451059CA7910A4F469F78F4FDCCAF06`
- `work\test_price_action_strategy_batch.ps1`: `8ABE6DB50C238750B961C2BB7932EC7803A18A30449061CD100E5C36B2129EDD`
- `outputs\OFFLINE_VALIDATION_REFRESH.csv`: `636A811F2DACE3F9BB3B71625BBC839E5B2A5730C96443CBE4A7A3328D08E548`

## Background-Safety Note

The stop marker remains present at `work\STOP_MT5_FOCUS_WATCHDOG`. Any future MT5 validation should be treated as external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The status note is committed through the GitHub connector. The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that the status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.
