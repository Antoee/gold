# Continuation Validation - Seasonal, Adaptive Reverse, and Profit Protection

Date: 2026-07-09

This note continues the XAUUSD MT5 research after the earlier validation summary. Local source artifacts were synced after adding an optional month-of-year entry filter.

## Source checks

- `test_price_action_strategy_modules.ps1`: PASS
- `test_price_action_strategy_batch.ps1`: PASS
- `sync_ea_source_artifacts.ps1`: PASS
- Synced canonical source hash: `C03F27C4334BCA80B2B789D01AB47A33377FE16E8321A64179CCB5A0CC93EA06`

## Code change

Added optional month-of-year trading controls, default-off:

- `InpUseMonthFilter`
- `InpTradeJanuary` through `InpTradeDecember`

The filter is checked before opening a signal and records `month filter` as the last block reason when active.

## Seasonal validation

Goal: test whether replacing the exact 2026 Q1 date block with a broader seasonal Q1-off rule improves robustness.

| Profile | 2024-2026 Continuous | 2026 YTD | 2025 Full | 2024 Full | Jan | Feb | Mar | Apr | May | Jun | MinNet |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| base | 988.67 | -233.94 | 466.62 | 87.19 | -44.63 | -60.66 | -85.40 | 234.34 | -93.86 | -70.90 | -233.94 |
| month_q1_off | -419.19 | 45.85 | -107.54 | -244.77 | 0.00 | 0.00 | 0.00 | 234.34 | -93.86 | -70.90 | -419.19 |
| month_q1_off_peak15 | -419.19 | 247.29 | 183.21 | -244.77 | 0.00 | 0.00 | 0.00 | 247.29 | -93.86 | -70.90 | -419.19 |
| month_apr_only_peak15 | -119.35 | 247.29 | -99.88 | -41.76 | 0.00 | 0.00 | 0.00 | 247.29 | 0.00 | 0.00 | -119.35 |

Conclusion: the month filter is useful as a research control but should not be promoted. Q1-off improves 2026 YTD but damages the full 2024-2026 validation badly.

## Adaptive Reverse validation

Goal: test whether disabling or tightening Adaptive Reverse fixes the 2026 losses.

| Profile | 2024-2026 Continuous | 2026 YTD | 2025 Full | 2024 Full | Jan | Feb | Mar | Apr | May | Jun | MinNet |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| base | 988.67 | -233.94 | 466.62 | 87.19 | -44.63 | -60.66 | -85.40 | 234.34 | -93.86 | -70.90 | -233.94 |
| no_adaptive_reverse | 988.67 | -233.94 | 466.62 | 87.19 | -44.63 | -60.66 | -85.40 | 234.34 | -93.86 | -70.90 | -233.94 |
| strict_reverse_guard | 988.67 | -233.94 | 466.62 | 87.19 | -44.63 | -60.66 | -85.40 | 234.34 | -93.86 | -70.90 | -233.94 |
| liquidity_clear_reverse | 988.67 | -233.94 | 466.62 | 87.19 | -44.63 | -60.66 | -85.40 | 234.34 | -93.86 | -70.90 | -233.94 |
| no_reverse_peak15 | 319.83 | 42.50 | 175.52 | 319.83 | 42.50 | 80.95 | -85.40 | 247.29 | -93.86 | -70.90 | -93.86 |

Conclusion: in the fallback lane being tested, Adaptive Reverse is not the source of the bad 2026 YTD behavior. Turning it off or tightening reverse guards produced identical results until account-level profit protection was added.

## Base profit protection validation

Goal: test whether account-level profit protection alone can turn 2026 YTD positive without date/month filters.

| Profile | 2024-2026 Continuous | 2026 YTD | 2025 Full | 2024 Full | Jan | Feb | Mar | Apr | May | Jun | MinNet |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| base | 988.67 | -233.94 | 466.62 | 87.19 | -44.63 | -60.66 | -85.40 | 234.34 | -93.86 | -70.90 | -233.94 |
| base_peak15 | 319.83 | 42.50 | 175.52 | 319.83 | 42.50 | 80.95 | -85.40 | 247.29 | -93.86 | -70.90 | -93.86 |
| base_peak25 | 287.07 | 42.50 | 175.52 | 287.07 | 42.50 | 80.95 | -85.40 | 231.08 | -93.86 | -70.90 | -93.86 |
| base_lock75 | 287.07 | 42.50 | 175.52 | 287.07 | 42.50 | 80.95 | -85.40 | 231.08 | -93.86 | -70.90 | -93.86 |

Conclusion: `base_peak15` is the best risk-first candidate from this continuation. It turns 2026 YTD positive and improves 2024 full, but gives up much of the strongest continuous 2024-2026 profit and still has losing March, May, and June slices.

## Status

The 2-3% per month objective is still not proven. The best current candidate is not robust enough for final promotion because monthly losses remain and the profit-protection tradeoff is substantial.
