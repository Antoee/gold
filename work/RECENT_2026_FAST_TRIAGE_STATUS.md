# Recent 2026 Fast Triage Status

Updated: 2026-07-06

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- Full EA source exists locally, but this note is the GitHub-safe status/evidence artifact.

## Latest Strategy-Code Change

Added a closed-profit requirement switch for growth boost layers. This prevents aggressive compounding from being triggered by temporary floating equity gains when the profile requires realized profit first.

New input and logic:

- `InpGrowthBoostRequiresClosedProfit`
- `m_initialBalance`
- `GrowthBoostAllowed()`
- `ClosedProfitAboveStarting()`

When enabled, the profit-only risk boost, hot-streak risk boost, and protected-cushion risk boost require current account balance to be above the starting balance. The profit-only boost also calculates its growth percentage from balance instead of floating equity in that mode.

Baseline keeps this disabled for comparison. Generated aggressive research profiles use `InpGrowthBoostRequiresClosedProfit=true`, so the growth stack can still press, but only after profit has actually been closed. This adds no martingale, grid, averaging down, or recovery behavior.

## Fast Batch Impact

- Batch size stayed at 10 profiles and 30 runs.
- Estimated tester runtime stayed at about 10.5 minutes before platform overhead.
- Baseline anchor keeps `InpGrowthBoostRequiresClosedProfit=false`.
- Generated research profiles use `InpGrowthBoostRequiresClosedProfit=true`.

## Quiet Validation Results

- `work\test_price_action_strategy_modules.ps1`: PASS
- `work\sync_ea_source_artifacts.ps1`: PASS, hash `B8631A53DE03001D432A02FF71C80D86578356A9C6F49D7AE2E881B64FBACBB6`
- `work\build_price_action_strategy_batch.ps1`: PASS, 10 profiles, 30 runs, estimated 10.5 minutes
- `work\test_ea_source_artifact_sync.ps1`: PASS
- `work\test_price_action_strategy_batch.ps1`: PASS
- `work\build_external_mt5_validation_package.ps1`: PASS, package configs 20, profiles 9
- `work\test_external_mt5_validation_package.ps1`: PASS, 26 checks, 0 failed
- `work\test_price_action_strategy_decision.ps1`: PASS
- `work\test_loss_streak_risk_reduction.ps1`: PASS
- `work\refresh_offline_validation_state.ps1`: PASS, 39 steps, 0 failed

## Latest Hashes

- `outputs\Professional_XAUUSD_EA.mq5`: `B8631A53DE03001D432A02FF71C80D86578356A9C6F49D7AE2E881B64FBACBB6`
- `Professional_XAUUSD_EA.mq5`: `B8631A53DE03001D432A02FF71C80D86578356A9C6F49D7AE2E881B64FBACBB6`
- `outputs\external_mt5_validation_package\source\Professional_XAUUSD_EA.mq5`: `B8631A53DE03001D432A02FF71C80D86578356A9C6F49D7AE2E881B64FBACBB6`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `E18DCFB2FD7F0447D9EC05FC156EE064640BE3F2D646DA43E5F0B9D0B556D150`
- `outputs\PRICE_ACTION_STRATEGY_BATCH.csv`: `6887C7B2EE4D4D91A5BB05D817F303AA608F807C276142686247ED0AB5998D99`
- `outputs\xauusd_micro_validation_package.zip`: `CC83893E4F49211BABB5A4B9E13E0E3CAC303D45B6597DB734F51C5825EA4C47`
- `work\test_price_action_strategy_modules.ps1`: `194F3A4E0965D2214278BEC18B4E687BEC339C967306BB589226B1C86BE7BF5D`
- `work\test_price_action_strategy_batch.ps1`: `B2F5AA0EA801E3C5B5417B5EBFAB4BA725EA81759985874DB7EB89FD6222F49B`
- `work\build_price_action_strategy_batch.ps1`: `269DF913CCCFDB294742D0C8AB43DD9F659CB8086CBEF25381C0B6417CA30276`

## Background-Safety Note

The stop marker remains expected at `work\STOP_MT5_FOCUS_WATCHDOG`. Any future MT5 validation should be treated as external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The status note was committed through the GitHub connector. The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that the status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.