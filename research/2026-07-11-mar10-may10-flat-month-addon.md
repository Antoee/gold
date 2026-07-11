# 2026-07-11 Mar10/May10 Flat-Month Add-On Test

Base candidate:

- `outputs\CANDIDATE_MAR10_MAY10_CONTINUOUS_PROFILE.set`
- Current-source baseline broad result: Continuous `3746.45`, YTD `1107.93`, Full2025 `214.30`, Full2024 `1409.57`, WorstWindow `0`, LosingWindows `0`.

Test:

- Built `work\local_mt5_mar10_may10_flat_month_addon_package` with controlled low-risk outside-month lanes.
- Compile: `outputs\MAR10_MAY10_FLAT_ADDON_COMPILE.log`, `0 errors, 0 warnings`.
- Results: `outputs\MAR10_MAY10_FLAT_ADDON_LOG_SUMMARY.csv`.

Summary:

| Profile | TotalNet | Continuous | YTD | Full2025 | Full2024 | WorstWindow | LosingWindows | Decision |
|---|---:|---:|---:|---:|---:|---:|---:|---|
| base_mar10_may10 | 7909.84 | 3746.45 | 1107.93 | 214.30 | 1409.57 | 0.00 | 0 | Keep |
| outside_lowrisk_gate | 5221.61 | 2879.16 | 116.33 | 214.30 | 1409.57 | 0.00 | 0 | Reject: lower continuous/YTD |
| outside_micro_rev | 5221.61 | 2879.16 | 116.33 | 214.30 | 1409.57 | 0.00 | 0 | Reject: lower continuous/YTD |
| outside_breakout | 5221.61 | 2879.16 | 116.33 | 214.30 | 1409.57 | 0.00 | 0 | Reject: lower continuous/YTD |
| outside_combo_strict | 5221.61 | 2879.16 | 116.33 | 214.30 | 1409.57 | 0.00 | 0 | Reject: lower continuous/YTD |
| outside_session_impulse | 884.64 | -24.12 | 116.33 | 214.30 | -24.12 | -24.12 | 2 | Reject: losing windows |

Conclusion:

The tested flat-month add-ons did not improve the promoted continuous candidate. The stricter outside-month lanes appear to reduce 2026 YTD and continuous full-period profit, while session impulse introduces losses. No promotion.

Next direction:

- Avoid generic outside-month bypasses on this profile.
- Focus next on improving the existing March/May edge, or on isolated month-specific add-ons that are validated month-by-month before broad integration.
