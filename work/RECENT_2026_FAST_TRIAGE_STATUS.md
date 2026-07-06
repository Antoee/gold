# Recent 2026 Fast Triage Status

Updated: 2026-07-06

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- Full EA source exists locally, but this note is the GitHub-safe status/evidence artifact.

## Latest Risk-Code Change

Added optional Trade Free-Margin Pressure Risk Scaling for generated research profiles:

- `InpUseTradeMarginRiskScaling`
- `InpTradeMarginRiskStartFraction`
- `InpMinTradeMarginRiskMultiplier`
- `TradeMarginRiskMultiplier()` estimates required margin for the candidate trade using `OrderCalcMargin()`.
- `OpenSignal()` now sizes once, estimates required margin as a percent of free margin, tapers risk if the trade is approaching the configured hard trade-margin cap, then recalculates lots before exposure/cost/margin guards.
- Entry logging records `Trade margin risk x...` when enabled.

This is strategy/risk code, not only settings. It reduces new-trade risk before the hard `InpMaxTradeMarginFreePercent` margin guard blocks the order. The baseline anchor remains disabled for clean comparison, while generated research profiles enable it. It adds no martingale, grid, averaging down, or recovery behavior.

## Fast Batch Impact

- Batch size stayed at 10 profiles and 30 runs.
- Estimated tester runtime stayed at about 10.5 minutes before platform overhead.
- Baseline anchor remains `InpUseTradeMarginRiskScaling=false`.
- Generated research profiles use `InpUseTradeMarginRiskScaling=true`.
- Research profiles begin tapering at `InpTradeMarginRiskStartFraction=0.50` of `InpMaxTradeMarginFreePercent` and taper toward minimum multiplier `0.50` as required margin approaches the hard cap.

## Quiet Validation Results

- `work\test_price_action_strategy_modules.ps1`: PASS
- `work\sync_ea_source_artifacts.ps1`: PASS, hash `1F3F7E943A16EB9D73C4D69F86E7D21F832B4A1184EE909FE752A573D5DED988`
- `work\build_price_action_strategy_batch.ps1`: PASS, 10 profiles, 30 runs, estimated 10.5 minutes
- `work\test_ea_source_artifact_sync.ps1`: PASS
- `work\test_price_action_strategy_batch.ps1`: PASS
- `work\build_external_mt5_validation_package.ps1`: PASS, package configs 20, profiles 9
- `work\test_external_mt5_validation_package.ps1`: PASS, 26 checks, 0 failed
- `work\refresh_offline_validation_state.ps1`: PASS, 39 steps, 0 failed

## Latest Hashes

- `outputs\Professional_XAUUSD_EA.mq5`: `1F3F7E943A16EB9D73C4D69F86E7D21F832B4A1184EE909FE752A573D5DED988`
- `Professional_XAUUSD_EA.mq5`: `1F3F7E943A16EB9D73C4D69F86E7D21F832B4A1184EE909FE752A573D5DED988`
- `outputs\external_mt5_validation_package\source\Professional_XAUUSD_EA.mq5`: `1F3F7E943A16EB9D73C4D69F86E7D21F832B4A1184EE909FE752A573D5DED988`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `4A9AFD3481C5F6E0FBD164B4278ECA90ECD73FA3906647944B83DC7265436ADC`
- `outputs\PRICE_ACTION_STRATEGY_BATCH.csv`: `903827B590601032A7A70DABEBD76776A74CDD40CD4C103FEB0574FC2D00BED6`
- `outputs\xauusd_micro_validation_package.zip`: `7699E6336722F51A826B561105EED242D57D694B88AF504F93B6EC3E2CF720C9`
- `work\test_price_action_strategy_modules.ps1`: `E031AF0C6C3A5D394A5C5D3C9C4F00C053BDF05A188A8705ECCACE4CBE002263`
- `work\test_price_action_strategy_batch.ps1`: `87DC90313F61D4B62F972783D6F06E3757ECF99CFB187D2AE6BF40C39CE2514A`
- `work\build_price_action_strategy_batch.ps1`: `B627C8E570E73FA235964770CE33FBA93DF87D09609A31C832EA21FE73DC7F5A`

## Background-Safety Note

The stop marker remains expected at `work\STOP_MT5_FOCUS_WATCHDOG`. Any future MT5 validation should be treated as external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The status note was committed through the GitHub connector. The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that the status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.
