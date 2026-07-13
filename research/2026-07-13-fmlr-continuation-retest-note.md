# FMLR Continuation Retest Note

Date: 2026-07-13

Status: code-only, default-off, not promoted, not backtested.

## Intent

The FMLR lane can already take an immediate sweep/reclaim and a simple recent retest, but that still risks being too sparse in flat months. This change adds a stricter continuation-retest mode: a prior sweep/reclaim creates the setup, and a later signal candle must retest the reclaimed level without chasing too far away from structure.

The goal is more participation in inactive months without enabling Adaptive Reverse, martingale, grid, averaging down, or looser ATR-only stops.

## Added Controls

- `InpFlatMonthLiquidityReclaimUseContinuationRetest=false`
- `InpFlatMonthLiquidityReclaimRequireContinuationRetest=false`
- `InpFlatMonthLiquidityReclaimContinuationLookbackBars=8`
- `InpFlatMonthLiquidityReclaimContinuationMaxPullbackATR=0.65`
- `InpFlatMonthLiquidityReclaimContinuationMinBodyPercent=24.0`
- `InpFlatMonthLiquidityReclaimContinuationRequireEMAHold=false`
- `InpFlatMonthLiquidityReclaimContinuationRequireVWAPHold=false`

## Logic

When enabled, `FlatMonthLiquidityContinuationRetestLevel` scans for a recent sweep/reclaim and then requires the current signal candle to:

- retest the reclaimed level within the existing FMLR retest tolerance
- close back on the correct side of that level
- stay within `InpFlatMonthLiquidityReclaimContinuationMaxPullbackATR`
- meet the continuation body threshold
- optionally hold the fast EMA
- optionally hold VWAP

The profile-level candidate requires EMA hold by default, leaves VWAP hold optional, and still uses the FMLR structural stop path rather than a pure ATR stop.

## Probe Profile

New package profile:

`fmlr_continuation_retest`

Important settings:

- `InpFlatMonthLiquidityReclaimRiskMultiplier=0.12`
- `InpFlatMonthLiquidityReclaimMaxMonthlyEntries=5`
- `InpFlatMonthLiquidityReclaimSpacingMinutes=300`
- `InpFlatMonthLiquidityReclaimMinScore=7`
- `InpFlatMonthLiquidityReclaimMinRR=1.00`
- `InpFlatMonthLiquidityReclaimUseContinuationRetest=true`
- `InpFlatMonthLiquidityReclaimRequireContinuationRetest=true`
- `InpFlatMonthLiquidityReclaimContinuationRequireEMAHold=true`
- `InpFlatMonthLiquidityReclaimUseLiquidityTarget=true`
- `InpFlatMonthLiquidityReclaimRequireForwardClearance=true`
- `InpFlatMonthLiquidityReclaimUsePhaseGate=true`
- `InpFlatMonthLiquidityReclaimAllowTransitionPhase=false`
- `InpFlatMonthLiquidityReclaimUseStopClusterBuffer=true`
- `InpFlatMonthLiquidityReclaimUseStopPocketShift=true`

The offline package now prepares 12 profiles across 12 windows, or `144` total configs.

## Verification

Completed local checks:

- `work/build_flat_month_liquidity_reclaim_probe_package.ps1`: built `144` configs
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
