# Recent 2026 Fast Triage Status

Updated: 2026-07-06

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- Full EA source exists locally, but this note is the GitHub-safe status/evidence artifact.

## Latest Strategy-Code Change

Added optional protected-cushion risk boost. This is an adaptive aggression layer that can increase risk only when there is meaningful equity cushion above the active protected floor:

- `InpUseProtectedCushionRiskBoost`
- `InpProtectedCushionBoostStartPercent`
- `InpProtectedCushionBoostFullPercent`
- `InpMaxProtectedCushionBoostMultiplier`
- `ProtectedCushionRiskBoostMultiplier()` reads cushion above `ProtectedEquityFloor()` and scales risk only when the cushion is above the configured start threshold.
- `EffectiveRiskPercent()` now applies this multiplier after the existing profit-only boost logic.

Aggressive research profiles enable this from a 6.0% protected-floor cushion to an 18.0% cushion, with a max 1.50x multiplier. The baseline profile keeps it disabled. The existing hard floor, protected-cushion per-trade cap, and protected-floor pressure throttle still apply, so this boost is intended to use house-money cushion rather than weaken the floor.

The existing winner-management and protected-floor framework remains in place:

- `InpWinnerScaleInMinLockedR` requires protected profit before scale-ins.
- `InpUseMFEProfitLockStop` can ratchet stops on strong open winners.
- `LotsForRisk()` caps theoretical stop risk so it should not exceed the active starting-equity/profit-lock floor.
- `InpUseProtectedFloorCushionRiskCap` limits each trade to a fraction of the cushion above the protected floor.
- `ProtectedFloorRiskMultiplier()` scales risk down as equity approaches the protected floor.
- `ProtectedFloorQualityAllows()` blocks lower-quality trades near the floor.

The existing aggressive growth framework remains in place:

- Elite quality and price-action risk scaling can boost only when the account is above starting equity.
- Hot-streak risk boost can press harder only after recent closed-trade average R improves.
- Protected-cushion risk boost can press only when equity has cushion above the protected floor.
- Winner-only scale-in can add only to same-direction protected winners with enough locked profit.
- Runner TP expansion stretches reward only for high-quality price-action setups.
- MFE profit-lock stop ratchets stops on strong open winners.
- Trend-regime risk boost can press strong ADX/ATR regimes.
- Trend-regime TP expansion can stretch reward further in strong ADX/ATR regimes.
- Starting-equity protection can halt/close risk at the configured floor.
- Equity profit lock can protect a configurable percentage of peak account profit.
- Protected-equity floor caps new trade risk so theoretical stop risk does not exceed the floor.
- Protected-cushion risk cap limits each trade to a fraction of that cushion.
- Profit-only risk boost can increase risk only after account equity is already above the configured profit threshold.

The generated aggressive research profiles now use 2.50% base risk, elite setup quality risk scaling enabled from quality score 10 to 14 with 1.00x to 1.25x multiplier, elite price-action risk scaling enabled from PA score 12 to 18 with 1.00x to 1.35x multiplier, protected-cushion risk boost enabled from 6.0% to 18.0% cushion with max 1.50x multiplier, winner scale-in enabled only when same-direction exposure is already profitable, protected by stop, quality score >= 10, current open profit >= 0.80R, locked/protected profit >= 0.25R, 0.50 scale-in risk multiplier, and 30-minute minimum since newest same-direction position, MFE profit-lock stop enabled at 1.50R MFE, 0.75R giveback, 0.35R minimum lock, trend-regime risk boost enabled at ADX 28.0 and ATR ratio 1.05 to 1.50 with max 1.50x multiplier, trend-regime TP expansion enabled at quality score >= 12 and price-action score >= 14 with max 1.50x multiplier, protected-floor risk scaling enabled from a 4.0% cushion above the protected floor down to a 0.25x minimum multiplier, protected-floor cushion cap enabled at 35.0% max cushion risk per trade, protected-floor quality gate enabled inside a 2.0% floor cushion with quality score >= 12 required, all boost/TP expansion layers requiring equity above starting equity, hot-streak risk boost enabled over 4 recent trades, boost starts at +0.35 average R, full boost at +1.00 average R, max hot-streak multiplier 1.75, max 2 simultaneous positions, 6 max trades per day, 15-minute minimum trade spacing, runner TP expansion enabled at quality score >= 12 and price-action score >= 14, 1.75 runner TP multiplier, trailing required for runner mode, starting-equity protection enabled at a 0.00% buffer, profit-only risk boost after +1.00% equity growth, full boost at +12.00%, max boost multiplier 3.00, equity profit lock after +2.00% peak equity growth, 50.0% peak-profit lock, 6.00% max equity drawdown, and 8.00% max open-risk cap. The baseline profile remains anchored at 1.60% risk with these aggressive boost features disabled.

This is intentionally more aggressive than the earlier conservative settings, but it still avoids martingale, grid, averaging down, and recovery mechanics. It is not proven profitable until a real MT5 backtest/forward-test report exists.

## Fast Batch Impact

- Batch size stayed at 10 profiles and 30 runs.
- Estimated tester runtime stayed at about 10.5 minutes before platform overhead.
- Baseline anchor keeps `InpUseProtectedCushionRiskBoost=false`, `InpUseWinnerScaleIn=false`, `InpWinnerScaleInMinLockedR=0.00`, `InpUseMFEProfitLockStop=false`, `InpUseProtectedFloorRiskScaling=false`, `InpUseProtectedFloorCushionRiskCap=false`, `InpUseProtectedFloorQualityGate=false`, `InpUseTrendRegimeRiskBoost=false`, and `InpUseTrendRegimeTakeProfitExpansion=false` plus the existing aggressive boost systems disabled.
- Generated research profiles use `InpUseProtectedCushionRiskBoost=true`, `InpProtectedCushionBoostStartPercent=6.0`, `InpProtectedCushionBoostFullPercent=18.0`, and `InpMaxProtectedCushionBoostMultiplier=1.50`.
- Generated research profiles use `InpUseWinnerScaleIn=true`, `InpWinnerScaleInMinProfitR=0.80`, `InpWinnerScaleInRequireProtectedStop=true`, `InpWinnerScaleInMinLockedR=0.25`, `InpWinnerScaleInMinQualityScore=10`, `InpWinnerScaleInRiskMultiplier=0.50`, and `InpWinnerScaleInMinMinutesSincePosition=30`.
- Generated research profiles use `InpUseMFEProfitLockStop=true`, `InpMFEProfitLockStartR=1.50`, `InpMFEProfitLockGivebackR=0.75`, and `InpMFEProfitLockMinR=0.35`.
- Generated research profiles use `InpUseProtectedFloorRiskScaling=true`, `InpProtectedFloorRiskStartPercent=4.0`, `InpMinProtectedFloorRiskMultiplier=0.25`, `InpUseProtectedFloorCushionRiskCap=true`, `InpMaxProtectedFloorCushionRiskPercent=35.0`, `InpUseProtectedFloorQualityGate=true`, `InpProtectedFloorQualityStartPercent=2.0`, and `InpProtectedFloorMinQualityScore=12`.
- Generated research profiles are designed to push upside harder only after signal quality, market regime, realized/open trade strength, protected-floor cushion, and account equity state all justify it, while reducing exposure near the protected floor.

## Quiet Validation Results

- `work\test_price_action_strategy_modules.ps1`: PASS
- `work\sync_ea_source_artifacts.ps1`: PASS, hash `DCE0586CFE1835B6F21C5DB81476C75AB810C893B7AB79FCFCE281BFF7BF420D`
- `work\build_price_action_strategy_batch.ps1`: PASS, 10 profiles, 30 runs, estimated 10.5 minutes
- `work\test_ea_source_artifact_sync.ps1`: PASS
- `work\test_price_action_strategy_batch.ps1`: PASS
- `work\build_external_mt5_validation_package.ps1`: PASS
- `work\test_external_mt5_validation_package.ps1`: PASS, 26 checks, 0 failed
- `work\test_price_action_strategy_decision.ps1`: PASS
- `work\test_loss_streak_risk_reduction.ps1`: PASS
- `work\refresh_offline_validation_state.ps1`: PASS, 39 steps, 0 failed

## Latest Hashes

- `outputs\Professional_XAUUSD_EA.mq5`: `DCE0586CFE1835B6F21C5DB81476C75AB810C893B7AB79FCFCE281BFF7BF420D`
- `Professional_XAUUSD_EA.mq5`: `DCE0586CFE1835B6F21C5DB81476C75AB810C893B7AB79FCFCE281BFF7BF420D`
- `outputs\external_mt5_validation_package\source\Professional_XAUUSD_EA.mq5`: `DCE0586CFE1835B6F21C5DB81476C75AB810C893B7AB79FCFCE281BFF7BF420D`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `E2F43934DA504AE3F218341DF3AFCB2D6C197CFF088A9D402EE561E182CE76D9`
- `outputs\PRICE_ACTION_STRATEGY_BATCH.csv`: `6887C7B2EE4D4D91A5BB05D817F303AA608F807C276142686247ED0AB5998D99`
- `outputs\xauusd_micro_validation_package.zip`: `E49CF22CB521EB6AD9939D608296CEAF61192E2BB6B429B785904989A725A2CF`
- `work\test_price_action_strategy_modules.ps1`: `655C224BF36F569961E37679845189F39FF4D753C61E6906879F6A791FCEA8EA`
- `work\test_price_action_strategy_batch.ps1`: `7A1EDCB9BD28745EF64E6C3A3645868AA3DD008DBCCDCC259A8D0EF039BF57A2`
- `work\build_price_action_strategy_batch.ps1`: `F3E4793B808F58A9A7C416E4CF5C4E87842FFC68782BDFA9DE25625CD4679AFB`

## Background-Safety Note

The stop marker remains expected at `work\STOP_MT5_FOCUS_WATCHDOG`. Any future MT5 validation should be treated as external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The status note was committed through the GitHub connector. The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that the status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.
