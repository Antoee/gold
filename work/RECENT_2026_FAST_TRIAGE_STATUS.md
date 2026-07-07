# Recent 2026 Fast Triage Status

Updated: 2026-07-07

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- Full EA source exists locally, but this note is the GitHub-safe status/evidence artifact.

## Latest Strategy-Code Change

Added a realized-profit giveback quality gate. This is an optional profit-preservation entry filter that raises the required entry quality when open equity drawdown is eating into already banked realized profit.

New inputs and logic:

- `InpUseRealizedProfitGivebackQualityGate`
- `InpRealizedProfitGivebackStartPercent`
- `InpRealizedProfitGivebackFullPercent`
- `InpRealizedProfitGivebackMinQualityScore`
- `InpRealizedProfitGivebackMaxQualityScore`
- `RealizedProfitGivebackQualityAllows()` compares realized balance profit against current equity profit.
- When giveback reaches the configured start threshold, required quality rises from the min score toward the max score.
- Weak new entries are blocked with `realized profit giveback quality`.
- Generated research profiles enable the gate from 25% to 60% giveback, requiring quality score 12 to 16.

This supports the goal by protecting banked profit earlier than the hard protected-floor guard while still allowing high-quality opportunities to continue trading. It does not add martingale, grid, averaging down, or recovery behavior.

## Fast Batch Impact

- Batch size stayed at 10 profiles and 30 runs.
- Estimated tester runtime stayed at about 10.5 minutes before platform overhead.
- Baseline anchor keeps realized-profit giveback quality gate disabled.
- Generated research profiles use:
  - `InpUseRealizedProfitGivebackQualityGate=true`
  - `InpRealizedProfitGivebackStartPercent=25.0`
  - `InpRealizedProfitGivebackFullPercent=60.0`
  - `InpRealizedProfitGivebackMinQualityScore=12`
  - `InpRealizedProfitGivebackMaxQualityScore=16`

## Quiet Validation Results

- `work\test_price_action_strategy_modules.ps1`: PASS
- `work\sync_ea_source_artifacts.ps1`: PASS, hash `0F1CD8EA6F15DB320D1008BA54FA4C57E6B20057870A7B3DBDAC7BE36FE10E10`
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

- `outputs\Professional_XAUUSD_EA.mq5`: `0F1CD8EA6F15DB320D1008BA54FA4C57E6B20057870A7B3DBDAC7BE36FE10E10`
- `Professional_XAUUSD_EA.mq5`: `0F1CD8EA6F15DB320D1008BA54FA4C57E6B20057870A7B3DBDAC7BE36FE10E10`
- `outputs\external_mt5_validation_package\source\Professional_XAUUSD_EA.mq5`: `0F1CD8EA6F15DB320D1008BA54FA4C57E6B20057870A7B3DBDAC7BE36FE10E10`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `08ED2C5CD40AD6AB3FF8839D8D17071CA50852B2D256C47153F1A0AC21134CAF`
- `outputs\xauusd_micro_validation_package.zip`: `C55763D875D453275DA19D875E93482EF367BC4C99C194D89B64113C8719B874`
- `work\build_price_action_strategy_batch.ps1`: `FB7716EEB71D156F543580EE5A97C3763F83EF57F48CA3267BA8B384632558B4`
- `work\test_price_action_strategy_modules.ps1`: `EF580368F93C42ACC5F0FE7AE388DEBCA8797C0691DED6B860C81AF50C3F9655`
- `work\test_price_action_strategy_batch.ps1`: `4AC10B08F987249E8BCB9A3691C9E9DEEDB3F6CDEA88F4BE44DC272C723B5E74`
- `outputs\OFFLINE_VALIDATION_REFRESH.csv`: `1C00BF74ED744D222C09FF6D93BF649F9E354B498E19A697750475ABEF9697F3`

## Background-Safety Note

The stop marker remains present at `work\STOP_MT5_FOCUS_WATCHDOG`. Any future MT5 validation should be treated as external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The status note is committed through the GitHub connector. The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that the status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.