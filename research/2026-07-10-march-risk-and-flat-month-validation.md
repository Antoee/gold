# 2026-07-10 March Risk and Flat-Month Validation

## Current stable candidate

Stable profile remains `CANDIDATE_SEASONAL_MAR1_MAY225_PROFILE`.

- March risk multiplier: `1.00`
- May risk multiplier: `2.25`
- Month gate: March and May only
- Broad real-tick validation: `TotalNet=3451.27`, `Continuous=1277.57`, `YTD=158.91`, `WorstWindow=0`, `LosingWindows=0`
- Monthly real-tick validation: `Total=2739.91`, `Green=6`, `Flat=24`, `Red=0`

## Flat-month probe validation

Filtered breakout probe profile:

- Enabled flat probe bypass outside the month filter.
- Disabled September and December for probe bypass after those months showed small losses.
- Monthly real-tick: `Total=2861.30`, `Green=6`, `Flat=24`, `Red=0`
- Broad real-tick: identical to current stable candidate: `TotalNet=3451.27`, `Continuous=1277.57`, `YTD=158.91`, `WorstWindow=0`

Decision: do not promote as a true improvement. The monthly reset score improves slightly, but continuous broad validation is unchanged and the profile does not solve flat-month inactivity.

## Guard and stop matrix

Tested stricter Adaptive Reverse whipsaw guards, follow-through reverse confirmation, confirmed swing-pivot stops, and deeper liquidity stops.

- Reverse guard variants: no material trade-set change versus baseline.
- Swing-pivot stop variants: no material trade-set change versus baseline.
- Deep liquidity stop variants: rejected; broad fast screen produced `TotalNet=-433`, `Continuous=-231.31`, `LosingWindows=5`.

Decision: keep existing stop profile. Do not enable deep liquidity stops.

## Extra month expansion

Tested adding February, July, and December to the current March/May profile.

- `feb_mar_may`: red months in 2025-02 and 2026-02.
- `mar_may_jul`: red month in 2025-07.
- `mar_may_dec`: red month in 2025-12.
- Guarded low-risk extra-month profile: `Total=2108.23`, `Red=5`.

Decision: reject month expansion. The added activity does not preserve the zero-red-month safety profile.

## March risk ladder

Fast monthly ladder with May fixed at `2.25`:

- `mar2p00_may2p25`: `Total=3200.02`, `Green=6`, `Flat=24`, `Red=0`
- `mar1p90_may2p25`: red in 2025-03
- `mar2p10_may2p25`: red in 2024-03
- `mar2p25_may2p25`: red in 2024-03
- `mar2p50_may2p25`: red in 2024-03
- `mar3p00_may2p25`: red in 2024-03

Real-tick monthly confirmation for `mar2p00_may2p25`:

- `Total=3186.66`
- `Green=6`
- `Flat=24`
- `Red=0`
- Non-zero windows: 2024-03 `667.17`, 2024-05 `45.92`, 2025-03 `235.22`, 2025-05 `679.20`, 2026-03 `1195.14`, 2026-05 `364.01`

Broad real-tick validation for `mar2p00_may2p25`:

- `TotalNet=4323.85`
- `Continuous=667.17`
- `YTD=1195.14`
- `Full2025=235.22`
- `Full2024=667.17`
- `WeakSum=1559.15`
- `WorstWindow=0`
- `LosingWindows=0`

Decision: save as a recent/aggressive candidate, not as the main stable profile. It improves monthly and 2026 YTD results, but reduces the full continuous 2024-2026 result versus the stable candidate.

## Artifacts

- Stable full set: `outputs/CANDIDATE_SEASONAL_MAR1_MAY225_PROFILE.set`
- Stable overrides: `outputs/CANDIDATE_SEASONAL_MAR1_MAY225_PROFILE_OVERRIDES.set`
- Recent/aggressive full set: `outputs/CANDIDATE_RECENT_AGGRESSIVE_MAR2_MAY225_PROFILE.set`
- Recent/aggressive overrides: `outputs/CANDIDATE_RECENT_AGGRESSIVE_MAR2_MAY225_PROFILE_OVERRIDES.set`
- March 2.00 monthly real-tick results: `outputs/LOCAL_MT5_MARCH2_MONTHLY_REALTICK_LOG_RESULTS.csv`
- March 2.00 broad real-tick summary: `outputs/LOCAL_MT5_MARCH2_BROAD_REALTICK_LOG_SUMMARY.csv`
