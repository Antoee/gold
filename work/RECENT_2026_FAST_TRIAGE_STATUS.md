# Recent 2026 Fast Triage Status

Updated: 2026-07-06

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- Full EA source exists locally, but this note is the GitHub-safe status/evidence artifact.

## Latest Strategy-Code Change

Added open basket partial harvest. When the full basket is in profit by a configurable percent of balance, the EA can bank part of each profitable open position once and optionally lock the remaining stop into positive R.

New inputs and logic:

- `InpUseOpenBasketPartialHarvest`
- `InpOpenBasketHarvestMinProfitPercent`
- `InpOpenBasketHarvestClosePercent`
- `InpOpenBasketHarvestMinPositions`
- `InpOpenBasketHarvestMoveStop`
- `InpOpenBasketHarvestStopLockR`
- `OpenBasketPartialHarvest()` harvests profitable open positions only.
- The harvest uses a separate `PXEA_BASKET_HARVEST_` marker so it does not collide with per-trade partial-close logic.
- The event logs `open basket partial harvest` and `open basket harvest stop lock`.

This supports the goal by banking a portion of a winning basket before a reversal can erase it, while leaving runners alive for additional upside. Generated research profiles harvest 25% of profitable positions when basket profit reaches 0.75% of balance, then lock the remaining stop at +0.10R when possible. It adds no martingale, grid, averaging down, or recovery behavior.

## Fast Batch Impact

- Batch size stayed at 10 profiles and 30 runs.
- Estimated tester runtime stayed at about 10.5 minutes before platform overhead.
- Baseline anchor keeps open basket partial harvest disabled.
- Generated research profiles use:
  - `InpUseOpenBasketPartialHarvest=true`
  - `InpOpenBasketHarvestMinProfitPercent=0.75`
  - `InpOpenBasketHarvestClosePercent=25.0`
  - `InpOpenBasketHarvestMinPositions=1`
  - `InpOpenBasketHarvestMoveStop=true`
  - `InpOpenBasketHarvestStopLockR=0.10`

## Quiet Validation Results

- `work\test_price_action_strategy_modules.ps1`: PASS
- `work\sync_ea_source_artifacts.ps1`: PASS, hash `3E1935A087C3E80C0F8EF8A9FCFFA43ED4367443971B927A6F5E77DB99D9E5AA`
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

- `outputs\Professional_XAUUSD_EA.mq5`: `3E1935A087C3E80C0F8EF8A9FCFFA43ED4367443971B927A6F5E77DB99D9E5AA`
- `Professional_XAUUSD_EA.mq5`: `3E1935A087C3E80C0F8EF8A9FCFFA43ED4367443971B927A6F5E77DB99D9E5AA`
- `outputs\external_mt5_validation_package\source\Professional_XAUUSD_EA.mq5`: `3E1935A087C3E80C0F8EF8A9FCFFA43ED4367443971B927A6F5E77DB99D9E5AA`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `040CBD74A50F2E42605A8854280BD0E6598D7759A54438D8C9159C478ECA39B0`, 35,456 bytes
- `outputs\xauusd_micro_validation_package.zip`: `ED61AFC4809AE7EBE15708926021AEF408C24FDC83E61B1D9F09FAD330EEB68E`
- `work\build_price_action_strategy_batch.ps1`: `6EFD8ABAC97732075C87C6873488888A08A4763FDB95816899C512DB7804A82B`
- `work\test_price_action_strategy_modules.ps1`: `5D69A5B6A06CA8E8831F91E6FEF1F831A6C1293F64EEB028EDDB7739CE25511D`
- `outputs\OFFLINE_VALIDATION_REFRESH.csv`: `E532CC970D631196F32D9E313BF85498851909DC83D3B5F29BE86B5AA8945AD1`

## Background-Safety Note

The stop marker remains present at `work\STOP_MT5_FOCUS_WATCHDOG`. Any future MT5 validation should be treated as external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The status note is committed through the GitHub connector. The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that the status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.