# Recent 2026 Fast Triage Status

Updated: 2026-07-06

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- Full EA source exists locally, but this note is the GitHub-safe status/evidence artifact.

## Latest Strategy-Code Change

Added optional elite setup risk boost with an equity-profit guard, so the EA can size the strongest signals larger only after the account is already above starting equity:

- `InpEliteSetupRiskRequiresEquityProfit`
- `EquityAboveStarting()` exposes whether current equity is above initialization equity.
- Existing quality risk scaling and price-action risk scaling can now be used as elite-signal boost layers.
- When the equity-profit guard is enabled and the account is not above starting equity, quality and price-action risk multipliers are clamped to `1.0` so they cannot increase risk from a hole.
- Aggressive generated profiles enable quality risk scaling and price-action risk scaling with `1.25x` and `1.35x` caps respectively, while the baseline leaves them disabled.

The existing aggressive growth framework remains in place:

- Hot-streak risk boost can press harder only after recent closed-trade average R improves.
- Winner-only scale-in can add only to same-direction protected winners.
- Runner TP expansion stretches reward only for high-quality price-action setups.
- Starting-equity protection can halt/close risk at the configured floor.
- Equity profit lock can protect a configurable percentage of peak account profit.
- Protected-equity floor caps new trade risk so theoretical stop risk does not exceed the floor.
- Profit-only risk boost can increase risk only after account equity is already above the configured profit threshold.

The generated aggressive research profiles now use 2.50% base risk, elite setup quality risk scaling enabled from quality score 10 to 14 with 1.00x to 1.25x multiplier, elite price-action risk scaling enabled from PA score 12 to 18 with 1.00x to 1.35x multiplier, elite boost requiring equity above starting equity, hot-streak risk boost enabled over 4 recent trades, boost starts at +0.35 average R, full boost at +1.00 average R, max hot-streak multiplier 1.75, hot-streak requires equity above starting equity, max 2 simultaneous positions, 6 max trades per day, 15-minute minimum trade spacing, winner scale-in enabled at 0.80R minimum open profit, protected stop required, quality score >= 10, 0.50 scale-in risk multiplier, 30-minute minimum since newest same-direction position, runner TP expansion enabled at quality score >= 12 and price-action score >= 14, 1.75 runner TP multiplier, trailing required for runner mode, starting-equity protection enabled at a 0.00% buffer, profit-only risk boost after +1.00% equity growth, full boost at +12.00%, max boost multiplier 3.00, equity profit lock after +2.00% peak equity growth, 50.0% peak-profit lock, 6.00% max equity drawdown, and 8.00% max open-risk cap. The baseline profile remains anchored at 1.60% risk with elite boost, hot-streak boost, winner scale-in, runner TP, starting-equity protection, profit-only boost, and equity profit lock disabled.

This is intentionally more aggressive than the earlier conservative settings, but it still avoids martingale, grid, averaging down, and recovery mechanics. It is not proven profitable until a real MT5 backtest/forward-test report exists.

## Fast Batch Impact

- Batch size stayed at 10 profiles and 30 runs.
- Estimated tester runtime stayed at about 10.5 minutes before platform overhead.
- Baseline anchor remains `InpUseQualityRiskScaling=false`, `InpUsePriceActionRiskScaling=false`, `InpUseHotStreakRiskBoost=false`, `InpUseWinnerScaleIn=false`, `InpUseRunnerTakeProfitExpansion=false`, `InpUseStartingEquityProtection=false`, `InpUseProfitOnlyRiskBoost=false`, and `InpUseEquityProfitLock=false`.
- Generated research profiles use `InpUseQualityRiskScaling=true`, `InpUsePriceActionRiskScaling=true`, `InpEliteSetupRiskRequiresEquityProfit=true`, `InpUseHotStreakRiskBoost=true`, `InpUseWinnerScaleIn=true`, `InpUseRunnerTakeProfitExpansion=true`, `InpUseStartingEquityProtection=true`, `InpUseProfitOnlyRiskBoost=true`, and `InpUseEquityProfitLock=true`.
- Generated research profiles are now designed to push upside harder only after signal quality, recent realized average R, and account equity state all justify it.

## Quiet Validation Results

- `work\test_price_action_strategy_modules.ps1`: PASS
- `work\sync_ea_source_artifacts.ps1`: PASS, hash `9C07271F461E48145F67E97AE0EF7739F84D1BBF2CF61765F6439958F2991FBA`
- `work\build_price_action_strategy_batch.ps1`: PASS, 10 profiles, 30 runs, estimated 10.5 minutes
- `work\test_ea_source_artifact_sync.ps1`: PASS
- `work\test_price_action_strategy_batch.ps1`: PASS
- `work\build_external_mt5_validation_package.ps1`: PASS
- `work\test_external_mt5_validation_package.ps1`: PASS, 26 checks, 0 failed
- `work\test_price_action_strategy_decision.ps1`: PASS
- `work\test_loss_streak_risk_reduction.ps1`: PASS
- `work\refresh_offline_validation_state.ps1`: PASS, 39 steps, 0 failed

## Latest Hashes

- `outputs\Professional_XAUUSD_EA.mq5`: `9C07271F461E48145F67E97AE0EF7739F84D1BBF2CF61765F6439958F2991FBA`
- `Professional_XAUUSD_EA.mq5`: `9C07271F461E48145F67E97AE0EF7739F84D1BBF2CF61765F6439958F2991FBA`
- `outputs\external_mt5_validation_package\source\Professional_XAUUSD_EA.mq5`: `9C07271F461E48145F67E97AE0EF7739F84D1BBF2CF61765F6439958F2991FBA`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `C6271BE0B827C343539DBF28C7B7B01C7903416CC53ADE50D3969FBB36268DC3`
- `outputs\PRICE_ACTION_STRATEGY_BATCH.csv`: `F170DD7B16E4AAE85E49CD0AB3A814C012C1C480FC2700F560A43E66A809FB49`
- `outputs\xauusd_micro_validation_package.zip`: `C946B14CC307A92CBD89C8E3AE14A889293E54D8021F1004A9718DAF37CFA460`
- `work\test_price_action_strategy_modules.ps1`: `FBDD3FC51507ADE0E30169B0ED56E7D5395FFE7B6AB7BBB1FE2F0CC1667F0610`
- `work\test_price_action_strategy_batch.ps1`: `3E8E51A14FD64B4D42713DDD4FCB27125F2F22A10E7B89C7E0D3525EBC4C65B7`
- `work\build_price_action_strategy_batch.ps1`: `61EB4E4B231D0A1616B0D10EF11AF6CDBF460DC3EF9F6818146B0829C346BA51`

## Background-Safety Note

The stop marker remains expected at `work\STOP_MT5_FOCUS_WATCHDOG`. Any future MT5 validation should be treated as external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The status note was committed through the GitHub connector. The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that the status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.
