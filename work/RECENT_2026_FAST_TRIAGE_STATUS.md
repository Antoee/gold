# Recent 2026 Fast Triage Status

Updated: 2026-07-09 00:03:35 -05:00

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- The GitHub-visible `$866` / 2.5-year result is still not enough for the active 2-3% monthly objective.

## Latest Strategy-Code Change

Added **winner scale-in price-action gate**, with adaptive-reverse post-stop lockout, liquidity-pocket stop shift, flat-month elite fallback, and PTC quality-scaled risk ramp still present.

The EA needs more upside, but pyramiding into weak continuation candles can give back wins. This pass adds a price-action score floor to winner scale-ins, so add-on entries can still compound profitable positions but require both quality score and price-action quality.

New configurable inputs:

- `InpWinnerScaleInMinPriceActionScore`

When winner scale-in is active, `WinnerScaleInAllows()` now checks `signal.priceActionScore` in addition to existing requirements: same-direction open position, protected stop, minimum locked R, minimum profit R, optional PTC lane requirement, trend-regime requirement, and open-profit risk coverage.

The protected-aggression generator now enables the stricter add-on gate with:

- `InpWinnerScaleInMinPriceActionScore=12`

Also retained from previous passes:

- adaptive-reverse post-stop lockout
- liquidity-pocket stop shift
- flat-month elite fallback
- PTC quality-scaled risk ramp
- `InpUseAdaptiveReverseRecentFlipCooldown`
- `InpAdaptiveReverseRecentFlipCooldownMinutes`
- `InpAdaptiveReverseRecentFlipMinQualityScore`
- compact adaptive-reverse history tag: `AR;`

## Why This Matters

This targets the profit side without simply raising base risk. Better scale-in filtering lets the aggressive profile press true winners while avoiding low-quality add-ons that can turn a good trade into noisy exposure.

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
- winner scale-in price-action gate
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

- `outputs\Professional_XAUUSD_EA.mq5`: `0DFAA5192ADB7B2F023CD271B75101FAA9AE0F42A51B14D6B1ABA7DA69FE6D0D`
- `Professional_XAUUSD_EA.mq5`: `0DFAA5192ADB7B2F023CD271B75101FAA9AE0F42A51B14D6B1ABA7DA69FE6D0D`
- `outputs\external_mt5_validation_package\source\Professional_XAUUSD_EA.mq5`: `0DFAA5192ADB7B2F023CD271B75101FAA9AE0F42A51B14D6B1ABA7DA69FE6D0D`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `B31F5833CB1E480F35A365C9234DEAD1572061F33B153E55A315945767A2ECCE`
- `outputs\xauusd_micro_validation_package.zip`: `BBC40DA0143BE269CF39A286C03D990FB0352A7678A05EB2AF1CECFE4C286DDB`
- `work\build_price_action_strategy_batch.ps1`: `20B01229B3D318D0092C2CE6F3699BBE14BF9AEA862109B22E7C56906A7F4123`
- `work\test_price_action_strategy_modules.ps1`: `708D99F1375E2927CFDA379F9B972E690F42EF697AE8BB80289FF565FA212E1E`
- `work\test_price_action_strategy_batch.ps1`: `E6F0E59FF26522FBC331C6801A651A72A3D081ED06E817D3245C92EBF5FEAFBF`
- `outputs\OFFLINE_VALIDATION_REFRESH.csv`: `A123FE1F989BD20DA52BBA651B1C69C63686734C7F13358937EF719B767D49CA`

## Background-Safety Note

The stop marker remains present at `work\STOP_MT5_FOCUS_WATCHDOG`. Future MT5 validation should be external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that this status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.
