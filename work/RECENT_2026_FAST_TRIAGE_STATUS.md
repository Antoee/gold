# Recent 2026 Fast Triage Status

Updated: 2026-07-06

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- Full EA source exists locally, but this note is the GitHub-safe status/evidence artifact.

## Latest Risk-Code Change

Added optional Recent Average-R Risk Scaling for generated research profiles:

- `InpUseRecentPerformanceRRiskScaling`
- `InpRecentPerformanceRRiskLookbackTrades`
- `InpRecentPerformanceRRiskStartAverageR`
- `InpRecentPerformanceRRiskFullAverageR`
- `InpMinRecentPerformanceRRiskMultiplier`
- `RecentPerformanceRRiskMultiplier()` reuses the existing R-multiple sampler to scale new-trade risk down when recent average R weakens.
- `OpenSignal()` now multiplies this scaler into final lot sizing and logs `Recent R risk x...` when enabled.

This is risk-control logic, not only settings. It complements the recent average-R quality gate and full trade pause by reducing size earlier, before conditions are bad enough to block trading. It adds no martingale, grid, averaging down, or recovery behavior.

## Fast Batch Impact

- Batch size stayed at 10 profiles and 30 runs.
- Estimated tester runtime stayed at about 10.5 minutes before platform overhead.
- Baseline anchor remains `InpUseRecentPerformanceRRiskScaling=false`.
- Generated research profiles use `InpUseRecentPerformanceRRiskScaling=true`.
- Research profiles start tapering below average R `0.00`, fully taper by average R `-0.50`, and use minimum multiplier `0.50`.

## Quiet Validation Results

- `work\test_price_action_strategy_modules.ps1`: PASS
- `work\sync_ea_source_artifacts.ps1`: PASS, hash `291DB36B432EC610B111F2FA0AD582E6BB3542187FF484501CE7B8614C3791A3`
- `work\build_price_action_strategy_batch.ps1`: PASS, 10 profiles, 30 runs, estimated 10.5 minutes
- `work\test_ea_source_artifact_sync.ps1`: PASS
- `work\test_price_action_strategy_batch.ps1`: PASS
- `work\build_external_mt5_validation_package.ps1`: PASS, package configs 20, profiles 9
- `work\test_external_mt5_validation_package.ps1`: PASS, 26 checks, 0 failed
- `work\refresh_offline_validation_state.ps1`: PASS, 39 steps, 0 failed

## Latest Hashes

- `outputs\Professional_XAUUSD_EA.mq5`: `291DB36B432EC610B111F2FA0AD582E6BB3542187FF484501CE7B8614C3791A3`
- `Professional_XAUUSD_EA.mq5`: `291DB36B432EC610B111F2FA0AD582E6BB3542187FF484501CE7B8614C3791A3`
- `outputs\external_mt5_validation_package\source\Professional_XAUUSD_EA.mq5`: `291DB36B432EC610B111F2FA0AD582E6BB3542187FF484501CE7B8614C3791A3`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `9B48DC58BB7A451AB177448284C933B839217FA96C8842F97259C1E87AB52589`
- `outputs\PRICE_ACTION_STRATEGY_BATCH.csv`: `903827B590601032A7A70DABEBD76776A74CDD40CD4C103FEB0574FC2D00BED6`
- `outputs\xauusd_micro_validation_package.zip`: `FA75911511963B05A50B616B288890E8AFFDF9310892D746F913EB06071E001E`
- `work\test_price_action_strategy_modules.ps1`: `333470ED72F31835299E143F1DBC8076C3A4FAC489FFD230E3432C4BDA3BC40E`
- `work\test_price_action_strategy_batch.ps1`: `6655ACDB0E699A05C47397CEF2791A48B1EE700B9B736AF5F7F29AA1FBF0DF42`
- `work\build_price_action_strategy_batch.ps1`: `0E8F6A0D15401654129AF757D6797F889B36FC0525F4694BD2F7C2FF0D0479B8`

## Background-Safety Note

The stop marker remains expected at `work\STOP_MT5_FOCUS_WATCHDOG`. Any future MT5 validation should be treated as external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The status note was committed through the GitHub connector. The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that the status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.
