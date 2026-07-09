# Exit Management and Liquidity Stop Validation

Date: 2026-07-09

This continuation tested whether the fallback lane can improve March/May/June weakness using trade management and structural/liquidity stops instead of date or month filters.

## Source checks

- `test_price_action_strategy_modules.ps1`: PASS
- `test_price_action_strategy_batch.ps1`: PASS
- `sync_ea_source_artifacts.ps1`: PASS
- Synced source hash: `C03F27C4334BCA80B2B789D01AB47A33377FE16E8321A64179CCB5A0CC93EA06`

## Exit management matrix

All results are net profit on a $1,000 test deposit.

| Profile | 2024-2026 Continuous | 2026 YTD | 2025 Full | 2024 Full | Mar 2026 | Apr 2026 | May 2026 | Jun 2026 | MinNet |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| base | 988.67 | -233.94 | 466.62 | 87.19 | -85.40 | 234.34 | -93.86 | -70.90 | -233.94 |
| peak15 | 319.83 | 42.50 | 175.52 | 319.83 | -85.40 | 247.29 | -93.86 | -70.90 | -93.86 |
| peak15_structure_trail | 323.33 | 22.18 | 191.91 | 323.33 | -85.40 | 258.27 | -89.44 | -64.50 | -89.44 |
| peak15_liquidity_stop | 786.27 | 84.72 | 124.51 | 786.27 | -84.88 | 192.20 | -99.55 | -70.90 | -99.55 |

Conclusion: `peak15_liquidity_stop` is the strongest current candidate for the structural-stop requirement. It preserves much more continuous 2024-2026 profit than peak-trail alone and turns 2026 YTD positive without date or month filters.

## Focused liquidity-stop verification

| Profile | 2024-2026 Continuous | 2026 YTD | 2025 Full | 2024 Full | Jan | Feb | Mar | Apr | May | Jun | MinNet |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| base | 988.67 | -233.94 | 466.62 | 87.19 | -44.63 | -60.66 | -85.40 | 234.34 | -93.86 | -70.90 | -233.94 |
| peak15 | 319.83 | 42.50 | 175.52 | 319.83 | 42.50 | 80.95 | -85.40 | 247.29 | -93.86 | -70.90 | -93.86 |
| peak15_structure_trail | 323.33 | 22.18 | 191.91 | 323.33 | -60.08 | 130.96 | -85.40 | 258.27 | -89.44 | -64.50 | -89.44 |
| peak15_liquidity_stop | 786.27 | 84.72 | 124.51 | 786.27 | 84.72 | 78.78 | -84.88 | 192.20 | -99.55 | -70.90 | -99.55 |

## Liquidity-stop tuning

The tuning pass tested tighter/wider buffers, previous-day/week levels, equal-only and sweep-only levels, cluster extension, and liquidity-pocket shifts.

| Profile | 2024-2026 Continuous | 2026 YTD | 2025 Full | 2024 Full | Mar | Apr | May | Jun | MinNet |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| liq_base | 786.27 | 84.72 | 124.51 | 786.27 | -84.88 | 192.20 | -99.55 | -70.90 | -99.55 |
| liq_equal_only | 785.30 | 84.72 | 140.37 | 785.30 | -84.88 | 192.20 | -93.86 | -70.90 | -93.86 |
| liq_wider | 495.93 | 87.04 | 184.78 | 495.93 | -84.88 | 189.69 | -92.25 | -70.90 | -92.25 |
| liq_tighter | 213.61 | 118.40 | 139.59 | 213.61 | -97.00 | 214.83 | -96.96 | -70.90 | -97.00 |
| liq_prev_day | -428.22 | -301.53 | -180.97 | -120.73 | -84.88 | -97.20 | 35.67 | -89.81 | -428.22 |

Conclusion: the default verified liquidity-stop settings remain best overall. Previous-day/week stop levels were harmful in this configuration.

## Current best candidate

`peak15_liquidity_stop`:

- Uses account-level equity peak trail (`15%` giveback after `3%` peak profit).
- Enables liquidity-aware structure stops.
- Turns 2026 YTD positive without exact-date or month filters.
- Strongly improves 2024 full and continuous 2024-2026 compared with peak-trail alone.

Remaining issue: monthly consistency is not solved. March, May, and June 2026 remain negative, so the full 2-3% per month objective is still unproven.
