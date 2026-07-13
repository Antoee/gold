# Adaptive Reverse Quarantine Note

Date: 2026-07-13

Status: source guardrail, not a promoted profit change.

## Decision

Adaptive Reverse remains internally disabled:

`bool InpUseAdaptiveReverse = false;`

It is also not optimizer-visible as an `input`.

If Adaptive Reverse is manually re-enabled for future research, its default guard layer is now strict:

- Recent reverse-flip cooldown enabled.
- Post-stop lockout enabled.
- Range-phase block enabled.
- Trend-phase requirement enabled.
- Forward-liquidity trap guard enabled.
- Forward-liquidity clearance requirement enabled.
- Follow-through close requirement enabled.

## Why

Stop-and-reverse logic is dangerous on XAUUSD when the market is choppy or mean-reverting. The active research path should add profit through independent structural entry lanes, not by flipping after invalidation.

This change does not claim a new profit result. It lowers the chance that a future `.set` file or research branch accidentally revives a whipsaw-prone reversal engine.

## Validation

Completed local checks:

- `work/test_adaptive_reverse_quarantine.ps1`: `ADAPTIVE_REVERSE_QUARANTINE_SMOKE_PASS`
- `work/test_price_action_strategy_modules.ps1`: `PRICE_ACTION_STRATEGY_MODULES_SMOKE_PASS`
- `work/test_flat_month_liquidity_reclaim_probe_package.ps1`: `FLAT_MONTH_LIQUIDITY_RECLAIM_PROBE_PACKAGE_SMOKE_PASS`
- `work/test_flat_month_liquidity_reclaim_compact_source.ps1`: `FLAT_MONTH_LIQUIDITY_RECLAIM_COMPACT_SOURCE_SMOKE_PASS`
- `work/audit_mt5_local_safety.ps1`: `PASS`, `39 / 39`
- Root and canonical EA copies match.

MT5 compile/backtest was not run because `work/MT5_LOCAL_LAUNCH_DISABLED.lock` remains active to prevent focus stealing.

## Decision

Do not promote this as a profit improvement.

Keep Adaptive Reverse off. Continue pursuing flat-month profit through low-risk structural lanes such as `FMLR`, direct structural stops, and liquidity-aware targets.
