# ISLP TP150 Risk050 Rejection Note - 2026-07-12

## Summary

The ISLP TP150/Risk050 profile improved the fast-model continuous validation, but failed the higher-fidelity `Model=1` comparison against the previous June/Oct-Dec profile.

Because the project goal prioritizes robustness over a single larger historical number, this variant is rejected and the current research-best pointer is reverted to `CANDIDATE_PRIMARY_RANGE_ELITE_MFE_FAILURE_MARCH_ISLP_JUN_OCTDEC_PROFILE.set`.

## Rejected Candidate

- Profile: `outputs/CANDIDATE_PRIMARY_RANGE_ELITE_MFE_FAILURE_MARCH_ISLP_JUN_OCTDEC_TP150_RISK050_PROFILE.set`
- Builder: `work/build_current_best_mfe_failure_march_islp_jun_octdec_tp150_risk050_profile.ps1`
- SHA-256: `E0411FF8D997E32856A728BCE81588A812239F7FC7FD21A235CC890E2D21B2A5`

## Fast-Model Evidence

Validation file:

- `outputs/ISLP_RISK_TARGET_LOG_RESULTS.csv`

Fast-model results versus previous current best:

- Full 2024: `3048.13` versus `3349.39`
- Full 2025: `214.18` versus `214.18`
- 2026 YTD: `1375.04` versus `1375.04`
- Continuous 2024-2026: `10687.20` versus `9512.09`
- Losing broad windows: `0`

## Higher-Fidelity Rejection Evidence

Validation files:

- `outputs/HF_CURRENT_VS_PREV_LOG_RESULTS.csv`
- `outputs/HF_CURRENT_VS_PREV_LOG_SUMMARY.csv`

`Model=1` results:

- Previous June/Oct-Dec continuous: `7210.30`
- TP150/Risk050 continuous: `1974.32`
- Continuous regression: `-5235.98`
- Previous full 2024: `2507.85`
- TP150/Risk050 full 2024: `2186.33`
- Full 2025 unchanged: `214.18`
- 2026 YTD unchanged: `1375.04`

## Decision

Reject TP150/Risk050 despite the larger fast-model result.

Restore `CANDIDATE_PRIMARY_RANGE_ELITE_MFE_FAILURE_MARCH_ISLP_JUN_OCTDEC_PROFILE.set` as the current research-best candidate because it is substantially stronger under the higher-fidelity check.
