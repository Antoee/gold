# Recent 2026 Fast Triage Status

Updated: 2026-07-06

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- Full EA source exists locally, but this note is the GitHub-safe status/evidence artifact.

## Latest Strategy-Code Change

Added optional Aggressive Growth controls with principal protection and profit-only risk scaling:

- `InpUseStartingEquityProtection`
- `InpStartingEquityBufferPercent`
- `InpUseProfitOnlyRiskBoost`
- `InpProfitBoostStartPercent`
- `InpProfitBoostFullPercent`
- `InpMaxProfitBoostMultiplier`
- `CRiskManager` now stores `m_initialEquity` from initialization.
- `StartingEquityFloor()` can halt/close risk when equity reaches the configured starting-equity floor.
- `EffectiveRiskPercent()` can increase risk only after account equity is already above the configured profit threshold.

The generated aggressive research profiles now use 2.50% base risk, starting-equity protection enabled at a 0.00% buffer, profit-only risk boost enabled after +1.00% equity growth, full boost at +12.00%, max boost multiplier 3.00, 6.00% max equity drawdown, and 8.00% max open-risk cap. The baseline profile remains anchored at the prior 1.60% risk with the new aggressive controls disabled.

This is intentionally more aggressive than the previous conservative settings, but it still avoids martingale, grid, averaging down, and recovery mechanics. It is not proven profitable until a real MT5 backtest/forward-test report exists.

## Fast Batch Impact

- Batch size stayed at 10 profiles and 30 runs.
- Estimated tester runtime stayed at about 10.5 minutes before platform overhead.
- Baseline anchor remains `InpUseStartingEquityProtection=false` and `InpUseProfitOnlyRiskBoost=false`.
- Generated research profiles use `InpUseStartingEquityProtection=true` and `InpUseProfitOnlyRiskBoost=true`.
- Generated research profiles are now designed to push upside harder while cutting off risk at the starting-equity floor and existing hard-risk limits.

## Quiet Validation Results

- `work\test_price_action_strategy_modules.ps1`: PASS
- `work\sync_ea_source_artifacts.ps1`: PASS, hash `682FBB0282F9779251E42DB7E507B3B3033E34140128387AE47B91C567EAA072`
- `work\build_price_action_strategy_batch.ps1`: PASS, 10 profiles, 30 runs, estimated 10.5 minutes
- `work\test_ea_source_artifact_sync.ps1`: PASS
- `work\test_price_action_strategy_batch.ps1`: PASS
- `work\test_price_action_strategy_decision.ps1`: PASS
- `work\build_external_mt5_validation_package.ps1`: PASS
- `work\test_external_mt5_validation_package.ps1`: PASS, 26 checks, 0 failed
- `work\refresh_offline_validation_state.ps1`: PASS, 39 steps, 0 failed

## Latest Hashes

- `outputs\Professional_XAUUSD_EA.mq5`: `682FBB0282F9779251E42DB7E507B3B3033E34140128387AE47B91C567EAA072`
- `Professional_XAUUSD_EA.mq5`: `682FBB0282F9779251E42DB7E507B3B3033E34140128387AE47B91C567EAA072`
- `outputs\external_mt5_validation_package\source\Professional_XAUUSD_EA.mq5`: `682FBB0282F9779251E42DB7E507B3B3033E34140128387AE47B91C567EAA072`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `D33D341AB605C520A5F47F7D3B0113F433232583A0EAD05AE8B6EC915E58A5A2`
- `outputs\PRICE_ACTION_STRATEGY_BATCH.csv`: `F719CA6642AFD84E95AF55C6391A5C1B26EE5D4A11BB52CA6D9E655457F68707`
- `outputs\xauusd_micro_validation_package.zip`: `8B115DA3F6F9A0DF99A9505372DB929ABA5C5126F4DD8788B650562B7F0967D3`
- `work\test_price_action_strategy_modules.ps1`: `A0A1D56B9D2A299991CBE17DA3C7B2F7E9E422F1482449739E7F8D21A21E3102`
- `work\test_price_action_strategy_batch.ps1`: `5AB89804A3754B43D22E163C216E133E36BD87A7EB353F578B18AD6B2B2859EE`
- `work\build_price_action_strategy_batch.ps1`: `84974C1F8E22856AFACAE7111818559D849D73CE47DA38A35CAD160802E704A1`
- `work\test_price_action_strategy_decision.ps1`: `DF346BD202B7BF98BF7D9D9CD23773943530AB633AC00E402B3403826D869739`

## Background-Safety Note

The stop marker remains expected at `work\STOP_MT5_FOCUS_WATCHDOG`. Any future MT5 validation should be treated as external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The status note was committed through the GitHub connector. The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that the status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.
