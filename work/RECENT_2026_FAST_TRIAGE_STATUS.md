# Recent 2026 Fast Triage Status

Updated: 2026-07-07

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- Full EA source exists locally, but this note is the GitHub-safe status/evidence artifact.

## Latest Strategy-Code Change

Added a starting-equity recovery quality gate. This optional entry filter raises the required setup quality whenever account equity is below the starting equity level.

New inputs and logic:

- `InpUseStartingEquityRecoveryQualityGate`
- `InpStartingEquityRecoveryStartDrawdownPercent`
- `InpStartingEquityRecoveryFullDrawdownPercent`
- `InpStartingEquityRecoveryMinQualityScore`
- `InpStartingEquityRecoveryMaxQualityScore`
- `StartingEquityRecoveryQualityAllows()` measures equity drawdown from the original starting equity.
- When equity is below start by the configured threshold, required quality rises from the min score toward the max score.
- Weak new entries are blocked with `starting equity recovery quality`.
- Generated research profiles enable the gate from 0.25% to 3.00% below starting equity, requiring quality score 12 to 18.

This supports the goal by making the EA much pickier while it is below starting equity instead of letting ordinary-quality trades dig deeper. It does not add martingale, grid, averaging down, or recovery behavior.

## Fast Batch Impact

- Batch size stayed at 10 profiles and 30 runs.
- Estimated tester runtime stayed at about 10.5 minutes before platform overhead.
- Baseline anchor keeps starting-equity recovery quality gate disabled.
- Generated research profiles use:
  - `InpUseStartingEquityRecoveryQualityGate=true`
  - `InpStartingEquityRecoveryStartDrawdownPercent=0.25`
  - `InpStartingEquityRecoveryFullDrawdownPercent=3.00`
  - `InpStartingEquityRecoveryMinQualityScore=12`
  - `InpStartingEquityRecoveryMaxQualityScore=18`

## Quiet Validation Results

- `work\test_price_action_strategy_modules.ps1`: PASS
- `work\sync_ea_source_artifacts.ps1`: PASS, hash `11E44DFA30D5F365014E412E581927CBC549DA35FAB4F51217E74B9806172F70`
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

- `outputs\Professional_XAUUSD_EA.mq5`: `11E44DFA30D5F365014E412E581927CBC549DA35FAB4F51217E74B9806172F70`
- `Professional_XAUUSD_EA.mq5`: `11E44DFA30D5F365014E412E581927CBC549DA35FAB4F51217E74B9806172F70`
- `outputs\external_mt5_validation_package\source\Professional_XAUUSD_EA.mq5`: `11E44DFA30D5F365014E412E581927CBC549DA35FAB4F51217E74B9806172F70`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `2FEA4159B1AC5F01D796C87851797DA46A025049E887EEA0500E1F89CC856A5E`
- `outputs\xauusd_micro_validation_package.zip`: `FDB68B230003754DC72BC7E5526A56DEEF7C31E492099ADF18A3C5C50476730A`
- `work\build_price_action_strategy_batch.ps1`: `79E4F076ECD72951D6E4A35FFD55B5179C50CD2EA215BFCB50F4C198DD807561`
- `work\test_price_action_strategy_modules.ps1`: `5A5BF09D0D9EE9CC06F3C215D8E78D80D208865408FC0628BBC12BF8E0386766`
- `work\test_price_action_strategy_batch.ps1`: `B2D9E6C0E96C20A96A632DE8676F8E8A2F47752C67EC0F36387810F8C6B6FEE4`
- `outputs\OFFLINE_VALIDATION_REFRESH.csv`: `DD3989D1D804BE985D8BF2C17C60FACC980ECF5D9991BBF14B37AD442D7E6BAB`

## Background-Safety Note

The stop marker remains present at `work\STOP_MT5_FOCUS_WATCHDOG`. Any future MT5 validation should be treated as external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The status note is committed through the GitHub connector. The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that the status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.