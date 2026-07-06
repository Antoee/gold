# Recent 2026 Fast Triage Status

Updated: 2026-07-06

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- Full EA source exists locally, but this note is the GitHub-safe status/evidence artifact.

## Latest Risk-Code Change

Added optional Daily Profit Protection Risk Scaling for generated research profiles:

- `InpUseDailyProfitRiskScaling`
- `InpDailyProfitRiskStartFraction`
- `InpMinDailyProfitRiskMultiplier`
- `DailyProfitProtectionRiskMultiplier()` uses current-day realized profit and `InpDailyProfitLockPercent` to taper risk as the EA approaches the daily profit lock.
- `OpenSignal()` now multiplies daily-profit protection risk into final lot sizing and logs `Daily profit risk x...` when enabled.

This is profit-preservation risk code, not only parameter tweaking. It reduces new-trade exposure after the EA has built daily profit, helping protect green days before a hard profit lock or giveback guard is reached. The baseline anchor remains disabled for clean comparison, while generated research profiles enable it. It adds no martingale, grid, averaging down, or recovery behavior.

## Fast Batch Impact

- Batch size stayed at 10 profiles and 30 runs.
- Estimated tester runtime stayed at about 10.5 minutes before platform overhead.
- Baseline anchor remains `InpUseDailyProfitRiskScaling=false`.
- Generated research profiles use `InpUseDailyProfitRiskScaling=true`.
- Research profiles start tapering at `0.50` of the daily profit-lock target and taper toward minimum multiplier `0.50`.

## Quiet Validation Results

- `work\test_price_action_strategy_modules.ps1`: PASS
- `work\sync_ea_source_artifacts.ps1`: PASS, hash `7D04FDC8491CFD4B715B545D804744AD5F2D39C69D3B73FC903BC9FEDCEE6B9A`
- `work\build_price_action_strategy_batch.ps1`: PASS, 10 profiles, 30 runs, estimated 10.5 minutes
- `work\test_ea_source_artifact_sync.ps1`: PASS
- `work\test_price_action_strategy_batch.ps1`: PASS
- `work\build_external_mt5_validation_package.ps1`: PASS, package configs 20, profiles 9
- `work\test_external_mt5_validation_package.ps1`: PASS, 26 checks, 0 failed
- `work\refresh_offline_validation_state.ps1`: PASS, 39 steps, 0 failed

## Latest Hashes

- `outputs\Professional_XAUUSD_EA.mq5`: `7D04FDC8491CFD4B715B545D804744AD5F2D39C69D3B73FC903BC9FEDCEE6B9A`
- `Professional_XAUUSD_EA.mq5`: `7D04FDC8491CFD4B715B545D804744AD5F2D39C69D3B73FC903BC9FEDCEE6B9A`
- `outputs\external_mt5_validation_package\source\Professional_XAUUSD_EA.mq5`: `7D04FDC8491CFD4B715B545D804744AD5F2D39C69D3B73FC903BC9FEDCEE6B9A`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `A711CA31CB2E01164C685EC855EE9E781265524FE1ACA78DC1BEE397AC6D8BEA`
- `outputs\PRICE_ACTION_STRATEGY_BATCH.csv`: `903827B590601032A7A70DABEBD76776A74CDD40CD4C103FEB0574FC2D00BED6`
- `outputs\xauusd_micro_validation_package.zip`: `2503F0AA315C59CCC8939B11D25D7150F4D7526C9F82D3A7AA346E7C7752DD4D`
- `work\test_price_action_strategy_modules.ps1`: `6E90664CB6D1825E573BA9E288758C363A809938A0BF52D7F1AC7E77A0230586`
- `work\test_price_action_strategy_batch.ps1`: `9B1616A5C2D0C5C6BAE72122FF31D7BBB6A670976C500E017DEBBCFA9B44172C`
- `work\build_price_action_strategy_batch.ps1`: `B2DD77D0F71F4AF4975AB9AE43E09A7424C628EB89E3A38DB467627A7C391977`

## Background-Safety Note

The stop marker remains expected at `work\STOP_MT5_FOCUS_WATCHDOG`. Any future MT5 validation should be treated as external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The status note was committed through the GitHub connector. The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that the status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.
