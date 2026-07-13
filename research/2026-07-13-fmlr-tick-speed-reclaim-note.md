# FMLR Tick-Speed Reclaim Note

Date: 2026-07-13

Status: local source/package generated, not MT5 backtested, not promoted.

## Summary

Added a default-off FMLR tick-speed reclaim path using the existing `InpUseTickSpeedImpulse` input.

When enabled by a candidate profile, FMLR can now tag a setup as:

`FMLR tick-speed reclaim`

The path requires:

- directional tick-speed impulse from the existing tick-speed helper
- existing FMLR sweep/reclaim context
- no Adaptive Reverse
- FMLR order-flow and forward-clearance controls from the candidate profile

The path can participate in the protected structural runner setup list, which lets the existing runner-target stretch logic test whether fast tape movement after a liquidity reclaim captures more of flat-month moves.

## New Validation Profile

Added isolated profile:

`fmlr_tick_speed_reclaim`

The profile enables `InpUseTickSpeedImpulse=true` but leaves the tick-speed thresholds at EA defaults to avoid bloating the compact tester source. It also requires order flow, forward clearance, liquidity targets, stop-pocket shift, stop-cluster buffering, runner-target stretch, and FMLR structure trailing.

## Package Counts

- Full FMLR package: `456` Model4 configs, `38` profiles
- Fast FMLR screen: `150` Model4 configs, `25` profiles
- `fmlr_tick_speed_reclaim` appears in both packages

## Local Checks Passed

- `PRICE_ACTION_STRATEGY_MODULES_SMOKE_PASS`
- `FLAT_MONTH_LIQUIDITY_RECLAIM_PROBE_PACKAGE_SMOKE_PASS`
- `FLAT_MONTH_LIQUIDITY_RECLAIM_FAST_PROBE_PACKAGE_SMOKE_PASS`
- `FLAT_MONTH_LIQUIDITY_RECLAIM_COMPACT_SOURCE_SMOKE_PASS`

## Source Hash

`B6AA1915D2CA7483B1066C227F2506D7A85756D918820FF1100BAF66B0FBDBBE`

## Decision

Do not promote.

This is an opportunity-expansion candidate for local hidden MT5 testing. It should only compete against `lowatr_current` after the 150-config fast screen shows better net profit without adding red control windows.
