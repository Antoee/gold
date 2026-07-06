# Recent 2026 Fast Triage Status

Updated: 2026-07-06

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- Full EA source exists locally, but this note is the GitHub-safe status/evidence artifact.

## Latest Strategy-Code Change

Added an optional Consecutive Candle Exhaustion Guard:

- `InpUseConsecutiveCandleExhaustionGuard`
- `InpConsecutiveCandleLookbackBars`
- `InpMaxConsecutiveDirectionalBars`
- `InpConsecutiveMoveMaxATR`
- `InpConsecutiveMinBodyPercent`
- `CEntryEngine::ConsecutiveCandleExhaustionAllows()` detects same-direction candle runs with meaningful bodies and rejects late entries when the run has already moved too far in ATR terms.
- Entry rejection logs `Consecutive candle exhaustion reject`.

This changes strategy logic instead of only changing settings. The goal is to avoid chasing XAUUSD after a stretched one-way candle sequence, where continuation entries often have poor reward-to-risk and snapback risk. It is disabled in the robust base profile and enabled only in strict research profiles. It adds no martingale, grid, averaging down, or recovery behavior.

## Fast Batch Impact

- Batch size stayed at 10 profiles and 30 runs.
- Estimated tester runtime stayed at about 10.5 minutes before platform overhead.
- `weighted_quality_confluence` enables Consecutive Candle Exhaustion Guard with lookback `5`, max directional bars `4`, max move `1.60 ATR`, and minimum body `35%`.
- `pa_full_confluence` enables a stricter version with lookback `6`, max directional bars `4`, max move `1.45 ATR`, and minimum body `38%`.
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

- `outputs\Professional_XAUUSD_EA.mq5`: `37A67C35D053BBCD691127A81F01555E3EA03931A1849C68ACDEB7ED5F411C0A`
- `Professional_XAUUSD_EA.mq5`: `37A67C35D053BBCD691127A81F01555E3EA03931A1849C68ACDEB7ED5F411C0A`
- `outputs\external_mt5_validation_package\source\Professional_XAUUSD_EA.mq5`: `37A67C35D053BBCD691127A81F01555E3EA03931A1849C68ACDEB7ED5F411C0A`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `7279BF16E11BCA5DAF429053CEAD50FAEF2FEB6731FF678A6CA2A3CA93390241`
- `outputs\PRICE_ACTION_STRATEGY_BATCH.csv`: `903827B590601032A7A70DABEBD76776A74CDD40CD4C103FEB0574FC2D00BED6`
- `outputs\xauusd_micro_validation_package.zip`: `650C484F507B4A945212D8B7CF89415E008231BF3DD500A0C6B641F0DAE03E27`
- `work\test_price_action_strategy_modules.ps1`: `EE20A1E5DF6D49890ADAF4E5AE4D866FFEE41308E64111E116F64425C5FD3688`
- `work\test_price_action_strategy_batch.ps1`: `6FCC6B714CA6CF17E415BF04A7A85DF05DED8B1DCCFFF26616586441D2134C82`
- `work\build_price_action_strategy_batch.ps1`: `B31DEF2338E2CCA7B42816A6610E089C29F0094162E667670562A3497CD15A64`

## Background-Safety Note

The stop marker remains expected at `work\STOP_MT5_FOCUS_WATCHDOG`. Any future MT5 validation should be treated as external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The status note can be committed through the GitHub connector. The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that the status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.
