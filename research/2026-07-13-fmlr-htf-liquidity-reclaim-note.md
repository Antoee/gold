# FMLR HTF Liquidity Reclaim Note

Date: 2026-07-13

Status: code-only, default-off, not promoted, not backtested.

## Intent

Gold often reacts around previous day and previous week highs/lows. This candidate adds a default-off FMLR setup for higher-timeframe liquidity sweeps: price pierces a prior high/low, reclaims back through it, and uses the swept level as structural context.

This directly targets the flat-month activity problem without enabling martingale, grid, averaging down, Adaptive Reverse, or pure ATR-only stop placement.

## Added Controls

- `InpFlatMonthLiquidityReclaimUseHTFLiquidityReclaim=false`
- `InpFlatMonthLiquidityReclaimRequireHTFLiquidityReclaim=false`
- `InpFlatMonthLiquidityReclaimHTFUsePreviousDay=true`
- `InpFlatMonthLiquidityReclaimHTFUsePreviousWeek=false`
- `InpFlatMonthLiquidityReclaimHTFUsePreviousMonth=false`
- `InpFlatMonthLiquidityReclaimHTFBreakBufferPoints=20.0`
- `InpFlatMonthLiquidityReclaimHTFMinReclaimATR=0.05`
- `InpFlatMonthLiquidityReclaimHTFMinBodyPercent=26.0`
- `InpFlatMonthLiquidityReclaimHTFMinCloseLocation=0.56`
- `InpFlatMonthLiquidityReclaimHTFMaxLevelDistanceATR=1.80`
- `InpFlatMonthLiquidityReclaimHTFUseOppositeTarget=true`
- `InpFlatMonthLiquidityReclaimHTFMinTargetATR=0.75`
- `InpFlatMonthLiquidityReclaimHTFMaxTargetATR=2.60`

## Logic

When enabled, `FlatMonthLiquidityHTFReclaimLevel`:

- tests the previous day level if enabled
- tests the previous week level if enabled
- tests the previous month level only if explicitly enabled
- requires a sweep beyond the selected high/low by a point buffer
- requires a reclaim back through that level by a minimum ATR distance
- requires body strength and close-location strength
- rejects entries that are already too far from the reclaimed level
- anchors the stop beyond the swept HTF level
- optionally targets the opposite side of the same HTF range, capped by ATR

## Probe Profile

New package profile:

`fmlr_htf_reclaim`

Important settings:

- `InpFlatMonthLiquidityReclaimRiskMultiplier=0.12`
- `InpFlatMonthLiquidityReclaimMaxMonthlyEntries=5`
- `InpFlatMonthLiquidityReclaimSpacingMinutes=240`
- `InpFlatMonthLiquidityReclaimMinScore=7`
- `InpFlatMonthLiquidityReclaimMinRR=0.95`
- `InpFlatMonthLiquidityReclaimRequireOrderFlow=true`
- `InpFlatMonthLiquidityReclaimUseImbalanceRetest=true`
- `InpFlatMonthLiquidityReclaimAllowImbalanceInsteadOfOrderFlow=true`
- `InpFlatMonthLiquidityReclaimUseHTFLiquidityReclaim=true`
- `InpFlatMonthLiquidityReclaimRequireHTFLiquidityReclaim=true`
- `InpFlatMonthLiquidityReclaimHTFUsePreviousDay=true`
- `InpFlatMonthLiquidityReclaimHTFUsePreviousWeek=true`
- `InpFlatMonthLiquidityReclaimHTFUsePreviousMonth=false`
- `InpFlatMonthLiquidityReclaimHTFUseOppositeTarget=true`
- `InpFlatMonthLiquidityReclaimUsePhaseGate=true`
- `InpFlatMonthLiquidityReclaimAllowTransitionPhase=false`
- `InpFlatMonthLiquidityReclaimUseStopClusterBuffer=true`
- `InpFlatMonthLiquidityReclaimUseStopPocketShift=true`

The offline package now prepares 16 profiles across 12 weak/flat/control windows, or `192` total configs.

## Verification

Completed local checks:

- `work/build_flat_month_liquidity_reclaim_probe_package.ps1`: built `192` configs
- `work/test_price_action_strategy_modules.ps1`: `PRICE_ACTION_STRATEGY_MODULES_SMOKE_PASS`
- `work/test_flat_month_liquidity_reclaim_probe_package.ps1`: `FLAT_MONTH_LIQUIDITY_RECLAIM_PROBE_PACKAGE_SMOKE_PASS`
- `work/test_flat_month_liquidity_reclaim_compact_source.ps1`: `FLAT_MONTH_LIQUIDITY_RECLAIM_COMPACT_SOURCE_SMOKE_PASS`
- `work/test_adaptive_reverse_quarantine.ps1`: `ADAPTIVE_REVERSE_QUARANTINE_SMOKE_PASS`
- `work/audit_mt5_local_safety.ps1`: `PASS`, `39 / 39`
- `work/test_ea_source_artifact_sync.ps1`: `EA_SOURCE_ARTIFACT_SYNC_SMOKE_PASS`

Root and canonical EA copies match:

`Professional_XAUUSD_EA.mq5` equals `outputs/Professional_XAUUSD_EA.mq5`.

## Decision

Do not promote. This is only the next untested FMLR candidate for hidden/local MT5 execution.

The current stability-best profile remains:

`Score7 Regime No-M1-Shock Dec-ISLP-Off + ISLP LowATR OrderFlow`

MT5 compile/backtest remains pending because `work/MT5_LOCAL_LAUNCH_DISABLED.lock` is active to prevent window focus theft.
