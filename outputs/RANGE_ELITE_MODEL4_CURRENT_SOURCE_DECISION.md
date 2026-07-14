# Range-Elite Current-Source Model4 Decision

Date: 2026-07-14

Verdict: **REJECTED AS TRADE-READY / KEEP AS RESEARCH LEAD ONLY**

The older `range_elite_micro` branch was retested on the current EA source with exported MT5 Model4 real-tick yearly reports from 2019 through 2026 YTD. It is profitable overall, but it fails the risk-first stability gate because multiple yearly windows are red and drawdown is too high for a money-ready profile.

## Identity

- Candidate: `CANDIDATE_PRIMARY_AUG40_REVERSE_OFF_FSD_STRICT_MFE_AUGUST_ONLY_MICRO_R035_RANGE_ELITE_PROFILE`
- Source hash: `2219F6AE66CF1121972848C118213B50C01F91E783ABFE6D66F75105C655EB4D`
- Profile SHA-256: `3690755F9F97B3556222E8FACA784294A6BADF41BEDCAB5CC5CEB4EE7B12F836`
- MT5 model: `Model=4` real ticks
- Reports parsed: `8 / 8`
- Log-only rows: `0 / 8`
- Evidence:
  - `outputs/RANGE_ELITE_MODEL4_YEARLY_METRICS.md`
  - `outputs/RANGE_ELITE_MODEL4_YEARLY_RESULTS.csv`
  - `outputs/RANGE_ELITE_MODEL4_YEARLY_ROUTING.md`

## Summary

| Metric | Result |
| --- | ---: |
| Total validation-window net | `+$2,953.27` |
| Worst yearly net | `-$131.33` |
| Average annualized return | `45.31%/yr` |
| Worst annualized return | `-13.18%/yr` |
| Worst drawdown | `27.87%` |
| Total trades | `61` |
| Parsed full reports | `8 / 8` |

## Yearly Results

| Window | Net | Annualized Return | CAGR | Profit Factor | Trades | Max DD |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 2019 full | `-$83.32` | `-8.36%/yr` | `-8.36%` | `0.00` | `3` | `11.33%` |
| 2020 full | `+$88.75` | `+8.88%/yr` | `+8.88%` | `2.92` | `2` | `13.26%` |
| 2021 full | `-$62.11` | `-6.23%/yr` | `-6.23%` | `0.40` | `2` | `20.85%` |
| 2022 full | `+$9.59` | `+0.96%/yr` | `+0.96%` | `1.13` | `2` | `23.77%` |
| 2023 full | `-$131.33` | `-13.18%/yr` | `-13.17%` | `0.56` | `17` | `18.02%` |
| 2024 full | `+$2,174.47` | `+217.60%/yr` | `+217.70%` | `5.01` | `21` | `24.25%` |
| 2025 full | `+$214.30` | `+21.50%/yr` | `+21.51%` | `4.96` | `3` | `11.97%` |
| 2026 YTD | `+$742.92` | `+141.33%/yr` | `+187.73%` | `1.93` | `11` | `27.87%` |

## Decision

This branch is interesting because it keeps the 2024-2026 profit engine alive and gives the first current-source Model4 proof of the larger old range-elite idea. It should not be promoted because the edge is uneven:

- 2019, 2021, and 2023 are losing years.
- 2022 barely clears positive territory.
- 2026 YTD makes money but reaches `27.87%` drawdown.
- The profit is concentrated heavily in 2024, which raises regime-dependence risk.

Next useful work is not to increase risk. The next useful work is to identify why the branch loses in 2019/2021/2023 and why 2026 drawdown is so high, then add a regime or entry-quality filter that reduces those failures without simply disabling calendar years.
