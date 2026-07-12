# MFE August Risk Ladder Rejection Note

Date: 2026-07-12

## Purpose

Retest the August risk ladder after promoting the August-only MFE profit-lock stop. The goal was to see whether the improved August exit management repaired the instability seen at higher August risk allocations.

## Evidence

- Package builder: `work/build_current_best_august_risk_ladder_package.ps1`
- Package: `work/local_mt5_mfe_august_risk_ladder_model0_package`
- Run log: `outputs/MFE_AUGUST_RISK_LADDER_MODEL0_RUN.csv`
- Parsed results: `outputs/MFE_AUGUST_RISK_LADDER_MODEL0_LOG_RESULTS.csv`
- Summary: `outputs/MFE_AUGUST_RISK_LADDER_MODEL0_LOG_SUMMARY.csv`
- Compile log: `outputs/MFE_AUGUST_RISK_LADDER_MODEL0_COMPILE.log`

## Results

| Profile | Parsed | Expected | Total Net | Continuous | 2026 YTD | Full 2025 | Full 2024 | Worst Window | Losing Windows |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| aug_risk040 | 7 | 7 | 10513.73 | 6633.61 | 1107.93 | 214.30 | 2406.27 | 0.00 | 0 |
| aug_risk020 | 7 | 7 | 7119.46 | 5818.74 | 1107.93 | 92.30 | 0.00 | 0.00 | 0 |
| aug_risk060 | 7 | 7 | 4034.56 | 1487.12 | 1107.93 | 214.30 | 1318.75 | -54.90 | 2 |
| aug_risk100 | 7 | 7 | 3567.87 | 1203.43 | 1107.93 | 214.30 | 1203.43 | -98.82 | 2 |
| aug_risk150 | 7 | 7 | 3532.55 | 1082.65 | 1107.93 | 214.30 | 1082.65 | -148.23 | 1 |
| aug_risk200 | 7 | 7 | 2943.93 | 961.87 | 1107.93 | 214.30 | 961.87 | -197.64 | 2 |

## Decision

Keep `aug_risk040`, which is the current research-best setting inside `outputs/CANDIDATE_PRIMARY_AUG40_REVERSE_OFF_FSD_STRICT_MFE_AUGUST_ONLY_PROFILE.set`.

Reject `aug_risk060`, `aug_risk100`, `aug_risk150`, and `aug_risk200` because they reduced continuous profit and reintroduced losing validation windows. Reject `aug_risk020` because it remained safe but gave up too much profit compared with `aug_risk040`.

The MFE August lock improved the current profile, but it did not make higher August risk robust enough to promote.
