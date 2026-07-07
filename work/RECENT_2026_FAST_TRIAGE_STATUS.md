# Recent 2026 Fast Triage Status

Updated: 2026-07-07 15:46:34 -05:00

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- Full EA source exists locally, but this note is the GitHub-safe status/evidence artifact.

## Latest Strategy-Code Change

Added a lifetime equity profit peak trail. This optional account-level ratchet lets the EA pursue larger upside, but closes/blocks when equity gives back too much after building a configurable profit peak.

New inputs and logic:

- `InpUseEquityProfitPeakTrail`
- `InpEquityProfitPeakTrailMinProfitPercent`
- `InpEquityProfitPeakTrailGivebackPercent`
- `EquityProfitPeakTrailHit()` tracks lifetime peak equity after the configured minimum profit is reached.
- `RiskLimitHit(...)` now returns `equity profit peak trail` when the account gives back more than the allowed share of peak profit.

This supports the goal by pairing aggressive profit pursuit with a higher-watermark giveback stop. It does not add martingale, grid, averaging down, or recovery behavior.

## Fast Batch Impact

- Batch size stayed at 10 profiles and 30 runs.
- Estimated tester runtime stayed at about 10.5 minutes before platform overhead.
- Baseline anchor keeps the lifetime equity profit peak trail disabled.
- Generated research profiles use:
  - `InpUseEquityProfitPeakTrail=true`
  - `InpEquityProfitPeakTrailMinProfitPercent=3.00`
  - `InpEquityProfitPeakTrailGivebackPercent=30.0`

## Quiet Validation Results

- `work\test_price_action_strategy_modules.ps1`: PASS
- `work\sync_ea_source_artifacts.ps1`: PASS, hash `51DE6A3201CF179BA79BF5AF7533A96F25E411EF47177BFC6BB0BDFC787EF4EC`
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

- `outputs\Professional_XAUUSD_EA.mq5`: `51DE6A3201CF179BA79BF5AF7533A96F25E411EF47177BFC6BB0BDFC787EF4EC`
- `Professional_XAUUSD_EA.mq5`: `51DE6A3201CF179BA79BF5AF7533A96F25E411EF47177BFC6BB0BDFC787EF4EC`
- `outputs\external_mt5_validation_package\source\Professional_XAUUSD_EA.mq5`: `51DE6A3201CF179BA79BF5AF7533A96F25E411EF47177BFC6BB0BDFC787EF4EC`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `73B4460867346EB1E0F78048F1E8272CA404B1446444B7AC4E30E6058A4AD0E4`
- `outputs\xauusd_micro_validation_package.zip`: `B08ED276DD9FA1C1ECC41ABD3069102D24CBAB1436BE2624B10D01E4113EC659`
- `work\build_price_action_strategy_batch.ps1`: `D4084D8CA87113CBF605395055CAA850EFAB1DA81CDFFD8067CA17D93B8D616F`
- `work\test_price_action_strategy_modules.ps1`: `8B5257B1FC529FCD516DD461FAD986E93F2F3EBD03220DADA3DED39917153292`
- `work\test_price_action_strategy_batch.ps1`: `091F255FDB6B776932A585D8846F8BD54D46E744EF2766390B184437893BD618`
- `outputs\OFFLINE_VALIDATION_REFRESH.csv`: `600D8AA15F2E603A426BB5A2FBB611B05AE09F8F552F28C2EE15257DA7DC3465`

## Background-Safety Note

The stop marker remains present at `work\STOP_MT5_FOCUS_WATCHDOG`. Any future MT5 validation should be treated as external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The status note is committed through the GitHub connector. The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that the status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.
