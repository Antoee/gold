# Recent 2026 Fast Triage Status

Updated: 2026-07-07 19:50:30 -05:00

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- Full EA source exists locally, but this note is the GitHub-safe status/evidence artifact.

## Latest Strategy-Code Change

Added protected runner exit patience to the EA source and enabled it in the protected-aggression research profile. This is a better-logic profit-seeking feature, not just a bigger-risk setting: it gives already-protected winners more room only when the account is in house-money mode, trend-regime conditions are present, and current continuation structure still supports the trade.

Follow-up after reviewing the GitHub-visible `$866.59` / 2.5-year result: that result is not enough for the stated goal. Older local notes show higher historical figures when date-specific buy/sell blocks were used, but those are treated as curve-fit evidence and should not be promoted as live-ready. The next research change keeps the fast batch size unchanged while making `protected_aggression_breakout` more ambitious.

Follow-up for the active 2-3% monthly objective: the current bottleneck is not just risk size; it is too much idle time plus whipsaw risk from adaptive reverse and ATR-only stop placement. The current code change directly targets those three issues:

- Flat-month efficiency: `protected_aggression_breakout` now allows `InpMaxTradesPerDay=10` and `InpMinMinutesBetweenTrades=5`, instead of the shared `6` / `15` settings, while keeping the risk/exposure caps.
- Adaptive reverse whipsaws: adaptive reverse now has a whipsaw guard requiring ADX/structure confirmation, and the protected-aggression lane additionally requires sweep rejection before allowing adaptive reverse.
- ATR-only stops: structure stops can now expand beyond recent sweep/equal-level liquidity with a configurable buffer, so the stop is not blindly parked inside a likely liquidity pool.

New inputs and logic:

- `InpUseRunnerExitPatience`
- `InpRunnerExitPatienceMinR`
- `InpRunnerExitPatienceMinMFER`
- `InpRunnerExitPatienceRequireHouseMoney`
- `InpRunnerExitPatienceRequireProtectedStop`
- `InpRunnerExitPatienceRequireTrendRegime`
- `InpRunnerExitPatienceRequireContinuation`
- `InpRunnerExitPatienceMFEGivebackMultiplier`
- `RunnerExitPatienceAllows(...)`
- `ContinuationStructureSupports(...)`
- Exit logs can add `runner patience MFE giveback exit ...` when a protected runner receives the wider giveback threshold.
- `InpUseAdaptiveReverseWhipsawGuard`
- `InpAdaptiveReverseMinADX`
- `InpAdaptiveReverseRequireStructure`
- `InpAdaptiveReverseRequireSweepReject`
- `AdaptiveReverseWhipsawGuardAllows(...)`
- `InpUseLiquidityAwareStructureStop`
- `InpLiquidityStopLookbackBars`
- `InpLiquidityStopBufferATR`
- `InpLiquidityStopBufferPoints`
- `LastSweepStopLevel(...)`
- `EqualLiquidityStopLevel(...)`

The feature stretches the MFE giveback exit and blocks no-follow-through/stagnation exits only for positions that meet minimum current R, minimum max-favorable R, protected-stop, house-money, trend-regime, and continuation-structure checks. It still keeps the shared safety rails: starting-equity protection, close-on-risk-limit, max equity drawdown, max effective risk cap, open-risk cap, protected-floor gates, house-money gates, spread/cost/margin guards, and no martingale/grid/averaging down.

Protected-aggression upside tuning now applies after shared conservative defaults so it is not overwritten:

- `InpMinimumEntryScore=5`
- `InpBreakoutContinuationMinScore=6`
- `InpBreakoutContinuationRequireRegime=false`
- `InpMaxTradesPerDay=10`
- `InpMinMinutesBetweenTrades=5`
- `InpUseAdaptiveReverseWhipsawGuard=true`
- `InpAdaptiveReverseMinADX=20.0`
- `InpAdaptiveReverseRequireStructure=true`
- `InpAdaptiveReverseRequireSweepReject=true`
- `InpUseLiquidityAwareStructureStop=true`
- `InpLiquidityStopLookbackBars=24`
- `InpLiquidityStopBufferATR=0.20`
- `InpLiquidityStopBufferPoints=45.0`
- `InpMaxStopATRMultiplier=4.00`
- `InpTakeProfitATRMultiplier=5.50`
- `InpMinRiskReward=1.20`
- `InpMFEGivebackStartR=1.00`
- `InpMFEGivebackMaxGivebackR=0.90`
- `InpMFEGivebackMinCloseR=0.20`
- `InpRunnerExitPatienceMinR=0.25`
- `InpRunnerExitPatienceMinMFER=0.75`
- `InpRunnerExitPatienceRequireTrendRegime=false`
- `InpRunnerExitPatienceMFEGivebackMultiplier=1.80`

## Fast Batch Impact

- Batch size remains 11 profiles / 33 runs.
- Estimated tester runtime remains about 11.55 minutes before platform overhead.
- `protected_aggression_breakout` now enables `InpUseBreakoutContinuationQuality=true`, `InpUseRunnerExitPatience=true`, and higher-upside TP/giveback settings.
- The batch still uses fast no-visual tester configs with `Model=2`, `Visual=0`, `ShutdownTerminal=1`, and `ReplaceReport=1`.

## Quiet Validation Results

- `work\test_price_action_strategy_modules.ps1`: PASS
- `work\sync_ea_source_artifacts.ps1`: PASS, hash `98BE545F7A4631A2BE793242D4A6EBFC8FFE3DACE52D1CFF63A2D6A298F6941A`
- `work\build_price_action_strategy_batch.ps1`: PASS, 11 profiles, 33 runs, estimated 11.55 minutes
- `work\test_open_risk_exposure_guard.ps1`: PASS
- `work\test_price_action_strategy_decision.ps1`: PASS
- `work\test_loss_streak_risk_reduction.ps1`: PASS
- `work\test_ea_source_artifact_sync.ps1`: PASS
- `work\test_price_action_strategy_batch.ps1`: PASS
- `work\test_price_action_strategy_handoff.ps1`: PASS
- `work\build_external_mt5_validation_package.ps1`: PASS, package configs 20, profiles 9
- `work\test_external_mt5_validation_package.ps1`: PASS, 26 checks, 0 failed
- `work\refresh_offline_validation_state.ps1`: PASS, 40 steps, 0 failed
- MT5-family process scan: empty
- Stop marker: present at `work\STOP_MT5_FOCUS_WATCHDOG`

## Latest Evidence

- `outputs\Professional_XAUUSD_EA.mq5`: `071E3723E40406C48929BD78FDC8B2E1681E8464F4491AC0A18B522344E8BC14`
- `Professional_XAUUSD_EA.mq5`: `071E3723E40406C48929BD78FDC8B2E1681E8464F4491AC0A18B522344E8BC14`
- `outputs\external_mt5_validation_package\source\Professional_XAUUSD_EA.mq5`: `071E3723E40406C48929BD78FDC8B2E1681E8464F4491AC0A18B522344E8BC14`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `A822D22AE2E8D3C7CDF73F104EC9CF852AB3EAC6DDCD2D29FEBACA76AF695F52`
- `outputs\xauusd_micro_validation_package.zip`: `8D470946FB81E3D9B013BCE0D172B886F267940DBC400348045F2FAD3A13E4D3`
- `work\build_price_action_strategy_batch.ps1`: `797AADD4A30C63ABF5BDA307ECAA5B8348B433CB5342998751AE9836A7195D66`
- `work\test_price_action_strategy_modules.ps1`: `B324E5DB31BE7332484230AC25D5B83553487429620F041E4BEA26E574C75516`
- `work\test_price_action_strategy_batch.ps1`: `740CD23D4D5151D1C3AD1688B0B9955ACC46F003F378AD196DA4BBB57F9F23C7`
- `work\test_price_action_strategy_handoff.ps1`: `F8B5503E3B72DD32EDAA79630D758693E41E3E851D5B56ED75CC7820C80F9BBF`
- `outputs\PRICE_ACTION_STRATEGY_BATCH.csv`: `1BD59B253422253BF095B10B2146CD88406F7C2CC06D23FA1A79831947594BD1`
- `outputs\OFFLINE_VALIDATION_REFRESH.csv`: `4B1399B159C4C73019E7914FF67B8590E4563F04E5B1699AA4EE44677B442472`

## Background-Safety Note

The stop marker remains present at `work\STOP_MT5_FOCUS_WATCHDOG`. Any future MT5 validation should be treated as external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The status note is committed through the GitHub connector. The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that the status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.
