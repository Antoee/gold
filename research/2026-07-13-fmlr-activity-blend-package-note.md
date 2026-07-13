# FMLR Activity Blend Package Note

Date: 2026-07-13

Status: package/profile refinement only. Not promoted and not MT5-backtested yet.

## Purpose

The flat-month bottleneck remains the main opportunity-cost problem. Prior single-lane flat-month probes either matched the current best without adding trades or degraded robustness.

This pass adds two low-risk package profiles that combine already-protected FMLR structural triggers instead of loosening the whole EA:

- `fmlr_activity_blend`
- `fmlr_activity_blend_tight`

The intent is to test whether a controlled blend can wake zero-trade months while keeping Adaptive Reverse off and avoiding pure ATR-only stops.

## Generated Profiles

`outputs/CANDIDATE_FMLR_ACTIVITY_BLEND_PROFILE.set`

SHA-256:

`149481621EC3194A08CF2B291033FEA38AE7D40B1EDA677820780A51F9A9DBDB`

Key settings:

- `InpFlatMonthLiquidityReclaimRiskMultiplier=0.08`
- `InpFlatMonthLiquidityReclaimMaxMonthlyEntries=6`
- `InpFlatMonthLiquidityReclaimMinScore=9`
- order flow required
- forward clearance required
- forward liquidity targets enabled
- session, Asian, swing, previous-day, and previous-week targets enabled
- stop-cluster buffer enabled
- stop-pocket shift enabled
- FMLR structure trail enabled
- tick-speed confirmation enabled
- Adaptive Reverse disabled

`outputs/CANDIDATE_FMLR_ACTIVITY_BLEND_TIGHT_PROFILE.set`

SHA-256:

`50F2000B153458B5DB494DD6AA873BDD6256F2C8B3AE11BABE5E4C615E2BC67A`

Key differences:

- `InpFlatMonthLiquidityReclaimRiskMultiplier=0.10`
- `InpFlatMonthLiquidityReclaimMaxMonthlyEntries=5`
- `InpFlatMonthLiquidityReclaimMinScore=11`
- `InpFlatMonthLiquidityReclaimMinRR=1.05`
- `InpFlatMonthLiquidityReclaimMinClearanceATR=1.10`
- larger runner target stretch
- slightly wider structural stop-pocket buffer

## Package Counts

- Full FMLR package: `480` Model4 configs, `40` profiles.
- Fast FMLR screen: `162` Model4 configs, `27` profiles.

Both activity-blend profiles appear in the full package and fast screen.

## Why This Is Safer Than Broad Relaxation

The blend does not enable martingale, grid, averaging down, recovery sizing, or Adaptive Reverse.

It also does not remove the structural protections:

- FMLR still requires protected liquidity-reclaim context.
- Order-flow confirmation remains required.
- Forward clearance remains required.
- Structural target logic remains active.
- Stop-pocket and stop-cluster logic remain active.
- Structure trailing remains available.

## Required Next Test

Run the fast `162`-config Model4 screen first.

Promote nothing unless a blend profile:

- beats `lowatr_current` net profit,
- increases active windows,
- does not add red control windows,
- does not worsen 2026 May / June controls,
- and still passes full-report drawdown and trade-quality review.

No new profit claim is made by this note.
