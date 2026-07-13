# FMLR Sweep Unlimited Runner Note

Date: 2026-07-13

Status: local source/package generated, not backtested, not promoted.

## Summary

FMLR no-fixed-TP runner permission now recognizes the non-structural sweep-runner path when the signal has:

- `InpFlatMonthLiquidityReclaimUseLiquidityTarget=true`
- `InpFlatMonthLiquidityReclaimRequireForwardClearance=true`
- `FMLR sweep runner`
- `FMLR forward clearance`
- runner-stretch evidence
- FMLR structure trailing enabled

The planned stretched target still has to pass minimum RR and spread-adjusted RR before entry. The change only affects default-off FMLR runner profiles and does not enable martingale, grid, averaging down, recovery sizing, or Adaptive Reverse.

## New Validation Profile

Added isolated profile:

`fmlr_sweep_unlimited_runner`

The profile keeps non-structural sweep-displacement BOS optional/off, but requires stricter quality, forward clearance, runner target stretch, structure trailing, and structural stop-pocket controls.

## Package Counts

- Full FMLR package: `444` Model4 configs, `37` profiles
- Fast FMLR screen: `144` Model4 configs, `24` profiles
- `fmlr_sweep_unlimited_runner` appears in both packages

## Local Checks Passed

- `PRICE_ACTION_STRATEGY_MODULES_SMOKE_PASS`
- `FLAT_MONTH_LIQUIDITY_RECLAIM_PROBE_PACKAGE_SMOKE_PASS`
- `FLAT_MONTH_LIQUIDITY_RECLAIM_FAST_PROBE_PACKAGE_SMOKE_PASS`
- `FLAT_MONTH_LIQUIDITY_RECLAIM_COMPACT_SOURCE_SMOKE_PASS`
- `EA_SOURCE_ARTIFACT_SYNC_SMOKE_PASS`
- `ADAPTIVE_REVERSE_QUARANTINE_SMOKE_PASS`
- `MT5_HIDDEN_LAUNCHER_LOCK_SMOKE_PASS`
- MT5 local safety audit: `PASS 39 / 39`

## Source Hash

`0289641ABE4F1B93FB69D81FF098FFBAA28FFA14478282ACD0BCA4B3A1CBAFC3`

## Decision

Do not promote.

This is a profit-capture candidate for local hidden MT5 testing. It should only compete against `lowatr_current` after the fast 144-config screen shows better net profit without adding red control windows.
