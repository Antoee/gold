# Recent 2026 Fast Triage Status

Updated: 2026-07-09 03:04:45 -05:00

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- The GitHub-visible `$866` / 2.5-year result is still not enough for the active 2-3% monthly objective.

## Latest Strategy-Code Change

Added **Flat-Month Missed-Move Wake-Up**, with Liquidity Cluster Stop Extension, Adaptive-Reverse Follow-Through Close Filter, Flat-Month Probe Quality Cap Bypass, Flat-Month Probe Failure Exit, Flat-Month Probe Quality Risk Ramp, Range-Reversion Liquidity Stop Extension, Adaptive-Reverse Liquidity-Trap Guard, Flat-Month Catch-Up Standalone Relaxation, Runner MFE Profit-Lock Patience, Session Impulse Quality Risk Ramp, Flat-Month Catch-Up Take-Profit Expansion, Previous-Period Liquidity Stops, Adaptive-Reverse Phase Whipsaw Gate, Flat-Month Stale SIL Wake-Up, Protected SIL Winner Scale-In Gate, Session Impulse Runner Patience, Session Impulse Failure Exit, Session Impulse Lane (`SIL`), flat-month late catch-up pressure, winner scale-in price-action gate, adaptive-reverse post-stop lockout, liquidity-pocket stop shift, flat-month elite fallback, and PTC quality-scaled risk ramp still present.

The previous pass improved stop placement around clustered liquidity. This pass returns to the flat-month efficiency bottleneck: if XAUUSD moves materially while the EA has been inactive, the bot should be able to wake up a qualified momentum/continuation lane instead of waiting for the normal confirmation stack forever.

New configurable inputs:

- `InpUseFlatMonthMissedMoveWakeUp`
- `InpFlatMonthMissedMoveMinHours`
- `InpFlatMonthMissedMoveMaxMonthlyEntries`
- `InpFlatMonthMissedMoveMinATR`
- `InpFlatMonthMissedMoveScoreDiscount`
- `InpFlatMonthMissedMoveRRDiscount`
- `InpFlatMonthMissedMoveRequireLiquidSession`
- `InpFlatMonthMissedMoveAllowBreakout`
- `InpFlatMonthMissedMoveAllowSessionImpulse`
- `InpFlatMonthMissedMoveAllowPowerTrend`

`FlatMonthMissedMoveWakeUpAllowed()` compares the current close to the last entry time, or the current month open when there is no recent entry, and requires a configurable ATR-sized move plus a minimum idle time. When active, it can reduce required confirmations, score, and RR only for allowed breakout/session-impulse/power-trend lanes.

The protected-aggression generator now enables this with:

- `InpUseFlatMonthMissedMoveWakeUp=true`
- `InpFlatMonthMissedMoveMinHours=18`
- `InpFlatMonthMissedMoveMaxMonthlyEntries=10`
- `InpFlatMonthMissedMoveMinATR=1.10`
- `InpFlatMonthMissedMoveScoreDiscount=1`
- `InpFlatMonthMissedMoveRRDiscount=0.05`
- `InpFlatMonthMissedMoveRequireLiquidSession=true`
- `InpFlatMonthMissedMoveAllowBreakout=true`
- `InpFlatMonthMissedMoveAllowSessionImpulse=true`
- `InpFlatMonthMissedMoveAllowPowerTrend=true`

## Why This Matters

The `$866` / 2.5-year result implies the EA still leaves too much capital idle. This pass adds an activity trigger based on actual market movement during inactivity, so flat-month relaxation is tied to a missed XAUUSD move rather than just time passing.

The change is default-off in the base optimization profile and enabled in the protected-aggression generator. It is not martingale, grid, averaging down, or recovery trading.

It is still not proof of higher profit. This needs MT5 compile/backtest evidence, then out-of-sample and walk-forward validation.

## Existing Profit-Focused Work Still Present

- session impulse lane: `SIL;`
- session impulse quality risk ramp
- session impulse failure exit
- session impulse runner patience
- runner MFE profit-lock patience
- flat-month catch-up standalone relaxation
- protected SIL winner scale-in gate
- flat-month stale SIL wake-up
- flat-month opportunity mode
- flat-month probe mode
- flat-month probe quality risk ramp
- flat-month probe failure exit
- flat-month probe quality cap bypass
- flat-month missed-move wake-up
- flat-month probe lane spacing
- flat-month stale-entry nudge
- flat-month elite fallback
- flat-month breakout-continuation probe risk lane
- flat-month catch-up risk ramp
- flat-month catch-up entry relaxation
- flat-month catch-up take-profit expansion
- flat-month late catch-up pressure
- liquid-session catch-up relaxation guard
- liquid-session catch-up risk guard
- breakout-continuation standalone entry
- breakout-continuation follow-through close gate
- power trend continuation lane
- PTC quality-scaled risk ramp
- compact setup-lane tags: `PTC;`, `SIL;`, `BCQ;`, `RRO;`
- PTC-only winner scale-in gate
- winner scale-in price-action gate
- PTC runner patience
- adaptive-reverse whipsaw guard
- adaptive-reverse loss cooldown
- adaptive-reverse recent-flip cooldown
- adaptive-reverse post-stop lockout
- adaptive-reverse liquidity-trap guard
- adaptive-reverse follow-through close filter
- adaptive-reverse range/transition phase gate
- compact adaptive-reverse history tag: `AR;`
- setup-lane performance risk scaling
- liquidity-aware structural stops
- liquidity cluster stop extension
- liquidity-pocket stop shift
- previous-period liquidity stops
- liquidity-stop-aware max ATR ceiling
- protected runner exit patience
- protected-aggression breakout/continuation lane
- range-reversion lane with structural stop and mean target
- range-reversion liquidity stop extension

## Quiet Validation Results

- `work\test_price_action_strategy_modules.ps1`: PASS
- `work\test_price_action_strategy_batch.ps1`: PASS
- `work\sync_ea_source_artifacts.ps1`: PASS, artifacts 3
- `work\test_open_risk_exposure_guard.ps1`: PASS
- `work\test_price_action_strategy_decision.ps1`: PASS
- `work\test_loss_streak_risk_reduction.ps1`: PASS
- `work\test_ea_source_artifact_sync.ps1`: PASS
- `work\build_external_mt5_validation_package.ps1`: PASS, package configs 20, profiles 9
- `work\test_price_action_strategy_handoff.ps1`: PASS
- `work\test_external_mt5_validation_package.ps1`: PASS, 26 checks, 0 failed
- `work\refresh_offline_validation_state.ps1`: PASS, 40 steps, 0 failed
- MT5-family process scan: empty
- Stop marker: present at `work\STOP_MT5_FOCUS_WATCHDOG`

## Latest Evidence

- `outputs\Professional_XAUUSD_EA.mq5`: `E99AED821B396348AD3E66B953AAC5D8B400DBACEC06D736105739715097B54A`
- `Professional_XAUUSD_EA.mq5`: `E99AED821B396348AD3E66B953AAC5D8B400DBACEC06D736105739715097B54A`
- `outputs\external_mt5_validation_package\source\Professional_XAUUSD_EA.mq5`: `E99AED821B396348AD3E66B953AAC5D8B400DBACEC06D736105739715097B54A`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `B148ED335D7234CD120E76BD33B545037F0FDB8F64214BCBCCC77F164ED5CC7E`
- `outputs\xauusd_micro_validation_package.zip`: `C911F67D931E4DAD9619D0D1BCEF7EE82CFFBB1F809C3623010ECB16DF95539D`
- `work\build_price_action_strategy_batch.ps1`: `0149B22B31465587BFA11553E50DE2732BF6E9C5D42E9D9EE030601C7AB52444`
- `work\test_price_action_strategy_modules.ps1`: `7FD405BB4CB59537AB9457411F9FDE291F0C15E6EE00D04A0222023111426929`
- `work\test_price_action_strategy_batch.ps1`: `37CB6F9F8554A294F850B5BDE0A3FA147BD47033BDF76C72FFAC798097612834`
- `outputs\OFFLINE_VALIDATION_REFRESH.csv`: `6658AA0C55464D5F6F3083206FFA482CDC4CFEACD18CD1D4CA5F87B37C3E1DD0`

## Background-Safety Note

The stop marker remains present at `work\STOP_MT5_FOCUS_WATCHDOG`. Future MT5 validation should be external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that this status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.
