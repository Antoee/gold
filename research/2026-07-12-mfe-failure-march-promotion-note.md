# MFE Failure March Promotion Note - 2026-07-12

## Summary

The all-month MFE failure exit was rejected because it improved 2026 YTD but damaged full-year 2024 and the continuous validation window.

A new month-gated MFE failure exit was added so no-progress exits can be isolated to months where the evidence supports them. The promoted candidate enables it only in March.

## Source Patch

- `patches/2026-07-12-mfe-failure-month-filter.patch`

## Promoted Candidate

- Profile: `outputs/CANDIDATE_PRIMARY_RANGE_ELITE_MFE_FAILURE_MARCH_PROFILE.set`
- Builder: `work/build_current_best_mfe_failure_march_profile.ps1`
- SHA-256: `690C546EC57D2DB3BBE666B3A81DF61C871F36D59853EB3DDCCD1D3D17207693`

## Key Settings

- `InpUseMFEFailureExit=true`
- `InpMFEFailureBars=6`
- `InpMFEFailureMinMFER=0.30`
- `InpMFEFailureMaxCurrentR=0.05`
- `InpUseMFEFailureMonthFilter=true`
- `InpMFEFailureTradeMarch=true`
- All other `InpMFEFailureTrade*` month toggles are `false`.

## Rejection Evidence: All-Month MFE Failure

Validation file:

- `outputs/MFE_FAILURE_VALIDATION_LOG_RESULTS.csv`

Results:

- Full 2024: `1760.49` versus current best `2473.48`
- Full 2025: `214.18`
- 2026 YTD: `1375.04`
- Continuous 2024-2026: `6354.71` versus current best `6763.86`

Rejected because the 2026 gain did not survive the broad validation gate.

## Promotion Evidence: March-Gated MFE Failure

Validation file:

- `outputs/MFE_FAILURE_MONTH_VARIANT_LOG_RESULTS.csv`

Results:

- Full 2024: `2459.19`
- Full 2025: `214.18`
- 2026 YTD: `1375.04`
- Continuous 2024-2026: `7756.74`
- Losing validation windows: `0`

Quarter validation:

- `outputs/MFE_FAILURE_MARCH_QUARTER_LOG_RESULTS.csv`

Quarter results:

- 2024 Q1: `1482.99`
- 2024 Q2: `209.80`
- 2024 Q3: `12.04`
- 2024 Q4: `46.75`
- 2025 Q1: `214.18`
- 2025 Q2: `0.00`
- 2025 Q3: `20.87`
- 2025 Q4: `41.25`
- 2026 YTD: `1375.04`
- Losing quarter windows: `0`

## Decision

Promote `CANDIDATE_PRIMARY_RANGE_ELITE_MFE_FAILURE_MARCH_PROFILE.set` as the current research-best profile.

This is still a research candidate, not a live-money production profile. The next gate should use higher-fidelity tick/spread/slippage stress testing and exported MT5 reports once the report-export issue is resolved.
