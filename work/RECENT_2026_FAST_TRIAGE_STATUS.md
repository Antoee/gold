# Recent 2026 Fast Triage Status

Updated: 2026-07-06

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- Full EA source exists locally, but this note is the GitHub-safe status/evidence artifact.

## Latest Strategy-Code Change

Added post-partial runner take-profit expansion. Once a trade has already banked partial profit or basket-harvest profit, the EA can extend the remaining TP one time if the runner is still healthy and protected.

New inputs and logic:

- `InpUsePostPartialRunnerTPExpansion`
- `InpPostPartialRunnerTPMultiplier`
- `InpPostPartialRunnerMinR`
- `InpPostPartialRunnerRequireProtectedStop`
- `PostPartialRunnerTPExpansion()` expands an existing TP only once after a partial marker exists.
- The feature uses a separate `PXEA_POST_PARTIAL_TP_` marker to prevent repeated TP expansion.
- It can require the stop to already be protected before widening the target.
- The event logs `post partial runner TP expansion`.

This supports the goal by letting secured winners reach for more profit without increasing initial risk. Generated research profiles use a 1.35x TP expansion after partial profit, with a minimum +0.75R runner and protected-stop requirement. It adds no martingale, grid, averaging down, or recovery behavior.

## Fast Batch Impact

- Batch size stayed at 10 profiles and 30 runs.
- Estimated tester runtime stayed at about 10.5 minutes before platform overhead.
- Baseline anchor keeps post-partial runner TP expansion disabled.
- Generated research profiles use:
  - `InpUsePostPartialRunnerTPExpansion=true`
  - `InpPostPartialRunnerTPMultiplier=1.35`
  - `InpPostPartialRunnerMinR=0.75`
  - `InpPostPartialRunnerRequireProtectedStop=true`

## Quiet Validation Results

- `work\test_price_action_strategy_modules.ps1`: PASS
- `work\sync_ea_source_artifacts.ps1`: PASS, hash `1ADB249BA8E1B1D7FC6703F496A9F20CE39D8E8B253F79294C75BC2994B267A8`
- `work\build_price_action_strategy_batch.ps1`: PASS, 10 profiles, 30 runs, estimated 10.5 minutes
- `work\test_open_risk_exposure_guard.ps1`: PASS
- `work\test_price_action_strategy_decision.ps1`: PASS
- `work\test_loss_streak_risk_reduction.ps1`: PASS
- `work\test_ea_source_artifact_sync.ps1`: PASS
- `work\test_price_action_strategy_batch.ps1`: PASS
- `work\build_external_mt5_validation_package.ps1`: PASS, package configs 20, profiles 9
- `work\test_external_mt5_validation_package.ps1`: PASS, 26 checks, 0 failed
- `work\refresh_offline_validation_state.ps1`: PASS, 40 steps, 0 failed
- MT5-family process scan: empty

## Latest Evidence

- `outputs\Professional_XAUUSD_EA.mq5`: `1ADB249BA8E1B1D7FC6703F496A9F20CE39D8E8B253F79294C75BC2994B267A8`
- `Professional_XAUUSD_EA.mq5`: `1ADB249BA8E1B1D7FC6703F496A9F20CE39D8E8B253F79294C75BC2994B267A8`
- `outputs\external_mt5_validation_package\source\Professional_XAUUSD_EA.mq5`: `1ADB249BA8E1B1D7FC6703F496A9F20CE39D8E8B253F79294C75BC2994B267A8`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `7DB02E343AA4858A35D7106E795D1842329077FAC993B28B596440330F9C48EB`, 35,690 bytes
- `outputs\xauusd_micro_validation_package.zip`: `2A63206AB522AD7464623E3911CCC4311A836ECE33669E55FB73C805B3DC1290`
- `work\build_price_action_strategy_batch.ps1`: `2DAC92965DC7786B6C98EFC1D6F18B8FC0B2AE49B22415DA9F8D8EC8425FDCA1`
- `work\test_price_action_strategy_modules.ps1`: `E287F113DC1C5EEC15B422CE83AFB0553E12E044D2AE2AAA71382A88056E069D`
- `outputs\OFFLINE_VALIDATION_REFRESH.csv`: `7A55117CF917B19DD02967A9DABC50A70704DFD7B58817B41B6FD83C6C8256C6`

## Background-Safety Note

The stop marker remains present at `work\STOP_MT5_FOCUS_WATCHDOG`. Any future MT5 validation should be treated as external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The status note is committed through the GitHub connector. The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that the status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.