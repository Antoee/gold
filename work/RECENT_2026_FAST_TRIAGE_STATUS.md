# Recent 2026 Fast Triage Status

Updated: 2026-07-09 02:31:08 -05:00

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- The GitHub-visible `$866` / 2.5-year result is still not enough for the active 2-3% monthly objective.

## Latest Strategy-Code Change

Added **Flat-Month Probe Failure Exit**, with Flat-Month Probe Quality Risk Ramp, Range-Reversion Liquidity Stop Extension, Adaptive-Reverse Liquidity-Trap Guard, Flat-Month Catch-Up Standalone Relaxation, Runner MFE Profit-Lock Patience, Session Impulse Quality Risk Ramp, Flat-Month Catch-Up Take-Profit Expansion, Previous-Period Liquidity Stops, Adaptive-Reverse Phase Whipsaw Gate, Flat-Month Stale SIL Wake-Up, Protected SIL Winner Scale-In Gate, Session Impulse Runner Patience, Session Impulse Failure Exit, Session Impulse Lane (`SIL`), flat-month late catch-up pressure, winner scale-in price-action gate, adaptive-reverse post-stop lockout, liquidity-pocket stop shift, flat-month elite fallback, and PTC quality-scaled risk ramp still present.

The previous pass let higher-quality flat-month probes scale beyond the tiny base probe size while still respecting the protected equity floor. This pass targets the other side of that same bottleneck: if a flat-month probe is admitted, tagged, and fails to produce favorable movement quickly, it should free capital instead of sitting through low-quality drift.

New configurable inputs:

- `InpUseFlatMonthProbeFailureExit`
- `InpFlatMonthProbeFailureBars`
- `InpFlatMonthProbeFailureMinMFER`
- `InpFlatMonthProbeFailureMaxCurrentR`

Flat-month probe entries now receive the compact `FMP;` tag. `FlatMonthProbeFailureExitHit()` uses that tag, held bars, max favorable excursion in R, and current R to close failed probe positions before they consume too much time/capital.

The protected-aggression generator now enables this with:

- `InpUseFlatMonthProbeFailureExit=true`
- `InpFlatMonthProbeFailureBars=4`
- `InpFlatMonthProbeFailureMinMFER=0.15`
- `InpFlatMonthProbeFailureMaxCurrentR=-0.08`

## Why This Matters

The `$866` / 2.5-year result implies the EA still leaves too much capital idle. The last pass made better flat-month probes matter more; this pass tries to stop bad probes from tying up capital after they fail to get even minor favorable movement.

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
- adaptive-reverse range/transition phase gate
- compact adaptive-reverse history tag: `AR;`
- setup-lane performance risk scaling
- liquidity-aware structural stops
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

- `outputs\Professional_XAUUSD_EA.mq5`: `4356E8C378DC000DBE634B764D90227F40F7DB689B1B0785A86CDE2603B6FDFB`
- `Professional_XAUUSD_EA.mq5`: `4356E8C378DC000DBE634B764D90227F40F7DB689B1B0785A86CDE2603B6FDFB`
- `outputs\external_mt5_validation_package\source\Professional_XAUUSD_EA.mq5`: `4356E8C378DC000DBE634B764D90227F40F7DB689B1B0785A86CDE2603B6FDFB`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `54C2002E356D9641D2CE10A64FBE252A6BB976B6576A78E2E8B61BF1832D4B84`
- `outputs\xauusd_micro_validation_package.zip`: `308BBC96FB6D8AE895C97428A425235DB1C42EA98842BA57218EC8119356FBBE`
- `work\build_price_action_strategy_batch.ps1`: `52BA5B24DE68CFD8C4BE850A21074588D85549A11777FBCC99978A67B77024EB`
- `work\test_price_action_strategy_modules.ps1`: `7EAA53F4142B4595527EA2A976707D9E07513E208CE6903BD53AD41ECEAD142C`
- `work\test_price_action_strategy_batch.ps1`: `D446E5D0F6C3DE885999D26D31A7D3148C4EF78151A8645A1A5B8FCB11E07BDD`
- `outputs\OFFLINE_VALIDATION_REFRESH.csv`: `54D412AA7F660C9F02A11FE987A4E0D430F855CA10F67F66FC7F7A8F38870655`

## Background-Safety Note

The stop marker remains present at `work\STOP_MT5_FOCUS_WATCHDOG`. Future MT5 validation should be external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that this status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.
