# ISLP Min ATR Probe

Date: 2026-07-12

## Purpose

Diagnose and reduce the current Dec-ISLP-Off `2024_10` Model4 losing window without banning the full October ISLP lane.

The current compact Dec-ISLP-Off diagnostic showed:

- `2024_10`: one ISLP sell, `-44.64`, entry ATR diagnostic around `3.74`
- `2025_10`: one ISLP sell, `+107.82`, entry ATR diagnostic around `13.19`

Both trades had the same lane and score profile:

- In-session liquidity pullback
- Score `8`
- EMA pullback
- VWAP pullback
- Liquidity/retest
- Liquidity sweep

The clean difference was volatility. The losing trade fired in a much lower ATR environment.

## Change Tested

Added optional input:

`InpInSessionLiquidityPullbackMinATR`

Default:

`0.0`

Candidate:

`5.0`

This keeps baseline behavior unchanged unless enabled in a test profile.

## Validation

Package:

`outputs/realtick_islp_min_atr_probe_package`

Model:

`Model=4`

Source:

Compact tester source generated from local `Professional_XAUUSD_EA.mq5`

Compact audit:

- Original inputs: `1440`
- Kept tester inputs: `334`
- Converted to globals: `1106`

Windows:

- `2024_07`
- `2024_10`
- `2025_07`
- `2025_10`
- `2026_07td`
- `h2_2024`
- `h2_2025`

## Result

Profile summary:

| Profile | Parsed | Total | Losing Windows | Worst | Best |
| --- | ---: | ---: | ---: | ---: | ---: |
| `dec_islp_off` | `7` | `+204.86` | `1` | `-44.64` | `+107.82` |
| `islp_min_atr5` | `7` | `+249.50` | `0` | `0.00` | `+107.82` |

Window diff:

| Window | Dec-ISLP-Off | ISLP MinATR5 | Delta | Winner |
| --- | ---: | ---: | ---: | --- |
| `2024_07` | `0.00` | `0.00` | `0.00` | tie |
| `2024_10` | `-44.64` | `0.00` | `+44.64` | ISLP MinATR5 |
| `2025_07` | `+51.66` | `+51.66` | `0.00` | tie |
| `2025_10` | `+107.82` | `+107.82` | `0.00` | tie |
| `2026_07td` | `0.00` | `0.00` | `0.00` | tie |
| `h2_2024` | `+69.16` | `+69.16` | `0.00` | tie |
| `h2_2025` | `+20.86` | `+20.86` | `0.00` | tie |

## Decision

Promising probe, not promoted yet.

Reason:

- It fixes the diagnosed sampled Model4 October loss.
- It does not harm the sampled winners.
- It removes the only losing sampled window.
- But it has only been tested on the small seven-window probe.

Required next gate:

- Run wider monthly Model4 validation.
- Then run quarterly Model4 validation.
- Promote only if it keeps total profit higher and does not reintroduce losing windows.

## Safety

Local MT5 safety audit after the run:

- `PASS`
- `39 / 39`
