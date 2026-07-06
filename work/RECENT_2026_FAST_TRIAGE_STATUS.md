# Recent 2026 Fast Triage Status

Updated: 2026-07-06

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- Full EA source exists locally, but this note is the GitHub-safe status/evidence artifact.

## Latest Risk-Code Change

Added optional Spread Risk Scaling:

- `InpUseSpreadRiskScaling`
- `InpSpreadRiskStartPoints`
- `InpMinSpreadRiskMultiplier`
- `SpreadRiskMultiplier()` compares current spread to the configured start point and the hard maximum spread guard, then scales position risk down as spread gets worse.
- `OpenSignal()` now combines quality, session, day-of-week, directional-loss, volatility, and spread risk multipliers before lot sizing.
- Entry logging adds `Spread risk x...` when enabled.

This changes risk logic instead of only changing settings. The goal is to keep otherwise valid setups eligible while cutting exposure when XAUUSD spread conditions are deteriorating but have not yet reached the hard no-trade spread limit. It is disabled in the robust base profile and enabled only in strict research profiles. It adds no martingale, grid, averaging down, or recovery behavior.

## Fast Batch Impact

- Batch size stayed at 10 profiles and 30 runs.
- Estimated tester runtime stayed at about 10.5 minutes before platform overhead.
- `weighted_quality_confluence` enables Spread Risk Scaling from `120.0` points with minimum risk multiplier `0.60`.
- `pa_full_confluence` enables a stricter version from `100.0` points with minimum risk multiplier `0.50`.
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

- `outputs\Professional_XAUUSD_EA.mq5`: `FCB0B3A905A76654595E5C48B107FDE8A10BE084F22AC0A6E4749553F636D2C5`
- `Professional_XAUUSD_EA.mq5`: `FCB0B3A905A76654595E5C48B107FDE8A10BE084F22AC0A6E4749553F636D2C5`
- `outputs\external_mt5_validation_package\source\Professional_XAUUSD_EA.mq5`: `FCB0B3A905A76654595E5C48B107FDE8A10BE084F22AC0A6E4749553F636D2C5`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `16947CECD73E8E1647B26AD686ADFB1806D9177105ECB8F858FAA070C7F4FDC3`
- `outputs\PRICE_ACTION_STRATEGY_BATCH.csv`: `903827B590601032A7A70DABEBD76776A74CDD40CD4C103FEB0574FC2D00BED6`
- `outputs\xauusd_micro_validation_package.zip`: `0107FBF517B10F8E737C09B63D883A87EF1984BF1937E3605D8C18A3D2B1CCC0`
- `work\test_price_action_strategy_modules.ps1`: `A67F704AB8910E35A0B30CE096591CB3E8E65B1BA28FFD463972E0F671B2BD98`
- `work\test_price_action_strategy_batch.ps1`: `08B75CEB0833AFF8504A0E7F6C68F0C373A81278C70FEC5BECB572430670FCBA`
- `work\build_price_action_strategy_batch.ps1`: `57B8BE2A550F9FAD42B0FCF97A1AFC58855617BEAE7D216672C5A99DDC66D3FC`

## Background-Safety Note

The stop marker remains expected at `work\STOP_MT5_FOCUS_WATCHDOG`. Any future MT5 validation should be treated as external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The status note can be committed through the GitHub connector. The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that the status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.
