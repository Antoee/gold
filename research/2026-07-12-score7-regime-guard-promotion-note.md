# Score7 Regime Guard Promotion Note - 2026-07-12

## Summary

The Score7 profile was stress-tested with stricter spread and trading-cost controls. Most variants blocked too much opportunity or damaged validation windows. The survivor was `regime_m1_strict`, which enables spread-regime and M1 spread-shock guards without changing risk, targets, active months, or ISLP score.

## Promoted Candidate

- Profile: `outputs/CANDIDATE_PRIMARY_RANGE_ELITE_MFE_FAILURE_MARCH_ISLP_JUN_OCTDEC_SCORE7_REGIME_PROFILE.set`
- Builder: `work/build_current_best_mfe_failure_march_islp_jun_octdec_score7_regime_profile.ps1`
- SHA-256: `7BD4019104BCDF117A7D729289D6821D5F4BF6FB6FF9FE2D543BCF91717DC204`

## Key Setting Changes

- `InpUseSpreadRegimeGuard=true`
- `InpSpreadRegimeLookbackBars=24`
- `InpMaxSpreadRegimeRatio=1.35`
- `InpMinSpreadRegimePoints=30.0`
- `InpUseM1SpreadShockGuard=true`
- `InpM1SpreadShockLookbackBars=30`
- `InpM1SpreadShockMaxRatio=1.60`
- `InpM1SpreadShockMinPoints=35.0`

## Model=1 Broad/Stress Validation

Validation files:

- `outputs/MODEL1_SCORE7_COST_STRESS_LOG_RESULTS.csv`
- `outputs/MODEL1_SCORE7_COST_STRESS_LOG_SUMMARY.csv`

Results versus previous Score7 best:

- Continuous 2024-2026: `9753.58` versus `7970.70`
- Full 2024: `3201.96` versus `2507.85`
- Full 2025: `214.18` versus `214.18`
- 2026 YTD: `1375.04` versus `1375.04`
- 2025 Q4: `194.82` versus `194.82`
- 2024 Q4: `-0.50` versus `-0.50`

Rejected stress variants:

- `cap150_atr12` blocked too much 2024 opportunity and reduced continuous validation to `-2.62`.
- `spread_risk_scale` reduced continuous validation to `1711.63`.
- `combined_cost_guard` reduced continuous validation to `64.91` and made full 2025 negative at `-10.02`.

## Model=1 Quarter Gate

Validation files:

- `outputs/MODEL1_SCORE7_REGIME_QTR_LOG_RESULTS.csv`
- `outputs/MODEL1_SCORE7_REGIME_QTR_LOG_SUMMARY.csv`

Quarter validation was neutral:

- Quarter total: `3638.18` versus `3638.18`
- Worst quarter: `-0.50` versus `-0.50`
- Losing quarters: `1` versus `1`
- Damaged quarters: none

## Decision

Promote `CANDIDATE_PRIMARY_RANGE_ELITE_MFE_FAILURE_MARCH_ISLP_JUN_OCTDEC_SCORE7_REGIME_PROFILE.set` as the current research-best profile.

This remains a research profile, not a production guarantee. Its edge appears in the continuous equity path rather than quarter-reset windows, so the next gate should retest continuous performance under another model/source and then examine trade-level reasons.
