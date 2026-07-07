# Recent 2026 Fast Triage Status

Updated: 2026-07-07

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- Full EA source exists locally, but this note is the GitHub-safe status/evidence artifact.

## Latest Strategy-Code Change

Added starting-equity recovery risk scaling. This optional risk-management layer reduces position risk whenever account equity is below the original starting equity.

New inputs and logic:

- `InpUseStartingEquityRecoveryRiskScaling`
- `InpStartingEquityRecoveryRiskStartDrawdownPercent`
- `InpStartingEquityRecoveryRiskFullDrawdownPercent`
- `InpMinStartingEquityRecoveryRiskMultiplier`
- `EffectiveRiskPercent()` now applies a below-start risk multiplier before profit-pressing boosts.
- Generated research profiles reduce risk from normal down toward 0.35x as equity moves from 0.25% to 3.00% below starting equity.

This supports the goal by making red-zone trades smaller as well as rarer. It does not add martingale, grid, averaging down, or recovery behavior.

## Fast Batch Impact

- Batch size stayed at 10 profiles and 30 runs.
- Estimated tester runtime stayed at about 10.5 minutes before platform overhead.
- Baseline anchor keeps starting-equity recovery risk scaling disabled.
- Generated research profiles use:
  - `InpUseStartingEquityRecoveryRiskScaling=true`
  - `InpStartingEquityRecoveryRiskStartDrawdownPercent=0.25`
  - `InpStartingEquityRecoveryRiskFullDrawdownPercent=3.00`
  - `InpMinStartingEquityRecoveryRiskMultiplier=0.35`

## Quiet Validation Results

- `work\test_price_action_strategy_modules.ps1`: PASS
- `work\sync_ea_source_artifacts.ps1`: PASS, hash `B024E606FE6D5894715BF0D4085F33E9F16B6B8FE1F76754A33CF48337C1BBE7`
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

- `outputs\Professional_XAUUSD_EA.mq5`: `B024E606FE6D5894715BF0D4085F33E9F16B6B8FE1F76754A33CF48337C1BBE7`
- `Professional_XAUUSD_EA.mq5`: `B024E606FE6D5894715BF0D4085F33E9F16B6B8FE1F76754A33CF48337C1BBE7`
- `outputs\external_mt5_validation_package\source\Professional_XAUUSD_EA.mq5`: `B024E606FE6D5894715BF0D4085F33E9F16B6B8FE1F76754A33CF48337C1BBE7`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `B84D912E06A68B30E57200055451F403E93319417437A8BB8B45D98AD08059BB`
- `outputs\xauusd_micro_validation_package.zip`: `E8BAC5C4D2BF75E10F5735BD05D366DBC6EE2F16387C75706FE04F84971BE10C`
- `work\build_price_action_strategy_batch.ps1`: `76F25072049D9E18AD3ABA71714A1ABC535777A2E138D983C3D45F01908128E1`
- `work\test_price_action_strategy_modules.ps1`: `EFD58A2CF03AD8A6B5D08D1395BA57D15B09903EB7C9538B7AA2BE90E861CABA`
- `work\test_price_action_strategy_batch.ps1`: `437A1AEFDB7F0DB0DE16FA65919142EF65406E3D9E6C047BFB707FC262979CA4`
- `outputs\OFFLINE_VALIDATION_REFRESH.csv`: `D03A225732F13C93C1C5D5A4EA95A9FF4254D8D29A8018D9F19680461EB39100`

## Background-Safety Note

The stop marker remains present at `work\STOP_MT5_FOCUS_WATCHDOG`. Any future MT5 validation should be treated as external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The status note is committed through the GitHub connector. The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that the status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.