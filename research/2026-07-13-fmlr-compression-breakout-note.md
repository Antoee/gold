# FMLR Compression Breakout Note

Date: 2026-07-13

Status: code-only, default-off, not promoted, not backtested.

## Intent

Flat months can spend long stretches compressing in narrow ranges before expanding. The existing FMLR sweep/reclaim logic may miss those moves if there is no clean liquidity sweep first. This change adds a default-off compression-breakout substitute setup that can enter after a tight box breaks cleanly.

The stop is not a plain ATR multiple. The candidate anchors the stop beyond the opposite side of the compression box, then still allows the existing cluster buffer and pocket shift logic to move the stop beyond nearby liquidity.

## Added Controls

- `InpFlatMonthLiquidityReclaimUseCompressionBreakout=false`
- `InpFlatMonthLiquidityReclaimRequireCompressionBreakout=false`
- `InpFlatMonthLiquidityReclaimCompressionLookbackBars=14`
- `InpFlatMonthLiquidityReclaimCompressionMaxRangeATR=1.05`
- `InpFlatMonthLiquidityReclaimCompressionBreakBufferPoints=15.0`
- `InpFlatMonthLiquidityReclaimCompressionMinBodyPercent=40.0`
- `InpFlatMonthLiquidityReclaimCompressionMinCloseLocation=0.62`
- `InpFlatMonthLiquidityReclaimCompressionMinBreakRangeATR=0.45`

## Logic

When enabled, `FlatMonthLiquidityCompressionBreakoutLevel`:

- scans the prior compression box using the FMLR compression lookback
- rejects boxes wider than the max ATR range
- requires the current candle to break outside the box by a point buffer
- requires body strength and close-location strength
- requires minimum breakout candle range
- returns the opposite side of the box as the structural stop level

The main FMLR lane can use this as a substitute setup when no sweep/reclaim is present. If `InpFlatMonthLiquidityReclaimRequireCompressionBreakout=true`, the candidate rejects non-compression setups.

## Probe Profile

New package profile:

`fmlr_compression_breakout`

Important settings:

- `InpFlatMonthLiquidityReclaimRiskMultiplier=0.12`
- `InpFlatMonthLiquidityReclaimMaxMonthlyEntries=5`
- `InpFlatMonthLiquidityReclaimSpacingMinutes=300`
- `InpFlatMonthLiquidityReclaimMinScore=7`
- `InpFlatMonthLiquidityReclaimMinRR=1.00`
- `InpFlatMonthLiquidityReclaimUseCompressionBreakout=true`
- `InpFlatMonthLiquidityReclaimRequireCompressionBreakout=true`
- `InpFlatMonthLiquidityReclaimUseLiquidityTarget=true`
- `InpFlatMonthLiquidityReclaimRequireForwardClearance=true`
- `InpFlatMonthLiquidityReclaimUsePhaseGate=true`
- `InpFlatMonthLiquidityReclaimAllowTransitionPhase=false`
- `InpFlatMonthLiquidityReclaimUseStopClusterBuffer=true`
- `InpFlatMonthLiquidityReclaimUseStopPocketShift=true`

The offline package now prepares 13 profiles across 12 windows, or `156` total configs.

## Verification

Completed local checks:

- `work/build_flat_month_liquidity_reclaim_probe_package.ps1`: built `156` configs
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
