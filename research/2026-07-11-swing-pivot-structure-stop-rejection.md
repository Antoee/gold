# Swing Pivot Structure Stop Rejection

## Purpose

Tested a confirmed swing-pivot stop default on top of the current research-best `aug_risk040` profile. This was intended to move beyond pure ATR stops by tightening stops around recent confirmed structure.

## Implementation Finding

The swing-pivot controls were originally plain globals rather than MT5 `input` parameters, so `.set` files could not tune them. Temporarily converting all nine controls to inputs exceeded MT5 Strategy Tester's input-parameter limit. The experiment was therefore run as a code-default test using the compact tester source.

## Result

- Evidence: `outputs/CURRENT_BEST_SWING_DEFAULT_MODEL2_LOG_SUMMARY.csv`
- Compile proof: `outputs/SWING_DEFAULT_COMPACT_COMPILE.log`
- Compact audit: `outputs/SWING_DEFAULT_TESTER_COMPACT_SOURCE_AUDIT.csv`

Compared with the current Model 2 `aug_risk040` baseline:

- Baseline continuous: `5805.71`
- Swing-pivot continuous: `5773.88`
- Baseline 2026 YTD: `1107.90`
- Swing-pivot 2026 YTD: `676.10`
- Losing windows: `0`

## Decision

Reject the swing-pivot default. It did not add losing windows, but it reduced recent performance too much. The EA was restored to the current-best compact build after the test.
