# Recent 2026 Fast Triage Status

Updated: 2026-07-06

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- Full EA source exists locally, but this note is the GitHub-safe status/evidence artifact.

## Latest Strategy-Code Change

Added directional hour-of-day performance controls. The EA can now treat buy and sell performance separately for the current broker/server hour, instead of assuming both sides behave the same.

New inputs and logic:

- `InpUseDirectionalHourPerformanceRiskScaling`
- `InpDirectionalHourPerformanceLookbackDays`
- `InpDirectionalHourPerformanceMinTrades`
- `InpDirectionalHourPerformanceWeakNetPercent`
- `InpDirectionalHourPerformanceStrongNetPercent`
- `InpMinDirectionalHourPerformanceRiskMultiplier`
- `InpMaxDirectionalHourPerformanceRiskMultiplier`
- `InpDirectionalHourPerformanceBoostRequiresClosedProfit`
- `InpUseDirectionalHourPerformanceQualityGate`
- `InpDirectionalHourPerformanceMinQualityScore`
- `EntryBiasForPosition()` maps closed deals back to the original entry side.
- `DirectionalHourPerformanceSample()` samples same-hour, same-direction closed trade performance.
- `DirectionalHourPerformanceRiskMultiplier()` can reduce weak directional hours and modestly boost strong ones.
- `DirectionalHourPerformanceQualityAllows()` blocks low-quality trades when the same side has recently performed poorly in that hour.
- `OpenSignal()` can now reject with `directional hour performance quality`.

This supports the goal by letting research profiles press a proven side during good hours while cutting or blocking the side that has recently hurt the account. The boost remains optional, capped, and closed-profit gated by default. It adds no martingale, grid, averaging down, or recovery behavior.

## Fast Batch Impact

- Batch size stayed at 10 profiles and 30 runs.
- Estimated tester runtime stayed at about 10.5 minutes before platform overhead.
- Baseline anchor keeps directional-hour controls disabled.
- Generated research profiles use:
  - `InpUseDirectionalHourPerformanceRiskScaling=true`
  - `InpDirectionalHourPerformanceLookbackDays=60`
  - `InpDirectionalHourPerformanceMinTrades=3`
  - `InpMaxDirectionalHourPerformanceRiskMultiplier=1.20`
  - `InpDirectionalHourPerformanceBoostRequiresClosedProfit=true`
  - `InpUseDirectionalHourPerformanceQualityGate=true`
  - `InpDirectionalHourPerformanceMinQualityScore=13`

## Quiet Validation Results

- `work\test_price_action_strategy_modules.ps1`: PASS
- `work\sync_ea_source_artifacts.ps1`: PASS, hash `28C794F01328170B6708A95742A2DFD2CDC4891E8686DC6226511249CE40DF6D`
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

- `outputs\Professional_XAUUSD_EA.mq5`: `28C794F01328170B6708A95742A2DFD2CDC4891E8686DC6226511249CE40DF6D`
- `Professional_XAUUSD_EA.mq5`: `28C794F01328170B6708A95742A2DFD2CDC4891E8686DC6226511249CE40DF6D`
- `outputs\external_mt5_validation_package\source\Professional_XAUUSD_EA.mq5`: `28C794F01328170B6708A95742A2DFD2CDC4891E8686DC6226511249CE40DF6D`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: 34,177 bytes; contains the new directional-hour input block.
- `outputs\xauusd_micro_validation_package.zip`: `B72F92ED8A78ABAE8BC8747455047DDAA422EB55BA921E47B51F50D49741049C`
- `work\build_price_action_strategy_batch.ps1`: `91DFAB26FDF50B3FB30B909C19EB50051E259B48F7BC0DB67E5ABAD810952B05`
- `work\test_price_action_strategy_modules.ps1`: `ED6D348AC1D080A2F17C583D1A25CE472A18D61D56366F11F0212B5D6929922B`
- `outputs\OFFLINE_VALIDATION_REFRESH.csv`: `F6B0DCB5D2521F02E04D7F703F2A8CCD95E03014822DEDAE36A0240D05799210`

## Background-Safety Note

The stop marker remains present at `work\STOP_MT5_FOCUS_WATCHDOG`. Any future MT5 validation should be treated as external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The status note is committed through the GitHub connector. The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that the status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.