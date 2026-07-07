# Recent 2026 Fast Triage Status

Updated: 2026-07-06

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- Full EA source exists locally, but this note is the GitHub-safe status/evidence artifact.

## Latest Strategy-Code Change

Added an open-profit add-on quality gate. When the EA already has a profitable open basket, new entries must meet stronger quality and price-action thresholds before adding more exposure.

New inputs and logic:

- `InpUseOpenProfitAddOnQualityGate`
- `InpOpenProfitAddOnMinProfitPercent`
- `InpOpenProfitAddOnMinPositions`
- `InpOpenProfitAddOnMinQualityScore`
- `InpOpenProfitAddOnMinPriceActionScore`
- `OpenProfitAddOnQualityAllows()` checks current open basket profit as a percent of balance.
- `OpenSignal()` can now reject lower-quality add-ons with `open profit add-on quality`.

This supports the goal by protecting open winners from being diluted by weaker follow-on trades. Generated research profiles require quality score 13 and price-action score 15 once open basket profit is at least 0.50% of balance. It adds no martingale, grid, averaging down, or recovery behavior.

## Fast Batch Impact

- Batch size stayed at 10 profiles and 30 runs.
- Estimated tester runtime stayed at about 10.5 minutes before platform overhead.
- Baseline anchor keeps open-profit add-on quality gate disabled.
- Generated research profiles use:
  - `InpUseOpenProfitAddOnQualityGate=true`
  - `InpOpenProfitAddOnMinProfitPercent=0.50`
  - `InpOpenProfitAddOnMinPositions=1`
  - `InpOpenProfitAddOnMinQualityScore=13`
  - `InpOpenProfitAddOnMinPriceActionScore=15`

## Quiet Validation Results

- `work\test_price_action_strategy_modules.ps1`: PASS
- `work\sync_ea_source_artifacts.ps1`: PASS, hash `B0669028E12AB5A32DC16EA552A7ADB64827B65D26CCB6E9BF4EB9024F96DC24`
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

- `outputs\Professional_XAUUSD_EA.mq5`: `B0669028E12AB5A32DC16EA552A7ADB64827B65D26CCB6E9BF4EB9024F96DC24`
- `Professional_XAUUSD_EA.mq5`: `B0669028E12AB5A32DC16EA552A7ADB64827B65D26CCB6E9BF4EB9024F96DC24`
- `outputs\external_mt5_validation_package\source\Professional_XAUUSD_EA.mq5`: `B0669028E12AB5A32DC16EA552A7ADB64827B65D26CCB6E9BF4EB9024F96DC24`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `5FC75FD2453B4FECE5457BCDE8DA26F7D5C1BF8F0C702528372396A12B8C8D42`, 35,124 bytes
- `outputs\xauusd_micro_validation_package.zip`: `465A237F2D838012F8CB24D7011F417334A5E493BB344A8BEABB8181550B51AE`
- `work\build_price_action_strategy_batch.ps1`: `A10A8504418A7DB88DDE54C03E3AF5D90E1C9FF59347DB30EDE0465C2B8B27AF`
- `work\test_price_action_strategy_modules.ps1`: `AA798E4DD04A085674A2CF531EA523D268B71BDBC875F6ACE9AD8530DD9D53F3`
- `outputs\OFFLINE_VALIDATION_REFRESH.csv`: `26D2322DFED4AC863002E4AD7329FA37FD45BEB78C8308F6EBC2414E3FAD177D`

## Background-Safety Note

The stop marker remains present at `work\STOP_MT5_FOCUS_WATCHDOG`. Any future MT5 validation should be treated as external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The status note is committed through the GitHub connector. The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that the status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.