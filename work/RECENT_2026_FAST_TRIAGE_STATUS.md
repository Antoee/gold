# Recent 2026 Fast Triage Status

Updated: 2026-07-06

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- Full EA source exists locally, but this note is the GitHub-safe status/evidence artifact.

## Latest Risk-Code Change

Added optional Price Action Risk Scaling on top of the Price Action Composite Gate:

- `InpUsePriceActionCompositeGate`
- `InpPriceActionCompositeMinScore`
- `InpPriceActionRequireStructure`
- `InpPriceActionRequireLiquidity`
- `InpPriceActionRequireExecution`
- `InpPriceActionRequireOrderFlow`
- `InpWeightPriceActionComposite`
- `InpUsePriceActionRiskScaling`
- `InpPriceActionRiskMinScore`
- `InpPriceActionRiskFullScore`
- `InpMinPriceActionRiskMultiplier`
- `InpMaxPriceActionRiskMultiplier`
- `PriceActionCompositeQuality()` scores BOS, displacement BOS, CHoCH, breakout retest, liquidity sweeps, wick rejection, equal/session/Asian sweeps, FVG, FVG retest, order block, OHLC wick/body rejection, displacement candle, tick pressure, tick speed, momentum, candle anatomy, volume, cumulative delta proxy, tick tape, VWAP, daily open, previous-day range, and regime quality.
- `Build()` now rejects enabled low-quality entries with `PA composite reject score ...` before normal confirmations.
- Passing composite setups now add `PA composite score ...` as a weighted confirmation so quality risk scaling and quality TP scaling can react to stronger price-action evidence.
- `OpenSignal()` now applies `PriceActionRiskMultiplier(signal.priceActionScore)` before lot sizing and logs `PA risk x...` when enabled.

This changes entry and risk strategy code, not only settings. The goal is to require actual market-structure, liquidity, execution-candle, and optional order-flow evidence before allowing strict research profiles to trade, then reduce position size on marginal-but-valid price-action scores. It is disabled in the robust base profile and enabled only in strict research profiles. It adds no martingale, grid, averaging down, or recovery behavior.

## Fast Batch Impact

- Batch size stayed at 10 profiles and 30 runs.
- Estimated tester runtime stayed at about 10.5 minutes before platform overhead.
- `weighted_quality_confluence` enables Price Action Risk Scaling from score `9` to `16`, minimum risk multiplier `0.55`, order-flow requirement disabled, and PA composite weight `3`.
- `pa_full_confluence` enables a stricter version from score `12` to `20`, minimum risk multiplier `0.45`, order-flow requirement enabled, and PA composite weight `4`.
- Generated configs confirmed the module is enabled in strict price-action research profiles and pinned disabled in the robust base profile.

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

- `outputs\Professional_XAUUSD_EA.mq5`: `618496E938E7B983F2BB8FF812B14EB93821EBC81B57F158A29E4FE2FD85801D`
- `Professional_XAUUSD_EA.mq5`: `618496E938E7B983F2BB8FF812B14EB93821EBC81B57F158A29E4FE2FD85801D`
- `outputs\external_mt5_validation_package\source\Professional_XAUUSD_EA.mq5`: `618496E938E7B983F2BB8FF812B14EB93821EBC81B57F158A29E4FE2FD85801D`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `6B554539682F71ADAC3DAAD13CC8232F5905C89F0BF470382A4E10169DC1873A`
- `outputs\PRICE_ACTION_STRATEGY_BATCH.csv`: `903827B590601032A7A70DABEBD76776A74CDD40CD4C103FEB0574FC2D00BED6`
- `outputs\xauusd_micro_validation_package.zip`: `100228EFE5F62C854B9989A0347D1D65F3A35B395F0E79A61FCA9681647AA6C1`
- `work\test_price_action_strategy_modules.ps1`: `50C7B8EE392F9D652C2FBB0F954053175609CAA16E4D25C34F34DD865C9FE228`
- `work\test_price_action_strategy_batch.ps1`: `D172C40AD65DBDC3F12CC04D85483CAC4379CA86E1E774DA28B0110DF2F2C6E7`
- `work\build_price_action_strategy_batch.ps1`: `86527C3D521F88B2452D83739584DFDCB7BE67CD8414DDF955DC960E9FE5ADC6`

## Background-Safety Note

The stop marker remains expected at `work\STOP_MT5_FOCUS_WATCHDOG`. Any future MT5 validation should be treated as external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The status note can be committed through the GitHub connector. The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that the status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.
