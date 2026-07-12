# ISLP Min ATR Monthly Validation

Date: 2026-07-12

## Purpose

Validate whether the ISLP MinATR5 probe should replace the current Dec-ISLP-Off research-best profile.

The small seven-window probe improved:

- `dec_islp_off`: `+204.86`, `1` losing window
- `islp_min_atr5`: `+249.50`, `0` losing windows

This monthly gate checks whether that improvement survives all monthly Model4 windows from January 2024 through July 12, 2026.

## Candidate

`InpInSessionLiquidityPullbackMinATR=5.0`

Intent:

- Block very low-ATR ISLP entries.
- Avoid the diagnosed October 2024 ISLP loss.
- Preserve higher-volatility ISLP winners.

## Validation

Package:

`outputs/realtick_islp_min_atr_monthly_validation_package`

Model:

`Model=4`

Configs:

`62`

Windows:

- `31` monthly windows for `dec_islp_off`
- `31` monthly windows for `islp_min_atr5`

Reports:

`NO_REPORT`, parsed from MT5 tester log final balances.

Local safety after run:

- `PASS`
- `39 / 39`

## Result

| Profile | Parsed | Total | Losing Windows | Worst | Best |
| --- | ---: | ---: | ---: | ---: | ---: |
| `dec_islp_off` | `31` | `+3,637.53` | `1` | `-44.64` | `+1,497.84` |
| `islp_min_atr5` | `31` | `+3,615.61` | `0` | `0.00` | `+1,497.84` |

Non-tie windows:

| Window | Dec-ISLP-Off | ISLP MinATR5 | Delta | Winner |
| --- | ---: | ---: | ---: | --- |
| `2024_06` | `+66.56` | `0.00` | `-66.56` | Dec-ISLP-Off |
| `2024_10` | `-44.64` | `0.00` | `+44.64` | ISLP MinATR5 |

Net monthly delta:

`-21.92`

## Decision

Do not promote ISLP MinATR5 as the primary research-best profile.

Reason:

- It removes the only losing monthly window.
- But it also blocks a larger winning month.
- Monthly total profit is lower than Dec-ISLP-Off by `21.92`.

Classification:

`Conservative risk-smoothing candidate`

Current primary research-best remains:

`Score7 Regime No-M1-Shock Dec-ISLP-Off`

## Next

The better target is not a simple ISLP ATR floor. The next improvement should try to preserve the `2024_06` winner while blocking the `2024_10` loser, likely by comparing the structural/price-action context of those two ISLP trades rather than using ATR alone.
