# Recent 2026 Fast Triage Status

Updated: 2026-07-06

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- Full EA source exists locally, but this note is the GitHub-safe status/evidence artifact.

## Latest Strategy-Code Change

Added optional high-quality runner take-profit expansion so the best confluence setups can target larger winners:

- `InpUseRunnerTakeProfitExpansion`
- `InpRunnerMinQualityScore`
- `InpRunnerMinPriceActionScore`
- `InpRunnerTakeProfitMultiplier`
- `InpRunnerRequireTrailing`
- `RunnerTakeProfitMultiplier()` returns a larger TP multiplier only when runner mode is enabled, trailing/profit-management support is active when required, total quality meets the threshold, and price-action score meets the threshold.
- Entry sizing still uses the same protected risk path. The runner only expands the reward side of qualifying trades.
- Runner entries are logged with `Runner TP x...`.

The existing aggressive growth framework remains in place:

- Winner-only scale-in can add only to same-direction protected winners.
- Starting-equity protection can halt/close risk at the configured floor.
- Equity profit lock can protect a configurable percentage of peak account profit.
- Protected-equity floor caps new trade risk so theoretical stop risk does not exceed the floor.
- Profit-only risk boost can increase risk only after account equity is already above the configured profit threshold.

The generated aggressive research profiles now use 2.50% base risk, max 2 simultaneous positions, 6 max trades per day, 15-minute minimum trade spacing, winner scale-in enabled at 0.80R minimum open profit, protected stop required, quality score >= 10, 0.50 scale-in risk multiplier, 30-minute minimum since newest same-direction position, runner TP expansion enabled at quality score >= 12 and price-action score >= 14, 1.75 runner TP multiplier, trailing required for runner mode, starting-equity protection enabled at a 0.00% buffer, profit-only risk boost after +1.00% equity growth, full boost at +12.00%, max boost multiplier 3.00, equity profit lock after +2.00% peak equity growth, 50.0% peak-profit lock, 6.00% max equity drawdown, and 8.00% max open-risk cap. The baseline profile remains anchored at 1.60% risk, 1 max position, 4 trades/day, 30-minute spacing, winner scale-in disabled, and runner TP disabled.

This is intentionally more aggressive than the earlier conservative settings, but it still avoids martingale, grid, averaging down, and recovery mechanics. It is not proven profitable until a real MT5 backtest/forward-test report exists.

## Fast Batch Impact

- Batch size stayed at 10 profiles and 30 runs.
- Estimated tester runtime stayed at about 10.5 minutes before platform overhead.
- Baseline anchor remains `InpUseWinnerScaleIn=false`, `InpUseRunnerTakeProfitExpansion=false`, `InpUseStartingEquityProtection=false`, `InpUseProfitOnlyRiskBoost=false`, and `InpUseEquityProfitLock=false`.
- Generated research profiles use `InpUseWinnerScaleIn=true`, `InpUseRunnerTakeProfitExpansion=true`, `InpUseStartingEquityProtection=true`, `InpUseProfitOnlyRiskBoost=true`, and `InpUseEquityProfitLock=true`.
- Generated research profiles are now designed to push upside harder by pressing protected winners and stretching targets only for the strongest confluence signals while keeping account-level risk floors active.

## Quiet Validation Results

- `work\test_price_action_strategy_modules.ps1`: PASS
- `work\sync_ea_source_artifacts.ps1`: PASS, hash `B065E7D6BCFF4F68F6AC40CD0939FD2C476E9B765C5D690A8051A9FB67295AB2`
- `work\build_price_action_strategy_batch.ps1`: PASS, 10 profiles, 30 runs, estimated 10.5 minutes
- `work\test_ea_source_artifact_sync.ps1`: PASS
- `work\test_price_action_strategy_batch.ps1`: PASS
- `work\build_external_mt5_validation_package.ps1`: PASS
- `work\test_external_mt5_validation_package.ps1`: PASS, 26 checks, 0 failed
- `work\test_price_action_strategy_decision.ps1`: PASS
- `work\test_loss_streak_risk_reduction.ps1`: PASS
- `work\refresh_offline_validation_state.ps1`: PASS, 39 steps, 0 failed

## Latest Hashes

- `outputs\Professional_XAUUSD_EA.mq5`: `B065E7D6BCFF4F68F6AC40CD0939FD2C476E9B765C5D690A8051A9FB67295AB2`
- `Professional_XAUUSD_EA.mq5`: `B065E7D6BCFF4F68F6AC40CD0939FD2C476E9B765C5D690A8051A9FB67295AB2`
- `outputs\external_mt5_validation_package\source\Professional_XAUUSD_EA.mq5`: `B065E7D6BCFF4F68F6AC40CD0939FD2C476E9B765C5D690A8051A9FB67295AB2`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `60CBD2869DCA56B86B0B1B7963FF478FEAA21B4E62A87F59BAAB2E095E6E64C4`
- `outputs\PRICE_ACTION_STRATEGY_BATCH.csv`: `36CA47EAB0261A26A96CB302CCDEDA91EA3E4F0A4E712735C04E01AA2CB8F652`
- `outputs\xauusd_micro_validation_package.zip`: `B0EE610E31195145354A79CB08B66F0915C40D7189D32723963514EFE58B88E9`
- `work\test_price_action_strategy_modules.ps1`: `3245034700A98085A58AA87979397FAEC3CB9A4D29460F3DBB3B7A467820A4BE`
- `work\test_price_action_strategy_batch.ps1`: `026C3B99CCCBEF1D0D517B1D78EC9FDF3143C76B28B4E3B0B99DC468F3BECCD3`
- `work\build_price_action_strategy_batch.ps1`: `36A8CC7F5AA9521CDDAB11C6B22760E729800565615909E6DFFFFBC0A4E75A31`

## Background-Safety Note

The stop marker remains expected at `work\STOP_MT5_FOCUS_WATCHDOG`. Any future MT5 validation should be treated as external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The status note was committed through the GitHub connector. The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that the status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.
