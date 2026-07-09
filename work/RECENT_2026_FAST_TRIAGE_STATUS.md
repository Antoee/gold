# Recent 2026 Fast Triage Status

Updated: 2026-07-08 23:55:56 -05:00

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- The GitHub-visible `$866` / 2.5-year result is still not enough for the active 2-3% monthly objective.

## Latest Strategy-Code Change

Added **adaptive-reverse post-stop lockout**, with liquidity-pocket stop shift, flat-month elite fallback, and PTC quality-scaled risk ramp still present.

Adaptive reverse can still whipsaw if a stop-loss just happened and the next signal immediately flips direction. This pass adds a configurable post-stop lockout: after a recent SL exit, low-quality adaptive reverse flips are blocked for a set number of minutes unless the new reversal meets a higher quality threshold.

New configurable inputs:

- `InpUseAdaptiveReversePostStopLockout`
- `InpAdaptiveReversePostStopLockoutMinutes`
- `InpAdaptiveReversePostStopMinQualityScore`
- `InpAdaptiveReversePostStopMatchDirection`

When enabled, `AdaptiveReversePostStopLockoutActive()` scans recent exit deals for `DEAL_REASON_SL`. If a stop-loss exit is still inside the lockout window, the adaptive reverse guard blocks the flip unless the setup quality score meets the override threshold. Direction matching is configurable so the lockout can focus on flips into the stop-out exit direction.

The protected-aggression generator now enables the lockout with:

- `InpUseAdaptiveReversePostStopLockout=true`
- `InpAdaptiveReversePostStopLockoutMinutes=240`
- `InpAdaptiveReversePostStopMinQualityScore=14`
- `InpAdaptiveReversePostStopMatchDirection=true`

Also retained from previous passes:

- liquidity-pocket stop shift
- flat-month elite fallback
- PTC quality-scaled risk ramp
- `InpUseAdaptiveReverseRecentFlipCooldown`
- `InpAdaptiveReverseRecentFlipCooldownMinutes`
- `InpAdaptiveReverseRecentFlipMinQualityScore`
- compact adaptive-reverse history tag: `AR;`

## Why This Matters

This directly targets the hidden risk in adaptive reverse. The EA already had loss and recent-flip guards; now it also reacts to a fresh stop-loss event, reducing the chance of buying, getting stopped, immediately flipping short, and getting stopped again in choppy XAUUSD conditions.

## Existing Profit-Focused Work Still Present

- flat-month opportunity mode
- flat-month probe mode
- flat-month probe lane spacing
- flat-month stale-entry nudge
- flat-month elite fallback
- flat-month breakout-continuation probe risk lane
- flat-month catch-up risk ramp
- flat-month catch-up entry relaxation
- liquid-session catch-up relaxation guard
- liquid-session catch-up risk guard
- breakout-continuation standalone entry
- breakout-continuation follow-through close gate
- power trend continuation lane
- PTC quality-scaled risk ramp
- compact setup-lane tags: `PTC;`, `BCQ;`, `RRO;`
- PTC-only winner scale-in gate
- PTC runner patience
- adaptive-reverse whipsaw guard
- adaptive-reverse loss cooldown
- adaptive-reverse recent-flip cooldown
- adaptive-reverse post-stop lockout
- compact adaptive-reverse history tag: `AR;`
- setup-lane performance risk scaling
- liquidity-aware structural stops
- liquidity-pocket stop shift
- liquidity-stop-aware max ATR ceiling
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

- `outputs\Professional_XAUUSD_EA.mq5`: `3E5CF452609A4A25EA7DFC30A261795F7C956E7ACD8D1B6D77D9EF857C5315EF`
- `Professional_XAUUSD_EA.mq5`: `3E5CF452609A4A25EA7DFC30A261795F7C956E7ACD8D1B6D77D9EF857C5315EF`
- `outputs\external_mt5_validation_package\source\Professional_XAUUSD_EA.mq5`: `3E5CF452609A4A25EA7DFC30A261795F7C956E7ACD8D1B6D77D9EF857C5315EF`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `9389076496B49866F7FF728BE95A24D7A7FE5FB23C6F1AEBBD8D1C6CB02F53A1`
- `outputs\xauusd_micro_validation_package.zip`: `BE42D6B47FE9B99B4D83F9CD2FD9CFA5B830C4DF5194AB94D9BA30457CC90FC0`
- `work\build_price_action_strategy_batch.ps1`: `F1DFFADB6C36451CB6DF42E4479F54E9C4F585532E11B86FF2261CFF862D450E`
- `work\test_price_action_strategy_modules.ps1`: `0683F8ACDCFAA0F016612AC4A9D3582939FCD215206929F8A53EB0818BD25A70`
- `work\test_price_action_strategy_batch.ps1`: `160631BF9036B73B45722ED24F69478EDC1920CB653AA296353E9DE8DAE338AF`
- `outputs\OFFLINE_VALIDATION_REFRESH.csv`: `1011B5F9045667A6B41975B0E4A616F93E1C817C0792878BF05D027E07E9DCD5`

## Background-Safety Note

The stop marker remains present at `work\STOP_MT5_FOCUS_WATCHDOG`. Future MT5 validation should be external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that this status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.
