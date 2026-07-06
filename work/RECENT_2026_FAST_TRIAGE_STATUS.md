# Recent 2026 Fast Triage Status

Updated: 2026-07-06

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- Full EA source exists locally, but this note is the GitHub-safe status/evidence artifact.

## Latest Strategy-Code Change

Added optional protected-floor pressure controls. This is a risk/profit stabilizer for the user goal of pushing upside while trying not to go red:

- `InpUseProtectedFloorRiskScaling`
- `InpProtectedFloorRiskStartPercent`
- `InpMinProtectedFloorRiskMultiplier`
- `InpUseProtectedFloorQualityGate`
- `InpProtectedFloorQualityStartPercent`
- `InpProtectedFloorMinQualityScore`
- `ProtectedFloorCushionPercent()` measures cushion above the active protected floor.
- `ProtectedFloorRiskMultiplier()` scales risk down as equity approaches the protected floor.
- `ProtectedFloorQualityAllows()` blocks lower-quality trades near the floor.
- Entry logging now records `Protected floor risk x...` when the throttle reduces risk.

The hard protected-floor cap still remains in `LotsForRisk()`: theoretical stop risk is capped so it should not exceed the active starting-equity/profit-lock floor. The new pressure controls begin acting before that hard cap is reached, so aggressive profiles can keep hunting for strong trades while reducing weaker or oversized exposure near the danger zone.

The existing aggressive growth framework remains in place:

- Elite quality and price-action risk scaling can boost only when the account is above starting equity.
- Hot-streak risk boost can press harder only after recent closed-trade average R improves.
- Winner-only scale-in can add only to same-direction protected winners.
- Runner TP expansion stretches reward only for high-quality price-action setups.
- Trend-regime risk boost can press strong ADX/ATR regimes.
- Trend-regime TP expansion can stretch reward further in strong ADX/ATR regimes.
- Starting-equity protection can halt/close risk at the configured floor.
- Equity profit lock can protect a configurable percentage of peak account profit.
- Protected-equity floor caps new trade risk so theoretical stop risk does not exceed the floor.
- Profit-only risk boost can increase risk only after account equity is already above the configured profit threshold.

The generated aggressive research profiles now use 2.50% base risk, elite setup quality risk scaling enabled from quality score 10 to 14 with 1.00x to 1.25x multiplier, elite price-action risk scaling enabled from PA score 12 to 18 with 1.00x to 1.35x multiplier, trend-regime risk boost enabled at ADX 28.0 and ATR ratio 1.05 to 1.50 with max 1.50x multiplier, trend-regime TP expansion enabled at quality score >= 12 and price-action score >= 14 with max 1.50x multiplier, protected-floor risk scaling enabled from a 4.0% cushion above the protected floor down to a 0.25x minimum multiplier, protected-floor quality gate enabled inside a 2.0% floor cushion with quality score >= 12 required, all boost/TP expansion layers requiring equity above starting equity, hot-streak risk boost enabled over 4 recent trades, boost starts at +0.35 average R, full boost at +1.00 average R, max hot-streak multiplier 1.75, max 2 simultaneous positions, 6 max trades per day, 15-minute minimum trade spacing, winner scale-in enabled at 0.80R minimum open profit, protected stop required, quality score >= 10, 0.50 scale-in risk multiplier, 30-minute minimum since newest same-direction position, runner TP expansion enabled at quality score >= 12 and price-action score >= 14, 1.75 runner TP multiplier, trailing required for runner mode, starting-equity protection enabled at a 0.00% buffer, profit-only risk boost after +1.00% equity growth, full boost at +12.00%, max boost multiplier 3.00, equity profit lock after +2.00% peak equity growth, 50.0% peak-profit lock, 6.00% max equity drawdown, and 8.00% max open-risk cap. The baseline profile remains anchored at 1.60% risk with these aggressive boost features disabled.

This is intentionally more aggressive than the earlier conservative settings, but it still avoids martingale, grid, averaging down, and recovery mechanics. It is not proven profitable until a real MT5 backtest/forward-test report exists.

## Fast Batch Impact

- Batch size stayed at 10 profiles and 30 runs.
- Estimated tester runtime stayed at about 10.5 minutes before platform overhead.
- Baseline anchor keeps `InpUseProtectedFloorRiskScaling=false`, `InpUseProtectedFloorQualityGate=false`, `InpUseTrendRegimeRiskBoost=false`, and `InpUseTrendRegimeTakeProfitExpansion=false` plus the existing aggressive boost systems disabled.
- Generated research profiles use `InpUseProtectedFloorRiskScaling=true`, `InpProtectedFloorRiskStartPercent=4.0`, `InpMinProtectedFloorRiskMultiplier=0.25`, `InpUseProtectedFloorQualityGate=true`, `InpProtectedFloorQualityStartPercent=2.0`, and `InpProtectedFloorMinQualityScore=12`.
- Generated research profiles use `InpUseTrendRegimeRiskBoost=true`, `InpTrendRegimeBoostADX=28.0`, `InpTrendRegimeBoostATRLookbackBars=20`, `InpTrendRegimeBoostMinATRRatio=1.05`, `InpTrendRegimeBoostFullATRRatio=1.50`, `InpMaxTrendRegimeRiskMultiplier=1.50`, and `InpTrendRegimeBoostRequiresEquityProfit=true`.
- Generated research profiles use `InpUseTrendRegimeTakeProfitExpansion=true`, `InpTrendRegimeTPMinQualityScore=12`, `InpTrendRegimeTPMinPriceActionScore=14`, `InpTrendRegimeTPMultiplier=1.50`, `InpTrendRegimeTPRequireTrailing=true`, and `InpTrendRegimeTPRequiresEquityProfit=true`.
- Generated research profiles are designed to push upside harder only after signal quality, market regime, recent realized average R, and account equity state all justify it, while reducing exposure near the protected floor.

## Quiet Validation Results

- `work\test_price_action_strategy_modules.ps1`: PASS
- `work\sync_ea_source_artifacts.ps1`: PASS, hash `BB0D2EC237FD044A4249866B618DBC943A2C252CF1FA5EA1037E02DBFA01017D`
- `work\build_price_action_strategy_batch.ps1`: PASS, 10 profiles, 30 runs, estimated 10.5 minutes
- `work\test_ea_source_artifact_sync.ps1`: PASS
- `work\test_price_action_strategy_batch.ps1`: PASS
- `work\build_external_mt5_validation_package.ps1`: PASS
- `work\test_external_mt5_validation_package.ps1`: PASS, 26 checks, 0 failed
- `work\test_price_action_strategy_decision.ps1`: PASS
- `work\test_loss_streak_risk_reduction.ps1`: PASS
- `work\refresh_offline_validation_state.ps1`: PASS, 39 steps, 0 failed

## Latest Hashes

- `outputs\Professional_XAUUSD_EA.mq5`: `BB0D2EC237FD044A4249866B618DBC943A2C252CF1FA5EA1037E02DBFA01017D`
- `Professional_XAUUSD_EA.mq5`: `BB0D2EC237FD044A4249866B618DBC943A2C252CF1FA5EA1037E02DBFA01017D`
- `outputs\external_mt5_validation_package\source\Professional_XAUUSD_EA.mq5`: `BB0D2EC237FD044A4249866B618DBC943A2C252CF1FA5EA1037E02DBFA01017D`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `0F1E787846E359DEF59B3B3C4C6C4DD9430EB1D207FC686DD7172BFC896282C1`
- `outputs\PRICE_ACTION_STRATEGY_BATCH.csv`: `B7CE9943D6777E97CC4CBD301D921109DC13DE401A467BFD7803ABBEF8B3B107`
- `outputs\xauusd_micro_validation_package.zip`: `9258B24B0AE03512E72BF3127313A2758DF1EAD7D89E9DA127878C70891050A3`
- `work\test_price_action_strategy_modules.ps1`: `E936A9A5DD11DB70DD013ACA5C4854A495E0D2E4B1763922D3C6965CDD94BF51`
- `work\test_price_action_strategy_batch.ps1`: `B738AEAE5EC91E9D833D841A5FA93D7E977B7FFD231B6A39643C069B4BAC55CA`
- `work\build_price_action_strategy_batch.ps1`: `1695C81B28EB6C85839A49CAA4BB37A8409F4E34E7686A805D222462FC30CCF5`

## Background-Safety Note

The stop marker remains expected at `work\STOP_MT5_FOCUS_WATCHDOG`. Any future MT5 validation should be treated as external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The status note was committed through the GitHub connector. The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that the status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.
