# FMLR Range Failure Reclaim Note

Date: 2026-07-13

Status: code-only, default-off, not promoted, not backtested.

## Intent

Flat months can produce failed breaks around Asian or rolling ranges: price sweeps outside the box, rejects, and closes back inside. The existing FMLR sweep/reclaim path looks for liquidity sweeps, while the session-range breakout path looks for clean expansion. This candidate covers the opposite case: failed expansion back into the range.

The stop is structural. It is anchored beyond the failed range edge, not built from a plain ATR stop. The optional target is the opposite side of the failed range, capped by ATR so the profile does not chase an unrealistic box target.

## Added Controls

- `InpFlatMonthLiquidityReclaimUseRangeFailureReclaim=false`
- `InpFlatMonthLiquidityReclaimRequireRangeFailureReclaim=false`
- `InpFlatMonthLiquidityReclaimRangeFailureUseAsianRange=true`
- `InpFlatMonthLiquidityReclaimRangeFailureUseRollingRange=true`
- `InpFlatMonthLiquidityReclaimRangeFailureLookbackHours=6`
- `InpFlatMonthLiquidityReclaimRangeFailureMaxRangeATR=1.60`
- `InpFlatMonthLiquidityReclaimRangeFailureBreakBufferPoints=18.0`
- `InpFlatMonthLiquidityReclaimRangeFailureMinBodyPercent=28.0`
- `InpFlatMonthLiquidityReclaimRangeFailureMinCloseLocation=0.58`
- `InpFlatMonthLiquidityReclaimRangeFailureMinReclaimPercent=0.18`
- `InpFlatMonthLiquidityReclaimRangeFailureUseRangeTarget=true`
- `InpFlatMonthLiquidityReclaimRangeFailureMinTargetATR=0.70`
- `InpFlatMonthLiquidityReclaimRangeFailureMaxTargetATR=2.20`

## Logic

When enabled, `FlatMonthLiquidityRangeFailureReclaimLevel`:

- tests the Asian range if enabled
- tests a rolling range if enabled
- rejects ranges wider than the max ATR range
- requires the signal candle to break outside the selected range by a point buffer
- requires the candle to close back inside the range by a minimum reclaim percentage
- requires body strength and close-location strength
- selects the narrower valid range when both Asian and rolling ranges qualify
- returns the failed edge as the structural stop level and the opposite edge as the range target

The main FMLR lane can use this as a substitute setup when no sweep/reclaim is present. If `InpFlatMonthLiquidityReclaimRequireRangeFailureReclaim=true`, the candidate rejects non-range-failure setups.

## Probe Profile

New package profile:

`fmlr_range_failure_reclaim`

Important settings:

- `InpFlatMonthLiquidityReclaimRiskMultiplier=0.12`
- `InpFlatMonthLiquidityReclaimMaxMonthlyEntries=5`
- `InpFlatMonthLiquidityReclaimSpacingMinutes=240`
- `InpFlatMonthLiquidityReclaimMinScore=7`
- `InpFlatMonthLiquidityReclaimMinRR=0.95`
- `InpFlatMonthLiquidityReclaimRequireOrderFlow=true`
- `InpFlatMonthLiquidityReclaimUseImbalanceRetest=true`
- `InpFlatMonthLiquidityReclaimAllowImbalanceInsteadOfOrderFlow=true`
- `InpFlatMonthLiquidityReclaimUseRangeFailureReclaim=true`
- `InpFlatMonthLiquidityReclaimRequireRangeFailureReclaim=true`
- `InpFlatMonthLiquidityReclaimRangeFailureUseAsianRange=true`
- `InpFlatMonthLiquidityReclaimRangeFailureUseRollingRange=true`
- `InpFlatMonthLiquidityReclaimRangeFailureUseRangeTarget=true`
- `InpFlatMonthLiquidityReclaimUsePhaseGate=true`
- `InpFlatMonthLiquidityReclaimAllowTrendPhase=false`
- `InpFlatMonthLiquidityReclaimAllowRangePhase=true`
- `InpFlatMonthLiquidityReclaimAllowTransitionPhase=false`
- `InpFlatMonthLiquidityReclaimUseStopClusterBuffer=true`
- `InpFlatMonthLiquidityReclaimUseStopPocketShift=true`

The offline package now prepares 15 profiles across 12 weak/flat/control windows, or `180` total configs.

## Verification

Completed local checks:

- `work/build_flat_month_liquidity_reclaim_probe_package.ps1`: built `180` configs
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
