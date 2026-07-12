# MFE August Spread-Stress Rejection Note

Date: 2026-07-12

## Purpose

Stress the newly promoted MFE-August profile against stricter spread and spread-regime controls. This was a robustness gate after promoting:

- `outputs/CANDIDATE_PRIMARY_AUG40_REVERSE_OFF_FSD_STRICT_MFE_AUGUST_ONLY_PROFILE.set`

## Evidence

Source:

- Partial run CSV: `outputs/MFE_AUGUST_SPREAD_STRESS_MODEL0_RUN.csv`
- Parsed results: `outputs/MFE_AUGUST_SPREAD_STRESS_MODEL0_LOG_RESULTS_PARTIAL.csv`
- Parsed summary: `outputs/MFE_AUGUST_SPREAD_STRESS_MODEL0_LOG_SUMMARY_PARTIAL.csv`
- Builder reused: `work/build_current_best_spread_stress_package.ps1`

Model 0 results:

| Profile | Parsed | Continuous | YTD | Full 2025 | Full 2024 | Worst Window | Losing Windows |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| primary_aug20 | 7/7 | 6633.61 | 1107.93 | 214.30 | 2406.27 | 0.00 | 0 |
| aug20_maxspread220 | 7/7 | -1.99 | 1107.93 | 214.30 | -1.99 | -1.99 | 2 |
| aug20_regime155 | 7/7 | -1.99 | 1107.93 | 214.30 | -1.99 | -1.99 | 2 |
| aug20_shock180 | 7/7 | -1.99 | 1107.93 | 214.30 | -1.99 | -1.99 | 2 |
| aug20_spread_rr125 | 3/3 | -1.99 | 1107.93 | 214.30 | n/a | -1.99 | 1 |

The profile names are inherited from an older spread-stress builder. In this run, `primary_aug20` is the promoted MFE-August base profile, not the old Aug20 candidate.

## Decision

Reject the tested stricter spread-control variants for the promoted MFE-August profile.

The base profile preserved the promoted result. The strict spread variants introduced losing windows and collapsed the continuous/full-2024 result. This means these spread controls are not safe defensive defaults for the current profile.

## Takeaway

Do not tighten the current profile's spread settings using these old stress overrides. The profitable August path is sensitive to those filters, and defensive spread hardening can erase the edge rather than merely reduce bad fills.

The current research-best profile remains:

- `outputs/CANDIDATE_PRIMARY_AUG40_REVERSE_OFF_FSD_STRICT_MFE_AUGUST_ONLY_PROFILE.set`
- Continuous: `6633.61`
- 2026 YTD: `1107.93`
- Full 2025: `214.30`
- Full 2024: `2406.27`
- Losing windows: `0`

Local MT5 safety audit after testing: PASS 39/39.
