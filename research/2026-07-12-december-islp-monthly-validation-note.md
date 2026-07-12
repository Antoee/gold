# December ISLP Monthly Real-Tick Validation Note

Date: 2026-07-12

## Purpose

Validate whether the promoted `Score7 Regime No-M1-Shock Dec-ISLP-Off` profile remains better than the prior `no_m1shock` profile when tested month-by-month with `Model=4` real ticks.

## Test

- Package: `outputs/realtick_dec_islp_monthly_validation_package`
- Runner CSV: `outputs/REALTICK_DEC_ISLP_MONTHLY_VALIDATION_RUN.csv`
- Parsed log results: `outputs/REALTICK_DEC_ISLP_MONTHLY_VALIDATION_LOG_RESULTS.csv`
- Month diff: `outputs/REALTICK_DEC_ISLP_MONTHLY_VALIDATION_DIFF.csv`
- Profile summary: `outputs/REALTICK_DEC_ISLP_MONTHLY_VALIDATION_PROFILE_SUMMARY.csv`
- Decision summary: `outputs/REALTICK_DEC_ISLP_MONTHLY_VALIDATION_DECISION_SUMMARY.csv`
- Tester model: `Model=4`
- Window set: monthly windows from `2024.01.01` through `2026.07.12`
- Configs: `62`

The MT5 runner did not write report files, so the result was recovered from tester-log final-balance lines. This is valid for net-profit/month comparison, but it does not provide full report statistics such as drawdown, trades, or profit factor.

## Result

| Profile | Parsed Months | Total Net | Nonzero Months | Losing Months | Worst Month | Best Month |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `no_m1shock` | `31 / 31` | `+$3,687.00` | `16` | `2` | `-$49.40` | `+$1,497.84` |
| `dec_islp_off` | `31 / 31` | `+$3,779.52` | `14` | `0` | `$0.00` | `+$1,497.84` |

Month-by-month decision:

| Metric | Value |
| --- | ---: |
| `dec_islp_off` wins | `2` |
| `no_m1shock` wins | `0` |
| Ties | `29` |
| Total delta | `+$92.52` |

The only changed months were December:

| Month | No-M1-Shock | Dec-ISLP-Off | Delta |
| --- | ---: | ---: | ---: |
| 2024-12 | `-$49.40` | `$0.00` | `+$49.40` |
| 2025-12 | `-$43.12` | `$0.00` | `+$43.12` |

## Decision

Keep `Score7 Regime No-M1-Shock Dec-ISLP-Off` as the current research-best.

This monthly gate supports the guard because it:

- improved total monthly parsed-log net by `+$92.52`,
- removed both losing months,
- did not reduce any non-December month,
- confirmed the guard is narrowly affecting the intended failure area.

## Caveats

- This was parsed from tester logs because HTML/XML reports were not generated.
- The evidence proves monthly net-profit comparison, not full risk statistics.
- Model2 still prefers the previous no-m1-shock profile on the broader sampled validation set.
- The next validation gate should fix report generation or add richer trade/stat extraction for monthly Model4 runs.
