# Flat-Month FSD Efficiency Relaxation Probe

Date: 2026-07-12

Status: rejected, not promoted.

## Goal

Test whether Flat Month Structural Displacement could trade more of the idle months without enabling Adaptive Reverse, grid logic, martingale sizing, or pure ATR-only stops.

The active problem was efficiency: the current LowATR OrderFlow profile still has too many zero-trade months. This probe tried to relax the structural-displacement lane only when the month was behind target and stale enough.

## Code Change

Added optional inputs, all defaulted off:

- `InpUseFlatMonthStructuralDisplacementEfficiencyRelaxation`
- `InpFlatMonthStructuralDisplacementRelaxAfterHours`
- `InpFlatMonthStructuralDisplacementRelaxMinCatchUpProgress`
- `InpFlatMonthStructuralDisplacementRelaxMinRangeATR`
- `InpFlatMonthStructuralDisplacementRelaxMinBodyPercent`
- `InpFlatMonthStructuralDisplacementRelaxMaxOppositeWickPercent`
- `InpFlatMonthStructuralDisplacementRelaxMinScore`
- `InpFlatMonthStructuralDisplacementRelaxRequireSweepOrOrderFlow`

When enabled, the lane can use slightly lower candle-size/body requirements and can accept either sweep/retest evidence or order-flow evidence instead of requiring both. It still requires structural direction, direct structure stop placement, forward liquidity clearance when enabled, liquid-session gating, RR checks, and normal flat-month entry spacing.

Adaptive Reverse stayed disabled.

## Tested Profiles

Package:

`outputs/flat_month_efficiency_relaxation_probe_package`

Candidate set files:

- `outputs/CANDIDATE_FSD_EFFICIENCY_RELAXED_48H_PROFILE.set`
- `outputs/CANDIDATE_FSD_EFFICIENCY_RELAXED_24H_PROFILE.set`

Candidate hashes:

- 48h: `535D8108DCB0C09AB65C36AC01B139E4F93AC3F4CD81F7C5826F60F76174AFB1`
- 24h: `41B20042B5AEE829059D9D78136E3C6E8DAA2B6FB8CACA4FCF855D0B0EFE7590`

Compact tester source:

`outputs/FLAT_MONTH_EFFICIENCY_RELAXATION_COMPACT.mq5`

Compact source hash:

`93A9AC5BA8D8A2448CEA395C951F82FFCEBF71D7B16E8CB52BEAB74690847506`

Compile result:

`0 errors, 0 warnings`

## Local Hidden Model4 Probe

Windows tested:

`2024_01`, `2024_02`, `2024_04`, `2024_05`, `2024_09`, `2024_10`, `2025_01`, `2025_04`, `2025_06`, `2026_01`, `2026_05`, `2026_06`

Summary:

| Profile | Parsed | Active Windows | Zero-Trade Windows | Total Net | Losing Windows | Total Trades | Worst Equity DD % |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `lowatr_current` | `12 / 12` | `3` | `9` | `+508.07` | `0` | `6` | `30.9408` |
| `fsd_relaxed_48h` | `12 / 12` | `3` | `9` | `+508.07` | `0` | `6` | `30.9408` |
| `fsd_relaxed_24h` | `12 / 12` | `3` | `9` | `+508.07` | `0` | `6` | `30.9408` |

Evidence files:

- `outputs/FLAT_MONTH_EFFICIENCY_RELAXATION_PROBE_RESULTS.csv`
- `outputs/FLAT_MONTH_EFFICIENCY_RELAXATION_PROBE_SUMMARY.csv`
- `outputs/FLAT_MONTH_EFFICIENCY_RELAXATION_PROBE_RUN.csv`
- `outputs/FLAT_MONTH_EFFICIENCY_RELAXATION_PROBE_MANIFEST.csv`
- `outputs/MT5_HIDDEN_COMPILE_FSD_EFFICIENCY_RELAXATION.log`

## Decision

Rejected.

The relaxation did not add trades, did not reduce zero-trade windows, did not increase net profit, and did not improve the drawdown warning. The current stability-best profile remains:

`Score7 Regime No-M1-Shock Dec-ISLP-Off + ISLP LowATR OrderFlow`

The useful takeaway is diagnostic: the flat-month bottleneck is not just the final FSD sweep/order-flow gate. A future attempt probably needs a different opportunity lane or earlier candidate discovery logic, not small threshold relaxation inside the existing FSD lane.

## Safety

The run was launched with the hidden local MT5 background wrapper. After completion:

- stderr was empty
- no MT5 or MetaEditor process remained active
- MT5 local safety audit passed `39 / 39`
