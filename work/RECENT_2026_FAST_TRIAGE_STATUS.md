# Recent 2026 Fast Triage Status

Updated: 2026-07-07

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- Full EA source exists locally, but this note is the GitHub-safe status/evidence artifact.

## Latest Strategy-Code Change

Added a stricter protected-profit optimizer fitness mode: `FITNESS_PROFIT_RECOVERY_FLOOR`.

New inputs and logic:

- `FITNESS_PROFIT_RECOVERY_FLOOR = 4`
- `InpTesterProtectedProfitNetPower`
- `InpTesterRecoveryFloorPenaltyPower`
- `InpTesterDrawdownExcessPenaltyPower`
- `OnTester()` now has a mode that still rewards net profit, but downranks results with weak profit factor, weak recovery factor, or equity drawdown above the configured drawdown budget.
- Generated research profiles use this mode while `baseline_promoted` remains a comparison anchor.

This supports the goal by making future MT5 optimization chase aggressive profit only when the run also maintains recovery and drawdown quality. It does not add martingale, grid, averaging down, or recovery behavior.

## Fast Batch Impact

- Batch size stayed at 10 profiles and 30 runs.
- Estimated tester runtime stayed at about 10.5 minutes before platform overhead.
- Baseline anchor keeps its comparison behavior.
- Generated research profiles use:
  - `InpTesterFitnessMode=4`
  - `InpTesterProfitFactorRewardPower=0.75`
  - `InpTesterRecoveryRewardPower=0.75`
  - `InpTesterDrawdownRewardPower=1.25`
  - `InpTesterProtectedProfitNetPower=1.00`
  - `InpTesterRecoveryFloorPenaltyPower=2.00`
  - `InpTesterDrawdownExcessPenaltyPower=2.00`

## Quiet Validation Results

- `work\test_price_action_strategy_modules.ps1`: PASS
- `work\sync_ea_source_artifacts.ps1`: PASS, hash `90A1A1E7E6C86EB014CCAF8EC22DEB3024747234E0BC03239DD84D9C03FA4956`
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

- `outputs\Professional_XAUUSD_EA.mq5`: `90A1A1E7E6C86EB014CCAF8EC22DEB3024747234E0BC03239DD84D9C03FA4956`
- `Professional_XAUUSD_EA.mq5`: `90A1A1E7E6C86EB014CCAF8EC22DEB3024747234E0BC03239DD84D9C03FA4956`
- `outputs\external_mt5_validation_package\source\Professional_XAUUSD_EA.mq5`: `90A1A1E7E6C86EB014CCAF8EC22DEB3024747234E0BC03239DD84D9C03FA4956`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `8415510A65D4FDDCAD2EA67272D6566DE583B43CE3EBA37A5571EF7746A1FDED`
- `outputs\xauusd_micro_validation_package.zip`: `A76F3328234ADF6C2020B504FF74A9831AC914EF3693C7693AB487B4833547C8`
- `work\build_price_action_strategy_batch.ps1`: `D66C00898E1677EA71F77F802C57F2E305546CB805A766380B41BC7797FE48E7`
- `work\test_price_action_strategy_modules.ps1`: `5B29F6D20866A5687F870C062E5C00B4B0E1D6DD74D5C73636A3C9FA7767D775`
- `work\test_price_action_strategy_batch.ps1`: `E12C6D7A4ED0707D4D5A5F84FBD32DBDE2737FB7337DB541816F0D22FB70EC36`
- `outputs\OFFLINE_VALIDATION_REFRESH.csv`: `A6387BA442796AB8184777A86027209E4403480D92820E2F7FFCC8746E901E80`

## Background-Safety Note

The stop marker remains present at `work\STOP_MT5_FOCUS_WATCHDOG`. Any future MT5 validation should be treated as external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The status note is committed through the GitHub connector. The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that the status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.