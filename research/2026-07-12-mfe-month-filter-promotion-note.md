# MFE Month Filter Promotion Note

Date: 2026-07-12

## Purpose

The global MFE profit-lock stop improved the 2024-2026 continuous run, but damaged 2026 YTD because it cut March winners too early. This test added a default-off month filter for `InpUseMFEProfitLockStop` and validated whether a narrower MFE lock could preserve recent performance while keeping the continuous improvement.

## Code Change

Added default-off inputs:

- `InpUseMFEProfitLockMonthFilter`
- `InpMFEProfitLockTradeJanuary` through `InpMFEProfitLockTradeDecember`

Added helper:

- `MFEProfitLockMonthAllows()`

Applied the helper to the MFE profit-lock stop condition. Defaults preserve existing behavior.

## Evidence

Source:

- Summary: `outputs/CURRENT_BEST_MFE_MONTH_FILTER_MODEL0_LOG_SUMMARY.csv`
- Results: `outputs/CURRENT_BEST_MFE_MONTH_FILTER_MODEL0_LOG_RESULTS.csv`
- Builder: `work/build_current_best_mfe_month_filter_model0_package.ps1`
- Promoted set builder: `work/write_promoted_mfe_august_only_set.ps1`

Model 0 broad-window results:

| Profile | Continuous | YTD | Full 2025 | Full 2024 | Worst Window | Losing Windows |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| base | 6222.35 | 1107.93 | 214.30 | 2390.20 | 0.00 | 0 |
| mfe_august_only | 6633.61 | 1107.93 | 214.30 | 2406.27 | 0.00 | 0 |
| mfe_balanced_no_march | 6633.61 | 1107.93 | 214.30 | 2406.27 | 0.00 | 0 |
| mfe_loose_no_march | 6456.57 | 1107.93 | 214.30 | 2390.20 | 0.00 | 0 |

## Decision

Promote `mfe_august_only`.

This is the narrower of the two top-scoring profiles. It matches the `mfe_balanced_no_march` result while limiting the MFE profit-lock stop to the month where attribution showed benefit.

Promoted profile:

- `outputs/CANDIDATE_PRIMARY_AUG40_REVERSE_OFF_FSD_STRICT_MFE_AUGUST_ONLY_PROFILE.set`
- SHA-256: `DD3C357C4E830B17D744A310B57A83254467B92DB8CD94D90215B5BEA9C7C77E`

## Current Best

New research-best metrics:

- Continuous: `6633.61`
- 2026 YTD: `1107.93`
- Full 2025: `214.30`
- Full 2024: `2406.27`
- Losing windows: `0`

Local MT5 safety audit after testing: PASS 39/39.
