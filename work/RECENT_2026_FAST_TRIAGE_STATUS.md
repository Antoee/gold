# Recent 2026 Fast Triage Status

Updated: 2026-07-06

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- Full EA source exists locally, but this note is the GitHub-safe status/evidence artifact.

## Latest Entry-Code Change

Added optional directional loss risk scaling:

- `InpUseDirectionalLossRiskScaling`
- `InpDirectionalLossRiskLookbackTrades`
- `InpDirectionalLossRiskThreshold`
- `InpDirectionalLossRiskMultiplier`
- `CRiskManager::DirectionalLossRiskMultiplier()` scans recent closed deals and counts losing closes by inferred original trade direction.
- `OpenSignal()` now multiplies normal quality/session/day risk by the directional risk multiplier when recent losses in the attempted direction exceed the configured threshold.
- Entries log `Directional risk x...` when the feature is enabled.

This is a risk-control module for reducing position size after the market has recently punished one direction. Unlike the directional cooldown and quality gates, it still allows normal entries but cuts exposure on the struggling side. It is disabled in the robust base profile and enabled only in strict risk-management research profiles. It adds no martingale, grid, averaging down, or recovery behavior.

## Fast Batch Impact

- Batch size stayed at 10 profiles and 30 runs.
- Estimated tester runtime stayed at about 10.5 minutes before platform overhead.
- `weighted_quality_confluence` enables directional loss risk scaling with lookback `4`, loss threshold `2`, and risk multiplier `0.50`.
- `pa_full_confluence` enables a stricter version with lookback `5`, loss threshold `2`, and risk multiplier `0.40`.
- Generated configs confirmed the module is enabled in strict risk-management research profiles and pinned disabled in the robust base profile.

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

- `outputs\Professional_XAUUSD_EA.mq5`: `71C9A88FEBAFD879C7978B052A715963C13A42CF193A61B6CBEAE84A852CD070`
- `Professional_XAUUSD_EA.mq5`: `71C9A88FEBAFD879C7978B052A715963C13A42CF193A61B6CBEAE84A852CD070`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `F8ED5A3F9109E9EA1CB2017A6C4162A4C102FC6ADBAE8D1A59C78533612E9C20`
- `outputs\PRICE_ACTION_STRATEGY_BATCH.csv`: `903827B590601032A7A70DABEBD76776A74CDD40CD4C103FEB0574FC2D00BED6`
- `outputs\xauusd_micro_validation_package.zip`: `7B4B47AE313647566455458DDBA000E72FC002BB49C82A4DA866E9548FC887D7`
- `work\test_price_action_strategy_modules.ps1`: `1C775D606FB6D7B62A526A2484E24081FB29FB452F34833DEDDBD5C48E5B0775`
- `work\test_price_action_strategy_batch.ps1`: `CBFC034BD7BD8630DFE856B6553C675718601BB2F06E19727D71F87941429850`
- `work\build_price_action_strategy_batch.ps1`: `EC3C51CC28CB4AEB2CA4EC742C5E181AC26C251F8AA97C78385EB0538EF63828`

## Background-Safety Note

The stop marker remains expected at `work\STOP_MT5_FOCUS_WATCHDOG`. Any future MT5 validation should be treated as external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The status note is committed through the GitHub connector. The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that the status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.
