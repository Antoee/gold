# Recent 2026 Fast Triage Status

Updated: 2026-07-06

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- Full EA source exists locally, but this note is the GitHub-safe status/evidence artifact.

## Latest Risk-Code Change

Added optional Daily Loss Pressure Risk Scaling:

- `InpUseDailyLossRiskScaling`
- `InpDailyLossRiskStartFraction`
- `InpMinDailyLossRiskMultiplier`
- `DailyLossPressureRiskMultiplier()` uses current-day realized P/L and `InpMaxDailyLossPercent` to taper risk before the hard daily loss limit is reached.
- `OpenSignal()` now multiplies daily-loss pressure risk into final lot sizing and logs `Daily loss risk x...` when enabled.

This changes risk strategy code, not only settings. The goal is to reduce exposure as the current day deteriorates, instead of waiting until the daily loss limit blocks trading or flattens positions. The baseline anchor remains pinned disabled for comparison, while generated research profiles enable it. It adds no martingale, grid, averaging down, or recovery behavior.

## Fast Batch Impact

- Batch size stayed at 10 profiles and 30 runs.
- Estimated tester runtime stayed at about 10.5 minutes before platform overhead.
- Baseline anchor remains `InpUseDailyLossRiskScaling=false` for clean comparison.
- Generated research profiles enable `InpUseDailyLossRiskScaling=true`.
- Research profiles use start fraction `0.35` and minimum multiplier `0.50`, so risk starts tapering after 35% of the daily loss budget is used.

## Quiet Validation Results

- `work\test_price_action_strategy_modules.ps1`: PASS
- `work\build_price_action_strategy_batch.ps1`: PASS, 10 profiles, 30 runs, estimated 10.5 minutes
- `work\sync_ea_source_artifacts.ps1`: PASS
- `work\test_price_action_strategy_batch.ps1`: PASS
- `work\test_ea_source_artifact_sync.ps1`: PASS
- `work\build_external_mt5_validation_package.ps1`: PASS, package configs 20, profiles 9
- `work\test_external_mt5_validation_package.ps1`: PASS, 26 checks, 0 failed
- `work\refresh_offline_validation_state.ps1`: PASS, 39 steps, 0 failed

## Latest Hashes

- `outputs\Professional_XAUUSD_EA.mq5`: `5EAE2D170D51A4A75832978B21C1C7BDAA5BA9B72B8DBDD20D151F8C3F4436BB`
- `Professional_XAUUSD_EA.mq5`: `5EAE2D170D51A4A75832978B21C1C7BDAA5BA9B72B8DBDD20D151F8C3F4436BB`
- `outputs\external_mt5_validation_package\source\Professional_XAUUSD_EA.mq5`: `5EAE2D170D51A4A75832978B21C1C7BDAA5BA9B72B8DBDD20D151F8C3F4436BB`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `E4767F717632A810F5702F84DB57565C95588D7DB5334E1643D62D11AF176148`
- `outputs\PRICE_ACTION_STRATEGY_BATCH.csv`: `903827B590601032A7A70DABEBD76776A74CDD40CD4C103FEB0574FC2D00BED6`
- `outputs\xauusd_micro_validation_package.zip`: `922AB2DDC5CE6B4317A8F67EC0AE08B80EF9FBB75ABA05A40BB23EA316F5B843`
- `work\test_price_action_strategy_modules.ps1`: `C459A7E17A7DF2925C6618EF17E027E826366C74BCC6F8EED45A222689E4A5D5`
- `work\test_price_action_strategy_batch.ps1`: `65949D1A28A4728D598C10443D638EB0A3A69E6D682D542FC6BB504ABB51EFB9`
- `work\build_price_action_strategy_batch.ps1`: `DF13A73023ED34F7D2B68D318D7AEB1CFC3317ECFBA77654F78B38F9F9CBFF07`

## Background-Safety Note

The stop marker remains expected at `work\STOP_MT5_FOCUS_WATCHDOG`. Any future MT5 validation should be treated as external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The status note can be committed through the GitHub connector. The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that the status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.
