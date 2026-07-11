# 2026-07-11 Micro Dedicated July/October Promotion Note

## Candidate

`outputs/CANDIDATE_MICRO_DEDICATED_JULOCT_PROFILE.set`

This candidate keeps the March/May core and adds a standalone micro-reversion lane only in July and October:

- `InpUseFlatMonthOpportunityMode=false`
- `InpFlatMonthMicroReversionStandaloneActive=true`
- `InpUseFlatMonthMicroReversionMonthFilter=true`
- July and October only for `InpFlatMicroRevTrade*`

## Broad Validation

Model 0 broad screen:

| Profile | Continuous | YTD | Full2025 | Full2024 | WorstWindow | LosingWindows |
|---|---:|---:|---:|---:|---:|---:|
| micro_dedicated_jul_oct | 4061.66 | 1107.93 | 214.30 | 1505.93 | 0.00 | 0 |
| base_mar10_may10 | 3746.45 | 1107.93 | 214.30 | 1409.57 | 0.00 | 0 |

Model 2 sanity check:

| Profile | Continuous | YTD | Full2025 | Full2024 | WorstWindow | LosingWindows |
|---|---:|---:|---:|---:|---:|---:|
| micro_dedicated_jul_oct | 4073.38 | 1107.90 | 214.18 | 1493.71 | 0.00 | 0 |
| base_mar10_may10 | 3697.15 | 1107.90 | 214.18 | 1394.72 | 0.00 | 0 |

Note: Model 2 is a fast sanity check, not stricter proof. The important result is that it did not contradict the Model 0 broad improvement.

## Monthly Attribution

Monthly attribution confirms the candidate only changes July and October:

| Window | Base | Candidate | Delta |
|---|---:|---:|---:|
| 2024_07 | 0.00 | 30.36 | 30.36 |
| 2024_10 | 0.00 | 27.50 | 27.50 |
| 2025_07 | 0.00 | 27.95 | 27.95 |
| 2025_10 | 0.00 | 27.80 | 27.80 |

All other monthly windows were unchanged in the attribution package.

Monthly totals:

| Profile | Parsed | TotalNet | WorstWindow | LosingWindows |
|---|---:|---:|---:|---:|
| micro_dedicated_jul_oct | 30 | 3472.25 | 0.00 | 0 |
| base_mar10_may10 | 30 | 3358.64 | 0.00 | 0 |

## Decision

Promote as current research-best candidate over `base_mar10_may10`, because it:

- improves continuous broad profit by `+315.21` in Model 0
- preserves 2026 YTD
- preserves 2025
- improves 2024
- adds no losing monthly windows in attribution
- only changes the intended July/October flat-month behavior

Still not final production-grade. Next gate should be higher-fidelity validation with more realistic tick modeling, spread/slippage stress, and walk-forward windows.