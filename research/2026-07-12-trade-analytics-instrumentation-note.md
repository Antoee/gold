# Trade Analytics Instrumentation Note - 2026-07-12

## Purpose

Parameter-only changes were producing weak or fragile gains. The EA now has a local instrumentation patch to make the next strategy-code iterations evidence-driven instead of blind tuning.

## Local EA Change

Patch artifact:

- `patches/2026-07-12-trade-analytics-instrumentation.patch`

Behavior impact:

- No entry rules changed.
- No exit rules changed.
- No risk sizing changed.
- Trade logging gains additional analytics fields at the end of the CSV.

New exported analytics columns:

- `max_favorable_r`
- `max_adverse_r`
- `held_bars`
- `entry_context`

The EA already tracked maximum favorable R internally. This patch exposes it to the CSV logger and adds matching maximum adverse R tracking through the same global-variable pattern.

## Validation

Local Windows workflow-equivalent smoke checks passed:

- `work/test_report_collector_parser.ps1`
- `work/test_external_mt5_micro_decision.ps1`
- `work/test_risk_adjusted_micro_batch.ps1`
- `work/test_generate_profit_search_configs.ps1`
- `work/test_report_import_preflight.ps1`
- `work/test_offline_refresh_quiet_mode.ps1`
- `work/bootstrap_ci_risk_adjusted_handoff.ps1`
- `work/build_external_mt5_validation_package.ps1 -EaSourcePath Professional_XAUUSD_EA.mq5`
- `work/audit_handoff_config_integrity.ps1`
- `work/test_external_mt5_validation_package.ps1`

Hidden MetaEditor compile:

- `outputs/MT5_HIDDEN_COMPILE_ANALYTICS.log`
- Result: `0 errors, 0 warnings`

Local MT5 safety audit:

- `outputs/MT5_LOCAL_SAFETY_AUDIT.csv`
- Result: `PASS`, 39/39 checks

## Next Use

Run a compact logged validation pass on the current research-best profile, then group losing and low-efficiency trades by:

- MFE reached before loss
- MAE depth before winner
- hold bars
- entry reason tokens
- month/session

This should identify whether the next code change should target:

- earlier invalidation exits,
- wider initial stops for trades that recover after deep MAE,
- profit-lock thresholds for trades with high MFE giveback,
- or entry filters for setups with poor MFE.
