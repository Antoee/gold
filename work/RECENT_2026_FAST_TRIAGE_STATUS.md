# Recent 2026 Fast Triage Status

Updated: 2026-07-07 17:23:18 -05:00

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- Full EA source exists locally, but this note is the GitHub-safe status/evidence artifact.

## Latest Strategy-Code Change

Added a mediocre/weak-setup risk throttle. This optional feature still allows trades, but cuts position risk when the setup quality and price-action scores are below the configured high-upside thresholds.

New inputs and logic:

- `InpUseMediocreSetupRiskThrottle`
- `InpMediocreSetupMinQualityScore`
- `InpMediocreSetupMinPriceActionScore`
- `InpMediocreSetupRiskMultiplier`
- `InpMediocreSetupBypassWithHouseMoney`
- `MediocreSetupRiskMultiplier(...)`
- Entry logs add `Mediocre setup risk x...` when the throttle reduces risk.

This supports the goal by protecting risk budget during mediocre setups while leaving the "press harder with protected house money" path intact. The baseline remains unchanged, and this does not add martingale, grid, averaging down, or recovery behavior.

## Fast Batch Impact

- Batch size stayed at 10 profiles and 30 runs.
- Estimated tester runtime stayed at about 10.5 minutes before platform overhead.
- Baseline anchor remains conservative and keeps the new throttle disabled.
- Generated research profiles now use:
  - `InpUseMediocreSetupRiskThrottle=true`
  - `InpMediocreSetupMinQualityScore=12`
  - `InpMediocreSetupMinPriceActionScore=14`
  - `InpMediocreSetupRiskMultiplier=0.50`
  - `InpMediocreSetupBypassWithHouseMoney=true`

## Quiet Validation Results

- `work\test_price_action_strategy_modules.ps1`: PASS
- `work\sync_ea_source_artifacts.ps1`: PASS, hash `BF3D8244AD39D85E95DD663FFED1B4DEC9F3373BC5D99E9A89AACF2B0118784A`
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
- Stop marker: present at `work\STOP_MT5_FOCUS_WATCHDOG`

## Latest Evidence

- `outputs\Professional_XAUUSD_EA.mq5`: `BF3D8244AD39D85E95DD663FFED1B4DEC9F3373BC5D99E9A89AACF2B0118784A`
- `Professional_XAUUSD_EA.mq5`: `BF3D8244AD39D85E95DD663FFED1B4DEC9F3373BC5D99E9A89AACF2B0118784A`
- `outputs\external_mt5_validation_package\source\Professional_XAUUSD_EA.mq5`: `BF3D8244AD39D85E95DD663FFED1B4DEC9F3373BC5D99E9A89AACF2B0118784A`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `E2835758726ADCF61D8B35FFE76F05B61BD449A53B3E1FB5D47AEA7FFD21107C`
- `outputs\xauusd_micro_validation_package.zip`: `6F0DDF972934DCAE66C90F3F76B47B6D1E341192A713DE31248095F36B1711DA`
- `work\build_price_action_strategy_batch.ps1`: `53F0CB561DFE8478472D69F3733CADA8FFDA58C2EFF34649F1AC5843A6B4955F`
- `work\test_price_action_strategy_modules.ps1`: `6CCCB5599FAB6D0330A382778B9CA0BE44A9CC7393824484B622D7737251B4C8`
- `work\test_price_action_strategy_batch.ps1`: `BD818A2E18552769E69CAB593A2A423919065D230908DE3FAF87C93BC614BD09`
- `outputs\OFFLINE_VALIDATION_REFRESH.csv`: `79AE01A0F0C864E17DE2831470A2D4FD5A2C014700A0ED11E64E9145AABFDDBC`

## Background-Safety Note

The stop marker remains present at `work\STOP_MT5_FOCUS_WATCHDOG`. Any future MT5 validation should be treated as external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The status note is committed through the GitHub connector. The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that the status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.
