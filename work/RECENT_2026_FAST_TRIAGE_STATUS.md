# Recent 2026 Fast Triage Status

Updated: 2026-07-06

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- Full EA source exists locally, but this note is the GitHub-safe status/evidence artifact.

## Latest Risk-Code Change

Added optional Correlation Risk Scaling on top of the price-action risk stack:

- `InpUseCorrelationRiskScaling`
- `InpCorrelationWeakRiskMultiplier`
- `InpCorrelationConflictRiskMultiplier`
- `CorrelationRiskMultiplier()` reuses the configured correlation symbol/timeframe/lookback/mode and reduces risk when the related market move is weak or conflicts with the XAUUSD setup.
- `OpenSignal()` now multiplies correlation risk into final lot sizing and logs `Correlation risk x...` when enabled.

This changes risk strategy code, not only settings. The goal is to keep valid XAUUSD setups eligible while reducing exposure when XAGUSD/correlation evidence is weak or contradictory. It is disabled in the robust base profile and enabled only in strict research profiles. It adds no martingale, grid, averaging down, or recovery behavior.

## Fast Batch Impact

- Batch size stayed at 10 profiles and 30 runs.
- Estimated tester runtime stayed at about 10.5 minutes before platform overhead.
- `weighted_quality_confluence` enables Correlation Risk Scaling with weak multiplier `0.75` and conflict multiplier `0.50`.
- `pa_full_confluence` enables a stricter version with weak multiplier `0.70` and conflict multiplier `0.40`.
- Generated configs confirmed the module is enabled in strict price-action research profiles and pinned disabled in the robust base profile.

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

- `outputs\Professional_XAUUSD_EA.mq5`: `3D5B8FA153F731A44AB4BC080DD43F7047AB7B165DFCB04A9C6126DFFA360AF8`
- `Professional_XAUUSD_EA.mq5`: `3D5B8FA153F731A44AB4BC080DD43F7047AB7B165DFCB04A9C6126DFFA360AF8`
- `outputs\external_mt5_validation_package\source\Professional_XAUUSD_EA.mq5`: `3D5B8FA153F731A44AB4BC080DD43F7047AB7B165DFCB04A9C6126DFFA360AF8`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `91961D16EF06BA8A49D0BFD1C2631EBEBA2BB8460D7342099E3FE53416DF4520`
- `outputs\PRICE_ACTION_STRATEGY_BATCH.csv`: `903827B590601032A7A70DABEBD76776A74CDD40CD4C103FEB0574FC2D00BED6`
- `outputs\xauusd_micro_validation_package.zip`: `816D13391A6C766AA592BFFA71033A2FE5F8C07757FE2A21A21462FBC8E19549`
- `work\test_price_action_strategy_modules.ps1`: `8DB8A576B3483183A175AA03C0C87AC0E8165703D70645C2E0A15012A2E1A52E`
- `work\test_price_action_strategy_batch.ps1`: `03870E50B424147B7C58711FDCB66C38F09A9F85B29FDB67C947EA08F0FF2900`
- `work\build_price_action_strategy_batch.ps1`: `525527BFF6193CD07B6CB9CDB871FACFB45DA509CFF5DC93C095E4EB234E64F2`

## Background-Safety Note

The stop marker remains expected at `work\STOP_MT5_FOCUS_WATCHDOG`. Any future MT5 validation should be treated as external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The status note can be committed through the GitHub connector. The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that the status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.
