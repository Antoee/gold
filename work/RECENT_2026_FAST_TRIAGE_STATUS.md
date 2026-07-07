# Recent 2026 Fast Triage Status

Updated: 2026-07-07 16:25:00 -05:00

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- Full EA source exists locally, but this note is the GitHub-safe status/evidence artifact.

## Latest Strategy-Code Change

Added an open-profit risk coverage gate for winner scale-ins. This is meant to let the EA press strong winning trades only when existing open profit can absorb the new add-on's estimated stop-loss risk.

New inputs and logic:

- `InpWinnerScaleInRequireOpenProfitRiskCover`
- `InpWinnerScaleInOpenProfitRiskCoverage`
- `ScaleInOpenProfitCoversRisk(...)`
- The entry path calls the coverage check after final lot sizing, so it uses the actual add-on lots and stop distance.
- Generated research profiles enable the gate with `InpWinnerScaleInOpenProfitRiskCoverage=1.25`.

This supports the goal by allowing more profit-seeking winner scale-ins while requiring the current basket's open profit cushion to cover at least 125% of the new trade's estimated risk. It does not add martingale, grid, averaging down, or recovery behavior.

## Fast Batch Impact

- Batch size stayed at 10 profiles and 30 runs.
- Estimated tester runtime stayed at about 10.5 minutes before platform overhead.
- Baseline anchor remains conservative and keeps the new coverage gate disabled.
- Generated research profiles now use:
  - `InpWinnerScaleInRequireOpenProfitRiskCover=true`
  - `InpWinnerScaleInOpenProfitRiskCoverage=1.25`
  - Existing house-money, protected-stop, locked-R, trend-regime, and giveback-quality scale-in gates remain active.

## Quiet Validation Results

- `work\test_price_action_strategy_modules.ps1`: PASS
- `work\sync_ea_source_artifacts.ps1`: PASS, hash `E94E247D5A9D3393DE50B463CE55F1475E40745BA3DC3F78176E6768A4ED7144`
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
- Stop marker: present at `work\STOP_MT5_FOCUS_WATCHDOG`

## Latest Evidence

- `outputs\Professional_XAUUSD_EA.mq5`: `E94E247D5A9D3393DE50B463CE55F1475E40745BA3DC3F78176E6768A4ED7144`
- `Professional_XAUUSD_EA.mq5`: `E94E247D5A9D3393DE50B463CE55F1475E40745BA3DC3F78176E6768A4ED7144`
- `outputs\external_mt5_validation_package\source\Professional_XAUUSD_EA.mq5`: `E94E247D5A9D3393DE50B463CE55F1475E40745BA3DC3F78176E6768A4ED7144`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `B4F6D37CF5F5D1A13BF74AFBA68E4F25F6DEDCC84E90E205D7872058B94AAE71`
- `outputs\xauusd_micro_validation_package.zip`: `66003EEC8384EACE88D7343937BC54D9AC64AD9E2F7B63ECA7FB7AEDF9A195AE`
- `work\build_price_action_strategy_batch.ps1`: `967BCC6AF1419033F71547B4A464EBC7D6FA6C66553F34BB074A1D98E650B2F5`
- `work\test_price_action_strategy_modules.ps1`: `AE84698B89E859D01E432217193D0E1EFEF8FFBD32301F9806CA56123968757D`
- `work\test_price_action_strategy_batch.ps1`: `8DCA5DDD5222AEDBC9173A50F7F2C9A5C9B69F95D559EC3347AA0712923034AC`
- `outputs\OFFLINE_VALIDATION_REFRESH.csv`: `9282104566F74749EF70C3429E92901D42B8FB04BEF48580C4B043DC2B095BB1`

## Background-Safety Note

The stop marker remains present at `work\STOP_MT5_FOCUS_WATCHDOG`. Any future MT5 validation should be treated as external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The status note is committed through the GitHub connector. The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that the status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.
