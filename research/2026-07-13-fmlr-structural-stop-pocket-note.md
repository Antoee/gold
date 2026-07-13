# FMLR Structural Stop Pocket Note

Date: 2026-07-13

Status: code-only, default-off, not promoted, not backtested.

## Intent

The Flat Month Liquidity Reclaim lane already placed a direct stop beyond the swept liquidity level, but that stop could still sit close to clustered resting liquidity or a nearby stop pocket. This follow-up adds optional stop-side structure controls so the lane can test wider, more market-structure-aware stops without changing the promoted LowATR OrderFlow profile.

## Added Controls

Stop cluster buffer:

- `InpFlatMonthLiquidityReclaimUseStopClusterBuffer=false`
- `InpFlatMonthLiquidityReclaimStopClusterMinTouches=3`
- `InpFlatMonthLiquidityReclaimStopClusterProximityATR=0.20`
- `InpFlatMonthLiquidityReclaimStopClusterProximityPoints=50.0`
- `InpFlatMonthLiquidityReclaimStopClusterExtraBufferATR=0.10`
- `InpFlatMonthLiquidityReclaimStopClusterExtraBufferPoints=30.0`

Stop pocket shift:

- `InpFlatMonthLiquidityReclaimUseStopPocketShift=false`
- `InpFlatMonthLiquidityReclaimStopPocketLookbackBars=24`
- `InpFlatMonthLiquidityReclaimStopPocketProximityATR=0.18`
- `InpFlatMonthLiquidityReclaimStopPocketProximityPoints=45.0`
- `InpFlatMonthLiquidityReclaimStopPocketBufferATR=0.22`
- `InpFlatMonthLiquidityReclaimStopPocketBufferPoints=55.0`

## Probe Profile

New package profile:

`fmlr_structural_stop`

The profile combines the stricter FMLR research path with:

- phase gate enabled
- liquidity/session/Asian/swing targets enabled
- recent retest enabled
- forward clearance enabled
- stop cluster buffer enabled
- stop pocket shift enabled
- `InpFlatMonthLiquidityReclaimRiskMultiplier=0.12`
- `InpFlatMonthLiquidityReclaimMinScore=7`
- `InpFlatMonthLiquidityReclaimMinRR=1.00`
- `InpFlatMonthLiquidityReclaimMaxTargetATR=2.70`

The structural-stop profile remains one of the active FMLR probe profiles. After the session-range breakout follow-up, the offline package now prepares 14 profiles across 12 windows, or `168` total configs.

## Verification

Completed local checks:

- `work/build_flat_month_liquidity_reclaim_probe_package.ps1`: latest package build prepared `168` configs
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

Follow-up note:

`research/2026-07-13-fmlr-continuation-retest-note.md`

Latest follow-up note:

`research/2026-07-13-fmlr-compression-breakout-note.md`

Current latest follow-up note:

`research/2026-07-13-fmlr-session-range-breakout-note.md`
