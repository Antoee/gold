# Recent 2026 Fast Triage Status

Updated: 2026-07-06

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- Full EA source exists locally, but this note is the GitHub-safe status/evidence artifact.

## Latest Risk-Code Change

Added optional Margin Pressure Risk Scaling for generated research profiles:

- `InpUseMarginPressureRiskScaling`
- `InpMarginPressureStartLevelPercent`
- `InpMinMarginPressureRiskMultiplier`
- `MarginPressureRiskMultiplier()` reads account margin level and tapers new-trade risk as margin level approaches `InpMinMarginLevelPercent`.
- `OpenSignal()` now multiplies margin-pressure risk into final lot sizing and logs `Margin risk x...` when enabled.

This is proactive margin-risk code, not only parameter tweaking. It reduces new-trade exposure before the hard margin guard blocks trades, helping prevent good-looking signals from consuming too much free margin under pressure. The baseline anchor remains disabled for clean comparison, while generated research profiles enable it. It adds no martingale, grid, averaging down, or recovery behavior.

## Fast Batch Impact

- Batch size stayed at 10 profiles and 30 runs.
- Estimated tester runtime stayed at about 10.5 minutes before platform overhead.
- Baseline anchor remains `InpUseMarginPressureRiskScaling=false`.
- Generated research profiles use `InpUseMarginPressureRiskScaling=true`.
- Research profiles start tapering below margin level `600.0` and taper toward minimum multiplier `0.50` as margin approaches the configured hard floor.

## Quiet Validation Results

- `work\test_price_action_strategy_modules.ps1`: PASS
- `work\sync_ea_source_artifacts.ps1`: PASS, hash `808D1A7042F40753C1EBA513F8CDE582005E8E00E47DEF8AAF2F2B10CDDF595A`
- `work\build_price_action_strategy_batch.ps1`: PASS, 10 profiles, 30 runs, estimated 10.5 minutes
- `work\test_ea_source_artifact_sync.ps1`: PASS
- `work\test_price_action_strategy_batch.ps1`: PASS
- `work\build_external_mt5_validation_package.ps1`: PASS, package configs 20, profiles 9
- `work\test_external_mt5_validation_package.ps1`: PASS, 26 checks, 0 failed
- `work\refresh_offline_validation_state.ps1`: PASS, 39 steps, 0 failed

## Latest Hashes

- `outputs\Professional_XAUUSD_EA.mq5`: `808D1A7042F40753C1EBA513F8CDE582005E8E00E47DEF8AAF2F2B10CDDF595A`
- `Professional_XAUUSD_EA.mq5`: `808D1A7042F40753C1EBA513F8CDE582005E8E00E47DEF8AAF2F2B10CDDF595A`
- `outputs\external_mt5_validation_package\source\Professional_XAUUSD_EA.mq5`: `808D1A7042F40753C1EBA513F8CDE582005E8E00E47DEF8AAF2F2B10CDDF595A`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `CB615629AD4E04A106A4E749DA8486955579B50FB6820A59C6910570A7311785`
- `outputs\PRICE_ACTION_STRATEGY_BATCH.csv`: `903827B590601032A7A70DABEBD76776A74CDD40CD4C103FEB0574FC2D00BED6`
- `outputs\xauusd_micro_validation_package.zip`: `6B25C436EF7755D926EE63BD626BCA4167CF65A41D71A71C7CBC719D88D08DDD`
- `work\test_price_action_strategy_modules.ps1`: `D38B9637C8843E6A1AE3A8E18457C55AEB08E9DD2386F78E655C78695D2E738B`
- `work\test_price_action_strategy_batch.ps1`: `EEB76A9E03B67916D2DC918E8B2E35E4B939409742A8DCA9E21E26ED9271D567`
- `work\build_price_action_strategy_batch.ps1`: `6BAE3186E80F2725D6D8EBED3FDD2CE61F005627D9356C3E5D8AEFE68DB5A510`

## Background-Safety Note

The stop marker remains expected at `work\STOP_MT5_FOCUS_WATCHDOG`. Any future MT5 validation should be treated as external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The status note was committed through the GitHub connector. The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that the status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.
