# ISLP Jun/Oct-Dec Promotion Note - 2026-07-12

## Summary

After promoting the In-Session Liquidity Pullback lane for October through December, a month-addition sweep tested January through September one at a time.

June was the only added month that improved the broad continuous validation while preserving the full 2025 and 2026 YTD results. The quarterly validation was neutral, meaning the June benefit appears through continuous-run equity path and later position sizing rather than a standalone quarterly profit bucket.

## Promoted Candidate

- Profile: `outputs/CANDIDATE_PRIMARY_RANGE_ELITE_MFE_FAILURE_MARCH_ISLP_JUN_OCTDEC_PROFILE.set`
- Builder: `work/build_current_best_mfe_failure_march_islp_jun_octdec_profile.ps1`
- SHA-256: `7DA01C9F084D81CE6852FE3AAD56E4AF6CA03A8B69A86569ADC4855374876E3F`

## Key Settings

- `InpUseInSessionLiquidityPullbackLane=true`
- `InpAllowInSessionLiquidityPullbackOutsideMonthFilter=true`
- `InpUseInSessionLiquidityPullbackMonthFilter=true`
- `InpISLPTradeJune=true`
- `InpISLPTradeOctober=true`
- `InpISLPTradeNovember=true`
- `InpISLPTradeDecember=true`

## Broad Validation

Validation files:

- `outputs/ISLP_ADD_MONTH_LOG_RESULTS.csv`
- `outputs/ISLP_ADD_MONTH_LOG_SUMMARY.csv`

Results versus previous current best:

- Full 2024: `3349.39` versus `3095.13`
- Full 2025: `214.18` versus `214.18`
- 2026 YTD: `1375.04` versus `1375.04`
- Continuous 2024-2026: `9512.09` versus `9065.41`
- Losing broad validation windows: `0`

Rejected month additions:

- January reduced full 2025 and continuous validation.
- February improved 2026 YTD but damaged 2024, 2025, and continuous validation.
- March, April, May, July, August, and September all reduced continuous validation.

## Quarter Validation

Validation files:

- `outputs/ISLP_JUN_QTR_LOG_RESULTS.csv`
- `outputs/ISLP_JUN_QTR_LOG_SUMMARY.csv`

Quarter validation was neutral:

- Quarter total: `3821.39` versus previous `3821.39`
- Worst quarter window: `0.00`
- Losing quarter windows: `0`

## Decision

Promote `CANDIDATE_PRIMARY_RANGE_ELITE_MFE_FAILURE_MARCH_ISLP_JUN_OCTDEC_PROFILE.set` as the current research-best profile.

This is a cautious promotion. The next gate should stress the continuous result with higher-fidelity tick/spread/slippage settings because the added June benefit appears in the continuous equity path rather than isolated quarter resets.
