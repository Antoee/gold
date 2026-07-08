# Recent 2026 Fast Triage Status

Updated: 2026-07-07 22:24:00 -05:00

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- The GitHub-visible `$866` / 2.5-year result is still not enough for the active 2-3% monthly objective.

## Latest Strategy-Code Change

Added **adaptive-reverse loss cooldown**.

Adaptive reverse already had a market-context whipsaw guard, but it did not remember whether recent adaptive flips had actually lost money. The EA now scans closed trade history for entries tagged with `Adaptive reverse guarded;`, counts recent losing reverse trades in the same intended direction, and blocks weak-quality repeat flips during a cooldown window.

New configurable inputs:

- `InpUseAdaptiveReverseLossCooldown=true`
- `InpAdaptiveReverseLossLookbackTrades=6`
- `InpAdaptiveReverseLossThreshold=2`
- `InpAdaptiveReverseLossCooldownMinutes=360`
- `InpAdaptiveReverseLossMinQualityScore=12`

New helper logic:

- `EntryCommentForHistoryPosition(...)`
- `AdaptiveReverseLossCooldownActive(...)`

If the recent adaptive-reverse loss threshold is reached, lower-quality reverse attempts are blocked through the existing `Adaptive reverse whipsaw guard;` path. High-quality reverse attempts can still pass, which keeps the EA from becoming permanently passive when a true high-confluence reversal appears.

## Protected-Aggression Settings

`protected_aggression_breakout` now uses:

- `InpUseAdaptiveReverseLossCooldown=true`
- `InpAdaptiveReverseLossLookbackTrades=6`
- `InpAdaptiveReverseLossThreshold=2`
- `InpAdaptiveReverseLossCooldownMinutes=360`
- `InpAdaptiveReverseLossMinQualityScore=12`

This complements the existing work already in the EA:

- flat-month opportunity mode
- flat-month probe mode
- flat-month probe lane spacing
- setup-lane performance risk scaling
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

- `outputs\Professional_XAUUSD_EA.mq5`: `B00F4F0DA6B972946394BB2B1ACFAF707D38FD0ABF82B3A9974E03E8D9AB30CA`
- `Professional_XAUUSD_EA.mq5`: `B00F4F0DA6B972946394BB2B1ACFAF707D38FD0ABF82B3A9974E03E8D9AB30CA`
- `outputs\external_mt5_validation_package\source\Professional_XAUUSD_EA.mq5`: `B00F4F0DA6B972946394BB2B1ACFAF707D38FD0ABF82B3A9974E03E8D9AB30CA`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `A41FD0C9ACFE35B5A5F4457A55D4F0AE506EAF69E7EE56A18C206332DD613EBA`
- `outputs\xauusd_micro_validation_package.zip`: `D7EEFDFC4422C7FD3EA525A964A11B9FE47437384726E1CD8AD236A34E1B0DF3`
- `work\build_price_action_strategy_batch.ps1`: `9A91AA10C76C3F7B2C31A9BFF949FE34C8522949C250880183444E1AD6A062CB`
- `work\test_price_action_strategy_modules.ps1`: `D6DA073FF43799CAAD6F1DD6A14AB0E99763248E22FBFA558C97E3287C0EA62A`
- `work\test_price_action_strategy_batch.ps1`: `D7BFB012163ED2058E54AF20AA0F4D596651255EB98CC76C2371B993623A0DBE`
- `outputs\OFFLINE_VALIDATION_REFRESH.csv`: `37D562C2D8086EEFD0B9BC1BEA4267264B1BB0321514678CB12A5DE34F3723D8`

## Background-Safety Note

The stop marker remains present at `work\STOP_MT5_FOCUS_WATCHDOG`. Future MT5 validation should be external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that this status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.
