# Recent 2026 Fast Triage Status

Updated: 2026-07-06

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- Full EA source exists locally, but this note is the GitHub-safe status/evidence artifact.

## Latest Strategy-Code Change

Added optional closed-trade hot-streak risk boost so the EA can press harder only after recent realized performance improves:

- `InpUseHotStreakRiskBoost`
- `InpHotStreakLookbackTrades`
- `InpHotStreakStartAverageR`
- `InpHotStreakFullAverageR`
- `InpMaxHotStreakRiskMultiplier`
- `InpHotStreakRequiresEquityProfit`
- `HotStreakRiskMultiplier()` reads recent closed-trade average R and returns a capped boost only when the recent average R exceeds the configured start threshold.
- When required, hot-streak boost stays inactive unless account equity is above starting equity.
- The boost is applied inside `EffectiveRiskPercent()` and remains wrapped by the existing lot-sizing, protected-equity floor, open-risk, drawdown, and loss controls.

The existing aggressive growth framework remains in place:

- Winner-only scale-in can add only to same-direction protected winners.
- Runner TP expansion stretches reward only for high-quality price-action setups.
- Starting-equity protection can halt/close risk at the configured floor.
- Equity profit lock can protect a configurable percentage of peak account profit.
- Protected-equity floor caps new trade risk so theoretical stop risk does not exceed the floor.
- Profit-only risk boost can increase risk only after account equity is already above the configured profit threshold.

The generated aggressive research profiles now use 2.50% base risk, hot-streak risk boost enabled over 4 recent trades, boost starts at +0.35 average R, full boost at +1.00 average R, max hot-streak multiplier 1.75, hot-streak requires equity above starting equity, max 2 simultaneous positions, 6 max trades per day, 15-minute minimum trade spacing, winner scale-in enabled at 0.80R minimum open profit, protected stop required, quality score >= 10, 0.50 scale-in risk multiplier, 30-minute minimum since newest same-direction position, runner TP expansion enabled at quality score >= 12 and price-action score >= 14, 1.75 runner TP multiplier, trailing required for runner mode, starting-equity protection enabled at a 0.00% buffer, profit-only risk boost after +1.00% equity growth, full boost at +12.00%, max boost multiplier 3.00, equity profit lock after +2.00% peak equity growth, 50.0% peak-profit lock, 6.00% max equity drawdown, and 8.00% max open-risk cap. The baseline profile remains anchored at 1.60% risk with hot-streak boost, winner scale-in, runner TP, starting-equity protection, profit-only boost, and equity profit lock disabled.

This is intentionally more aggressive than the earlier conservative settings, but it still avoids martingale, grid, averaging down, and recovery mechanics. It is not proven profitable until a real MT5 backtest/forward-test report exists.

## Fast Batch Impact

- Batch size stayed at 10 profiles and 30 runs.
- Estimated tester runtime stayed at about 10.5 minutes before platform overhead.
- Baseline anchor remains `InpUseHotStreakRiskBoost=false`, `InpUseWinnerScaleIn=false`, `InpUseRunnerTakeProfitExpansion=false`, `InpUseStartingEquityProtection=false`, `InpUseProfitOnlyRiskBoost=false`, and `InpUseEquityProfitLock=false`.
- Generated research profiles use `InpUseHotStreakRiskBoost=true`, `InpUseWinnerScaleIn=true`, `InpUseRunnerTakeProfitExpansion=true`, `InpUseStartingEquityProtection=true`, `InpUseProfitOnlyRiskBoost=true`, and `InpUseEquityProfitLock=true`.
- Generated research profiles are now designed to push upside harder only after recent realized average R turns strong, while keeping account-level risk floors active.

## Quiet Validation Results

- `work\test_price_action_strategy_modules.ps1`: PASS
- `work\sync_ea_source_artifacts.ps1`: PASS, hash `96006AA936C6EAF5AF35E4AF5A9036C92B79AE31A379848119E882728FA70A6A`
- `work\build_price_action_strategy_batch.ps1`: PASS, 10 profiles, 30 runs, estimated 10.5 minutes
- `work\test_ea_source_artifact_sync.ps1`: PASS
- `work\test_price_action_strategy_batch.ps1`: PASS
- `work\build_external_mt5_validation_package.ps1`: PASS
- `work\test_external_mt5_validation_package.ps1`: PASS, 26 checks, 0 failed
- `work\test_price_action_strategy_decision.ps1`: PASS
- `work\test_loss_streak_risk_reduction.ps1`: PASS
- `work\refresh_offline_validation_state.ps1`: PASS, 39 steps, 0 failed

## Latest Hashes

- `outputs\Professional_XAUUSD_EA.mq5`: `96006AA936C6EAF5AF35E4AF5A9036C92B79AE31A379848119E882728FA70A6A`
- `Professional_XAUUSD_EA.mq5`: `96006AA936C6EAF5AF35E4AF5A9036C92B79AE31A379848119E882728FA70A6A`
- `outputs\external_mt5_validation_package\source\Professional_XAUUSD_EA.mq5`: `96006AA936C6EAF5AF35E4AF5A9036C92B79AE31A379848119E882728FA70A6A`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `2C40FCD61BD8598F73898692BE5E201CFF20C14EA3FE96D7CB5A93D198AA98F8`
- `outputs\PRICE_ACTION_STRATEGY_BATCH.csv`: `91E0A6BC9E70F5BB87C9975973065D9EED0DDB27361291AC8F703DDEEFE83D91`
- `outputs\xauusd_micro_validation_package.zip`: `89F78D5051E6DE6FB204E79926EBA8429B0C5FEA4FCEDB300AACFCED38FB2CB1`
- `work\test_price_action_strategy_modules.ps1`: `11D5715D98EF7B0306F07FB3B8BF093F3D8C4DD7D28957DCAE54C138A9A589E8`
- `work\test_price_action_strategy_batch.ps1`: `A4F0EC27D090A0275BD584B916B919E904FEFA2CE4BAB5F403D06052843A6F7D`
- `work\build_price_action_strategy_batch.ps1`: `B88413D00458BC3F8CD0B5D6BC62CD39B9CA4A15831032E2D2C7E28868B67399`

## Background-Safety Note

The stop marker remains expected at `work\STOP_MT5_FOCUS_WATCHDOG`. Any future MT5 validation should be treated as external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The status note was committed through the GitHub connector. The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that the status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.
