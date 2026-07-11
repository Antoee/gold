# Primary August Unlock Promotion Note

Date: 2026-07-11

## Decision

Promote `outputs/CANDIDATE_PRIMARY_AUG20_MICRO_JULOCT_PROFILE.set` as the current research-best candidate.

This keeps the existing March/May primary strategy and July/October standalone micro-reversion add-on, then unlocks the primary strategy in August at a low `0.20` month risk multiplier.

## Candidate

- Profile: `outputs/CANDIDATE_PRIMARY_AUG20_MICRO_JULOCT_PROFILE.set`
- SHA-256: `5E547B49656A688083D3F9B7896BB8D9652509F5A15C4D4FE913C45320134C96`
- Key delta:
  - `InpTradeAugust=true`
  - `InpAugustRiskMultiplier=0.20`
  - `InpUseMonthRiskMultipliers=true`

## Model 0 Broad Evidence

Source: `outputs/CURRENT_BEST_PRIMARY_AUG20_MODEL0_LOG_SUMMARY.csv`

| Profile | Continuous | YTD | Full 2025 | Full 2024 | Worst Window | Losing Windows |
|---|---:|---:|---:|---:|---:|---:|
| `primary_aug20` | 5340.46 | 1107.93 | 214.30 | 2179.44 | 0 | 0 |
| `base_current_best` | 4061.66 | 1107.93 | 214.30 | 1505.93 | 0 | 0 |

Broad attribution:

- Continuous: `+1278.80`
- Full 2024: `+673.51`
- 2025 August/September target window: `+38.14`
- 2024 August/September target window: `+57.67`
- 2026 YTD: unchanged
- 2026 June guard: unchanged at `0`

## Monthly Attribution

Source: `outputs/CURRENT_BEST_PRIMARY_AUG20_MONTHLY_ATTRIBUTION.csv`

Only August changed in isolated monthly tests:

| Window | Base | Candidate | Delta |
|---|---:|---:|---:|
| 2024_08 | 0.00 | 57.67 | +57.67 |
| 2025_08 | 0.00 | 38.14 | +38.14 |

Monthly isolated total improved from `3472.25` to `3568.06`, with `0` losing monthly windows.

## Rejected Neighbor

The standalone micro-reversion Aug/Sep extension was rejected.

Source: `outputs/MICRO_AUGSEP_MODEL2_LOG_SUMMARY.csv`

- `micro_dedicated_aug_sep_jul_oct` had `1` losing window and underperformed the July/October-only micro candidate.
- `micro_dedicated_aug_sep` had `2` losing windows.
- `micro_dedicated_sep_jul_oct` was identical to July/October only, so September added no trades.

## Status

This is a research-best candidate, not a final production profile. Next validation gate:

- Spread/slippage stress
- Higher-fidelity walk-forward windows
- Forward unseen August validation when new data exists
