# Recent 2026 Fast Triage Status

Updated: 2026-07-08 23:48:09 -05:00

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- The GitHub-visible `$866` / 2.5-year result is still not enough for the active 2-3% monthly objective.

## Latest Strategy-Code Change

Added **liquidity-pocket stop shift**, with flat-month elite fallback, PTC quality-scaled risk ramp, and adaptive-reverse recent-flip cooldown still present.

Fixed ATR and even basic structure stops can still land directly inside recent swing liquidity. This pass adds a configurable stop adjustment that scans recent swing highs/lows around the computed stop; if the stop is too close to that liquidity pocket, the EA shifts the stop beyond the pocket by an ATR/points buffer instead of leaving it in the most obvious stop-hunt zone.

New configurable inputs:

- `InpUseLiquidityPocketStopShift`
- `InpLiquidityPocketLookbackBars`
- `InpLiquidityPocketProximityATR`
- `InpLiquidityPocketProximityPoints`
- `InpLiquidityPocketBufferATR`
- `InpLiquidityPocketBufferPoints`

When enabled, `LiquidityPocketStopLevel()` checks whether the currently computed stop is near a recent swing low for buys or recent swing high for sells. If so, `StructureStopDistance()` can widen the stop beyond that pocket and mark it as a liquidity-aware stop, so the existing wider max-ATR ceiling and risk sizing path remain in control.

The protected-aggression generator now enables the shift with:

- `InpUseLiquidityPocketStopShift=true`
- `InpLiquidityPocketLookbackBars=28`
- `InpLiquidityPocketProximityATR=0.20`
- `InpLiquidityPocketProximityPoints=55.0`
- `InpLiquidityPocketBufferATR=0.24`
- `InpLiquidityPocketBufferPoints=65.0`

Also retained from previous passes:

- flat-month elite fallback
- PTC quality-scaled risk ramp
- `InpUseAdaptiveReverseRecentFlipCooldown`
- `InpAdaptiveReverseRecentFlipCooldownMinutes`
- `InpAdaptiveReverseRecentFlipMinQualityScore`
- compact adaptive-reverse history tag: `AR;`

## Why This Matters

This directly targets the "move beyond pure ATR multipliers" requirement. Instead of accepting a mechanically calculated ATR/structure stop when it sits near recent liquidity, the EA now has a configurable way to place the stop past that pocket while preserving the normal risk, exposure, RR, spread, margin, and max-stop checks.

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

- `outputs\Professional_XAUUSD_EA.mq5`: `F5AD988DAC271C254584A87D148078DBD86A207B61F751ACD0171D82CB8EEE2A`
- `Professional_XAUUSD_EA.mq5`: `F5AD988DAC271C254584A87D148078DBD86A207B61F751ACD0171D82CB8EEE2A`
- `outputs\external_mt5_validation_package\source\Professional_XAUUSD_EA.mq5`: `F5AD988DAC271C254584A87D148078DBD86A207B61F751ACD0171D82CB8EEE2A`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `4AA8385DC48178DB744D7CA2BDEF1585DB5DF92FFFC1E6AE743200336E5BA5C5`
- `outputs\xauusd_micro_validation_package.zip`: `C2C61FCB23D36E24A9C0900523F6E112E23E7A4EEB49F78576EB99EFC38E1E51`
- `work\build_price_action_strategy_batch.ps1`: `29FE02DCEF0B0B6EF8EEFFBEB970DEC59D622B2ABD63BDB475F742FFDD595347`
- `work\test_price_action_strategy_modules.ps1`: `7981AFC58881F95F2A8B9FB297C7D7DBCCC99F9656A37CFA37DA99011376633E`
- `work\test_price_action_strategy_batch.ps1`: `9FE35082CF8CD9241D59104216F4AE5ADEE76F2E16DE85BD0B0A4047FD726042`
- `outputs\OFFLINE_VALIDATION_REFRESH.csv`: `237A6BB10044457A6D2A005313644D684E9FFFEE6ACDF5A8BCD38F4A3B8A37C3`

## Background-Safety Note

The stop marker remains present at `work\STOP_MT5_FOCUS_WATCHDOG`. Future MT5 validation should be external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that this status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.
