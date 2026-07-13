# Current Research Best Profile

Last updated: 2026-07-13 after adding annualized return context.

## Profile

`Score7 Regime No-M1-Shock Dec-ISLP-Off + ISLP LowATR OrderFlow`

Status: current stability-best research profile. Not live-ready.

## Exact Profile Identity

Generated locally by:

`work/build_realtick_islp_lowatr_orderflow_probe_package.ps1`

Local generated `.set` file:

`outputs/CANDIDATE_DEC_ISLP_OFF_ISLP_LOWATR_ORDERFLOW_PROFILE.set`

SHA-256:

`D0867E0333D3F110EF47410A2B2FF46402AAD96FC70B0DBF9506836124D633BC`

## Current Judgment

Keep LowATR OrderFlow as the most stable promoted research profile. Do not promote the latest FMLR work yet because it has not been MT5 backtested.

## Source Manifest

Latest local source manifest:

`outputs/SOURCE_MANIFEST.md`

Latest local EA source hash:

`0289641ABE4F1B93FB69D81FF098FFBAA28FFA14478282ACD0BCA4B3A1CBAFC3`

Local source size/lines:

- `902802` bytes
- `19193` lines

## Latest Default-Off Research Code

The local EA source includes a default-off Flat Month Liquidity Reclaim lane tagged `FMLR;`.

Latest source change:

- FMLR no-fixed-TP runner permission now recognizes proven non-structural sweep-runner setups when forward clearance, runner-stretch evidence, and FMLR structure trailing are present.
- The planned stretched target still has to pass minimum RR and spread-adjusted RR before entry.
- The entry log can add `FMLR sweep unlimited runner;` for that path.

Latest isolated package profile:

`fmlr_sweep_unlimited_runner`

Package counts:

- Full FMLR validation package: `444` Model4 configs, `37` profiles
- Fast FMLR screen: `144` Model4 configs, `24` profiles

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

The bot is still research-only. The best available tester-stat exports reported worst equity drawdown around `30.9408%`, and the newest FMLR package has not been MT5 backtested. No live funding decision should be made from these dashboard numbers alone.

## Latest Local Checks Passed

- `PRICE_ACTION_STRATEGY_MODULES_SMOKE_PASS`
- `EA_SOURCE_ARTIFACT_SYNC_SMOKE_PASS`
- `FLAT_MONTH_LIQUIDITY_RECLAIM_PROBE_PACKAGE_SMOKE_PASS`
- `FLAT_MONTH_LIQUIDITY_RECLAIM_FAST_PROBE_PACKAGE_SMOKE_PASS`
- `FLAT_MONTH_LIQUIDITY_RECLAIM_COMPACT_SOURCE_SMOKE_PASS`
- `ADAPTIVE_REVERSE_QUARANTINE_SMOKE_PASS`
- `MT5_HIDDEN_LAUNCHER_LOCK_SMOKE_PASS`
- MT5 local safety audit: `PASS 39 / 39`

## Decision

No promotion from the latest FMLR source/package refresh yet.

Next testing target: run the 144-config fast FMLR screen locally while keeping MT5 hidden/non-focus-stealing. Promote nothing unless it beats `lowatr_current` without adding red control windows.
