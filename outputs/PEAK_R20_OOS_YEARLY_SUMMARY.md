# Peak R20 OOS Yearly Validation Summary

Generated 2026-07-14 from hidden local MT5 runs on XAUUSD M15, `Model=1`.

This test was built because the 2024-2026 range is now research-seen data. The goal was to check whether the R10 branch survives older/yearly windows before treating it as money-ready.

No candidate passed.

## Decision

The R10 branch is not money-ready.

All three tested candidates have losing older years, weak profit factor in at least one year, and too much yearly drawdown for a robust live claim.

| Candidate | 2019 | 2020 | 2021 | 2022 | 2023 | 2024 | 2025 | 2026 YTD | Total Net | Losing Years | Worst DD |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `r10_base` | `-$40.29` | `+$197.77` | `-$66.26` | `+$65.83` | `-$33.96` | `+$814.43` | `+$186.95` | `+$246.96` | `+$1,371.43` | `3` | `12.44%` |
| `r10_loss_scale_15` | `-$26.01` | `+$53.84` | `-$90.25` | `-$6.49` | `-$45.31` | `+$800.72` | `+$22.80` | `+$246.96` | `+$956.26` | `4` | `14.21%` |
| `r10_profit_guard40` | `-$40.29` | `+$136.17` | `-$61.65` | `+$34.07` | `+$43.41` | `+$413.77` | `+$123.81` | `+$198.80` | `+$848.09` | `2` | `12.78%` |

`r10_profit_guard40` remains the best lower-drawdown recent fallback from the 2024-2026 Model4 shortlist, but this older-year pass shows it is not robust enough for a money-ready label.

## Yearly Details

| Candidate | Window | Net | Ann. Return | CAGR | PF | Recovery | Trades | Max DD |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `r10_base` | 2019 | `-$40.29` | `-4.04%` | `-4.04%` | `0.3507` | `-0.5166` | `5` | `7.74%` |
| `r10_base` | 2020 | `+$197.77` | `19.79%` | `19.79%` | `1.8596` | `1.5281` | `31` | `10.76%` |
| `r10_base` | 2021 | `-$66.26` | `-6.65%` | `-6.65%` | `0.5587` | `-0.5321` | `14` | `11.91%` |
| `r10_base` | 2022 | `+$65.83` | `6.61%` | `6.61%` | `1.2174` | `0.4897` | `28` | `12.44%` |
| `r10_base` | 2023 | `-$33.96` | `-3.41%` | `-3.41%` | `0.8817` | `-0.2793` | `24` | `11.18%` |
| `r10_base` | 2024 | `+$814.43` | `81.50%` | `81.52%` | `4.6128` | `6.5506` | `26` | `8.85%` |
| `r10_base` | 2025 | `+$186.95` | `18.76%` | `18.76%` | `1.7478` | `1.5867` | `30` | `10.01%` |
| `r10_base` | 2026 YTD | `+$246.96` | `46.98%` | `52.18%` | `4.6382` | `4.2557` | `18` | `4.88%` |
| `r10_loss_scale_15` | 2019 | `-$26.01` | `-2.61%` | `-2.61%` | `0.4923` | `-0.4083` | `7` | `6.32%` |
| `r10_loss_scale_15` | 2020 | `+$53.84` | `5.39%` | `5.39%` | `1.4148` | `0.5711` | `25` | `8.49%` |
| `r10_loss_scale_15` | 2021 | `-$90.25` | `-9.06%` | `-9.05%` | `0.4153` | `-0.6077` | `21` | `14.21%` |
| `r10_loss_scale_15` | 2022 | `-$6.49` | `-0.65%` | `-0.65%` | `0.9754` | `-0.0577` | `31` | `10.41%` |
| `r10_loss_scale_15` | 2023 | `-$45.31` | `-4.55%` | `-4.55%` | `0.8315` | `-0.4377` | `27` | `9.80%` |
| `r10_loss_scale_15` | 2024 | `+$800.72` | `80.13%` | `80.14%` | `4.7804` | `7.4237` | `27` | `7.68%` |
| `r10_loss_scale_15` | 2025 | `+$22.80` | `2.29%` | `2.29%` | `1.1383` | `0.2502` | `24` | `8.50%` |
| `r10_loss_scale_15` | 2026 YTD | `+$246.96` | `46.98%` | `52.18%` | `4.6382` | `4.2557` | `18` | `4.88%` |
| `r10_profit_guard40` | 2019 | `-$40.29` | `-4.04%` | `-4.04%` | `0.3507` | `-0.5166` | `5` | `7.74%` |
| `r10_profit_guard40` | 2020 | `+$136.17` | `13.63%` | `13.63%` | `2.1029` | `1.5616` | `22` | `7.86%` |
| `r10_profit_guard40` | 2021 | `-$61.65` | `-6.19%` | `-6.19%` | `0.4936` | `-0.5141` | `10` | `11.47%` |
| `r10_profit_guard40` | 2022 | `+$34.07` | `3.42%` | `3.42%` | `1.1733` | `0.2490` | `18` | `12.78%` |
| `r10_profit_guard40` | 2023 | `+$43.41` | `4.36%` | `4.36%` | `1.3484` | `0.5468` | `13` | `7.49%` |
| `r10_profit_guard40` | 2024 | `+$413.77` | `41.41%` | `41.41%` | `3.3054` | `4.2692` | `11` | `6.42%` |
| `r10_profit_guard40` | 2025 | `+$123.81` | `12.42%` | `12.43%` | `2.4031` | `1.9572` | `19` | `5.79%` |
| `r10_profit_guard40` | 2026 YTD | `+$198.80` | `37.82%` | `41.19%` | `4.6041` | `3.4258` | `18` | `4.88%` |

## What This Means

- The recent 2024-2026 edge is real enough to research, but it is not stable across older years.
- The fallback guard reduces some recent drawdown, but it does not solve regime dependence.
- The next research step should be a regime/market-phase filter or separate older-year failure diagnostic, not higher risk.

## Evidence Files

- Package: `outputs/peak_r20_oos_yearly_package`
- Queue manifest: `outputs/PEAK_R20_OOS_YEARLY_QUEUE.csv`
- Runner manifest: `outputs/PEAK_R20_OOS_YEARLY_PACKAGE_MANIFEST.csv`
- Results: `outputs/PEAK_R20_OOS_YEARLY_RESULTS.csv`
- Metrics: `outputs/PEAK_R20_OOS_YEARLY_METRICS.md`
- Builder: `work/build_peak_r20_oos_yearly_package.ps1`
