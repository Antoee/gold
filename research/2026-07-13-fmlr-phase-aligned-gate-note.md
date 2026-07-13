# FMLR Phase-Aligned Gate Note

Date: 2026-07-13

Status: code-only, default-off, not promoted, not backtested.

## Intent

The Flat Month Liquidity Reclaim (`FMLR`) lane now has an optional lane-specific phase gate. The goal is to avoid turning flat-month opportunity research into blind extra trading:

- Trend mode requires ADX strength and optional EMA slope alignment.
- Range mode requires low ADX plus bounded net movement and candle alternation.
- Transition mode can be blocked so unclear middle regimes do not become churn trades.

This is meant to help the next probe separate useful range reclaims and trend pullbacks from whipsaw-prone transition noise.

## New Inputs

- `InpFlatMonthLiquidityReclaimUsePhaseGate=false`
- `InpFlatMonthLiquidityReclaimAllowTrendPhase=true`
- `InpFlatMonthLiquidityReclaimAllowRangePhase=true`
- `InpFlatMonthLiquidityReclaimAllowTransitionPhase=true`
- `InpFlatMonthLiquidityReclaimTrendRequireEMASlope=true`
- `InpFlatMonthLiquidityReclaimPhaseLookbackBars=18`
- `InpFlatMonthLiquidityReclaimTrendMinADX=21.0`
- `InpFlatMonthLiquidityReclaimRangeMaxADX=18.0`
- `InpFlatMonthLiquidityReclaimTrendMinSlopePoints=25.0`
- `InpFlatMonthLiquidityReclaimRangeMaxNetMoveATR=1.15`
- `InpFlatMonthLiquidityReclaimRangeMinAlternationPercent=45.0`

## New Probe Profile

`fmlr_phase_aligned`

Important settings:

- Enables FMLR phase gate.
- Allows trend and range phases.
- Blocks transition phase.
- Requires trend EMA slope alignment.
- Uses forward-liquidity target, session/Asian target, swing target, recent retest, and forward clearance.
- Keeps Adaptive Reverse disabled.

## Package State

Offline package builder now prepares `120` configs:

- 10 profiles
- 12 weak/flat/control windows

The new profile contributes 12 configs, one for each existing FMLR validation window.

## Local Verification

Completed without launching MT5:

- `PRICE_ACTION_STRATEGY_MODULES_SMOKE_PASS`
- `FLAT_MONTH_LIQUIDITY_RECLAIM_PROBE_PACKAGE_SMOKE_PASS`
- `FLAT_MONTH_LIQUIDITY_RECLAIM_COMPACT_SOURCE_SMOKE_PASS`
- `ADAPTIVE_REVERSE_QUARANTINE_SMOKE_PASS`
- MT5 local safety audit: `PASS 39 / 39`
- Cleanup dry-run: `0` candidates
- Generated-package cleanup dry-run: `0` candidates
- MT5 lock remained active and no MT5 processes were running

## Decision

Do not promote. This is a candidate for the next hidden/local MT5 probe only.

Current research-best remains:

`Score7 Regime No-M1-Shock Dec-ISLP-Off + ISLP LowATR OrderFlow`
