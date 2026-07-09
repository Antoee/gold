# Recent 2026 Fast Triage Status

Updated: 2026-07-08 23:22:36 -05:00

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- The GitHub-visible `$866` / 2.5-year result is still not enough for the active 2-3% monthly objective.

## Latest Strategy-Code Change

Added **adaptive-reverse recent-flip cooldown plus compact `AR;` lane tag**.

The bot needs more profit, but recent adaptive-reverse logic can also create fast flip/whipsaw exposure if the market chops after a reversal. This pass adds a bounded cooldown that blocks repeated adaptive-reverse entries for a configurable period unless the new setup has enough quality score to override it.

New configurable inputs:

- `InpUseAdaptiveReverseRecentFlipCooldown`
- `InpAdaptiveReverseRecentFlipCooldownMinutes`
- `InpAdaptiveReverseRecentFlipMinQualityScore`

When enabled, the EA scans recent entry history for adaptive-reverse trades tagged with either the new compact `AR;` marker or the legacy `Adaptive reverse guarded;` reason. If the previous adaptive-reverse entry is still inside the cooldown window, a new adaptive-reverse entry is blocked unless its quality score meets the override threshold.

The protected-aggression generator now enables the guard with:

- `InpUseAdaptiveReverseRecentFlipCooldown=true`
- `InpAdaptiveReverseRecentFlipCooldownMinutes=240`
- `InpAdaptiveReverseRecentFlipMinQualityScore=13`

## Why This Matters

This directly targets the "make as much as possible but avoid going red" objective from the risk side. It does not increase trade count by itself, but it should reduce repeated reversal churn so profit-focused lanes like PTC, BCQ, RRO, and flat-month opportunity logic are not giving money back through low-quality adaptive reverse flips.

## Existing Profit-Focused Work Still Present

- flat-month opportunity mode
- flat-month probe mode
- flat-month probe lane spacing
- flat-month stale-entry nudge
- flat-month breakout-continuation probe risk lane
- flat-month catch-up risk ramp
- flat-month catch-up entry relaxation
- liquid-session catch-up relaxation guard
- liquid-session catch-up risk guard
- breakout-continuation standalone entry
- breakout-continuation follow-through close gate
- power trend continuation lane
- compact setup-lane tags: `PTC;`, `BCQ;`, `RRO;`
- PTC-only winner scale-in gate
- PTC runner patience
- adaptive-reverse whipsaw guard
- adaptive-reverse loss cooldown
- adaptive-reverse recent-flip cooldown
- compact adaptive-reverse history tag: `AR;`
- setup-lane performance risk scaling
- liquidity-aware structural stops
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

- `outputs\Professional_XAUUSD_EA.mq5`: `888B13F71B608064A0FE9D06D0933721FE6CAB82667DEDAA7F3921C897777DD6`
- `Professional_XAUUSD_EA.mq5`: `888B13F71B608064A0FE9D06D0933721FE6CAB82667DEDAA7F3921C897777DD6`
- `outputs\external_mt5_validation_package\source\Professional_XAUUSD_EA.mq5`: `888B13F71B608064A0FE9D06D0933721FE6CAB82667DEDAA7F3921C897777DD6`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `2E5880E81FF069209906AD4856C8718A44CD5E757F5697CA18F30D71F4A537B1`
- `outputs\xauusd_micro_validation_package.zip`: `D75FC3FDE9B4B494594DA7D79E3DCDA3E10A7C613F3950D705D9C4DA9753FB8C`
- `work\build_price_action_strategy_batch.ps1`: `2004E5978731079478C4F4D357BE223B63E1024AD2C0A3F5B18EECAB6EC5913E`
- `work\test_price_action_strategy_modules.ps1`: `51CA5DD0636F30993F665AD3EFC2D6297835A7FEE71E67C12882B1E98DF758EE`
- `work\test_price_action_strategy_batch.ps1`: `CD74C0F192885686E745A13491F1B256D6E3CB02E53C6AA7961DB869955F64F3`
- `outputs\OFFLINE_VALIDATION_REFRESH.csv`: `8959B2E330A685D205F26A69886E22402BFE638DC6CBDC4E7E976115696D8CA3`

## Background-Safety Note

The stop marker remains present at `work\STOP_MT5_FOCUS_WATCHDOG`. Future MT5 validation should be external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that this status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.
