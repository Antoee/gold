# Peak R20 Regime Combo Stability Lead Summary

Generated: 2026-07-14.

## Decision

`r10_pg40_atr085_adapt7` is the current best risk-first research lead, but it is not trade-ready.

The profile is much more stable than the prior R10 branches, but Model 4 still found one red yearly window: 2020 lost `-$22.92` on one diagnostic fallback trade. That blocks any real-money claim.

## Profile Identity

- Profile: `r10_pg40_atr085_adapt7`
- Canonical profile: `outputs/peak_r20_regime_combo_candidate_profiles/r10_pg40_atr085_adapt7.set`
- Profile SHA-256: `CB182D026A62AE499052949F88F514EF7FC67D8C071E9179AB069D29575C59B2`
- Source SHA-256: `FF1BCDB06E5D628F37039B7A2E6D96CE0EC60E2F0D33F2A1F8E3FF2EE4130394`

Key settings added to the `r10_profit_guard40` base:

- `InpUseDynamicATRRegimeGuard=true`
- `InpMinATRRegimeRatio=0.85`
- `InpMaxATRRegimeRatio=1.65`
- `InpUseAdaptiveRegimeConfidenceGate=true`
- `InpAdaptiveRegimeMinScore=7`
- `InpAdaptiveRegimeMinEfficiency=0.45`

## Model 1 Yearly Validation

File: `outputs/PEAK_R20_REGIME_COMBO_OOS_YEARLY_RESULTS.csv`

| Window | Net | Trades | Max DD |
| --- | ---: | ---: | ---: |
| 2019 | `+$33.10` | `2` | `2.85%` |
| 2020 | `+$9.25` | `4` | `6.11%` |
| 2021 | `+$76.54` | `3` | `4.59%` |
| 2022 | `+$37.64` | `8` | `6.02%` |
| 2023 | `+$63.91` | `2` | `3.65%` |
| 2024 | `+$15.72` | `4` | `7.08%` |
| 2025 | `+$53.52` | `4` | `4.11%` |
| 2026 YTD | `+$54.92` | `1` | `2.97%` |

Summary: `+$344.60`, `0` losing yearly windows, worst yearly net `+$9.25`, worst DD `7.08%`, `28` trades.

## Model 4 Yearly Validation

File: `outputs/PEAK_R20_REGIME_COMBO_MODEL4_YEARLY_RESULTS.csv`

Fresh current-source full-report reproduction: `outputs/PEAK_R20_REGIME_COMBO_MODEL4_CURRENT_SOURCE_REPORT_METRICS.md`.

- Source SHA-256: `2219F6AE66CF1121972848C118213B50C01F91E783ABFE6D66F75105C655EB4D`
- Current-source yearly profile SHA-256: `3E6B806E2941A993579756C8E503B7886E06891F077A104D39428704E48545BC`
- MT5 platform: `MetaQuotes-Demo (Build 5989)`
- Exported reports parsed: `8 / 8`
- Tester-log fallback rows: `0 / 8`

| Window | Net | Trades | Max DD | Note |
| --- | ---: | ---: | ---: | --- |
| 2019 | `+$44.30` | `1` | `2.39%` | Green |
| 2020 | `-$22.92` | `1` | `2.36%` | Red blocker |
| 2021 | `+$76.46` | `3` | `4.59%` | Green |
| 2022 | `+$37.31` | `8` | `6.05%` | Green |
| 2023 | `+$64.00` | `2` | `3.65%` | Green |
| 2024 | `+$15.79` | `4` | `7.09%` | Green but thin |
| 2025 | `+$48.78` | `3` | `3.06%` | Green |
| 2026 YTD | `$0.00` | `0` | `0.00%` | No real-tick trades |

Summary: `+$263.72`, `1` losing yearly window, worst yearly net `-$22.92`, worst DD `7.09%`, `22` trades.

Percent-per-year context from the full MT5 reports:

| Window | Ann. Return | CAGR | PF | Sharpe | Recovery |
| --- | ---: | ---: | ---: | ---: | ---: |
| 2019 | `+4.45%/yr` | `+4.45%/yr` | `0.00` | `0.71` | `1.82` |
| 2020 | `-2.29%/yr` | `-2.29%/yr` | `0.00` | `-4.80` | `-0.97` |
| 2021 | `+7.67%/yr` | `+7.67%/yr` | `4.27` | `2.63` | `1.49` |
| 2022 | `+3.74%/yr` | `+3.74%/yr` | `1.49` | `4.16` | `0.57` |
| 2023 | `+6.42%/yr` | `+6.42%/yr` | `0.00` | `1.82` | `1.59` |
| 2024 | `+1.58%/yr` | `+1.58%/yr` | `1.30` | `1.07` | `0.22` |
| 2025 | `+4.89%/yr` | `+4.90%/yr` | `8.41` | `2.10` | `1.47` |
| 2026 YTD | `0.00%/yr` | `0.00%/yr` | `0.00` | `0.00` | `0.00` |

## 2020 Model 4 Failure Diagnostic

File: `outputs/peak_r20_regime_combo_model4_diag_package/trade_logs/PXEA_R10A7_2020_m4_trades.csv`

The losing trade was:

- Entry: 2020-08-13 13:30, sell, `0.03` lots
- Entry reason: `Diagnostic trend fallback;`
- ATR: `3.82`
- Spread: `30.0` points
- Exit: stop loss at 2020-08-13 14:05:48
- Profit: `-$22.92`

The first diagnostic-quality sweep did not solve this. Requiring diagnostic fallback quality/liquidity/structure gates removed too many winners and still left yearly red windows.

## Rejected Follow-Up

File: `outputs/PEAK_R20_DIAG_QUALITY_YEARLY_RESULTS.csv`

| Candidate | Total Net | Losing Years | Worst Year | Worst DD | Decision |
| --- | ---: | ---: | ---: | ---: | --- |
| `r10_a7_diagq_default` | `+$328.37` | `1` | `-$20.84` | `6.47%` | Rejected |
| `r10_a7_diagq_liq` | `+$241.28` | `2` | `-$17.60` | `5.63%` | Rejected |
| `r10_a7_diagq_struct` | `+$195.55` | `1` | `-$17.60` | `4.79%` | Rejected |
| `r10_a7_diagq_struct_liq` | `+$195.55` | `1` | `-$17.60` | `4.79%` | Rejected |
| `r10_a7_no_diagfallback` | `+$123.15` | `2` | `-$23.40` | `4.79%` | Rejected |

## 2026-07-14 DGF Risk Follow-Up

File: `outputs/PEAK_R20_DGF_RISK_FOLLOWUP_SUMMARY.md`

No new best was promoted.

- Hard diagnostic-fallback spread/ATR caps were rejected because they created red Model1 yearly windows.
- `r10_a7_dfg_risk_25_45_50` partially improved Model4: total `+$270.66`, worst DD `6.20%`, and the 2020 loss improved from `-$22.92` to `-$15.28`.
- The 2020 Model4 yearly window is still red, so the spread-risk variant is not promoted.
- Diagnostic-fallback performance-risk throttle variants were rejected in Model1 yearly validation because every throttle variant created a red yearly window while the control stayed green.

## Next Best Work

The next branch should not be another narrow one-off filter. First priority is getting exported MT5 reports for the current stability lead and any serious replacement candidate, then testing broker/stress variation and only promoting a candidate if Model4 yearly windows are no-red and trade-quality evidence is available.

Useful next tests:

- full exported MT5 reports once a no-red Model4 yearly candidate exists
- broker/stress variation around spread, commission, slippage, and execution delay
- a broader diagnostic-fallback entry-quality model only if it passes Model1 yearly splits before Model4
