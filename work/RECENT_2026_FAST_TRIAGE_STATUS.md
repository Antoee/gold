# Recent 2026 Fast Triage Status

Updated: 2026-07-06

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- Full EA source exists locally, but this note is the GitHub-safe status/evidence artifact.

## Latest Strategy-Code Change

Added hour-of-day performance risk scaling. This lets the EA adapt risk by broker/server hour using closed trade history from that same hour.

New inputs and logic:

- `InpUseHourPerformanceRiskScaling`
- `InpHourPerformanceLookbackDays`
- `InpHourPerformanceMinTrades`
- `InpHourPerformanceWeakNetPercent`
- `InpHourPerformanceStrongNetPercent`
- `InpMinHourPerformanceRiskMultiplier`
- `InpMaxHourPerformanceRiskMultiplier`
- `InpHourPerformanceBoostRequiresClosedProfit`
- `HourPerformanceSample()` collects same-hour closed-trade net profit from recent account history.
- `HourPerformanceRiskMultiplier()` throttles risk in weak hours and can modestly boost strong hours when closed-profit protection allows it.
- `OpenSignal()` now multiplies this into order risk and logs `Hour performance risk x...` on entries.

This is meant to pursue more profit selectively: press times of day that have actually worked, reduce risk during hours that have recently lost money, and avoid boosting unless closed profit exists when that guard is enabled. It adds no martingale, grid, averaging down, or recovery behavior.

## Fast Batch Impact

- Batch size stayed at 10 profiles and 30 runs.
- Estimated tester runtime stayed at about 10.5 minutes before platform overhead.
- Baseline anchor keeps `InpUseHourPerformanceRiskScaling=false`.
- Generated research profiles use:
  - `InpUseHourPerformanceRiskScaling=true`
  - `InpHourPerformanceLookbackDays=45`
  - `InpHourPerformanceMinTrades=4`
  - `InpHourPerformanceWeakNetPercent=-0.10`
  - `InpHourPerformanceStrongNetPercent=0.25`
  - `InpMinHourPerformanceRiskMultiplier=0.50`
  - `InpMaxHourPerformanceRiskMultiplier=1.25`
  - `InpHourPerformanceBoostRequiresClosedProfit=true`

## Quiet Validation Results

- `work\test_price_action_strategy_modules.ps1`: PASS
- `work\sync_ea_source_artifacts.ps1`: PASS, hash `242669C427652AA9AA837B9A67A7EFE2402E81642B833591E34879F150ADE496`
- `work\build_price_action_strategy_batch.ps1`: PASS, 10 profiles, 30 runs, estimated 10.5 minutes
- `work\test_price_action_strategy_decision.ps1`: PASS
- `work\test_loss_streak_risk_reduction.ps1`: PASS
- `work\test_ea_source_artifact_sync.ps1`: PASS
- `work\test_price_action_strategy_batch.ps1`: PASS
- `work\build_external_mt5_validation_package.ps1`: PASS, package configs 20, profiles 9
- `work\test_external_mt5_validation_package.ps1`: PASS, 26 checks, 0 failed
- `work\refresh_offline_validation_state.ps1`: PASS, 40 steps, 0 failed
- MT5-family process scan: empty

## Latest Hashes

- `outputs\Professional_XAUUSD_EA.mq5`: `242669C427652AA9AA837B9A67A7EFE2402E81642B833591E34879F150ADE496`
- `Professional_XAUUSD_EA.mq5`: `242669C427652AA9AA837B9A67A7EFE2402E81642B833591E34879F150ADE496`
- `outputs\external_mt5_validation_package\source\Professional_XAUUSD_EA.mq5`: `242669C427652AA9AA837B9A67A7EFE2402E81642B833591E34879F150ADE496`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `4C5ECE96CDCDCFFCC42E2A285367E312C93A268DD3BE3AA5766A54D44025AB8F`
- `outputs\PRICE_ACTION_STRATEGY_BATCH.csv`: `6887C7B2EE4D4D91A5BB05D817F303AA608F807C276142686247ED0AB5998D99`
- `outputs\xauusd_micro_validation_package.zip`: `A0A67B9BA3CF77F279EFB9060CBDA28E19AA5B76294875896B85F6F9FB59BC92`
- `work\build_price_action_strategy_batch.ps1`: `FCE2FE0A128C1EEACE5BA70E877BC596A1C742522C5A8D6225C9FF3EE9D146CC`
- `work\test_price_action_strategy_modules.ps1`: `A655B58ACE1D8758DE5996DF3FD5C24F7D5F829B5273673FCA589FB8B8595488`
- `outputs\OFFLINE_VALIDATION_REFRESH.csv`: `830865B5A4BDE91413F1BC4C8C4F86E2D73B7E5F6D3324FD73B440AFB8891A69`

## Background-Safety Note

The stop marker remains expected at `work\STOP_MT5_FOCUS_WATCHDOG`. Any future MT5 validation should be treated as external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The status note is committed through the GitHub connector. The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that the status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.