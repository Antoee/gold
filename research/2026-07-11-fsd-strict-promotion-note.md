# FSD Strict Promotion Note

Date: 2026-07-11

## Decision

Promote `outputs/CANDIDATE_PRIMARY_AUG40_REVERSE_OFF_FSD_STRICT_MICRO_JULOCT_PROFILE.set` as the current research-best profile.

SHA-256:

```text
0E32FC5BC6558B969DF0F08B18EF5DBAEE3D5E65CD7FDC4E7F0E2F91C3FA7A40
```

This profile keeps Adaptive Reverse disabled and enables the new Flat Month Structural Displacement lane with conservative risk.

## What Changed

The EA now includes an optional `FSD` lane:

- Requires flat-month opportunity mode.
- Requires structural displacement via displacement BOS, BOS plus displacement, or range expansion.
- Requires sweep or retest confirmation.
- Requires order-flow confirmation.
- Requires forward liquidity clearance.
- Uses a structure-derived direct stop behind the signal candle.
- Uses low risk through `InpFlatMonthStructuralDisplacementRiskMultiplier`.
- Tags trades with `FSD;` for later attribution.

The lane is disabled by default. It is enabled only in the promoted `.set`.

## Model 2 Evidence

Source: `outputs/CURRENT_BEST_FSD_LANE_LOG_SUMMARY.csv`

- `base` continuous: `5805.71`
- `fsd_strict` continuous: `6125.57`
- Improvement: `319.86`
- 2026 YTD: unchanged at `1107.90`
- Full 2025: unchanged at `214.18`
- Full 2024: improved from `2360.86` to `2381.09`
- Losing windows: `0`

All tested FSD variants produced the same Model 2 summary. That suggests the lane only fired on a small number of high-filtered opportunities in this validation set.

## Model 0 Confirmation

Source: `outputs/CURRENT_BEST_FSD_LANE_MODEL0_LOG_SUMMARY.csv`

- `base` continuous: `5814.52`
- `fsd_strict` continuous: `6222.35`
- Improvement: `407.83`
- 2026 YTD: unchanged at `1107.93`
- Full 2025: unchanged at `214.30`
- Full 2024: improved from `2371.39` to `2390.20`
- Losing windows: `0`

This passed the first higher-fidelity confirmation gate.

## Caveat

This is a profit-quality improvement, not a complete flat-month fix yet.

The explicit flat windows in this batch remained inactive:

- 2025-01: `0`
- 2025-04: `0`
- 2025-06: `0`
- 2026-01: `0`

So the lane improved the full-period result without solving every dormant month. The next useful step is monthly attribution for the FSD gains, followed by a targeted second lane for still-dormant flat windows.

## Next Validation

- Run monthly attribution for 2024-2026 to locate the exact FSD contribution.
- Stress the promoted profile with real ticks, spread, and slippage.
- Keep Adaptive Reverse disabled unless a future reversal-specific strategy proves it adds robust OOS profit without whipsaw damage.
