# Recent 2026 Fast Triage Status

Updated: 2026-07-06

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- Full EA source exists locally, but this note is the GitHub-safe status/evidence artifact.

## Latest Strategy-Code Fix

Fixed open-risk accounting for positions whose stop loss has already moved to breakeven or profit.

Before this fix, `PositionRiskMoney()` treated a BUY position with `SL >= open price`, or a SELL position with `SL <= open price`, as `unprotected`. That was wrong: those positions have no remaining loss-side open risk. This could overstate exposure, show `Unprotected: Yes` on the dashboard, and block valid winner scale-ins or new entries under the open-risk guard even when existing positions were protected.

New behavior:

- Missing/invalid stop loss still counts as unprotected.
- Loss-side stop loss still contributes open risk.
- Breakeven/profit-side stop loss contributes `0.0` open risk and is not marked unprotected.

This supports the goal directly: protected winners can be pressed more correctly, while genuinely unprotected positions still block exposure as intended.

## Quiet Validation Results

- `work\test_open_risk_exposure_guard.ps1`: PASS
- `work\test_price_action_strategy_modules.ps1`: PASS
- `work\sync_ea_source_artifacts.ps1`: PASS, hash `D7BC081C95349AE214E936C04B6834CA77E3BA0014AA8299DAAF45DB8FAF5FD9`
- `work\build_price_action_strategy_batch.ps1`: PASS, 10 profiles, 30 runs, estimated 10.5 minutes
- `work\test_price_action_strategy_decision.ps1`: PASS
- `work\test_loss_streak_risk_reduction.ps1`: PASS
- `work\test_ea_source_artifact_sync.ps1`: PASS
- `work\test_price_action_strategy_batch.ps1`: PASS
- `work\build_external_mt5_validation_package.ps1`: PASS, package configs 20, profiles 9
- `work\test_external_mt5_validation_package.ps1`: PASS, 26 checks, 0 failed
- `work\refresh_offline_validation_state.ps1`: PASS, 40 steps, 0 failed
- MT5-family process scan: empty

## Latest Hashes

- `outputs\Professional_XAUUSD_EA.mq5`: `D7BC081C95349AE214E936C04B6834CA77E3BA0014AA8299DAAF45DB8FAF5FD9`
- `Professional_XAUUSD_EA.mq5`: `D7BC081C95349AE214E936C04B6834CA77E3BA0014AA8299DAAF45DB8FAF5FD9`
- `outputs\external_mt5_validation_package\source\Professional_XAUUSD_EA.mq5`: `D7BC081C95349AE214E936C04B6834CA77E3BA0014AA8299DAAF45DB8FAF5FD9`
- `outputs\xauusd_micro_validation_package.zip`: `323DE606A68C2A367CFB16FD2E8209808090D3007CFCF5748F32F8257C13843F`
- `work\test_open_risk_exposure_guard.ps1`: `6E55F4739F4ED111F85A7F8A103FF32E8E6674710C81FEE9374A77EB0B27E444`
- `outputs\OFFLINE_VALIDATION_REFRESH.csv`: `7281DD4DDED9CB12B339FFAC4995B577A610CEFC6ACC7D59485886962EA09664`

## Background-Safety Note

The stop marker remains expected at `work\STOP_MT5_FOCUS_WATCHDOG`. Any future MT5 validation should be treated as external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The status note is committed through the GitHub connector. The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that the status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.