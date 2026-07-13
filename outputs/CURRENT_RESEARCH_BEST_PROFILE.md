# Current Research Best Profile

Last updated: 2026-07-13 after adding the trade-readiness candidate and FMLR tick-speed reclaim probe.

## Profile

`Score7 Regime No-M1-Shock Dec-ISLP-Off + ISLP LowATR OrderFlow`

Status: current stability-best research profile. Not live-ready.

## Current Judgment

Keep LowATR OrderFlow as the most stable promoted research profile. Do not promote the latest FMLR work yet because it has not been MT5 backtested.

## Trade-Readiness Candidate

A conservative demo/forward-test candidate now exists locally:

`outputs/CANDIDATE_TRADE_READINESS_PROFILE.set`

SHA-256:

`B683100CA5BE912A9A848C3F715A67E4705473B00DEEF4B9070AE02BFDB708C5`

This candidate does not replace the current research-best. It lowers risk and enables stricter safety controls for demo/forward testing.

Key settings:

- `InpRiskPercent=0.50`
- `InpMaxEffectiveRiskPercent=0.50`
- `InpMaxOpenRiskPercent=0.75`
- `InpMaxPositionLots=0.05`
- `InpMaxDailyLossPercent=0.75`
- `InpMaxWeeklyLossPercent=2.00`
- `InpMaxMonthlyLossPercent=4.00`
- `InpMaxEquityDrawdownPercent=10.00`
- `InpUseAdaptiveReverse=false`
- `InpUseFlatMonthLiquidityReclaimLane=false`
- `InpUseTickSpeedImpulse=false`

## Source Manifest

Latest local source manifest:

`outputs/SOURCE_MANIFEST.md`

Latest local EA source hash:

`B6AA1915D2CA7483B1066C227F2506D7A85756D918820FF1100BAF66B0FBDBBE`

Local source size/lines:

- `904009` bytes
- `19213` lines

## Latest Default-Off Research Code

The local EA source includes a default-off Flat Month Liquidity Reclaim lane tagged `FMLR;`.

Latest source changes:

- FMLR no-fixed-TP runner permission recognizes proven non-structural sweep-runner setups when forward clearance, runner-stretch evidence, and FMLR structure trailing are present.
- FMLR can now tag `FMLR tick-speed reclaim` when an existing sweep/reclaim context is followed by a directional tick-speed impulse through `InpUseTickSpeedImpulse`.

Latest isolated package profile:

`fmlr_tick_speed_reclaim`

Package counts:

- Full FMLR validation package: `456` Model4 configs, `38` profiles
- Fast FMLR screen: `150` Model4 configs, `25` profiles

## Model4 Evidence For Current Best

Sampled, monthly, and quarterly totals below are validation-window comparisons, not annualized account curves.

Sampled probe:

| Profile | Parsed | Total | Losing Windows | Worst |
| --- | ---: | ---: | ---: | ---: |
| `dec_islp_off` | `7` | `+271.42` | `1` | `-44.64` |
| `islp_lowatr_of` | `7` | `+316.06` | `0` | `0.00` |

Monthly validation:

| Profile | Parsed | Total | Losing Windows | Worst |
| --- | ---: | ---: | ---: | ---: |
| `dec_islp_off` | `31` | `+3,637.53` | `1` | `-44.64` |
| `islp_lowatr_of` | `31` | `+3,682.17` | `0` | `0.00` |

Quarterly validation:

| Profile | Parsed | Total | Losing Windows | Worst |
| --- | ---: | ---: | ---: | ---: |
| `dec_islp_off` | `11` | `+3,421.49` | `1` | `-44.64` |
| `islp_lowatr_of` | `11` | `+3,435.65` | `1` | `-30.48` |

## Fresh Continuous Same-Source Check

Return math uses a `$1,000` starting balance and CAGR over `2024.01.01` to `2026.07.12`, about `2.53` years.

| Profile | Model | Window | Net | Total Return | CAGR/yr |
| --- | ---: | --- | ---: | ---: | ---: |
| `lowatr_current` | `4` | `2024.01.01` to `2026.07.12` | `+1,195.69` | `+119.57%` | `+36.51%/yr` |
| `dec_islp_off` | `4` | `2024.01.01` to `2026.07.12` | `+1,195.04` | `+119.50%` | `+36.49%/yr` |

The older `+4,507.51` Dec-ISLP-Off Model4 continuous result equals `+450.75%` total and about `+96.43%/yr` CAGR from a `$1,000` start, but it is now treated as historical/stale until reproduced on the current local source and compact tester path.

## Risk Warning

The bot is still research-only. The readiness candidate is safer but unproven. No live funding decision should be made until current-source Model4 backtests, full reports, walk-forward checks, broker variation, Monte Carlo stress, and demo forward tests are complete.

## Latest Local Checks Passed

- `PRICE_ACTION_STRATEGY_MODULES_SMOKE_PASS`
- `EA_SOURCE_ARTIFACT_SYNC_SMOKE_PASS`
- `FLAT_MONTH_LIQUIDITY_RECLAIM_PROBE_PACKAGE_SMOKE_PASS`
- `FLAT_MONTH_LIQUIDITY_RECLAIM_FAST_PROBE_PACKAGE_SMOKE_PASS`
- `FLAT_MONTH_LIQUIDITY_RECLAIM_COMPACT_SOURCE_SMOKE_PASS`
- `TRADE_READINESS_PROFILE_SMOKE_PASS`
- `ADAPTIVE_REVERSE_QUARANTINE_SMOKE_PASS`
- `MT5_HIDDEN_LAUNCHER_LOCK_SMOKE_PASS`
- MT5 local safety audit: `PASS 39 / 39`

## Decision

No promotion from the latest FMLR source/package refresh yet.

Next testing target: run the trade-readiness candidate and the 150-config fast FMLR screen locally while keeping MT5 hidden/non-focus-stealing. Promote nothing unless it beats `lowatr_current` without adding red control windows.
