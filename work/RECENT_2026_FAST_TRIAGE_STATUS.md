# Recent 2026 Fast Triage Status

Updated: 2026-07-06

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- Full EA source exists locally, but this note is the GitHub-safe status/evidence artifact.

## Latest Strategy-Code Change

Added optional chop/noise entry filter:

- `InpUseChopFilter`
- `InpChopLookbackBars`
- `InpChopMaxNetMoveATR`
- `InpChopMinAlternationPercent`
- `CEntryEngine::ChopFilterAllows()` detects alternating candle direction with small net movement versus ATR.
- `CEntryEngine::Build()` now rejects low-progress alternating conditions with `Chop reject;` when the feature is enabled.

This is a price-action quality filter for XAUUSD. It is intended to avoid low-probability chop where breakout/crossover logic can get whipsawed. It stays optional, configurable, and disabled in the robust base profile. It adds no martingale, grid, averaging down, or recovery behavior.

## Fast Batch Impact

- Batch size stayed at 10 profiles and 30 runs.
- Estimated tester runtime stayed at about 10.5 minutes before platform overhead.
- `weighted_quality_confluence` enables chop filtering with lookback `10`, max net move `0.60 ATR`, and minimum alternation `65.0%`.
- `pa_full_confluence` enables stricter chop filtering with lookback `12`, max net move `0.55 ATR`, and minimum alternation `70.0%`.
- Generated configs confirmed the module is enabled in the strict research profiles and pinned disabled in the robust base profile.

## Quiet Validation Results

- `work\build_price_action_strategy_batch.ps1`: PASS, 10 profiles, 30 runs, estimated 10.5 minutes
- `work\sync_ea_source_artifacts.ps1`: PASS
- `work\test_price_action_strategy_modules.ps1`: PASS
- `work\test_price_action_strategy_batch.ps1`: PASS
- `work\test_ea_source_artifact_sync.ps1`: PASS
- `work\refresh_offline_validation_state.ps1`: PASS, 39 steps, 0 failed
- `work\build_external_mt5_validation_package.ps1`: PASS, package configs 20, profiles 9
- `work\test_external_mt5_validation_package.ps1`: PASS, 26 checks, 0 failed

## Latest Hashes

- `outputs\Professional_XAUUSD_EA.mq5`: `5A3DB64BC261C4E8091D48F0A6D38A772346F6D57662F65280A4CBC9DB350C9E`
- `Professional_XAUUSD_EA.mq5`: `5A3DB64BC261C4E8091D48F0A6D38A772346F6D57662F65280A4CBC9DB350C9E`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `FB319E370193CB97A5F02BC1E11EA378C0849ADFB3FB184A80DB2CFEFF65E4D0`
- `outputs\PRICE_ACTION_STRATEGY_BATCH.csv`: `903827B590601032A7A70DABEBD76776A74CDD40CD4C103FEB0574FC2D00BED6`
- `outputs\xauusd_micro_validation_package.zip`: `B8D948F40B842096CC25338F21AE8C4B199D65027936D529299C95B678E5C2D0`
- `work\test_price_action_strategy_modules.ps1`: `DA121E96274ED96E64845EE1C7E39DE17B575BA8AB3E0F4503615487F4080052`
- `work\test_price_action_strategy_batch.ps1`: `75B79462FA3895E3F8143CBA17CEAA349166C1E78BFFDBC102BB3C4800FD0FF5`
- `work\build_price_action_strategy_batch.ps1`: `278342D1F6EC7CFD1F2AB230F6B77BAF1DCA91B252E354C800AAF49F462EC3F7`

## Background-Safety Note

The stop marker remains expected at `work\STOP_MT5_FOCUS_WATCHDOG`. Any future MT5 validation should be treated as external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The status note is committed through the GitHub connector. The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that the status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.
