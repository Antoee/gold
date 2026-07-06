# Recent 2026 Fast Triage Status

Updated: 2026-07-06

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- Full EA source exists locally, but this note is the GitHub-safe status/evidence artifact.

## Latest Strategy-Code Change

Added optional trend-regime risk boost for aggressive research profiles. This is a controlled upside mechanism meant to press stronger only when the market is already showing trend strength and volatility expansion:

- `InpUseTrendRegimeRiskBoost`
- `InpTrendRegimeBoostADX`
- `InpTrendRegimeBoostATRLookbackBars`
- `InpTrendRegimeBoostMinATRRatio`
- `InpTrendRegimeBoostFullATRRatio`
- `InpMaxTrendRegimeRiskMultiplier`
- `InpTrendRegimeBoostRequiresEquityProfit`
- `TrendRegimeRiskMultiplier()`
- Entry logging now records `Trend regime risk x...` when the boost actually applies.

The existing defensive `MarketPhaseRiskMultiplier()` still cannot boost above `1.0`; it remains a throttle for weaker phases. The new trend-regime boost is separate and defaults off in the base set. In aggressive research profiles it requires equity above starting equity, ADX >= 28.0, and current ATR expansion versus a 20-bar ATR average before scaling up toward a 1.50x cap.

The existing aggressive growth framework remains in place:

- Elite quality and price-action risk scaling can boost only when the account is above starting equity.
- Hot-streak risk boost can press harder only after recent closed-trade average R improves.
- Winner-only scale-in can add only to same-direction protected winners.
- Runner TP expansion stretches reward only for high-quality price-action setups.
- Starting-equity protection can halt/close risk at the configured floor.
- Equity profit lock can protect a configurable percentage of peak account profit.
- Protected-equity floor caps new trade risk so theoretical stop risk does not exceed the floor.
- Profit-only risk boost can increase risk only after account equity is already above the configured profit threshold.

The generated aggressive research profiles now use 2.50% base risk, elite setup quality risk scaling enabled from quality score 10 to 14 with 1.00x to 1.25x multiplier, elite price-action risk scaling enabled from PA score 12 to 18 with 1.00x to 1.35x multiplier, trend-regime risk boost enabled at ADX 28.0 and ATR ratio 1.05 to 1.50 with max 1.50x multiplier, all boost layers requiring equity above starting equity, hot-streak risk boost enabled over 4 recent trades, boost starts at +0.35 average R, full boost at +1.00 average R, max hot-streak multiplier 1.75, max 2 simultaneous positions, 6 max trades per day, 15-minute minimum trade spacing, winner scale-in enabled at 0.80R minimum open profit, protected stop required, quality score >= 10, 0.50 scale-in risk multiplier, 30-minute minimum since newest same-direction position, runner TP expansion enabled at quality score >= 12 and price-action score >= 14, 1.75 runner TP multiplier, trailing required for runner mode, starting-equity protection enabled at a 0.00% buffer, profit-only risk boost after +1.00% equity growth, full boost at +12.00%, max boost multiplier 3.00, equity profit lock after +2.00% peak equity growth, 50.0% peak-profit lock, 6.00% max equity drawdown, and 8.00% max open-risk cap. The baseline profile remains anchored at 1.60% risk with these aggressive boost features disabled.

This is intentionally more aggressive than the earlier conservative settings, but it still avoids martingale, grid, averaging down, and recovery mechanics. It is not proven profitable until a real MT5 backtest/forward-test report exists.

## Fast Batch Impact

- Batch size stayed at 10 profiles and 30 runs.
- Estimated tester runtime stayed at about 10.5 minutes before platform overhead.
- Baseline anchor keeps `InpUseTrendRegimeRiskBoost=false` plus the existing aggressive boost systems disabled.
- Generated research profiles use `InpUseTrendRegimeRiskBoost=true`, `InpTrendRegimeBoostADX=28.0`, `InpTrendRegimeBoostATRLookbackBars=20`, `InpTrendRegimeBoostMinATRRatio=1.05`, `InpTrendRegimeBoostFullATRRatio=1.50`, `InpMaxTrendRegimeRiskMultiplier=1.50`, and `InpTrendRegimeBoostRequiresEquityProfit=true`.
- Generated research profiles are designed to push upside harder only after signal quality, market regime, recent realized average R, and account equity state all justify it.

## Quiet Validation Results

- `work\test_price_action_strategy_modules.ps1`: PASS
- `work\sync_ea_source_artifacts.ps1`: PASS, hash `0F18F0C466D3D22CF6D58DD5888CE87ACE994907135D45AFD41D2D9DCB1E6054`
- `work\build_price_action_strategy_batch.ps1`: PASS, 10 profiles, 30 runs, estimated 10.5 minutes
- `work\test_ea_source_artifact_sync.ps1`: PASS
- `work\test_price_action_strategy_batch.ps1`: PASS
- `work\build_external_mt5_validation_package.ps1`: PASS
- `work\test_external_mt5_validation_package.ps1`: PASS, 26 checks, 0 failed
- `work\test_price_action_strategy_decision.ps1`: PASS
- `work\test_loss_streak_risk_reduction.ps1`: PASS
- `work\refresh_offline_validation_state.ps1`: PASS, 39 steps, 0 failed

## Latest Hashes

- `outputs\Professional_XAUUSD_EA.mq5`: `0F18F0C466D3D22CF6D58DD5888CE87ACE994907135D45AFD41D2D9DCB1E6054`
- `Professional_XAUUSD_EA.mq5`: `0F18F0C466D3D22CF6D58DD5888CE87ACE994907135D45AFD41D2D9DCB1E6054`
- `outputs\external_mt5_validation_package\source\Professional_XAUUSD_EA.mq5`: `0F18F0C466D3D22CF6D58DD5888CE87ACE994907135D45AFD41D2D9DCB1E6054`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `797799B3625BA1305A5CA8E695F8C69625D469D96E1CC1B0A19C4EC8298C8848`
- `outputs\PRICE_ACTION_STRATEGY_BATCH.csv`: `0632E5C8C014D35926BFD7C04B9C1EC8EF6F9EA251F0591D67DEC21DA89F3D1A`
- `outputs\xauusd_micro_validation_package.zip`: `46AFDE09B16ECAC1123D58ADA08B92D86410BA74A745C114D3DE3F31AD30204F`
- `work\test_price_action_strategy_modules.ps1`: `31D6A49C983093A67D4A5725DFBB038AF94C48BCF016A1F8A6E3DAAB6A547D06`
- `work\test_price_action_strategy_batch.ps1`: `912E6B1AA1C0AA9B2170009E55EC20985BEB827B1DDFBA1ED43C103D697C8482`
- `work\build_price_action_strategy_batch.ps1`: `809B4BA4AE9B56F75335CA3669969A35DBB4F3BD4F96B94B64B72B9A41D4B0D1`

## Background-Safety Note

The stop marker remains expected at `work\STOP_MT5_FOCUS_WATCHDOG`. Any future MT5 validation should be treated as external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The status note was committed through the GitHub connector. The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that the status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.
