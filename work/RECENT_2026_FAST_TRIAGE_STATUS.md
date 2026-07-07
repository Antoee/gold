# Recent 2026 Fast Triage Status

Updated: 2026-07-07

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- Full EA source exists locally, but this note is the GitHub-safe status/evidence artifact.

## Latest Strategy-Code Change

Added a recent profit-factor risk boost. This is an optional capped risk multiplier that lets the EA press harder only when recent closed trades show a strong gross-profit versus gross-loss edge.

New inputs and logic:

- `InpUseRecentProfitFactorRiskBoost`
- `InpRecentProfitFactorLookbackTrades`
- `InpRecentProfitFactorStart`
- `InpRecentProfitFactorFull`
- `InpMaxRecentProfitFactorRiskMultiplier`
- `InpRecentProfitFactorRequiresClosedProfit`
- `InpRecentProfitFactorRequiresEquityProfit`
- `RecentProfitFactorSample()` calculates recent closed-trade profit factor from account history for the EA symbol and magic number.
- `RecentProfitFactorRiskMultiplier()` returns `1.0` until sample size, profit-factor threshold, closed-profit gating, and equity-profit gating all pass.
- Generated research profiles cap the boost at 1.35x from PF 1.25 to PF 2.00 over the last 8 closed trades.

This supports the goal by adding a measured advantage-pressing layer that is gross-loss-aware. It does not add martingale, grid, averaging down, or recovery behavior.

## Fast Batch Impact

- Batch size stayed at 10 profiles and 30 runs.
- Estimated tester runtime stayed at about 10.5 minutes before platform overhead.
- Baseline anchor keeps recent profit-factor risk boost disabled.
- Generated research profiles use:
  - `InpUseRecentProfitFactorRiskBoost=true`
  - `InpRecentProfitFactorLookbackTrades=8`
  - `InpRecentProfitFactorStart=1.25`
  - `InpRecentProfitFactorFull=2.00`
  - `InpMaxRecentProfitFactorRiskMultiplier=1.35`
  - `InpRecentProfitFactorRequiresClosedProfit=true`
  - `InpRecentProfitFactorRequiresEquityProfit=true`

## Quiet Validation Results

- `work\test_price_action_strategy_modules.ps1`: PASS
- `work\sync_ea_source_artifacts.ps1`: PASS, hash `3E91F0AF5C6BBA74F8D80B468A77F5E56C26C5413DCBA055F1E5F01FBF74D83D`
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

- `outputs\Professional_XAUUSD_EA.mq5`: `3E91F0AF5C6BBA74F8D80B468A77F5E56C26C5413DCBA055F1E5F01FBF74D83D`
- `Professional_XAUUSD_EA.mq5`: `3E91F0AF5C6BBA74F8D80B468A77F5E56C26C5413DCBA055F1E5F01FBF74D83D`
- `outputs\external_mt5_validation_package\source\Professional_XAUUSD_EA.mq5`: `3E91F0AF5C6BBA74F8D80B468A77F5E56C26C5413DCBA055F1E5F01FBF74D83D`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `11F7ACC07DA38658027F3BCDC851D54492292E2D5D21E7BD139FBC3FF2B6C088`
- `outputs\xauusd_micro_validation_package.zip`: `7B1F9886C5D5E91B176B6460F419B46075DFBA0DB476DAF1B0289169F184D95A`
- `work\build_price_action_strategy_batch.ps1`: `30D401C8223619264F73DECD0EEFCF38BC270D4CCD4285C98B795229D64DD354`
- `work\test_price_action_strategy_modules.ps1`: `C907A794A4CD98D72B10A3BE6D663436C2FFCE18F5291BBFE1E6D4D91FCCA0FA`
- `work\test_price_action_strategy_batch.ps1`: `B2FFFD6EB4EF37C40BF2871437FDD9EDB5BC8FF96CE232C2A24F2E11F46FE362`
- `outputs\OFFLINE_VALIDATION_REFRESH.csv`: `E4F3B8857D58AB869781738D5BCFF1C47C9E82668D7560479E10D64006282097`

## Background-Safety Note

The stop marker remains present at `work\STOP_MT5_FOCUS_WATCHDOG`. Any future MT5 validation should be treated as external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The status note is committed through the GitHub connector. The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that the status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.