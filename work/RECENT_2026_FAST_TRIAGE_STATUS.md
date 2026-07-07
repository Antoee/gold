# Recent 2026 Fast Triage Status

Updated: 2026-07-07

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- Full EA source exists locally, but this note is the GitHub-safe status/evidence artifact.

## Latest Strategy-Code Change

Added a realized closed-profit take-profit expansion. This is an optional capped TP-distance multiplier that reaches for larger winners only after the account has banked realized balance profit above the starting balance.

New inputs and logic:

- `InpUseClosedProfitTakeProfitExpansion`
- `InpClosedProfitTPMinQualityScore`
- `InpClosedProfitTPMinPriceActionScore`
- `InpClosedProfitTPStartPercent`
- `InpClosedProfitTPFullPercent`
- `InpClosedProfitTPMultiplier`
- `InpClosedProfitTPRequireTrailing`
- `InpClosedProfitTPRequiresProtectedFloor`
- `ClosedProfitTakeProfitMultiplier()` returns `1.0` until realized balance profit clears the configured start threshold.
- When protected-floor gating is enabled, the expansion also requires equity to remain above the active protected floor.
- Entry logs include `Closed profit TP x...` when the multiplier is active.

This supports the goal of trying to make more without simply raising initial risk: after banked profit exists, high-quality protected setups can target farther. Generated research profiles cap the expansion at 1.35x from 2% to 8% realized balance profit. It adds no martingale, grid, averaging down, or recovery behavior.

## Fast Batch Impact

- Batch size stayed at 10 profiles and 30 runs.
- Estimated tester runtime stayed at about 10.5 minutes before platform overhead.
- Baseline anchor keeps closed-profit TP expansion disabled.
- Generated research profiles use:
  - `InpUseClosedProfitTakeProfitExpansion=true`
  - `InpClosedProfitTPMinQualityScore=13`
  - `InpClosedProfitTPMinPriceActionScore=15`
  - `InpClosedProfitTPStartPercent=2.00`
  - `InpClosedProfitTPFullPercent=8.00`
  - `InpClosedProfitTPMultiplier=1.35`
  - `InpClosedProfitTPRequireTrailing=true`
  - `InpClosedProfitTPRequiresProtectedFloor=true`

## Quiet Validation Results

- `work\test_price_action_strategy_modules.ps1`: PASS
- `work\sync_ea_source_artifacts.ps1`: PASS, hash `6615A5FE719733F7096FD3C76306041B7010A1AECA70B9636964E8FEFE7BCE87`
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

- `outputs\Professional_XAUUSD_EA.mq5`: `6615A5FE719733F7096FD3C76306041B7010A1AECA70B9636964E8FEFE7BCE87`
- `Professional_XAUUSD_EA.mq5`: `6615A5FE719733F7096FD3C76306041B7010A1AECA70B9636964E8FEFE7BCE87`
- `outputs\external_mt5_validation_package\source\Professional_XAUUSD_EA.mq5`: `6615A5FE719733F7096FD3C76306041B7010A1AECA70B9636964E8FEFE7BCE87`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `4A31995BA92209BAB1EA5DBF0FBB114F253EEC90D9D94E9FC4FE2AAB233BF87B`
- `outputs\xauusd_micro_validation_package.zip`: `EB80D77331BC3F875D1D3E51E9864B812BAAD94A45B2B9CE5EB277F763148FFB`
- `work\build_price_action_strategy_batch.ps1`: `D4F73AA2B5638A9455CECEFC35896E1E9A169CCCDD466111549D932F7F6F901B`
- `work\test_price_action_strategy_modules.ps1`: `D67BD4C73B39DDB783C08B410F3F37789EB8AA0F47810842A28B143A3B100D78`
- `work\test_price_action_strategy_batch.ps1`: `21293C8C7BFC6E0789E27F0839D63F0526D9AFBCBC6D3727D16B2106059EE657`
- `outputs\OFFLINE_VALIDATION_REFRESH.csv`: `C74957F9C23B76BCBD259C41D5FCEB42BDE8306608F479BB7E483DF4441E18F0`

## Background-Safety Note

The stop marker remains present at `work\STOP_MT5_FOCUS_WATCHDOG`. Any future MT5 validation should be treated as external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The status note is committed through the GitHub connector. The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that the status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.