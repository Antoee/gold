# Current Research Best Profile

Last updated: 2026-07-13 after the FMLR sweep-runner package refresh.

## Profile

`Score7 Regime No-M1-Shock Dec-ISLP-Off + ISLP LowATR OrderFlow`

Status: current stability-best research profile. Not live-ready.

## Exact Profile Identity

Generated locally by:

`work/build_realtick_islp_lowatr_orderflow_probe_package.ps1`

Local generated `.set` file:

`outputs/CANDIDATE_DEC_ISLP_OFF_ISLP_LOWATR_ORDERFLOW_PROFILE.set`

SHA-256:

`D0867E0333D3F110EF47410A2B2FF46402AAD96FC70B0DBF9506836124D633BC`

## Current Judgment

Keep LowATR OrderFlow as the most stable promoted research profile. Do not promote the latest FMLR work yet because it has not been MT5 backtested.

## Latest Default-Off Research Code

The local EA source includes a default-off Flat Month Liquidity Reclaim lane tagged `FMLR;`.

Latest source hash:

`10D1007CFD4CB124C8DE6EC247E1DE1611F1A7955E4E8EC2F9816B2A238DFA04`

Latest source change:

- Non-structural liquidity-sweep reclaims can use the existing runner-target stretch path when forward liquidity, sweep evidence, and quality confirmation exist.
- The EA logs `FMLR sweep runner` only when the target actually stretches.

Latest package/profile change:

- Added isolated `fmlr_sweep_runner` validation profile.
- It tests the non-structural sweep-runner payoff path without requiring sweep-displacement BOS.
- Full FMLR package: `432` Model4 configs, `36` profiles.
- Fast FMLR screen: `138` Model4 configs, `23` profiles.

Status:

- Not part of the current research-best profile.
- Not promoted.
- Not backtested yet.
- MT5 compile/backtest pending while `work/MT5_LOCAL_LAUNCH_DISABLED.lock` remains active.

## Local Checks Passed

- `PRICE_ACTION_STRATEGY_MODULES_SMOKE_PASS`
- `EA_SOURCE_ARTIFACT_SYNC_SMOKE_PASS`
- `FLAT_MONTH_LIQUIDITY_RECLAIM_PROBE_PACKAGE_SMOKE_PASS`
- `FLAT_MONTH_LIQUIDITY_RECLAIM_FAST_PROBE_PACKAGE_SMOKE_PASS`
- `FLAT_MONTH_LIQUIDITY_RECLAIM_COMPACT_SOURCE_SMOKE_PASS`
- `ADAPTIVE_REVERSE_QUARANTINE_SMOKE_PASS`
- `MT5_HIDDEN_LAUNCHER_LOCK_SMOKE_PASS`
- MT5 local safety audit: `PASS 39 / 39`

## Latest Research Notes

- `research/2026-07-13-fmlr-sweep-runner-profile-note.md`
- `research/2026-07-13-fmlr-sweep-runner-target-note.md`
- `research/2026-07-13-repository-cleanup-refresh-note.md`
- `research/2026-07-13-flat-month-liquidity-reclaim-lane-note.md`

## Source Sync Warning

This GitHub file was refreshed through the GitHub connector. The local folder is not currently a valid Git checkout because `.git` is empty, and shell Git has no GitHub credentials. The local EA source may still be ahead of GitHub until a proper authenticated Git push is available.
