# Recent 2026 Fast Triage Status

Updated: 2026-07-06

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- Full EA source exists locally, but this note is the GitHub-safe status/evidence artifact.

## Latest Strategy-Code Change

Added persistent initial-risk tracking for open positions. The EA now stores the original stop distance when a position opens and uses that value for R-based trade management instead of recalculating R from a stop that may already have moved.

New/changed logic:

- `PXEA_INITIAL_RISK_` global-variable keys store original position risk distance.
- `InitialRiskDistance()` returns the stored risk distance with a fallback for legacy/open positions.
- `RegisterInitialRiskForNewestPosition()` captures risk immediately after a successful entry.
- Winner scale-in locked-R checks now use stored initial risk.
- Position-manager `ProfitR()` now uses stored initial risk.
- Protected-runner partial stop locks, R profit locks, and MFE profit-lock stops now use stored initial risk.

This is a profit-seeking quality fix: it lets the EA press real winners and manage runners based on true original risk, while avoiding distorted R values after stops move to breakeven/profit. It adds no martingale, grid, averaging down, or recovery behavior.

## Fast Batch Impact

- Batch size stayed at 10 profiles and 30 runs.
- Estimated tester runtime stayed at about 10.5 minutes before platform overhead.
- Existing aggressive profile settings remain unchanged.
- The behavior change applies to all profiles that use R-based partials, profit locks, MFE locks, and winner scale-ins.

## Quiet Validation Results

- `work\test_price_action_strategy_modules.ps1`: PASS
- `work\sync_ea_source_artifacts.ps1`: PASS, hash `1E7B264596B077D820C126E6B86CD368B6B815B274BE91CD4EF9705DC79ABC1B`
- `work\build_price_action_strategy_batch.ps1`: PASS, 10 profiles, 30 runs, estimated 10.5 minutes
- `work\test_price_action_strategy_decision.ps1`: PASS
- `work\test_loss_streak_risk_reduction.ps1`: PASS
- `work\test_ea_source_artifact_sync.ps1`: PASS
- `work\test_price_action_strategy_batch.ps1`: PASS
- `work\build_external_mt5_validation_package.ps1`: PASS, package configs 20, profiles 9
- `work\test_external_mt5_validation_package.ps1`: PASS, 26 checks, 0 failed
- `work\refresh_offline_validation_state.ps1`: PASS, 39 steps, 0 failed

## Latest Hashes

- `outputs\Professional_XAUUSD_EA.mq5`: `1E7B264596B077D820C126E6B86CD368B6B815B274BE91CD4EF9705DC79ABC1B`
- `Professional_XAUUSD_EA.mq5`: `1E7B264596B077D820C126E6B86CD368B6B815B274BE91CD4EF9705DC79ABC1B`
- `outputs\external_mt5_validation_package\source\Professional_XAUUSD_EA.mq5`: `1E7B264596B077D820C126E6B86CD368B6B815B274BE91CD4EF9705DC79ABC1B`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `563810FE314F220B9ADCA65EDD55402D357BAE5EEE056C620F96D130C23EB378`
- `outputs\PRICE_ACTION_STRATEGY_BATCH.csv`: `6887C7B2EE4D4D91A5BB05D817F303AA608F807C276142686247ED0AB5998D99`
- `outputs\xauusd_micro_validation_package.zip`: `A8E63C81D9C0F5EEBC371C7BEE383517F7382878335AB88EB343394AD0D67608`
- `work\test_price_action_strategy_modules.ps1`: `E32F1BD68768FA312657AC6EF922607917E11C49A4D84DCA666A2640D6FCA6F5`
- `work\test_price_action_strategy_batch.ps1`: `D546C9556DD34AC509EDC8706D57B7D5CDD7B9B0AECFB6BD1097B28F962C4874`
- `work\build_price_action_strategy_batch.ps1`: `6D41142D9D74BEC4077168839A31EA209FACF563D17BC6639DB1E2B1C86A11D0`

## Background-Safety Note

The stop marker remains expected at `work\STOP_MT5_FOCUS_WATCHDOG`. Any future MT5 validation should be treated as external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The status note is committed through the GitHub connector. The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that the status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.