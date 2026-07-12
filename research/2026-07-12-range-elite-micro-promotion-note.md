# 2026-07-12 Range Elite Micro Promotion

## Decision

Promote `range_elite_micro` as the current research-best profile.

This is a small improvement, not a high-profit breakthrough. It passes the current promotion gate because it improves the continuous and 2024 validation windows while preserving recent/YTD behavior and keeping zero losing validation windows.

## Promoted Profile

`outputs/CANDIDATE_PRIMARY_AUG40_REVERSE_OFF_FSD_STRICT_MFE_AUGUST_ONLY_MICRO_R035_RANGE_ELITE_PROFILE.set`

SHA-256:

`AD6C1D1607BD7809FFBBB25DD068A1AB18E4EE2FBC879114F6A02DBCA06D1894`

## Evidence

Validation summary:

`outputs/CURRENT_BEST_SESSION_RANGE_VALIDATION_MODEL0_LOG_SUMMARY.csv`

| Profile | Continuous | 2026 YTD | Full 2025 | Full 2024 | Worst Window | Losing Windows |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| range_elite_micro | 6763.86 | 1107.93 | 214.30 | 2473.48 | 0.00 | 0 |
| base_micro_r035 | 6754.43 | 1107.93 | 214.30 | 2465.45 | 0.00 | 0 |

Per-window improvement came from 2024 H2/Q3/Q4. The profile did not improve 2025 or 2026 YTD, but also did not damage them.

## Enabled Range Settings

- `InpUseRangeReversionOpportunity=true`
- `InpRangeReversionMinScore=9`
- `InpWeightRangeReversionOpportunity=2`
- `InpRangeReversionStandaloneEntry=true`
- `InpRangeReversionMaxADX=20.0`
- `InpRangeReversionMinWickPercent=42.0`
- `InpRangeReversionMinCloseLocation=0.66`
- `InpRangeReversionMinRangeATR=0.42`
- `InpRangeReversionRequireVWAPMagnet=true`
- `InpRangeReversionMaxVWAPDistanceATR=1.05`
- `InpRangeReversionRequireOrderFlow=true`
- `InpRangeReversionUseStructuralStop=true`
- `InpRangeReversionStopBufferATR=0.08`
- `InpRangeReversionStopBufferPoints=18.0`
- `InpRangeReversionUseMeanTarget=true`
- `InpRangeReversionFallbackTPATR=0.85`
- `InpRangeReversionMinRR=0.85`
- `InpRangeReversionUseCustomEliteGate=true`
- `InpRangeReversionEliteMinConfirmations=3`
- `InpRangeReversionEliteMinQualityScore=7`

## Rejected In Same Batch

Session impulse variants were rejected because they reduced the continuous result and 2024 full-year result despite preserving 2025 and 2026 YTD:

- `session_strict_micro`: continuous `4167.44`, full 2024 `1492.57`
- `session_no_of_micro`: continuous `4262.63`, full 2024 `1461.54`

## Next Work

The current bottleneck is still profit magnitude. Next probes should target additive opportunities that improve 2025 and 2026 YTD, not only 2024. Promotion should continue to require:

- Continuous result above `6763.86`
- 2026 YTD at or above `1107.93`
- Full 2025 at or above `214.30`
- Full 2024 at or above `2473.48`
- Zero losing validation windows
