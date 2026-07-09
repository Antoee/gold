# Recent 2026 Fast Triage Status

Updated: 2026-07-08 23:31:39 -05:00

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- The GitHub-visible `$866` / 2.5-year result is still not enough for the active 2-3% monthly objective.

## Latest Strategy-Code Change

Added **PTC quality-scaled risk ramp**, with the adaptive-reverse recent-flip cooldown still present.

The `$866` / 2.5-year result is not enough. This pass adds a profit-side accelerator for the strongest power-trend-continuation lane while keeping it behind the existing house-money and liquid-session gates. It does not blindly raise base risk; it only scales PTC risk higher as signal quality improves.

New configurable inputs:

- `InpUsePowerTrendQualityRiskRamp`
- `InpPowerTrendQualityRiskFullScore`
- `InpPowerTrendQualityMaxRiskMultiplier`

When enabled, `PowerTrendContinuationRiskMultiplier()` starts from the normal PTC risk multiplier and linearly ramps toward a higher cap as `signal.qualityScore` rises from `InpPowerTrendContinuationMinScore` to `InpPowerTrendQualityRiskFullScore`.

The protected-aggression generator now enables the ramp with:

- `InpUsePowerTrendQualityRiskRamp=true`
- `InpPowerTrendQualityRiskFullScore=16`
- `InpPowerTrendQualityMaxRiskMultiplier=1.75`

Also retained from the previous pass:

- `InpUseAdaptiveReverseRecentFlipCooldown`
- `InpAdaptiveReverseRecentFlipCooldownMinutes`
- `InpAdaptiveReverseRecentFlipMinQualityScore`
- compact adaptive-reverse history tag: `AR;`

## Why This Matters

This directly targets the "make as much as possible but avoid going red" objective from both sides: the previous adaptive-reverse cooldown reduces churn, and the new PTC quality ramp gives the highest-quality continuation lane more upside only after the existing house-money/liquid-session checks allow it.

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

- `outputs\Professional_XAUUSD_EA.mq5`: `7790DC49DB082402E7319CB0636DC7A971D3AA9894D8F868AD8B6F07D02ABEA1`
- `Professional_XAUUSD_EA.mq5`: `7790DC49DB082402E7319CB0636DC7A971D3AA9894D8F868AD8B6F07D02ABEA1`
- `outputs\external_mt5_validation_package\source\Professional_XAUUSD_EA.mq5`: `7790DC49DB082402E7319CB0636DC7A971D3AA9894D8F868AD8B6F07D02ABEA1`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `39284FF5C7AC64782F8B69F9F9049D249E1B0395F7FDB6E7D65C5D49B160DF31`
- `outputs\xauusd_micro_validation_package.zip`: `38CD5C02230C5C2D96219832AE944C095DE7175B21A930385A3DBA64C9160DC8`
- `work\build_price_action_strategy_batch.ps1`: `D3535A9463DA3FC12740435A9E81C52D96D9B66A55409EBD91558B719F7E7372`
- `work\test_price_action_strategy_modules.ps1`: `B39B6B92CB18CF5F5ED83D9CB78AA7A5632FD6C225A2AAE98AF2240EAC9E14AD`
- `work\test_price_action_strategy_batch.ps1`: `E7F527507A6CB09816193144A5A387F74A9FEBB3240A77A34FC742CEA9F92D09`
- `outputs\OFFLINE_VALIDATION_REFRESH.csv`: `D4AE1EBC39D0C2D88774CA05ECA2E654658455744FDED97CD133D11BE10EC1E6`

## Background-Safety Note

The stop marker remains present at `work\STOP_MT5_FOCUS_WATCHDOG`. Future MT5 validation should be external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that this status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.
