# FMLR Session Range Breakout Note

Date: 2026-07-13

Status: code-only, default-off, not promoted, not backtested.

## Intent

Gold often compresses during Asian or quieter rolling ranges, then expands when London/New York liquidity arrives. The existing FMLR sweep/reclaim path can miss that move if price leaves the range cleanly without first printing a textbook sweep.

This change adds a default-off session-range breakout substitute setup. It can use the existing Asian range, a rolling range, or both, then anchors the stop beyond the opposite side of the selected range instead of using a plain ATR stop.

## Added Controls

- `InpFlatMonthLiquidityReclaimUseSessionRangeBreakout=false`
- `InpFlatMonthLiquidityReclaimRequireSessionRangeBreakout=false`
- `InpFlatMonthLiquidityReclaimSessionBreakoutUseAsianRange=true`
- `InpFlatMonthLiquidityReclaimSessionBreakoutUseRollingRange=true`
- `InpFlatMonthLiquidityReclaimSessionBreakoutLookbackHours=6`
- `InpFlatMonthLiquidityReclaimSessionBreakoutMaxRangeATR=1.25`
- `InpFlatMonthLiquidityReclaimSessionBreakoutBufferPoints=20.0`
- `InpFlatMonthLiquidityReclaimSessionBreakoutMinBodyPercent=38.0`
- `InpFlatMonthLiquidityReclaimSessionBreakoutMinCloseLocation=0.62`
- `InpFlatMonthLiquidityReclaimSessionBreakoutMinBreakRangeATR=0.45`

## Logic

When enabled, `FlatMonthLiquiditySessionRangeExpansionLevel`:

- tests the Asian range if enabled
- tests a rolling range if enabled
- rejects ranges wider than the max ATR range
- requires the signal candle to break outside the selected range by a point buffer
- requires body strength, close-location strength, and minimum breakout candle range
- selects the narrower valid range when both Asian and rolling ranges qualify
- returns the opposite side of the selected range as the structural stop level

The main FMLR lane can use this as a substitute setup when no sweep/reclaim is present. If `InpFlatMonthLiquidityReclaimRequireSessionRangeBreakout=true`, the candidate rejects non-session-range setups.

## Probe Profile

New package profile:

`fmlr_session_range_breakout`

Important settings:

- `InpFlatMonthLiquidityReclaimRiskMultiplier=0.12`
- `InpFlatMonthLiquidityReclaimMaxMonthlyEntries=5`
- `InpFlatMonthLiquidityReclaimSpacingMinutes=300`
- `InpFlatMonthLiquidityReclaimMinScore=7`
- `InpFlatMonthLiquidityReclaimMinRR=1.00`
- `InpFlatMonthLiquidityReclaimUseSessionRangeBreakout=true`
- `InpFlatMonthLiquidityReclaimRequireSessionRangeBreakout=true`
- `InpFlatMonthLiquidityReclaimSessionBreakoutUseAsianRange=true`
- `InpFlatMonthLiquidityReclaimSessionBreakoutUseRollingRange=true`
- `InpFlatMonthLiquidityReclaimSessionBreakoutMaxRangeATR=1.35`
- `InpFlatMonthLiquidityReclaimUseLiquidityTarget=true`
- `InpFlatMonthLiquidityReclaimTargetUseSessionRange=true`
- `InpFlatMonthLiquidityReclaimTargetUseAsianRange=true`
- `InpFlatMonthLiquidityReclaimTargetUseSwingLevels=true`
- `InpFlatMonthLiquidityReclaimRequireForwardClearance=true`
- `InpFlatMonthLiquidityReclaimUsePhaseGate=true`
- `InpFlatMonthLiquidityReclaimAllowTransitionPhase=false`
- `InpFlatMonthLiquidityReclaimUseStopClusterBuffer=true`
- `InpFlatMonthLiquidityReclaimUseStopPocketShift=true`

The offline package now prepares 14 profiles across 12 weak/flat/control windows, or `168` total configs.

## Verification

Completed local checks:

- `work/build_flat_month_liquidity_reclaim_probe_package.ps1`: built `168` configs
- `work/test_price_action_strategy_modules.ps1`: `PRICE_ACTION_STRATEGY_MODULES_SMOKE_PASS`
- `work/test_flat_month_liquidity_reclaim_probe_package.ps1`: `FLAT_MONTH_LIQUIDITY_RECLAIM_PROBE_PACKAGE_SMOKE_PASS`
- `work/test_flat_month_liquidity_reclaim_compact_source.ps1`: `FLAT_MONTH_LIQUIDITY_RECLAIM_COMPACT_SOURCE_SMOKE_PASS`
- `work/test_adaptive_reverse_quarantine.ps1`: `ADAPTIVE_REVERSE_QUARANTINE_SMOKE_PASS`
- `work/audit_mt5_local_safety.ps1`: `PASS`, `39 / 39`

Root and canonical EA copies match:

`Professional_XAUUSD_EA.mq5` equals `outputs/Professional_XAUUSD_EA.mq5`.

## Decision

Do not promote. This is only the next untested FMLR candidate for hidden/local MT5 execution.

The current stability-best profile remains:

`Score7 Regime No-M1-Shock Dec-ISLP-Off + ISLP LowATR OrderFlow`

MT5 compile/backtest remains pending because `work/MT5_LOCAL_LAUNCH_DISABLED.lock` is active to prevent window focus theft.
