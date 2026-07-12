# PTC Month Filter Rejection Note

Date: 2026-07-11

## Decision

Do not promote Power Trend Continuation.

The current research-best remains:

```text
outputs/CANDIDATE_PRIMARY_AUG40_REVERSE_OFF_FSD_STRICT_MICRO_JULOCT_PROFILE.set
```

## Code Change

Added a lane-specific month filter for Power Trend Continuation:

```text
InpUsePowerTrendContinuationMonthFilter
InpPowerTrendTradeJanuary ... InpPowerTrendTradeDecember
```

Defaults preserve prior behavior because the filter is disabled unless explicitly enabled.

## Evidence

Source: `outputs/CURRENT_BEST_PTC_MONTH_FILTER_MODEL0_PROBE_LOG_SUMMARY.csv`

| Profile | Parsed | Total Net | Continuous | 2026 YTD | Full 2025 | Full 2024 | Worst Window | Losing Windows |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `ptc_apr_nov` | `12 / 12` | `9294.75` | `6453.26` | `49.99` | `214.30` | `2579.60` | `-24.90` | `3` |
| `base` | `12 / 12` | `9962.58` | `6222.35` | `1107.93` | `214.30` | `2390.20` | `0.00` | `0` |
| `ptc_jul_aug_nov` | `12 / 12` | `8041.52` | `5127.63` | `49.99` | `214.30` | `2675.88` | `-24.90` | `3` |
| `ptc_nov_only` | `12 / 12` | `7640.53` | `4822.92` | `49.99` | `214.30` | `2579.60` | `-24.90` | `3` |
| `ptc_nov_micro_nohouse` | `12 / 12` | `7501.84` | `4801.84` | `49.99` | `214.30` | `2484.90` | `-24.90` | `3` |

These profiles still damaged 2026 YTD. The issue was not month selection alone.

Source: `outputs/CURRENT_BEST_PTC_NO_BCQ_MONTH_FILTER_MODEL0_PROBE_LOG_SUMMARY.csv`

| Profile | Parsed | Total Net | Continuous | 2026 YTD | Full 2025 | Full 2024 | Worst Window | Losing Windows |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `base` | `12 / 12` | `9962.58` | `6222.35` | `1107.93` | `214.30` | `2390.20` | `0.00` | `0` |
| `ptc_apr_nov_no_bcq` | `12 / 12` | `9962.58` | `6222.35` | `1107.93` | `214.30` | `2390.20` | `0.00` | `0` |
| `ptc_nov_no_bcq` | `12 / 12` | `9962.58` | `6222.35` | `1107.93` | `214.30` | `2390.20` | `0.00` | `0` |

When Breakout Continuation confirmation was disabled, seasonal PTC preserved robustness but added no trades or profit.

## Interpretation

The previous PTC gain was caused by the broader BCQ/PTC interaction, not by a clean isolated PTC edge. Enabling that interaction damaged recent robustness. Disabling the interaction removed both the damage and the gain.

The PTC month filter remains useful infrastructure, but no PTC profile is promotable from this evidence.
