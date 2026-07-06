# Recent 2026 Fast Triage Status

Updated: 2026-07-06

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- Full EA source exists locally, but this note is the GitHub-safe status/evidence artifact.

## Latest Strategy-Code Change

Added optional trend-regime take-profit expansion for aggressive research profiles. This is a profit-seeking change that tries to get more from strong winners without increasing initial stop risk:

- `InpUseTrendRegimeTakeProfitExpansion`
- `InpTrendRegimeTPMinQualityScore`
- `InpTrendRegimeTPMinPriceActionScore`
- `InpTrendRegimeTPMultiplier`
- `InpTrendRegimeTPRequireTrailing`
- `InpTrendRegimeTPRequiresEquityProfit`
- `TrendRegimeBoostProgress()` centralizes the ADX/ATR expansion progress logic.
- `TrendRegimeTakeProfitMultiplier()` stretches TP only when quality, price-action score, trailing support, equity state, ADX, and ATR expansion all agree.
- Entry logging now records `Trend regime TP x...` when the TP expansion actually applies.

The previous trend-regime risk boost remains in place. The existing defensive `MarketPhaseRiskMultiplier()` still cannot boost above `1.0`; it remains a throttle for weaker phases. Trend-regime risk boost and trend-regime TP expansion both default off in the base set. In aggressive research profiles they require equity above starting equity, ADX >= 28.0, and current ATR expansion versus a 20-bar ATR average. Risk can scale toward a 1.50x cap, while TP can scale toward a 1.50x cap.

The existing aggressive growth framework remains in place:

- Elite quality and price-action risk scaling can boost only when the account is above starting equity.
- Hot-streak risk boost can press harder only after recent closed-trade average R improves.
- Winner-only scale-in can add only to same-direction protected winners.
- Runner TP expansion stretches reward only for high-quality price-action setups.
- Trend-regime TP expansion can stretch reward further in strong ADX/ATR regimes.
- Starting-equity protection can halt/close risk at the configured floor.
- Equity profit lock can protect a configurable percentage of peak account profit.
- Protected-equity floor caps new trade risk so theoretical stop risk does not exceed the floor.
- Profit-only risk boost can increase risk only after account equity is already above the configured profit threshold.

The generated aggressive research profiles now use 2.50% base risk, elite setup quality risk scaling enabled from quality score 10 to 14 with 1.00x to 1.25x multiplier, elite price-action risk scaling enabled from PA score 12 to 18 with 1.00x to 1.35x multiplier, trend-regime risk boost enabled at ADX 28.0 and ATR ratio 1.05 to 1.50 with max 1.50x multiplier, trend-regime TP expansion enabled at quality score >= 12 and price-action score >= 14 with max 1.50x multiplier, all boost/TP expansion layers requiring equity above starting equity, hot-streak risk boost enabled over 4 recent trades, boost starts at +0.35 average R, full boost at +1.00 average R, max hot-streak multiplier 1.75, max 2 simultaneous positions, 6 max trades per day, 15-minute minimum trade spacing, winner scale-in enabled at 0.80R minimum open profit, protected stop required, quality score >= 10, 0.50 scale-in risk multiplier, 30-minute minimum since newest same-direction position, runner TP expansion enabled at quality score >= 12 and price-action score >= 14, 1.75 runner TP multiplier, trailing required for runner mode, starting-equity protection enabled at a 0.00% buffer, profit-only risk boost after +1.00% equity growth, full boost at +12.00%, max boost multiplier 3.00, equity profit lock after +2.00% peak equity growth, 50.0% peak-profit lock, 6.00% max equity drawdown, and 8.00% max open-risk cap. The baseline profile remains anchored at 1.60% risk with these aggressive boost features disabled.

This is intentionally more aggressive than the earlier conservative settings, but it still avoids martingale, grid, averaging down, and recovery mechanics. It is not proven profitable until a real MT5 backtest/forward-test report exists.

## Fast Batch Impact

- Batch size stayed at 10 profiles and 30 runs.
- Estimated tester runtime stayed at about 10.5 minutes before platform overhead.
- Baseline anchor keeps `InpUseTrendRegimeRiskBoost=false` and `InpUseTrendRegimeTakeProfitExpansion=false` plus the existing aggressive boost systems disabled.
- Generated research profiles use `InpUseTrendRegimeRiskBoost=true`, `InpTrendRegimeBoostADX=28.0`, `InpTrendRegimeBoostATRLookbackBars=20`, `InpTrendRegimeBoostMinATRRatio=1.05`, `InpTrendRegimeBoostFullATRRatio=1.50`, `InpMaxTrendRegimeRiskMultiplier=1.50`, and `InpTrendRegimeBoostRequiresEquityProfit=true`.
- Generated research profiles use `InpUseTrendRegimeTakeProfitExpansion=true`, `InpTrendRegimeTPMinQualityScore=12`, `InpTrendRegimeTPMinPriceActionScore=14`, `InpTrendRegimeTPMultiplier=1.50`, `InpTrendRegimeTPRequireTrailing=true`, and `InpTrendRegimeTPRequiresEquityProfit=true`.
- Generated research profiles are designed to push upside harder only after signal quality, market regime, recent realized average R, and account equity state all justify it.

## Quiet Validation Results

- `work\test_price_action_strategy_modules.ps1`: PASS
- `work\sync_ea_source_artifacts.ps1`: PASS, hash `A558FF5D0FD4AC9E99A710B11FD78964EDC8492759CCC8B2D61AD51E65BC6EA0`
- `work\build_price_action_strategy_batch.ps1`: PASS, 10 profiles, 30 runs, estimated 10.5 minutes
- `work\test_ea_source_artifact_sync.ps1`: PASS
- `work\test_price_action_strategy_batch.ps1`: PASS
- `work\build_external_mt5_validation_package.ps1`: PASS
- `work\test_external_mt5_validation_package.ps1`: PASS, 26 checks, 0 failed
- `work\test_price_action_strategy_decision.ps1`: PASS
- `work\test_loss_streak_risk_reduction.ps1`: PASS
- `work\refresh_offline_validation_state.ps1`: PASS, 39 steps, 0 failed

## Latest Hashes

- `outputs\Professional_XAUUSD_EA.mq5`: `A558FF5D0FD4AC9E99A710B11FD78964EDC8492759CCC8B2D61AD51E65BC6EA0`
- `Professional_XAUUSD_EA.mq5`: `A558FF5D0FD4AC9E99A710B11FD78964EDC8492759CCC8B2D61AD51E65BC6EA0`
- `outputs\external_mt5_validation_package\source\Professional_XAUUSD_EA.mq5`: `A558FF5D0FD4AC9E99A710B11FD78964EDC8492759CCC8B2D61AD51E65BC6EA0`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `D280CB394C9E70A63C5E75AC687B7AAAD143ED877AE8B8CE650ACD462CD35036`
- `outputs\PRICE_ACTION_STRATEGY_BATCH.csv`: `4848937D9944F5B051A9D85F6608849F1FBF90DC2A5F140AD6EE877DE9F3F3F8`
- `outputs\xauusd_micro_validation_package.zip`: `D21E45D692C8126E89BDCB0C548179C784D46B34654324D883CB2A26A581FD60`
- `work\test_price_action_strategy_modules.ps1`: `D2A4DF074A569BAEB3A55BBBC9C235F1AD8BFFEB0CA31576A3591B9E4FB72A9A`
- `work\test_price_action_strategy_batch.ps1`: `6EF9F3BF6FD6618F15E807AF2414F093D901C8741AB529268F925545E123725E`
- `work\build_price_action_strategy_batch.ps1`: `972FAD6E58789C1584426366521E04E9C6390C1F93E0248C769BAF9DED4DB7A9`

## Background-Safety Note

The stop marker remains expected at `work\STOP_MT5_FOCUS_WATCHDOG`. Any future MT5 validation should be treated as external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The status note was committed through the GitHub connector. The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that the status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.
