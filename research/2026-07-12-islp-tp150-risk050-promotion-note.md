# ISLP TP150 Risk050 Promotion Note - 2026-07-12

## Summary

After promoting ISLP for June, October, November, and December, a risk/target sweep tested whether the lane could be scaled without damaging broad validation safety.

Simple risk increases were rejected because they reduced continuous validation. The promoted variant keeps the same month filter and raises the ISLP risk multiplier from `0.40` to `0.50`, while also expanding the ISLP take-profit distance from `1.35 ATR` to `1.50 ATR` and the minimum RR from `0.85` to `0.90`.

## Promoted Candidate

- Profile: `outputs/CANDIDATE_PRIMARY_RANGE_ELITE_MFE_FAILURE_MARCH_ISLP_JUN_OCTDEC_TP150_RISK050_PROFILE.set`
- Builder: `work/build_current_best_mfe_failure_march_islp_jun_octdec_tp150_risk050_profile.ps1`
- SHA-256: `E0411FF8D997E32856A728BCE81588A812239F7FC7FD21A235CC890E2D21B2A5`

## Key Settings

- `InpInSessionLiquidityPullbackRiskMultiplier=0.50`
- `InpInSessionLiquidityPullbackTakeProfitATR=1.50`
- `InpInSessionLiquidityPullbackMinRR=0.90`
- ISLP remains month-filtered to June, October, November, and December.

## Broad Validation

Validation files:

- `outputs/ISLP_RISK_TARGET_LOG_RESULTS.csv`
- `outputs/ISLP_RISK_TARGET_LOG_SUMMARY.csv`

Results versus previous current best:

- Full 2024: `3048.13` versus `3349.39`
- Full 2025: `214.18` versus `214.18`
- 2026 YTD: `1375.04` versus `1375.04`
- Continuous 2024-2026: `10687.20` versus `9512.09`
- Losing broad validation windows: `0`

The full-year 2024 reset window is lower, so this is not a universal improvement. It is promoted because the continuous validation and quarter validation both improve while all broad windows remain profitable.

## Quarter Validation

Validation files:

- `outputs/ISLP_RISK_TARGET_QTR_LOG_RESULTS.csv`
- `outputs/ISLP_RISK_TARGET_QTR_LOG_SUMMARY.csv`

Quarter improvements versus previous current best:

- 2024 Q4: `250.97` versus `235.03`
- 2025 Q2: `81.36` versus `0.00`
- 2025 Q4: `194.65` versus `142.50`
- Quarter total: `3970.84` versus `3821.39`
- Losing quarter windows: `0`

## Rejected Variants

- Pure ISLP risk increases to `0.50`, `0.60`, `0.75`, and `1.00` reduced continuous validation.
- `tp165_risk050` improved continuous but less than `tp150_risk050`.
- `pull075_risk050` improved continuous and quarter total, but less than `tp150_risk050`.
- `score7_risk060` severely reduced continuous validation.

## Decision

Promote `CANDIDATE_PRIMARY_RANGE_ELITE_MFE_FAILURE_MARCH_ISLP_JUN_OCTDEC_TP150_RISK050_PROFILE.set` as the current research-best profile.

The next gate should use higher-fidelity tick/spread/slippage stress testing because this remains a fast-model research candidate.
