# Recent 2026 Fast Triage Status

Updated: 2026-07-06

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- Full EA source exists locally, but this note is the GitHub-safe status/evidence artifact.

## Latest Risk-Code Change

Added optional Recent Average-R Quality Gate for generated research profiles:

- `InpUseRecentPerformanceRQualityGate`
- `InpRecentPerformanceRLookbackTrades`
- `InpRecentPerformanceMaxAverageR`
- `InpRecentPerformanceRMinQualityScore`
- `RecentPerformanceRMultipleSample()` reconstructs recent R multiples from MT5 deal history using matching position IDs, entry stop loss, close volume, and closed-deal profit.
- `RecentPerformanceRQualityAllows()` raises the required signal quality score when recent average R is weak.
- `OpenSignal()` now blocks weak-quality entries with `recent average R quality` before risk sizing.

This is risk-adjusted selectivity code, not only parameter tweaking. It complements the net-percent recent performance gate with an R-based view that is less distorted by dynamic lot sizing. If a full reconstructable R sample is unavailable from MT5 history, the gate stays inactive and the existing recent-performance controls remain the fallback. The baseline anchor remains disabled for clean comparison, while generated research profiles enable it. It adds no martingale, grid, averaging down, or recovery behavior.

## Fast Batch Impact

- Batch size stayed at 10 profiles and 30 runs.
- Estimated tester runtime stayed at about 10.5 minutes before platform overhead.
- Baseline anchor remains `InpUseRecentPerformanceRQualityGate=false`.
- Generated research profiles use `InpUseRecentPerformanceRQualityGate=true`.
- Research profiles use lookback `5`, average-R threshold `-0.15`, and minimum quality score `11`.

## Quiet Validation Results

- `work\test_price_action_strategy_modules.ps1`: PASS
- `work\sync_ea_source_artifacts.ps1`: PASS, hash `3216889FC4F8742843B6AAD1AB15088A068E980460942C74EA222C195F456620`
- `work\build_price_action_strategy_batch.ps1`: PASS, 10 profiles, 30 runs, estimated 10.5 minutes
- `work\test_ea_source_artifact_sync.ps1`: PASS
- `work\test_price_action_strategy_batch.ps1`: PASS
- `work\build_external_mt5_validation_package.ps1`: PASS, package configs 20, profiles 9
- `work\test_external_mt5_validation_package.ps1`: PASS, 26 checks, 0 failed
- `work\refresh_offline_validation_state.ps1`: PASS, 39 steps, 0 failed

## Latest Hashes

- `outputs\Professional_XAUUSD_EA.mq5`: `3216889FC4F8742843B6AAD1AB15088A068E980460942C74EA222C195F456620`
- `Professional_XAUUSD_EA.mq5`: `3216889FC4F8742843B6AAD1AB15088A068E980460942C74EA222C195F456620`
- `outputs\external_mt5_validation_package\source\Professional_XAUUSD_EA.mq5`: `3216889FC4F8742843B6AAD1AB15088A068E980460942C74EA222C195F456620`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `3F3BA83908536C902E183DDAF4549392088222AAD6C28072564D1DED24949813`
- `outputs\PRICE_ACTION_STRATEGY_BATCH.csv`: `903827B590601032A7A70DABEBD76776A74CDD40CD4C103FEB0574FC2D00BED6`
- `outputs\xauusd_micro_validation_package.zip`: `75B113BBB9227E0C82CC8BBFDE10938BD23EAB92098E9733C4FF86AD1D393F8F`
- `work\test_price_action_strategy_modules.ps1`: `32AA8E7DE6971C8BE7095EEC360D0EBA50F27EA04BD19D4B86D285F83FCAE17B`
- `work\test_price_action_strategy_batch.ps1`: `BC3111F1A84F75228DFD536506663B6DF0783F2D120BBC6104BF0BD98C4089F2`
- `work\build_price_action_strategy_batch.ps1`: `C08A9D21FB8F8FCE834EBC572977186B80D016985EA71E9E19864C6F848B749A`

## Background-Safety Note

The stop marker remains expected at `work\STOP_MT5_FOCUS_WATCHDOG`. Any future MT5 validation should be treated as external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The status note was committed through the GitHub connector. The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that the status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.
