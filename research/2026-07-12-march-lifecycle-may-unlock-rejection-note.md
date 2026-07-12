# March Lifecycle / May Unlock Rejection Note

Date: 2026-07-12

## Purpose

Test whether earlier March exits, MFE locks, R-partial locks, stagnation exits, or no-follow-through exits could unlock the strong standalone May 2025 opportunity without damaging the broader 2024-2026 portfolio.

## Baseline

Current research-best profile remains:

- `outputs/CANDIDATE_PRIMARY_AUG40_REVERSE_OFF_FSD_STRICT_MFE_AUGUST_ONLY_PROFILE.set`
- Continuous 2024-2026 net profit: `6633.61`
- 2026 YTD net profit: `1107.93`
- Full 2025 net profit: `214.30`
- Full 2024 net profit: `2406.27`
- Losing validation windows: `0`

## Result

No March lifecycle or May unlock variant earned promotion.

| Profile | Continuous | 2026 YTD | Full 2025 | Full 2024 | Losing Windows |
|---|---:|---:|---:|---:|---:|
| base_mfe_aug | 6633.61 | 1107.93 | 214.30 | 2406.27 | 0 |
| may_stagnation_exit | 1113.95 | 1107.93 | 214.30 | 1113.95 | 0 |
| may_window_r280 | 1113.95 | 1107.93 | 214.30 | 1113.95 | 0 |
| may_march_mfe_lock_loose | 1113.95 | 708.99 | 214.30 | 1113.95 | 0 |
| may_march_mfe_lock | 1113.95 | 609.75 | 214.30 | 1113.95 | 0 |
| may_no_follow_exit | 1113.95 | 1375.36 | 214.30 | 1113.95 | 1 |
| may_march_rpartial | 920.29 | 1000.69 | 228.22 | 920.29 | 0 |

## Interpretation

The May 2025 standalone setup can be made very profitable when started directly in May, but the broader March-to-May and full-year path still suppresses or damages the portfolio. The May unlock variants also collapse continuous 2024-2026 profit from `6633.61` to roughly `1113.95` or worse.

The current best remains unchanged. The next useful direction is not more May risk scaling; it is isolating the path-dependent state that prevents the May leg from being available during full-period execution, or finding a separate additive lane that does not disturb the profitable March/August behavior.

## Artifacts

- `outputs/CURRENT_BEST_MARCH_LIFECYCLE_MAY_UNLOCK_MODEL0_LOG_SUMMARY.csv`
- `outputs/CURRENT_BEST_MARCH_LIFECYCLE_MAY_UNLOCK_MODEL0_LOG_RESULTS.csv`
- `work/build_current_best_march_lifecycle_may_unlock_model0_package.ps1`
