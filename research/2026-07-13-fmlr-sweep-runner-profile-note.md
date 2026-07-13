# FMLR Sweep-Runner Package Profile Note

Date: 2026-07-13

Status: local package generated, not backtested, not promoted.

## Summary

Added an isolated `fmlr_sweep_runner` validation profile to the FMLR full and fast packages.

This profile exists because the source now allows clean non-structural liquidity-sweep reclaims to use the runner-target stretch path when forward liquidity, sweep evidence, and quality confirmation exist.

The EA source logs:

`FMLR sweep runner`

only when the target actually stretches.

## Why This Matters

The previous `fmlr_runner_target_stretch` profile requires sweep-displacement BOS, so it mostly exercises the structural runner path.

The new `fmlr_sweep_runner` profile isolates the cleaner sweep-reclaim payoff path without requiring sweep-displacement BOS.

## Package Counts

- Full FMLR package: `432` Model4 configs, `36` profiles
- Fast FMLR screen: `138` Model4 configs, `23` profiles
- `fmlr_sweep_runner` appears in both packages

## Local Checks Passed

- `FLAT_MONTH_LIQUIDITY_RECLAIM_PROBE_PACKAGE_SMOKE_PASS`
- `FLAT_MONTH_LIQUIDITY_RECLAIM_FAST_PROBE_PACKAGE_SMOKE_PASS`
- `FLAT_MONTH_LIQUIDITY_RECLAIM_COMPACT_SOURCE_SMOKE_PASS`
- `PRICE_ACTION_STRATEGY_MODULES_SMOKE_PASS`
- `EA_SOURCE_ARTIFACT_SYNC_SMOKE_PASS`
- `ADAPTIVE_REVERSE_QUARANTINE_SMOKE_PASS`
- `MT5_HIDDEN_LAUNCHER_LOCK_SMOKE_PASS`
- MT5 local safety audit: `PASS 39 / 39`

## Decision

Do not promote.

This is a validation profile only. It needs local hidden MT5 testing before it can compete with `lowatr_current` or the current stability-best LowATR OrderFlow profile.
