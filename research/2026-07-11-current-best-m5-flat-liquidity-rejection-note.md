# Current Best M5 Flat-Liquidity Rejection Note

Date: 2026-07-11

## Purpose

Retest the M5 tight-liquidity secondary lane against the current research-best FSD strict profile instead of the older peak candidate. The goal was to see whether a very small M5 lane could fill flat months without damaging the robust March/May/August profile.

Base profile:

- `outputs/CANDIDATE_PRIMARY_AUG40_REVERSE_OFF_FSD_STRICT_MICRO_JULOCT_PROFILE.set`

Evidence:

- Run CSV: `outputs/CURRENT_BEST_M5_FLAT_LIQUIDITY_MODEL0_PROBE_RUN.csv`
- Log results: `outputs/CURRENT_BEST_M5_FLAT_LIQUIDITY_MODEL0_PROBE_LOG_RESULTS.csv`
- Summary: `outputs/CURRENT_BEST_M5_FLAT_LIQUIDITY_MODEL0_PROBE_LOG_SUMMARY.csv`
- Builder: `work/build_current_best_m5_flat_liquidity_model0_probe_package.ps1`

## Summary

Model 0, M5 tester period, with `InpSignalTimeframe=15`.

| Profile | Continuous | YTD | Full 2025 | Full 2024 | Worst Window | Losing Windows |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| base | 6222.35 | 1107.93 | 214.30 | 2390.20 | 0.00 | 0 |
| m5_flat_strict_align | 2002.28 | 20.66 | 214.62 | 2002.28 | -16.72 | 5 |
| m5_active_only | 1936.68 | 378.06 | 213.12 | 1936.68 | -13.25 | 5 |
| m5_flat_micro_free | 1771.02 | 1119.87 | 42.33 | 1984.59 | -7.95 | 3 |

## Decision

Rejected.

The M5 lane still does not solve the flat-month problem robustly. The best recent-looking variant, `m5_flat_micro_free`, improved 2026 YTD by only 11.94 while cutting full 2025 from 214.30 to 42.33 and adding 3 losing windows. The stricter aligned variants were worse, reducing continuous profit by roughly two-thirds and adding 5 losing windows.

The current research-best profile remains unchanged.

## Takeaway

M5 tight-liquidity is not a clean incremental edge for this candidate. It can add activity in dormant windows, but the new trades are not selective enough and create small losses where the base profile correctly stays flat.

Future work should avoid simply adding lower-timeframe entries. A better next direction is a regime controller that must prove a positive edge before allowing supplemental lanes, or an exit/position-management improvement that increases payoff on existing robust signals without opening new weak-month exposure.
