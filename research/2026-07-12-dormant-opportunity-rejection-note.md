# Dormant Opportunity Variant Rejection Note - 2026-07-12

## Summary

This pass tested strict, low-risk dormant-month opportunity lanes intended to reduce idle time without simply increasing risk.

The tested variants did not beat the current research-best profile and are rejected for promotion.

One source fix was kept:

- `patches/2026-07-12-flat-month-bypass-filter-scope.patch`

The flat probe month filter previously applied to every flat-month bypass. It now applies only to flat probe and flat momentum bypasses, so independently month-filtered flat micro-reversion and opportunity lanes are not blocked by a probe-only filter.

## Baseline To Beat

Current research-best:

- `outputs/CANDIDATE_PRIMARY_RANGE_ELITE_MFE_FAILURE_MARCH_PROFILE.set`

Evidence:

- Continuous 2024-2026: `7756.74`
- Full 2024: `2459.19`
- Full 2025: `214.18`
- 2026 YTD: `1375.04`
- Losing validation windows: `0`

## Tested Variants

Validation files:

- `outputs/DORMANT_OPPORTUNITY_FILTER_FIX_LOG_RESULTS.csv`
- `outputs/DORMANT_OPPORTUNITY_FILTER_FIX_LOG_SUMMARY.csv`

Variants:

- `stale_lowrisk`
- `missedmove_lowrisk`
- `elitefallback_lowrisk`
- `latecatch_lowrisk`
- `breakoutprobe_strict`
- `combo_conservative`

Results:

- `stale_lowrisk`, `missedmove_lowrisk`, `elitefallback_lowrisk`, `latecatch_lowrisk`
  - Full 2024: `2267.37`
  - Full 2025: `214.18`
  - 2026 YTD: `1375.04`
  - Continuous 2024-2026: `5578.11`
- `breakoutprobe_strict`
  - Full 2024: `2233.63`
  - Full 2025: `214.18`
  - 2026 YTD: `51.89`
  - Continuous 2024-2026: `4779.57`
- `combo_conservative`
  - Full 2024: `2240.26`
  - Full 2025: `214.18`
  - 2026 YTD: `63.41`
  - Continuous 2024-2026: `4846.29`

## Decision

Reject all tested dormant opportunity variants.

The current research-best profile remains:

- `outputs/CANDIDATE_PRIMARY_RANGE_ELITE_MFE_FAILURE_MARCH_PROFILE.set`

The dormant-month problem remains open. Future work should use trade-count/entry-reason instrumentation to distinguish "no signal" from "blocked signal" before relaxing more entry gates.

## Validation

- Compact compile: `outputs/MT5_HIDDEN_COMPILE_DORMANT_OPPORTUNITY_FILTER_FIX.log`
- Result: `0 errors, 0 warnings`
- Local MT5 safety audit: `PASS`, 39/39 checks
