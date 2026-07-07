# Recent 2026 Fast Triage Status

Updated: 2026-07-07 16:54:52 -05:00

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- Full EA source exists locally, but this note is the GitHub-safe status/evidence artifact.

## Latest Strategy-Code Change

Added a house-money open-risk cap expansion. This optional exposure feature keeps the normal open-risk cap intact, then progressively expands it only when the house-money gate and protected-cushion thresholds are satisfied.

New inputs and logic:

- `InpUseHouseMoneyOpenRiskExpansion`
- `InpHouseMoneyOpenRiskStartCushionPercent`
- `InpHouseMoneyOpenRiskFullCushionPercent`
- `InpHouseMoneyMaxOpenRiskPercent`
- `EffectiveMaxOpenRiskPercent(...)`
- `ExposureAllows(...)` now checks the effective cap instead of only the static `InpMaxOpenRiskPercent`.

This supports the goal by allowing the generated research profiles to press harder only after the account has earned a protected profit cushion. The baseline remains unchanged, and this does not add martingale, grid, averaging down, or recovery behavior.

## Fast Batch Impact

- Batch size stayed at 10 profiles and 30 runs.
- Estimated tester runtime stayed at about 10.5 minutes before platform overhead.
- Baseline anchor remains conservative and keeps the new expansion disabled.
- Generated research profiles now use:
  - `InpMaxOpenRiskPercent=8.00`
  - `InpUseHouseMoneyOpenRiskExpansion=true`
  - `InpHouseMoneyOpenRiskStartCushionPercent=6.0`
  - `InpHouseMoneyOpenRiskFullCushionPercent=18.0`
  - `InpHouseMoneyMaxOpenRiskPercent=12.00`

## Quiet Validation Results

- `work\test_price_action_strategy_modules.ps1`: PASS
- `work\sync_ea_source_artifacts.ps1`: PASS, hash `7E491232A6AEA3EC0D0B441D56FAABE363A3F268E4B1B0101738D116CCA0DC97`
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

- `outputs\Professional_XAUUSD_EA.mq5`: `7E491232A6AEA3EC0D0B441D56FAABE363A3F268E4B1B0101738D116CCA0DC97`
- `Professional_XAUUSD_EA.mq5`: `7E491232A6AEA3EC0D0B441D56FAABE363A3F268E4B1B0101738D116CCA0DC97`
- `outputs\external_mt5_validation_package\source\Professional_XAUUSD_EA.mq5`: `7E491232A6AEA3EC0D0B441D56FAABE363A3F268E4B1B0101738D116CCA0DC97`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `6AAC260566613E6AFCF18DE470CC5493BE9F57A8CC8F08B1601EB6798BD35AA1`
- `outputs\xauusd_micro_validation_package.zip`: `866568BF98B87676C4F369FEDEAF2CEC8D45EFF8AAC05D4EA1D56753A626E8F3`
- `work\build_price_action_strategy_batch.ps1`: `FB70FE1A08F55805BB399049B9E23B8E5F3AD9FCFEEE31BB37671A71A84551A5`
- `work\test_price_action_strategy_modules.ps1`: `652E31886F813DCA8E6B1E3B40DAABA18C29FFE02D03DE924C6B3A2DF21B2BAE`
- `work\test_price_action_strategy_batch.ps1`: `BFB4DB5F817F45A411ED9EB8749FEADEFCB53001452EFF8D9D931D90F8E5111F`
- `outputs\OFFLINE_VALIDATION_REFRESH.csv`: `5575719EF605755EF6BB149AD81F7040BD103634B9DEE4FEBA226ECA702683AF`

## Background-Safety Note

The stop marker remains present at `work\STOP_MT5_FOCUS_WATCHDOG`. Any future MT5 validation should be treated as external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The status note is committed through the GitHub connector. The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that the status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.
