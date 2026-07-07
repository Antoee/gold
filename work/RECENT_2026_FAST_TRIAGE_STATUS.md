# Recent 2026 Fast Triage Status

Updated: 2026-07-06

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- Full EA source exists locally, but this note is the GitHub-safe status/evidence artifact.

## Latest Strategy-Code Change

Added an open-basket profit trailing guard. This lets the EA protect floating profit across all currently open positions for the symbol/magic number, not just one trade at a time.

New inputs and logic:

- `InpUseOpenBasketProfitTrail`
- `InpOpenBasketTrailMinProfitPercent`
- `InpOpenBasketTrailGivebackPercent`
- `InpOpenBasketTrailMinPositions`
- `OpenBasketProfit()` sums current open basket profit for matching positions.
- `OpenBasketProfitTrailHit()` tracks peak floating basket profit and triggers a risk exit after configurable giveback.
- `RiskLimitHit()` can now return `open basket profit trail`, which routes through the existing `positionManager.CloseAll(...)` path.

This is a profit-protection feature for aggressive runs: it allows strong multi-position moves to keep running, then closes the basket if floating profit gives back too much. It adds no martingale, grid, averaging down, or recovery behavior.

## Fast Batch Impact

- Batch size stayed at 10 profiles and 30 runs.
- Estimated tester runtime stayed at about 10.5 minutes before platform overhead.
- Baseline anchor keeps `InpUseOpenBasketProfitTrail=false`.
- Generated research profiles use:
  - `InpUseOpenBasketProfitTrail=true`
  - `InpOpenBasketTrailMinProfitPercent=0.75`
  - `InpOpenBasketTrailGivebackPercent=35.0`
  - `InpOpenBasketTrailMinPositions=1`

## Quiet Validation Results

- `work\test_price_action_strategy_modules.ps1`: PASS
- `work\sync_ea_source_artifacts.ps1`: PASS, hash `EDA7D1CE1555EC0803FFF6C280843F7D69304F9AEB8E43628D2A51CD386ECC4E`
- `work\build_price_action_strategy_batch.ps1`: PASS, 10 profiles, 30 runs, estimated 10.5 minutes
- `work\test_price_action_strategy_decision.ps1`: PASS
- `work\test_loss_streak_risk_reduction.ps1`: PASS
- `work\test_ea_source_artifact_sync.ps1`: PASS
- `work\test_price_action_strategy_batch.ps1`: PASS
- `work\build_external_mt5_validation_package.ps1`: PASS, package configs 20, profiles 9
- `work\test_external_mt5_validation_package.ps1`: PASS, 26 checks, 0 failed
- `work\refresh_offline_validation_state.ps1`: PASS, 39 steps, 0 failed

## Latest Hashes

- `outputs\Professional_XAUUSD_EA.mq5`: `EDA7D1CE1555EC0803FFF6C280843F7D69304F9AEB8E43628D2A51CD386ECC4E`
- `Professional_XAUUSD_EA.mq5`: `EDA7D1CE1555EC0803FFF6C280843F7D69304F9AEB8E43628D2A51CD386ECC4E`
- `outputs\external_mt5_validation_package\source\Professional_XAUUSD_EA.mq5`: `EDA7D1CE1555EC0803FFF6C280843F7D69304F9AEB8E43628D2A51CD386ECC4E`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `17BC346B4432FF3634D31AD7C21B8930B0396660C311CFA1D124C2BEFFA6B62C`
- `outputs\PRICE_ACTION_STRATEGY_BATCH.csv`: `6887C7B2EE4D4D91A5BB05D817F303AA608F807C276142686247ED0AB5998D99`
- `outputs\xauusd_micro_validation_package.zip`: `139B654BA120AAE30AF0906C6C36373C4C34EC5017C9BF7EB30C5D6658EEAB5A`
- `work\test_price_action_strategy_modules.ps1`: `553D9F5E3688963999B58A55AA038F2E7793286E1DCD5B4E7CBC4B87D7996198`
- `work\test_price_action_strategy_batch.ps1`: `D546C9556DD34AC509EDC8706D57B7D5CDD7B9B0AECFB6BD1097B28F962C4874`
- `work\build_price_action_strategy_batch.ps1`: `908F2332A7A9A129F028ED52754019A49B02298FD470166CF475E8443D0A5391`

## Background-Safety Note

The stop marker remains expected at `work\STOP_MT5_FOCUS_WATCHDOG`. Any future MT5 validation should be treated as external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The status note is committed through the GitHub connector. The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that the status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.