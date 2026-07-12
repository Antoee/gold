# ISLP Score7 Promotion Note - 2026-07-12

## Summary

The higher-fidelity Model=1 variant sweep tested conservative In-Session Liquidity Pullback parameter changes against the current robust June/October/November/December ISLP profile.

The promoted change raises `InpInSessionLiquidityPullbackMinScore` from `6` to `7`. This keeps the same active months and risk settings, but requires a stronger ISLP quality score before entry.

## Promoted Candidate

- Profile: `outputs/CANDIDATE_PRIMARY_RANGE_ELITE_MFE_FAILURE_MARCH_ISLP_JUN_OCTDEC_SCORE7_PROFILE.set`
- Builder: `work/build_current_best_mfe_failure_march_islp_jun_octdec_score7_profile.ps1`
- SHA-256: `E36378232B722A2A09C1EFD2494F04385B7020CAE1F1679DDE903E05D8BC12D0`

## Key Setting Change

- `InpInSessionLiquidityPullbackMinScore=7`

## Model=1 Broad Validation

Validation files:

- `outputs/MODEL1_ISLP_VARIANT_SWEEP_LOG_RESULTS.csv`
- `outputs/MODEL1_ISLP_VARIANT_SWEEP_LOG_SUMMARY.csv`

Results versus previous robust best:

- Full 2024: `2507.85` versus `2507.85`
- Full 2025: `214.18` versus `214.18`
- 2026 YTD: `1375.04` versus `1375.04`
- Continuous 2024-2026: `7970.70` versus `7210.30`
- Losing broad validation windows: `0`

The higher-profit `risk045_tp150` variant reached `8112.91` on continuous validation, but reduced full 2024 from `2507.85` to `2209.66`, so it was not promoted.

## Model=1 Quarter Gate

Validation files:

- `outputs/MODEL1_SCORE7_QTR_LOG_RESULTS.csv`
- `outputs/MODEL1_SCORE7_QTR_LOG_SUMMARY.csv`

Quarter validation versus previous robust best:

- Quarter total: `3638.18` versus `3585.86`
- Worst quarter window: `-0.50` versus `-0.50`
- Losing quarter windows: `1` versus `1`
- Improved quarter: 2025 Q4 increased from `142.50` to `194.82`
- Damaged quarters: none

## Decision

Promote `CANDIDATE_PRIMARY_RANGE_ELITE_MFE_FAILURE_MARCH_ISLP_JUN_OCTDEC_SCORE7_PROFILE.set` as the current research-best profile.

This is still a research candidate, not a production guarantee. The next gate should stress spread, slippage, and tick model assumptions before increasing risk.
