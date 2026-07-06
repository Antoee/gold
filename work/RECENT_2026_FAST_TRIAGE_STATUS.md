# Recent 2026 Fast Triage Status

Updated: 2026-07-06

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- Full EA source exists locally, but this note is the GitHub-safe status/evidence artifact.

## Latest Strategy-Code Change

Added optional ADX DI direction confirmation:

- `InpUseDIDirectionConfirmation`
- `InpMinDIDifference`
- `InpWeightDIDirection`
- `PlusDI(...)` and `MinusDI(...)` accessors from the existing native MT5 ADX handle
- `DIDirectionConfirmation(...)`
- Entry scoring reason `DI direction;`

This is a real strategy-code addition from the requested trend strength, market phase, and indicator feature list. It is optional, configurable, weighted, and pinned disabled in the robust base profile. It is enabled only in indicator/regime and full-confluence research profiles for fast triage. It adds no martingale, grid, averaging down, or recovery behavior.

## Fast Batch Impact

- Batch size stayed at 10 profiles and 30 runs.
- Estimated tester runtime stayed at about 10.5 minutes before platform overhead.
- `indicator_phase_filter` enables DI direction confirmation with minimum DI difference 2.0.
- `pa_full_confluence` enables stricter DI direction confirmation with minimum DI difference 3.0.
- Generated configs confirmed the module is enabled only in the intended research profiles and pinned disabled in the robust base profile.

## Quiet Validation Results

- `work\build_price_action_strategy_batch.ps1`: PASS, 10 profiles, 30 runs, estimated 10.5 minutes
- `work\sync_ea_source_artifacts.ps1`: PASS
- `work\test_price_action_strategy_modules.ps1`: PASS
- `work\test_price_action_strategy_batch.ps1`: PASS
- `work\test_ea_source_artifact_sync.ps1`: PASS
- `work\refresh_offline_validation_state.ps1`: PASS, 39 steps, 0 failed
- `work\build_external_mt5_validation_package.ps1`: PASS, package configs 20, profiles 9
- `work\test_external_mt5_validation_package.ps1`: PASS, 26 checks, 0 failed

## Latest Hashes

- `outputs\Professional_XAUUSD_EA.mq5`: `528AD604026C378F068B31DFACD634E79F55A4C68D9A051FA2118A9EF6E3523F`
- `Professional_XAUUSD_EA.mq5`: `528AD604026C378F068B31DFACD634E79F55A4C68D9A051FA2118A9EF6E3523F`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `ACEE6CD7F96462DC2164EF9737EE066A06E4D5C44E0EBC597491B98241A4C28C`
- `outputs\PRICE_ACTION_STRATEGY_BATCH.csv`: `903827B590601032A7A70DABEBD76776A74CDD40CD4C103FEB0574FC2D00BED6`
- `outputs\xauusd_micro_validation_package.zip`: `9DD386393BAEAFE0609CDAB8195F8801685E0FB2AEDF5C817A0E411FD4124362`
- `work\test_price_action_strategy_modules.ps1`: `AE4659419DCC478C4BC9BDE465520B522253E6206BA64A4915C3A6E535ACF005`
- `work\test_price_action_strategy_batch.ps1`: `07E83D9CD7691E91DCAC8CF68D35856B05B17339C352801B5C974338280A06E6`
- `work\build_price_action_strategy_batch.ps1`: `87AAD943C9299EF0A638A5B04A76705DDAC56F66C61D25CAB03300115E2F3E48`

## Background-Safety Note

The stop marker remains expected at `work\STOP_MT5_FOCUS_WATCHDOG`. Any future MT5 validation should be treated as external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The status note is committed through the GitHub connector. The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that the status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.
