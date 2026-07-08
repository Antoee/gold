# Recent 2026 Fast Triage Status

Updated: 2026-07-07 21:02:00 -05:00

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- The GitHub-visible `$866` / 2.5-year result is still not enough for the active 2-3% monthly objective.

## Latest Strategy-Code Change

Added **setup-lane performance risk scaling** so breakout continuation and range reversion can learn separately from their own recent closed trades.

The EA now tags the signal context:

- `SSignal.isRangeReversion`
- `SSignal.isBreakoutContinuation`

The risk manager now reads historical entry comments by position ID and calculates recent average R for a specific setup lane:

- `EntryCommentForPosition(...)`
- `SetupLanePerformanceSample(...)`
- `SetupLanePerformanceRiskMultiplier(...)`

Why this matters: the bot now has two different profit engines. If range reversion is working but breakout continuation is cold, the EA can reduce breakout risk without strangling reversion trades. If a lane is producing strong recent R, it can receive a modest controlled boost, gated by closed-profit protection.

## Protected-Aggression Settings

`protected_aggression_breakout` now uses:

- `InpUseSetupLanePerformanceRiskScaling=true`
- `InpSetupLanePerformanceLookbackTrades=6`
- `InpSetupLanePerformanceMinTrades=3`
- `InpSetupLaneWeakAverageR=-0.20`
- `InpSetupLaneStrongAverageR=0.40`
- `InpMinSetupLaneRiskMultiplier=0.50`
- `InpMaxSetupLaneRiskMultiplier=1.30`
- `InpSetupLaneBoostRequiresClosedProfit=true`

This complements the existing work already in the EA:

- flat-month opportunity mode
- adaptive-reverse whipsaw guard
- liquidity-aware structural stops
- protected runner exit patience
- protected-aggression breakout/continuation lane
- range-reversion lane with structural stop and mean target

## Quiet Validation Results

- `work\test_price_action_strategy_modules.ps1`: PASS
- `work\test_price_action_strategy_batch.ps1`: PASS
- `work\sync_ea_source_artifacts.ps1`: PASS
- `work\test_open_risk_exposure_guard.ps1`: PASS
- `work\test_price_action_strategy_decision.ps1`: PASS
- `work\test_loss_streak_risk_reduction.ps1`: PASS
- `work\test_ea_source_artifact_sync.ps1`: PASS
- `work\build_external_mt5_validation_package.ps1`: PASS, package configs 20, profiles 9
- `work\test_external_mt5_validation_package.ps1`: PASS, 26 checks, 0 failed
- `work\test_price_action_strategy_handoff.ps1`: PASS
- `work\refresh_offline_validation_state.ps1`: PASS, 40 steps, 0 failed
- MT5-family process scan: empty
- Stop marker: present at `work\STOP_MT5_FOCUS_WATCHDOG`

## Latest Evidence

- `outputs\Professional_XAUUSD_EA.mq5`: `B5B9B67D41C6BC06A30DDB336499BFD4CB8158587F6B98EA241BAA1EDAD045BF`
- `Professional_XAUUSD_EA.mq5`: `B5B9B67D41C6BC06A30DDB336499BFD4CB8158587F6B98EA241BAA1EDAD045BF`
- `outputs\external_mt5_validation_package\source\Professional_XAUUSD_EA.mq5`: `B5B9B67D41C6BC06A30DDB336499BFD4CB8158587F6B98EA241BAA1EDAD045BF`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `8C3DA29A73D5AA50B19F012D882B6F739469CE435FF3E810026EF70AC9B9716E`
- `outputs\xauusd_micro_validation_package.zip`: `DB728B7F27F11F85FB8656C762777E8FC975908459531EB47F99DFAE4E747A6C`
- `work\build_price_action_strategy_batch.ps1`: `2020D72C82C447AB5565924C76BAA36398BCD7FE4A7F705360FEF87D8E0055E4`
- `work\test_price_action_strategy_modules.ps1`: `6B09D33B14B17A8D79FFD2632D9FCABE823D5ECD73672D439CC48EADD6626400`
- `work\test_price_action_strategy_batch.ps1`: `029027B102A186DBFC21DE3529A55B6687918A132228BDD5C16873693410B703`
- `outputs\OFFLINE_VALIDATION_REFRESH.csv`: `B5AB180ECF3563FDA9D47FE07075C01B93A0CDD28ADF93DBC007971A511114CB`

## Background-Safety Note

The stop marker remains present at `work\STOP_MT5_FOCUS_WATCHDOG`. Future MT5 validation should be external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that this status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.
