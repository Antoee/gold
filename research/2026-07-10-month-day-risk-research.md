# 2026-07-10 Month-Day Filter and Risk Research

## Objective

Increase XAUUSD EA profit without accepting red validation windows. Focus was on the only active profitable months in the promoted candidate: March and May.

## Source Changes

- Added optional adaptive reverse behavior:
  - `InpAdaptiveReverseBlockOriginalOnGuard`
  - Default: `false`
  - Result: stricter blocking reduced broad profit, so it remains off.
- Added optional month-day entry window filter:
  - `InpUseMonthDayWindowFilter`
  - Per-month min/max day inputs.
  - Default: off.
- Added optional month-day risk multipliers:
  - `InpUseMonthDayRiskMultipliers`
  - Per-month day-window risk multiplier inputs.
  - Reuses per-month min/max day inputs.
  - Default: off / `1.00`.

## Validation Results

### Adaptive Reverse Guard Blocking

Artifact: `outputs/ADAPTIVE_REVERSE_BLOCK_ORIGINAL_BROAD_LOG_SUMMARY.csv`

- Legacy pass-through: `5029.72` total net, `0` losing broad windows.
- Block guarded original: `4298.53` total net, `0` losing broad windows.
- Decision: rejected for promotion.

### Active Month Segment Diagnostic

Artifact: `outputs/ACTIVE_MONTH_WINDOW_DIAGNOSTIC_LOG_RESULTS.csv`

Findings:

- March profits cluster early in the month, especially days 1-10.
- May days 21-end were negative in 2024, 2025, and 2026.
- This justified testing day filters and day risk boosts.

### Month-Day Entry Filter

Artifacts:

- `outputs/MONTH_DAY_WINDOW_MATRIX_BROAD_LOG_SUMMARY.csv`
- `outputs/MONTH_DAY_WINDOW_MATRIX_MONTHLY_SHORTLIST_LOG_SUMMARY.csv`

Best broad result:

- `mar10_may10`: `7909.84` total net, `0` losing broad windows.

Monthly validation:

- Baseline: `5555.87` total net, `0` losing monthly windows.
- `mar10_may10`: `3358.64` total net, `0` losing monthly windows.
- Decision: rejected for promotion.

### Month-Day Risk Multiplier

Artifacts:

- `outputs/MONTH_DAY_RISK_LADDER_BROAD_LOG_SUMMARY.csv`
- `outputs/MONTH_DAY_RISK_LADDER_MONTHLY_SHORTLIST_LOG_SUMMARY.csv`
- `outputs/MONTH_DAY_RISK_LADDER_MAYONLY_FINE_LOG_SUMMARY.csv`

Best broad results:

- `mar200_may110`: `8108.25` total net, `0` losing broad windows.
- `mar200`: `7821.41` total net, `0` losing broad windows.
- `may125`: `5787.86` total net, `0` losing broad windows.

Monthly validation:

- Baseline: `5555.87` total net, `0` losing monthly windows.
- `may125`: `5866.42` total net, but `1` losing monthly window (`2024_05 -232.68`).
- `mar200`: `4918.48` total net, `1` losing monthly window (`2025_03 -196.16`).
- `mar200_may110`: `4366.41` total net, `2` losing monthly windows.
- Decision: rejected for promotion.

## Current Best Candidate

Keep promoted candidate unchanged:

- `outputs/CANDIDATE_LIQUIDITY_STOP_CONFLICT_MARCH_MAY280_MAYCAP17_PROFILE.set`
- Monthly validation: `5555.87` total net, `0` losing monthly windows.
- Broad validation: `5029.72` total net, `0` losing broad windows.

## Notes

The new inputs are useful for future controlled experiments but should remain disabled in the promoted profile until a configuration passes monthly, broad, and out-of-sample validation without red windows.
