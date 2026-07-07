# Recent 2026 Fast Triage Status

Updated: 2026-07-06

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- Full EA source exists locally, but this note is the GitHub-safe status/evidence artifact.

## Latest Strategy-Code Change

Added directional hour-of-day take-profit expansion. This builds on the same-side, same-hour performance sample added previously, but uses it to widen reward targets instead of increasing initial stop risk.

New inputs and logic:

- `InpUseDirectionalHourTakeProfitExpansion`
- `InpDirectionalHourTPMinQualityScore`
- `InpDirectionalHourTPMinPriceActionScore`
- `InpDirectionalHourTPMinNetPercent`
- `InpDirectionalHourTPMultiplier`
- `InpDirectionalHourTPRequireTrailing`
- `InpDirectionalHourTPRequiresClosedProfit`
- `DirectionalHourTakeProfitMultiplier()` expands TP only when directional-hour performance is strong enough.
- `DirectionalHourPerformanceSample()` now also activates when directional-hour TP expansion is enabled.
- `OpenSignal()` multiplies the TP distance by the directional-hour TP multiplier and logs `Directional hour TP x...`.

This supports the goal by seeking more profit from the exact side/hour that has recently shown edge, while leaving initial risk unchanged. The default research setting requires trailing capability and closed account profit before expansion. It adds no martingale, grid, averaging down, or recovery behavior.

## Fast Batch Impact

- Batch size stayed at 10 profiles and 30 runs.
- Estimated tester runtime stayed at about 10.5 minutes before platform overhead.
- Baseline anchor keeps directional-hour TP expansion disabled.
- Generated research profiles use:
  - `InpUseDirectionalHourTakeProfitExpansion=true`
  - `InpDirectionalHourTPMinQualityScore=13`
  - `InpDirectionalHourTPMinPriceActionScore=15`
  - `InpDirectionalHourTPMinNetPercent=0.25`
  - `InpDirectionalHourTPMultiplier=1.35`
  - `InpDirectionalHourTPRequireTrailing=true`
  - `InpDirectionalHourTPRequiresClosedProfit=true`

## Quiet Validation Results

- `work\test_price_action_strategy_modules.ps1`: PASS
- `work\sync_ea_source_artifacts.ps1`: PASS, hash `CD96285BB7F942BEF48C6E1D5BF6B07CA2845198E958536BF2D4A8A9F07D2A08`
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

- `outputs\Professional_XAUUSD_EA.mq5`: `CD96285BB7F942BEF48C6E1D5BF6B07CA2845198E958536BF2D4A8A9F07D2A08`
- `Professional_XAUUSD_EA.mq5`: `CD96285BB7F942BEF48C6E1D5BF6B07CA2845198E958536BF2D4A8A9F07D2A08`
- `outputs\external_mt5_validation_package\source\Professional_XAUUSD_EA.mq5`: `CD96285BB7F942BEF48C6E1D5BF6B07CA2845198E958536BF2D4A8A9F07D2A08`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `EFC8C60EC60B283DED1770FD1C4EFBDAD9A7AD05729E99E31135739D5646DD73`, 34,593 bytes
- `outputs\xauusd_micro_validation_package.zip`: `882F1020289E77780211C415FBEB576D1954A55E150930287204DC24B52E1D33`
- `work\build_price_action_strategy_batch.ps1`: `0C832849D5BC755FE3DE2CD950C5214A36291958C8B79F948F8AE6D89E6891DC`
- `work\test_price_action_strategy_modules.ps1`: `AC1473824E75847C904A99B99EA40A9BED298A4475E32C4420D75DCD2DBF2690`
- `outputs\OFFLINE_VALIDATION_REFRESH.csv`: `0DA32054FCAF27F6F446DDCB3AF033EFA26AD165BF59F88E519F8001024B0083`

## Background-Safety Note

The stop marker remains present at `work\STOP_MT5_FOCUS_WATCHDOG`. Any future MT5 validation should be treated as external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The status note is committed through the GitHub connector. The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that the status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.