# Independent M5 Failed-Breakout Trap Decision

## Decision

**Rejected. No new best, continuous test, recent-data test, or Model4 promotion was opened.**

The native M5 version did not preserve the positive M15 failed-breakout clue. Every one of the 12 frozen 14/16/18-bar structural and fixed-R shapes lost in both equal three-year eras. The least-bad aggregate validation score was `-$85.11` from `m5fbt_b18_struct_r075`, and it produced only `28` restart-window trades.

## Evidence Contract

- Source SHA-256: `6774D7E94A78E985630C34EE372086BF2C8A6EA4C77690078F15641B86119D3B`
- Compile: `0 errors, 0 warnings`
- Model1 reports: `24/24` parsed
- Windows: `2015-2017` and `2018-2020`
- Post-2020 rows: `0`
- Model4 rows: `0`
- Risk per accepted trade: `0.10%`; minimum-lot overflow is rejected; real-account trading defaults off.

## Gate Result

- Profitable in both eras: `0/12`
- PF at least 1.10 in both eras: `0/12`
- At least 100 trades in both eras: `0/12`
- Full discovery gate passes: `0/12`

| Candidate | 2015-2017 net | Annualized | PF | Trades | 2018-2020 net | Annualized | PF | Trades | Aggregate score | Decision |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| `m5fbt_b18_struct_r075` | -$57.71 | -0.19% | 0.11 | 8 | -$27.40 | -0.09% | 0.75 | 20 | -$85.11 | `REJECTED_BROAD_ERAS` |
| `m5fbt_b18_fixed_r150` | -$124.88 | -0.42% | 0.25 | 22 | -$22.21 | -0.07% | 0.86 | 29 | -$147.09 | `REJECTED_BROAD_ERAS` |
| `m5fbt_b16_struct_r075` | -$112.77 | -0.38% | 0.33 | 24 | -$39.00 | -0.13% | 0.76 | 33 | -$151.77 | `REJECTED_BROAD_ERAS` |
| `m5fbt_b18_fixed_r125` | -$120.69 | -0.40% | 0.28 | 22 | -$45.76 | -0.15% | 0.72 | 29 | -$166.45 | `REJECTED_BROAD_ERAS` |
| `m5fbt_b18_fixed_r200` | -$110.93 | -0.37% | 0.34 | 22 | -$62.75 | -0.21% | 0.62 | 29 | -$173.68 | `REJECTED_BROAD_ERAS` |
| `m5fbt_b16_fixed_r125` | -$205.23 | -0.68% | 0.35 | 44 | -$39.33 | -0.13% | 0.85 | 50 | -$244.56 | `REJECTED_BROAD_ERAS` |
| `m5fbt_b16_fixed_r150` | -$210.34 | -0.70% | 0.34 | 44 | -$35.93 | -0.12% | 0.86 | 50 | -$246.27 | `REJECTED_BROAD_ERAS` |
| `m5fbt_b16_fixed_r200` | -$196.59 | -0.66% | 0.38 | 44 | -$106.99 | -0.36% | 0.58 | 50 | -$303.58 | `REJECTED_BROAD_ERAS` |
| `m5fbt_b14_struct_r075` | -$245.61 | -0.82% | 0.33 | 52 | -$239.67 | -0.80% | 0.45 | 71 | -$485.28 | `REJECTED_BROAD_ERAS` |
| `m5fbt_b14_fixed_r150` | -$312.82 | -1.04% | 0.51 | 98 | -$243.37 | -0.81% | 0.60 | 103 | -$556.19 | `REJECTED_BROAD_ERAS` |
| `m5fbt_b14_fixed_r125` | -$313.54 | -1.05% | 0.50 | 98 | -$247.69 | -0.83% | 0.59 | 103 | -$561.23 | `REJECTED_BROAD_ERAS` |
| `m5fbt_b14_fixed_r200` | -$317.37 | -1.06% | 0.50 | 97 | -$309.50 | -1.03% | 0.49 | 103 | -$626.87 | `REJECTED_BROAD_ERAS` |

Aggregate validation scores add restart windows only for comparison; they are not sequential account returns.

## Interpretation

Changing the signal timeframe from M15 to native M5 bar geometry increased noise rather than useful activity. No candidate reached the frozen 100-trade floor in both eras, and every candidate had negative expectancy. This branch should not receive looser gates, continuous testing, newer data, or execution-model escalation.
