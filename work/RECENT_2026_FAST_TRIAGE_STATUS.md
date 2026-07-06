# Recent 2026 Fast Triage Status

Updated: 2026-07-06

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- Full EA source exists locally, but this note is the GitHub-safe status/evidence artifact.

## Latest Risk-Code Change

Enabled optional Flatten On Hard Risk Limits in generated research profiles:

- `InpClosePositionsOnRiskLimit`
- Existing `OnTick()` logic checks `riskManager.RiskLimitHit(riskExitReason)` before normal position management.
- When enabled, the EA calls `positionManager.CloseAll(riskExitReason)` if a hard account guard trips.
- Covered guard reasons include equity drawdown limit, daily/weekly/monthly loss limits, daily/weekly/monthly profit locks, daily equity trail, and profit giveback guards.

This improves risk behavior without adding recovery logic. The baseline anchor remains pinned disabled for comparison, while generated research profiles enable it so hard account guards can flatten exposure instead of only blocking new entries. It adds no martingale, grid, averaging down, or recovery behavior.

## Fast Batch Impact

- Batch size stayed at 10 profiles and 30 runs.
- Estimated tester runtime stayed at about 10.5 minutes before platform overhead.
- Baseline anchor remains `InpClosePositionsOnRiskLimit=false` for clean comparison.
- Generated research profiles enable `InpClosePositionsOnRiskLimit=true`.
- Generated configs confirmed the risk-flatten setting is enabled in research profiles and pinned disabled in the robust base profile.

## Quiet Validation Results

- `work\test_price_action_strategy_modules.ps1`: PASS
- `work\build_price_action_strategy_batch.ps1`: PASS, 10 profiles, 30 runs, estimated 10.5 minutes
- `work\sync_ea_source_artifacts.ps1`: PASS
- `work\test_price_action_strategy_batch.ps1`: PASS
- `work\test_ea_source_artifact_sync.ps1`: PASS
- `work\build_external_mt5_validation_package.ps1`: PASS, package configs 20, profiles 9
- `work\test_external_mt5_validation_package.ps1`: PASS, 26 checks, 0 failed
- `work\refresh_offline_validation_state.ps1`: PASS, 39 steps, 0 failed

## Latest Hashes

- `outputs\Professional_XAUUSD_EA.mq5`: `8FAD7C06613565E8D6BCF5E0AE4213F949B8837678714184937BD76BF7138834`
- `Professional_XAUUSD_EA.mq5`: `8FAD7C06613565E8D6BCF5E0AE4213F949B8837678714184937BD76BF7138834`
- `outputs\external_mt5_validation_package\source\Professional_XAUUSD_EA.mq5`: `8FAD7C06613565E8D6BCF5E0AE4213F949B8837678714184937BD76BF7138834`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `42C18B320A2AFB29F6C125EA511D03C233AD4BD5D1E074A35117AE9861A52D80`
- `outputs\PRICE_ACTION_STRATEGY_BATCH.csv`: `903827B590601032A7A70DABEBD76776A74CDD40CD4C103FEB0574FC2D00BED6`
- `outputs\xauusd_micro_validation_package.zip`: `920027B3641FB88C5BD7FB62FE459C3C98FE28596DCD9A67B068A147F1501429`
- `work\test_price_action_strategy_modules.ps1`: `6C4216633FE47DFF0956B2E59743D7B9585725A5034B521467D2BBD3CFA5F08C`
- `work\test_price_action_strategy_batch.ps1`: `4D3406DCD4DE68A9C2E618E668720418F1D5CABA947FB279BB7D4B9D7F3401FB`
- `work\build_price_action_strategy_batch.ps1`: `E3E5485D6C430714E1E3A5B2FC0CE97F53A40C6EA5A5EB173C207CE9C37466E9`

## Background-Safety Note

The stop marker remains expected at `work\STOP_MT5_FOCUS_WATCHDOG`. Any future MT5 validation should be treated as external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The status note can be committed through the GitHub connector. The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that the status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.
