# Recent 2026 Fast Triage Status

Updated: 2026-07-06

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- Full EA source exists locally, but this note is the GitHub-safe status/evidence artifact.

## Latest Strategy-Code Change

Added optional locked-profit requirement for winner scale-ins. This tightens the aggressive add-on logic so extra positions require the existing same-direction winner to have real protected profit, not only floating profit:

- `InpWinnerScaleInMinLockedR`
- `WinnerScaleInAllows()` now calculates protected locked R from the existing position stop loss versus open price.
- If `InpWinnerScaleInMinLockedR > 0.0`, scale-in is blocked with `winner scale-in locked R` until the existing position has enough stop-protected profit.

Aggressive research profiles now require `0.25R` locked/protected profit before allowing a winner scale-in. The baseline profile keeps this at `0.00`, with winner scale-in disabled. This keeps the upside tool, but makes add-ons more dependent on actual protected trade progress.

The existing winner-management and protected-floor framework remains in place:

- `InpUseMFEProfitLockStop` can ratchet stops on strong open winners.
- `LotsForRisk()` caps theoretical stop risk so it should not exceed the active starting-equity/profit-lock floor.
- `InpUseProtectedFloorCushionRiskCap` limits each trade to a fraction of the cushion above the protected floor.
- `ProtectedFloorRiskMultiplier()` scales risk down as equity approaches the protected floor.
- `ProtectedFloorQualityAllows()` blocks lower-quality trades near the floor.

The existing aggressive growth framework remains in place:

- Elite quality and price-action risk scaling can boost only when the account is above starting equity.
- Hot-streak risk boost can press harder only after recent closed-trade average R improves.
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

The generated aggressive research profiles now use 2.50% base risk, elite setup quality risk scaling enabled from quality score 10 to 14 with 1.00x to 1.25x multiplier, elite price-action risk scaling enabled from PA score 12 to 18 with 1.00x to 1.35x multiplier, winner scale-in enabled only when same-direction exposure is already profitable, protected by stop, quality score >= 10, current open profit >= 0.80R, locked/protected profit >= 0.25R, 0.50 scale-in risk multiplier, and 30-minute minimum since newest same-direction position, MFE profit-lock stop enabled at 1.50R MFE, 0.75R giveback, 0.35R minimum lock, trend-regime risk boost enabled at ADX 28.0 and ATR ratio 1.05 to 1.50 with max 1.50x multiplier, trend-regime TP expansion enabled at quality score >= 12 and price-action score >= 14 with max 1.50x multiplier, protected-floor risk scaling enabled from a 4.0% cushion above the protected floor down to a 0.25x minimum multiplier, protected-floor cushion cap enabled at 35.0% max cushion risk per trade, protected-floor quality gate enabled inside a 2.0% floor cushion with quality score >= 12 required, all boost/TP expansion layers requiring equity above starting equity, hot-streak risk boost enabled over 4 recent trades, boost starts at +0.35 average R, full boost at +1.00 average R, max hot-streak multiplier 1.75, max 2 simultaneous positions, 6 max trades per day, 15-minute minimum trade spacing, runner TP expansion enabled at quality score >= 12 and price-action score >= 14, 1.75 runner TP multiplier, trailing required for runner mode, starting-equity protection enabled at a 0.00% buffer, profit-only risk boost after +1.00% equity growth, full boost at +12.00%, max boost multiplier 3.00, equity profit lock after +2.00% peak equity growth, 50.0% peak-profit lock, 6.00% max equity drawdown, and 8.00% max open-risk cap. The baseline profile remains anchored at 1.60% risk with these aggressive boost features disabled.

This is intentionally more aggressive than the earlier conservative settings, but it still avoids martingale, grid, averaging down, and recovery mechanics. It is not proven profitable until a real MT5 backtest/forward-test report exists.

## Fast Batch Impact

- Batch size stayed at 10 profiles and 30 runs.
- Estimated tester runtime stayed at about 10.5 minutes before platform overhead.
- Baseline anchor keeps `InpUseWinnerScaleIn=false`, `InpWinnerScaleInMinLockedR=0.00`, `InpUseMFEProfitLockStop=false`, `InpUseProtectedFloorRiskScaling=false`, `InpUseProtectedFloorCushionRiskCap=false`, `InpUseProtectedFloorQualityGate=false`, `InpUseTrendRegimeRiskBoost=false`, and `InpUseTrendRegimeTakeProfitExpansion=false` plus the existing aggressive boost systems disabled.
- Generated research profiles use `InpUseWinnerScaleIn=true`, `InpWinnerScaleInMinProfitR=0.80`, `InpWinnerScaleInRequireProtectedStop=true`, `InpWinnerScaleInMinLockedR=0.25`, `InpWinnerScaleInMinQualityScore=10`, `InpWinnerScaleInRiskMultiplier=0.50`, and `InpWinnerScaleInMinMinutesSincePosition=30`.
- Generated research profiles use `InpUseMFEProfitLockStop=true`, `InpMFEProfitLockStartR=1.50`, `InpMFEProfitLockGivebackR=0.75`, and `InpMFEProfitLockMinR=0.35`.
- Generated research profiles use `InpUseProtectedFloorRiskScaling=true`, `InpProtectedFloorRiskStartPercent=4.0`, `InpMinProtectedFloorRiskMultiplier=0.25`, `InpUseProtectedFloorCushionRiskCap=true`, `InpMaxProtectedFloorCushionRiskPercent=35.0`, `InpUseProtectedFloorQualityGate=true`, `InpProtectedFloorQualityStartPercent=2.0`, and `InpProtectedFloorMinQualityScore=12`.
- Generated research profiles are designed to push upside harder only after signal quality, market regime, realized/open trade strength, and account equity state all justify it, while reducing exposure near the protected floor.

## Quiet Validation Results

- `work\test_price_action_strategy_modules.ps1`: PASS
- `work\sync_ea_source_artifacts.ps1`: PASS, hash `0884022700A3F8B022D67AAEEEA6550E2006CA8985EFAE0CBE5597B3BEB5014E`
- `work\build_price_action_strategy_batch.ps1`: PASS, 10 profiles, 30 runs, estimated 10.5 minutes
- `work\test_ea_source_artifact_sync.ps1`: PASS
- `work\test_price_action_strategy_batch.ps1`: PASS
- `work\build_external_mt5_validation_package.ps1`: PASS
- `work\test_external_mt5_validation_package.ps1`: PASS, 26 checks, 0 failed
- `work\test_price_action_strategy_decision.ps1`: PASS
- `work\test_loss_streak_risk_reduction.ps1`: PASS
- `work\refresh_offline_validation_state.ps1`: PASS, 39 steps, 0 failed

## Latest Hashes

- `outputs\Professional_XAUUSD_EA.mq5`: `0884022700A3F8B022D67AAEEEA6550E2006CA8985EFAE0CBE5597B3BEB5014E`
- `Professional_XAUUSD_EA.mq5`: `0884022700A3F8B022D67AAEEEA6550E2006CA8985EFAE0CBE5597B3BEB5014E`
- `outputs\external_mt5_validation_package\source\Professional_XAUUSD_EA.mq5`: `0884022700A3F8B022D67AAEEEA6550E2006CA8985EFAE0CBE5597B3BEB5014E`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `7D919C87834BCB0D870A23A3174CFEF147EC7AB049A0BFBB08FC565CC7E5785D`
- `outputs\PRICE_ACTION_STRATEGY_BATCH.csv`: `FE26B5345B82D8894DD5311112425F41DDF274E1BB6FADB0B0EA807BCA2C04C0`
- `outputs\xauusd_micro_validation_package.zip`: `2D675959A6AEDA96972BCF85DC0E3D770034E1D9FFF69A2E3E33AE4CE7E93C11`
- `work\test_price_action_strategy_modules.ps1`: `7F2FF4A3E2CC9BC7C9B8B1FAACF304A6572A77EBDCE888EFE8AC5D4512E0E529`
- `work\test_price_action_strategy_batch.ps1`: `F9D80270C53A1A33A71AE6A7237C6BF1344D98F75E59FE0C3F012240E04DA2B8`
- `work\build_price_action_strategy_batch.ps1`: `319E2CA2EA67456FCFCB1382908EB4055E57CA327B8ABB58829FDB03A64DDD0A`

## Background-Safety Note

The stop marker remains expected at `work\STOP_MT5_FOCUS_WATCHDOG`. Any future MT5 validation should be treated as external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The status note was committed through the GitHub connector. The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that the status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.
