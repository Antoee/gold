# ISLP Oct-Dec Promotion Note - 2026-07-12

## Summary

The In-Session Liquidity Pullback lane was added as a tightly gated price-action expansion path for otherwise quiet months. Broad all-month versions were rejected because they reduced 2026 YTD performance.

The promoted candidate enables the lane only in October, November, and December, with low risk and required liquidity confirmation. It keeps Adaptive Reverse disabled and leaves the existing MFE Failure March exit intact.

## Promoted Candidate

- Profile: `outputs/CANDIDATE_PRIMARY_RANGE_ELITE_MFE_FAILURE_MARCH_ISLP_OCTDEC_PROFILE.set`
- Builder: `work/build_current_best_mfe_failure_march_islp_octdec_profile.ps1`
- SHA-256: `6C34F17F3AF0741A4C9FAFAD86485576E618EB1EC41F6210198B906A2A6BD2B1`

## Key Settings

- `InpUseInSessionLiquidityPullbackLane=true`
- `InpAllowInSessionLiquidityPullbackOutsideMonthFilter=true`
- `InpUseInSessionLiquidityPullbackMonthFilter=true`
- `InpISLPTradeOctober=true`
- `InpISLPTradeNovember=true`
- `InpISLPTradeDecember=true`
- All other `InpISLPTrade*` month toggles are `false`.
- `InpInSessionLiquidityPullbackRiskMultiplier=0.40`
- `InpInSessionLiquidityPullbackMinScore=6`
- `InpInSessionLiquidityPullbackRequireLiquidSession=true`
- `InpInSessionLiquidityPullbackRequireLiquidity=true`
- `InpInSessionLiquidityPullbackRequireMTFAlignment=false`
- `InpInSessionLiquidityPullbackRequireOrderFlow=false`
- `InpInSessionLiquidityPullbackMinRR=0.85`

## Exact Current-Best Comparison

Validation files:

- `outputs/ISLP_EXACT_LOG_RESULTS.csv`
- `outputs/ISLP_EXACT_LOG_SUMMARY.csv`

Results versus the previous current-best profile:

- Full 2024: `3095.13` versus `2459.19`
- Full 2025: `214.18` versus `214.18`
- 2026 YTD: `1375.04` versus `1375.04`
- Continuous 2024-2026: `9065.41` versus `7756.74`
- Losing broad validation windows: `0`

## Quarter Validation

Validation files:

- `outputs/ISLP_QTR_LOG_RESULTS.csv`
- `outputs/ISLP_QTR_LOG_SUMMARY.csv`

Quarter results:

- 2024 Q1: `1482.99`
- 2024 Q2: `209.80`
- 2024 Q3: `12.04`
- 2024 Q4: `235.03` versus previous `46.75`
- 2025 Q1: `214.18`
- 2025 Q2: `0.00`
- 2025 Q3: `20.87`
- 2025 Q4: `142.50` versus previous `41.25`
- 2026 Q1: `1018.27`
- 2026 Q2: `485.71`
- 2026 Jul-to-date: `0.00`
- Losing quarter windows: `0`

## Decision

Promote `CANDIDATE_PRIMARY_RANGE_ELITE_MFE_FAILURE_MARCH_ISLP_OCTDEC_PROFILE.set` as the current research-best profile.

This remains a research candidate, not a live-money production profile. The next validation gate should use higher-fidelity tick/spread/slippage stress testing and exported MT5 reports once the report-export issue is resolved.
