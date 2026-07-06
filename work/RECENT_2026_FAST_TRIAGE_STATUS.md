# Recent 2026 Fast Triage Status

Updated: 2026-07-06

## Current State

- MT5, MetaEditor, terminal64, metatester, and Strategy Tester were not launched.
- Compile/backtest status is still `STALE` because GUI MT5 validation is intentionally disabled to avoid focus stealing.
- No profit claim is made from this offline-only validation.
- Full EA source exists locally, but this note is the GitHub-safe status/evidence artifact.

## Latest Strategy-Code Change

Added optional Protected-Cushion Take-Profit Expansion. This tries to make more from strong winners without increasing initial stop risk:

- `InpUseProtectedCushionTakeProfitExpansion`
- `InpProtectedCushionTPMinQualityScore`
- `InpProtectedCushionTPMinPriceActionScore`
- `InpProtectedCushionTPStartPercent`
- `InpProtectedCushionTPFullPercent`
- `InpProtectedCushionTPMultiplier`
- `InpProtectedCushionTPRequireTrailing`
- `ProtectedCushionTakeProfitMultiplier(const SSignal &signal)`

When enabled, the EA can expand take-profit distance only when:

- The setup quality score is high enough.
- The price-action score is high enough.
- Trailing/profit-management protection is available when required.
- Account equity has cushion above the active protected floor.

Generated aggressive research profiles enable this new TP expansion. The baseline keeps it disabled for clean comparison. This adds no martingale, grid, averaging down, or recovery behavior.

## Fast Batch Impact

- Batch size stayed at 10 profiles and 30 runs.
- Estimated tester runtime stayed at about 10.5 minutes before platform overhead.
- Baseline anchor keeps `InpUseProtectedCushionTakeProfitExpansion=false`.
- Generated research profiles use `InpUseProtectedCushionTakeProfitExpansion=true`.
- Generated research profiles expand protected-cushion TP from a 6.0% protected-floor cushion to full effect at 18.0%, with max multiplier `1.50`, quality score >= 12, price-action score >= 14, and trailing required.

## Quiet Validation Results

- `work\test_price_action_strategy_modules.ps1`: PASS
- `work\sync_ea_source_artifacts.ps1`: PASS, hash `5BA5A2A528BAA26B2112F8F3F10EE0561B0EBCC4CFCFB25EF8BCECF098DDE396`
- `work\build_price_action_strategy_batch.ps1`: PASS, 10 profiles, 30 runs, estimated 10.5 minutes
- `work\test_ea_source_artifact_sync.ps1`: PASS
- `work\test_price_action_strategy_batch.ps1`: PASS
- `work\build_external_mt5_validation_package.ps1`: PASS, package configs 20, profiles 9
- `work\test_external_mt5_validation_package.ps1`: PASS, 26 checks, 0 failed
- `work\test_price_action_strategy_decision.ps1`: PASS
- `work\test_loss_streak_risk_reduction.ps1`: PASS
- `work\refresh_offline_validation_state.ps1`: PASS, 39 steps, 0 failed

## Latest Hashes

- `outputs\Professional_XAUUSD_EA.mq5`: `5BA5A2A528BAA26B2112F8F3F10EE0561B0EBCC4CFCFB25EF8BCECF098DDE396`
- `Professional_XAUUSD_EA.mq5`: `5BA5A2A528BAA26B2112F8F3F10EE0561B0EBCC4CFCFB25EF8BCECF098DDE396`
- `outputs\external_mt5_validation_package\source\Professional_XAUUSD_EA.mq5`: `5BA5A2A528BAA26B2112F8F3F10EE0561B0EBCC4CFCFB25EF8BCECF098DDE396`
- `outputs\ROBUST_BOS_SWEEP_PROFILE.set`: `1DC75A51EC5AD4679F00FABB3CE4C66320C69389AFCD5755350CB8BE95018F4B`
- `outputs\PRICE_ACTION_STRATEGY_BATCH.csv`: `6887C7B2EE4D4D91A5BB05D817F303AA608F807C276142686247ED0AB5998D99`
- `outputs\xauusd_micro_validation_package.zip`: `1B475D7455E8B9A7EA439CC4758FE143A04F191A07D59A200CE9A07C1E935C90`
- `work\test_price_action_strategy_modules.ps1`: `1BABB56002A0C9EF81268216F8E1580F966542E5FBA42CC419B64EDBBF455762`
- `work\test_price_action_strategy_batch.ps1`: `92895D1F0D983857583A33A2879D52ED43C47D6496B9B44F816A1E4366419180`
- `work\build_price_action_strategy_batch.ps1`: `535598599A97A02D6727443F923DBB3CAC06610A0AE31A471056845FEF1C21A0`

## Background-Safety Note

The stop marker remains expected at `work\STOP_MT5_FOCUS_WATCHDOG`. Any future MT5 validation should be treated as external/manual or run only after the no-focus/no-popup issue is solved.

## GitHub Source Caveat

The status note was committed through the GitHub connector. The local shell still has no usable `git` or `gh` path in this workspace, and the full EA source is large enough that the status note plus hashes remains the safer connector artifact until a normal git push or non-truncated upload path is available.