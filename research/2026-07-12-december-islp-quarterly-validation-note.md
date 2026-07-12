# December ISLP Quarterly Real-Tick Validation Note

Date: 2026-07-12

## Purpose

Validate whether the promoted `Score7 Regime No-M1-Shock Dec-ISLP-Off` profile remains better than the prior `no_m1shock` profile on quarter-sized `Model=4` real-tick windows.

## Test

- Package: `outputs/realtick_dec_islp_quarterly_validation_package`
- Runner CSV: `outputs/REALTICK_DEC_ISLP_QUARTERLY_VALIDATION_RUN.csv`
- Parsed log results: `outputs/REALTICK_DEC_ISLP_QUARTERLY_VALIDATION_LOG_RESULTS.csv`
- Quarter diff: `outputs/REALTICK_DEC_ISLP_QUARTERLY_VALIDATION_DIFF.csv`
- Profile summary: `outputs/REALTICK_DEC_ISLP_QUARTERLY_VALIDATION_PROFILE_SUMMARY.csv`
- Decision summary: `outputs/REALTICK_DEC_ISLP_QUARTERLY_VALIDATION_DECISION_SUMMARY.csv`
- Tester model: `Model=4`
- Window set: quarters from `2024_Q1` through `2026_Q3TD`
- Configs: `22`

The MT5 runner did not write report files, so final balances were recovered from tester logs. This supports net-profit/quarter comparison, but not full report statistics.

## Result

| Profile | Parsed Quarters | Total Net | Nonzero Quarters | Losing Quarters | Worst Quarter | Best Quarter |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `no_m1shock` | `11 / 11` | `+$3,404.59` | `9` | `1` | `-$4.55` | `+$1,497.84` |
| `dec_islp_off` | `11 / 11` | `+$3,455.89` | `9` | `0` | `$0.00` | `+$1,497.84` |

Quarter-by-quarter decision:

| Metric | Value |
| --- | ---: |
| `dec_islp_off` wins | `1` |
| `no_m1shock` wins | `0` |
| Ties | `10` |
| Total delta | `+$51.30` |

The only changed quarter was Q4 2024:

| Quarter | No-M1-Shock | Dec-ISLP-Off | Delta |
| --- | ---: | ---: | ---: |
| 2024_Q4 | `-$4.55` | `+$46.75` | `+$51.30` |

## Decision

Keep `Score7 Regime No-M1-Shock Dec-ISLP-Off` as the current research-best.

This quarterly gate supports the guard because it removes the only losing quarter without reducing any other quarter.

## Caveats

- This was parsed from tester logs because HTML/XML reports were not generated.
- It proves quarterly net-profit comparison only, not full risk statistics.
- Model2 still prefers the previous no-m1-shock profile.
