# Recent 2026 Fast Triage Status

Updated: 2026-07-06

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- Full EA source exists locally, but this note is the GitHub-safe status/evidence artifact.

## Latest Strategy-Code Change

Added optional MFE profit-lock stop for strong open winners. This is a winner-management feature that tries to protect part of a trade's max favorable move while still letting the position run:

- `InpUseMFEProfitLockStop`
- `InpMFEProfitLockStartR`
- `InpMFEProfitLockGivebackR`
- `InpMFEProfitLockMinR`
- Position management now moves stop loss into protected profit once max favorable excursion reaches the configured R threshold.
- The protected stop locks at least `InpMFEProfitLockMinR`, or `maxFavorableR - InpMFEProfitLockGivebackR`, whichever is greater.

Aggressive research profiles enable this at `1.50R` MFE start, `0.75R` allowed giveback, and `0.35R` minimum locked profit. The baseline profile keeps it disabled. This differs from the existing MFE giveback exit: the new feature ratchets the stop, so the trade can keep running while downside on an already-winning open trade is reduced.

The existing protected-floor system remains in place:

- `LotsForRisk()` caps theoretical stop risk so it should not exceed the active starting-equity/profit-lock floor.
- `InpUseProtectedFloorCushionRiskCap` limits each trade to a fraction of the cushion above the protected floor.
- `ProtectedFloorRiskMultiplier()` scales risk down as equity approaches the protected floor.
- `ProtectedFloorQualityAllows()` blocks lower-quality trades near the floor.

The existing aggressive growth framework remains in place:

- Elite quality and price-action risk scaling can boost only when the account is above starting equity.
- Hot-streak risk boost can press harder only after recent closed-trade average R improves.
- Winner-only scale-in can add only to same-direction protected winners.
- Runner TP expansion stretches reward only for high-quality price-action setups.
- MFE profit-lock stop ratchets stops on strong open winners.
- Trend-regime risk boost can press strong ADX/ATR regimes.
- Trend-regime TP expansion can stretch reward further in strong ADX/ATR regimes.
- Starting-equity protection can halt/close risk at the configured floor.
- Equity profit lock can protect a configurable percentage of peak account profit.
- Protected-equity floor caps new trade risk so theoretical stop risk does not exceed the floor.
- Protected-cushion risk cap limits each trade to a fraction of that cushion.
- Profit-only risk boost can increase risk only after account equity is already above the configured profit threshold.

The generated aggressive research profiles now use 2.50% base risk, elite setup quality risk scaling enabled from quality score 10 to 14 with 1.00x to 1.25x multiplier, elite price-action risk scaling enabled from PA score 12 to 18 with 1.00x to 1.35x multiplier, MFE profit-lock stop enabled at 1.50R MFE, 0.75R giveback, 0.35R minimum lock, trend-regime risk boost enabled at ADX 28.0 and ATR ratio 1.05 to 1.50 with max 1.50x multiplier, trend-regime TP expansion enabled at quality score >= 12 and price-action score >= 14 with max 1.50x multiplier, protected-floor risk scaling enabled from a 4.0% cushion above the protected floor down to a 0.25x minimum multiplier, protected-floor cushion cap enabled at 35.0% max cushion risk per trade, protected-floor quality gate enabled inside a 2.0% floor cushion with quality score >= 12 required, all boost/TP expansion layers requiring equity above starting equity, hot-streak risk boost enabled over 4 recent trades, boost starts at +0.35 average R, full boost at +1.00 average R, max hot-streak multiplier 1.75, max 2 simultaneous positions, 6 max trades per day, 15-minute minimum trade spacing, winner scale-in enabled at 0.80R minimum open profit, protected stop required, quality score >= 10, 0.50 scale-in risk multiplier, 30-minute minimum since newest same-direction position, runner TP expansion enabled at quality score >= 12 and price-action score >= 14, 1.75 runner TP multiplier, trailing required for runner mode, starting-equity protection enabled at a 0.00% buffer, profit-only risk boost after +1.00% equity growth, full boost at +12.00%, max boost multiplier 3.00, equity profit lock after +2.00% peak equity growth, 50.0% peak-profit lock, 6.00% max equity drawdown, and 8.00% max open-risk cap. The baseline profile remains anchored at 1.60% risk with these aggressive boost features disabled.

This is intentionally more aggressive than the earlier conservative settings, but it still avoids martingale, grid, averaging down, and recovery mechanics. It is not proven profitable until a real MT5 backtest/forward-test report exists.

## Fast Batch Impact

- Batch size stayed at 10 profiles and 30 runs.
- Estimated tester runtime stayed at about 10.5 minutes before platform overhead.
- Baseline anchor keeps `InpUseMFEProfitLockStop=false`, `InpUseProtectedFloorRiskScaling=false`, `InpUseProtectedFloorCushionRiskCap=false`, `InpUseProtectedFloorQualityGate=false`, `InpUseTrendRegimeRiskBoost=false`, and `InpUseTrendRegimeTakeProfitExpansion=false` plus the existing aggressive boost systems disabled.
- Generated research profiles use `InpUseMFEProfitLockStop=true`, `InpMFEProfitLockStartR=1.50`, `InpMFEProfitLockGivebackR=0.75`, and `InpMFEProfitLockMinR=0.35`.
- Generated research profiles use `InpUseProtectedFloorRiskScaling=true`, `InpProtectedFloorRiskStartPercent=4.0`, `InpMinProtectedFloorRiskMultiplier=0.25`, `InpUseProtectedFloorCushionRiskCap=true`, `InpMaxProtectedFloorCushionRiskPercent=35.0`, `InpUseProtectedFloorQualityGate=true`, `InpProtectedFloorQualityStartPercent=2.0`, and `InpProtectedFloorMinQualityScore=12`.
- Generated research profiles use `InpUseTrendRegimeRiskBoost=true`, `InpTrendRegimeBoostADX=28.0`, `InpTrendRegimeBoostATRLookbackBars=20`, `InpTrendRegimeBoostMinATRRatio=1.05`, `InpTrendRegimeBoostFullATRRatio=1.50`, `InpMaxTrendRegimeRiskMultiplier=1.50`, and `InpTrendRegimeBoostRequiresEquityProfit=true`.
- Generated research profiles use `InpUseTrendRegimeTakeProfitExpansion=true`, `InpTrendRegimeTPMinQualityScore=12`, `InpTrendRegimeTPMinPriceActionScore=14`, `InpTrendRegimeTPMultiplier=1.50`, `InpTrendRegimeTPRequireTrailing=true`, and `InpTrendRegimeTPRequiresEquityProfit=true`.
- Generated research profiles are designed to push upside harder only after signal quality, market regime, recent realized average R, and account equity state all justify it, while reducing exposure near the protected floor.

## Quiet Validation Results

- `work\test_price_action_strategy_modules.ps1`: PASS
- `work\sync_ea_source_artifacts.ps1`: PASS, hash `19A6E184D22D804859A80C075D2DDAEEAC95536B4FA8033F618DE4FB3F2EFDEC`
- `work\build_price_action_strategy_batch.ps1`: PASS, 10 profiles, 30 runs, estimated 10.5 minutes
- `work\test_ea_source_artifact_sync.ps1`: PASS
- `work\test_price_action_strategy_batch.ps1`: PASS
- `work\build_external_mt5_validation_package.ps1`: PASS
- `work\test_external_mt5_validation_package.ps1`: PASS, 26 checks, 0 failed
- `work\test_price_action_strategy_decision.ps1`: PASS
- `work\test_loss_streak_risk_reduction.ps1`: PASS
- `work\refresh_offline_validation_state.ps1`: PASS, 39 steps, 0 failed

## Latest Hashes

- `outputs\Professional_XAUUSD_EA.mq5`: `19A6E184D22D804859A80C075D2DDAEEAC95536B4FA8033F618DE4FB3F2EFDEC`
- `Professional_XAUUSD_EA.mq5`: `19A6E184D22D804859A80C075D2DDAEEAC95536B4FA8033F618DE4FB3F2EFDEC`
- `outputs\external_mt5_validation_package\source\Professional_XAUUSD_EA.mq5`: `19A6E184D22D804859A80C075D2DDAEEAC95536B4FA8033F618DE4FB3F2EFDEC`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `2B2AD7C8B0F155A982AAA42416160E1475F15F8C84349D474F4F4B8BE8ED2745`
- `outputs\PRICE_ACTION_STRATEGY_BATCH.csv`: `224D3AF4E40DC394F1ABAB6343C53F35F4B4AB60D9248349C1A42584AF65FD2A`
- `outputs\xauusd_micro_validation_package.zip`: `E3AD85CC3F4D2DB55773B6996B9F1AF1EA1E1DE782798D135F808F8D7FDEC2F4`
- `work\test_price_action_strategy_modules.ps1`: `636FC0DC00BA8D8A0518EDD2238FABCF25C124B6DE672739971A597457743AB4`
- `work\test_price_action_strategy_batch.ps1`: `BED402E2731CC89E90B504E34BC1FE9C2B47242D9153A042FC7EF3A27288F242`
- `work\build_price_action_strategy_batch.ps1`: `5BF227DDE38E2520B87E560069E12F6912935BD000AAC498C71001B264171819`

## Background-Safety Note

The stop marker remains expected at `work\STOP_MT5_FOCUS_WATCHDOG`. Any future MT5 validation should be treated as external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The status note was committed through the GitHub connector. The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that the status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.
