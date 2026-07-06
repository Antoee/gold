# Recent 2026 Fast Triage Status

Updated: 2026-07-06

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- Full EA source exists locally, but this note is the GitHub-safe status/evidence artifact.

## Latest Strategy-Code Change

Added optional Aggressive Growth controls with principal protection, profit-only risk scaling, and a dynamic equity profit lock:

- `InpUseStartingEquityProtection`
- `InpStartingEquityBufferPercent`
- `InpUseProfitOnlyRiskBoost`
- `InpProfitBoostStartPercent`
- `InpProfitBoostFullPercent`
- `InpMaxProfitBoostMultiplier`
- `InpUseEquityProfitLock`
- `InpEquityProfitLockStartPercent`
- `InpEquityProfitLockPercent`
- `CRiskManager` stores `m_initialEquity` from initialization and tracks `m_peakEquity`.
- `StartingEquityFloor()` can halt/close risk when equity reaches the configured starting-equity floor.
- `EquityProfitLockFloor()` locks a configurable percentage of peak account profit after the profit threshold is reached.
- `ProtectedEquityFloor()` combines the starting-equity floor and dynamic profit-lock floor.
- `LotsForRisk()` now caps new trade risk so theoretical stop risk does not exceed the protected equity floor.
- `EffectiveRiskPercent()` can increase risk only after account equity is already above the configured profit threshold.

The generated aggressive research profiles now use 2.50% base risk, starting-equity protection enabled at a 0.00% buffer, profit-only risk boost enabled after +1.00% equity growth, full boost at +12.00%, max boost multiplier 3.00, equity profit lock enabled after +2.00% peak equity growth, 50.0% peak-profit lock, 6.00% max equity drawdown, and 8.00% max open-risk cap. The baseline profile remains anchored at 1.60% risk with the new aggressive controls disabled.

This is intentionally more aggressive than the earlier conservative settings, but it still avoids martingale, grid, averaging down, and recovery mechanics. It is not proven profitable until a real MT5 backtest/forward-test report exists.

## Fast Batch Impact

- Batch size stayed at 10 profiles and 30 runs.
- Estimated tester runtime stayed at about 10.5 minutes before platform overhead.
- Baseline anchor remains `InpUseStartingEquityProtection=false`, `InpUseProfitOnlyRiskBoost=false`, and `InpUseEquityProfitLock=false`.
- Generated research profiles use `InpUseStartingEquityProtection=true`, `InpUseProfitOnlyRiskBoost=true`, and `InpUseEquityProfitLock=true`.
- Generated research profiles are now designed to push upside harder, compound only after profits exist, and protect a configurable portion of peak account profit.

## Quiet Validation Results

- `work\test_price_action_strategy_modules.ps1`: PASS
- `work\sync_ea_source_artifacts.ps1`: PASS, hash `DA088592AC4D37626E2DC1C8DD20C9F5027C1E3B9AFBFA552DAF5FF3FE451542`
- `work\build_price_action_strategy_batch.ps1`: PASS, 10 profiles, 30 runs, estimated 10.5 minutes
- `work\test_ea_source_artifact_sync.ps1`: PASS
- `work\test_price_action_strategy_batch.ps1`: PASS
- `work\test_external_mt5_validation_package.ps1`: PASS, 26 checks, 0 failed
- `work\test_price_action_strategy_decision.ps1`: PASS
- `work\test_loss_streak_risk_reduction.ps1`: PASS
- `work\refresh_offline_validation_state.ps1`: PASS, 39 steps, 0 failed

## Latest Hashes

- `outputs\Professional_XAUUSD_EA.mq5`: `DA088592AC4D37626E2DC1C8DD20C9F5027C1E3B9AFBFA552DAF5FF3FE451542`
- `Professional_XAUUSD_EA.mq5`: `DA088592AC4D37626E2DC1C8DD20C9F5027C1E3B9AFBFA552DAF5FF3FE451542`
- `outputs\external_mt5_validation_package\source\Professional_XAUUSD_EA.mq5`: `DA088592AC4D37626E2DC1C8DD20C9F5027C1E3B9AFBFA552DAF5FF3FE451542`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `6B686788F27C2BD8A1B3923909DA6F8EABC48F091CD6445E48B329166AB1276E`
- `outputs\PRICE_ACTION_STRATEGY_BATCH.csv`: `A3E85AD7C580AED1BDD09A9EA8DEE3EF3B4FB9B93E996A5A42246D481944DBD9`
- `outputs\xauusd_micro_validation_package.zip`: `1920EFA5792149B17784EE6E7A7E40CFB9FBE8D3B7B23B5D0F8D6F978DB4E419`
- `work\test_price_action_strategy_modules.ps1`: `0BD86059F6BC0EC56A48E8BC679ACEDFDF6628ECC79E4AA6AEBC73A0C387D035`
- `work\test_price_action_strategy_batch.ps1`: `EBE7834A09301F3D486CEEF2EB1279D06CD7E8781B10858B2D82764346869631`
- `work\build_price_action_strategy_batch.ps1`: `4D647EFFE9377A19E63B2FDC2330978B64356A9C638C636DAE45C86BC4160EA8`
- `work\test_loss_streak_risk_reduction.ps1`: `5B0A4C71527E14961C1C18B645AE8BE99F14F18FB3DFA990D1BD670F23A323FB`

## Background-Safety Note

The stop marker remains expected at `work\STOP_MT5_FOCUS_WATCHDOG`. Any future MT5 validation should be treated as external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The status note was committed through the GitHub connector. The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that the status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.
