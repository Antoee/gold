# Recent 2026 Fast Triage Status

Updated: 2026-07-06

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- Full EA source exists locally, but this note is the GitHub-safe status/evidence artifact.

## Latest Risk-Code Change

Added optional Volatility Risk Scaling:

- `InpUseVolatilityRiskScaling`
- `InpVolatilityRiskLookbackBars`
- `InpVolatilityRiskStartRatio`
- `InpVolatilityRiskFullRatio`
- `InpMinVolatilityRiskMultiplier`
- `VolatilityRiskMultiplier()` compares current ATR to recent average ATR and scales position risk down when volatility is elevated.
- `OpenSignal()` now combines quality, session, day-of-week, directional-loss, and volatility risk multipliers before lot sizing.
- Entry logging adds `Volatility risk x...` when enabled.

This changes risk logic instead of only changing settings. The goal is to keep good setups eligible while cutting exposure during unusually volatile gold conditions, where slippage, stop-outs, and fast reversals are more likely. It is disabled in the robust base profile and enabled only in strict research profiles. It adds no martingale, grid, averaging down, or recovery behavior.

## Fast Batch Impact

- Batch size stayed at 10 profiles and 30 runs.
- Estimated tester runtime stayed at about 10.5 minutes before platform overhead.
- `weighted_quality_confluence` enables Volatility Risk Scaling with lookback `24`, start ratio `1.25`, full ratio `1.80`, and minimum risk multiplier `0.55`.
- `pa_full_confluence` enables a stricter version with lookback `30`, start ratio `1.20`, full ratio `1.70`, and minimum risk multiplier `0.45`.
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

- `outputs\Professional_XAUUSD_EA.mq5`: `C573910FDBE4A80859B3112BB481E19857179FFF39C9FCB4BD84F651B288F164`
- `Professional_XAUUSD_EA.mq5`: `C573910FDBE4A80859B3112BB481E19857179FFF39C9FCB4BD84F651B288F164`
- `outputs\external_mt5_validation_package\source\Professional_XAUUSD_EA.mq5`: `C573910FDBE4A80859B3112BB481E19857179FFF39C9FCB4BD84F651B288F164`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `BF4124C149B93B824D2B72D0690FA8481D4ACFCADCBEDF9DE3C52FC3BFB2469B`
- `outputs\PRICE_ACTION_STRATEGY_BATCH.csv`: `903827B590601032A7A70DABEBD76776A74CDD40CD4C103FEB0574FC2D00BED6`
- `outputs\xauusd_micro_validation_package.zip`: `E75400FABFF6F8660802122A75148355CE4F308D48D6F34CD2E95A43C6A60998`
- `work\test_price_action_strategy_modules.ps1`: `020ADD1FFAB147E4FA4F89D92479FF7B45E5A43F433A8798C66FF3858C1CF650`
- `work\test_price_action_strategy_batch.ps1`: `79571C97C15323EED06CEFE944D7DC511BD5B0E4C1B2AF043F05190EC793EB4E`
- `work\build_price_action_strategy_batch.ps1`: `D57B723FA12F710EAAD4875E25B63B581E722BE31793E6E4850136441CF4ECEA`

## Background-Safety Note

The stop marker remains expected at `work\STOP_MT5_FOCUS_WATCHDOG`. Any future MT5 validation should be treated as external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The status note can be committed through the GitHub connector. The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that the status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.
