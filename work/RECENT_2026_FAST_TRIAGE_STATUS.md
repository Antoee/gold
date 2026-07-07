# Recent 2026 Fast Triage Status

Updated: 2026-07-07

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- Full EA source exists locally, but this note is the GitHub-safe status/evidence artifact.

## Latest Strategy-Code Change

Added an equity-peak giveback quality gate. This is an optional profit-preservation entry filter that raises the required entry quality when equity pulls back from a meaningful high-watermark profit cushion.

New inputs and logic:

- `InpUseEquityPeakGivebackQualityGate`
- `InpEquityPeakGivebackMinPeakProfitPercent`
- `InpEquityPeakGivebackStartPercent`
- `InpEquityPeakGivebackFullPercent`
- `InpEquityPeakGivebackMinQualityScore`
- `InpEquityPeakGivebackMaxQualityScore`
- `EquityPeakGivebackQualityAllows()` tracks peak equity, requires a minimum peak-profit cushion, then raises required entry quality as giveback grows.
- Weak new entries are blocked with `equity peak giveback quality`.
- Generated research profiles enable the gate after a 2% peak-profit cushion, from 25% to 60% giveback, requiring quality score 12 to 16.

This supports the goal by protecting both floating and realized gains before they become deep drawdown, while still allowing high-quality opportunities to keep trading. It does not add martingale, grid, averaging down, or recovery behavior.

## Fast Batch Impact

- Batch size stayed at 10 profiles and 30 runs.
- Estimated tester runtime stayed at about 10.5 minutes before platform overhead.
- Baseline anchor keeps equity-peak giveback quality gate disabled.
- Generated research profiles use:
  - `InpUseEquityPeakGivebackQualityGate=true`
  - `InpEquityPeakGivebackMinPeakProfitPercent=2.00`
  - `InpEquityPeakGivebackStartPercent=25.0`
  - `InpEquityPeakGivebackFullPercent=60.0`
  - `InpEquityPeakGivebackMinQualityScore=12`
  - `InpEquityPeakGivebackMaxQualityScore=16`

## Quiet Validation Results

- `work\test_price_action_strategy_modules.ps1`: PASS
- `work\sync_ea_source_artifacts.ps1`: PASS, hash `2D5CA7D2AF69B25BED4B08DB03463E6B585C633B2EA4A2DD8D7871CB64D0D33D`
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

- `outputs\Professional_XAUUSD_EA.mq5`: `2D5CA7D2AF69B25BED4B08DB03463E6B585C633B2EA4A2DD8D7871CB64D0D33D`
- `Professional_XAUUSD_EA.mq5`: `2D5CA7D2AF69B25BED4B08DB03463E6B585C633B2EA4A2DD8D7871CB64D0D33D`
- `outputs\external_mt5_validation_package\source\Professional_XAUUSD_EA.mq5`: `2D5CA7D2AF69B25BED4B08DB03463E6B585C633B2EA4A2DD8D7871CB64D0D33D`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `A91FE48C4A4FB65897788726C7DADB44214357EBE8C9C508322238C9B9482672`
- `outputs\xauusd_micro_validation_package.zip`: `14F5E4632F52B5C8BD22DA5E5D0F99173138603C883B8E908BFF55B97670338B`
- `work\build_price_action_strategy_batch.ps1`: `73A551767D62A71BA1D80A48B7A573DDED1EFA1CE88D79C5BBAE9D0166C9201C`
- `work\test_price_action_strategy_modules.ps1`: `9D4A07BA2FA215F451C7CD18264B3E04D95B9B909D8E0E53196BF3434533B25E`
- `work\test_price_action_strategy_batch.ps1`: `0D171CF29D4E99E4AE0D7B0EC62F4B84A584EB72107A35DC7DD8D55B37F4E854`
- `outputs\OFFLINE_VALIDATION_REFRESH.csv`: `775C1AF704F34546549506D747BB53EC89BF45F6C1D6AC3959A0C7807696F530`

## Background-Safety Note

The stop marker remains present at `work\STOP_MT5_FOCUS_WATCHDOG`. Any future MT5 validation should be treated as external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The status note is committed through the GitHub connector. The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that the status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.