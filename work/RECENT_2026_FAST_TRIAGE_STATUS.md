# Recent 2026 Fast Triage Status

Updated: 2026-07-06

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- Full EA source exists locally, but this note is the GitHub-safe status/evidence artifact.

## Latest Strategy-Code Change

Added an R-based partial profit lock. This is a broader profit-preservation control than the existing protected-runner partial close because it can work on normal TP-based trades too.

New inputs and logic:

- `InpUseRPartialProfitLock`
- `InpRPartialProfitLockAtR`
- `InpRPartialProfitLockPercent`
- `InpRPartialProfitLockMoveStop`
- `InpRPartialProfitLockStopR`
- Position management can now close a configurable part of a winning trade at a target R multiple.
- After the partial close, the EA can move the remaining position stop into locked positive R.
- The event logs `R partial profit lock` and `R partial profit lock stop`.

This supports the goal by banking part of winners and protecting the remaining runner without increasing initial risk. Generated research profiles use a modest 35% partial at +1R and a +0.10R stop lock. It adds no martingale, grid, averaging down, or recovery behavior.

## Fast Batch Impact

- Batch size stayed at 10 profiles and 30 runs.
- Estimated tester runtime stayed at about 10.5 minutes before platform overhead.
- Baseline anchor keeps R partial profit lock disabled.
- Generated research profiles use:
  - `InpUseRPartialProfitLock=true`
  - `InpRPartialProfitLockAtR=1.00`
  - `InpRPartialProfitLockPercent=35.0`
  - `InpRPartialProfitLockMoveStop=true`
  - `InpRPartialProfitLockStopR=0.10`

## Quiet Validation Results

- `work\test_price_action_strategy_modules.ps1`: PASS
- `work\sync_ea_source_artifacts.ps1`: PASS, hash `44BC42E93855926670FDC0BDA51759BCDD2452A1C863D322FCBE0F47CB404863`
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

## Latest Evidence

- `outputs\Professional_XAUUSD_EA.mq5`: `44BC42E93855926670FDC0BDA51759BCDD2452A1C863D322FCBE0F47CB404863`
- `Professional_XAUUSD_EA.mq5`: `44BC42E93855926670FDC0BDA51759BCDD2452A1C863D322FCBE0F47CB404863`
- `outputs\external_mt5_validation_package\source\Professional_XAUUSD_EA.mq5`: `44BC42E93855926670FDC0BDA51759BCDD2452A1C863D322FCBE0F47CB404863`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `BCF77D3EAF53472B98BA8134D4EE5B97E4FCF2A3E21FD59A72BC9EDCD891B9E3`, 34,854 bytes
- `outputs\xauusd_micro_validation_package.zip`: `0A762280337A78AF8FF55FFC37A969D88CDE5A15E3CA88B5E4A036D397981C20`
- `work\build_price_action_strategy_batch.ps1`: `68162EBD79DB8E16A1FC25EB6E249F276D7E28F6BAED2EC2A796E3D493172729`
- `work\test_price_action_strategy_modules.ps1`: `79FA4D169D68BECE9ED949572769272604B840281912550186D17D1F50449FB7`
- `outputs\OFFLINE_VALIDATION_REFRESH.csv`: `613B4C8C8643A38C37B268F0398D782721177ABC922547EAC8C90DE8A5A1EC61`

## Background-Safety Note

The stop marker remains present at `work\STOP_MT5_FOCUS_WATCHDOG`. Any future MT5 validation should be treated as external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The status note is committed through the GitHub connector. The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that the status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.