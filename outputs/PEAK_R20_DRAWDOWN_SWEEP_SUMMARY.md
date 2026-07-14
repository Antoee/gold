# Peak R20 R10 Drawdown Sweep Summary

Generated 2026-07-14 from hidden local MT5 runs on XAUUSD M15, 2024-01-01 to 2026-07-12.

No new trade-ready profile was promoted.

## Decision

The aggressive R10 branch still has the best profit, but drawdown remains too high for a stability-best or trade-ready label.

Best high-profit frontier:

| Profile | Model | Net | Ann. Return | CAGR | PF | Recovery | Trades | Max DD |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `r10_base` | 1 | `+$1,716.76` | `67.94%` | `48.51%` | `2.8655` | `7.5227` | `76` | `10.62%` |
| `r10_base` | 4 | `+$1,564.01` | `61.89%` | `45.15%` | `2.6874` | `7.1007` | `74` | `10.64%` |
| `r10_dailytrail35` | 1 | `+$1,729.28` | `68.43%` | `48.78%` | `2.9051` | `7.5776` | `75` | `10.62%` |
| `r10_dailytrail35` | 4 | `+$1,577.25` | `62.42%` | `45.45%` | `2.7264` | `7.1609` | `73` | `10.64%` |

`r10_dailytrail35` is not promoted because the gain is tiny and drawdown is unchanged.

Best lower-drawdown fallback:

| Profile | Model | Net | Ann. Return | CAGR | PF | Recovery | Trades | Max DD |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `r10_profit_guard40` | 1 | `+$979.74` | `38.77%` | `31.03%` | `3.2752` | `8.4069` | `47` | `7.71%` |
| `r10_profit_guard40` | 4 | `+$1,000.97` | `39.61%` | `31.59%` | `3.4058` | `8.5240` | `46` | `7.76%` |

This is a meaningful risk-adjusted fallback, but it gives up too much profit to replace the high-profit frontier outright. It also still needs exported full reports, split windows, stress tests, and forward/demo evidence before any real-money use.

Follow-up older-year validation rejected it as money-ready: `r10_profit_guard40` had `2` losing yearly windows from 2019 through 2026 YTD and a `12.78%` worst yearly drawdown. See `outputs/PEAK_R20_OOS_YEARLY_SUMMARY.md`.

## Model4 Shortlist

| Candidate | Net | Ann. Return | CAGR | PF | Recovery | Sharpe | Trades | Max DD |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `r10_dailytrail35` | `+$1,577.25` | `62.42%` | `45.45%` | `2.7264` | `7.1609` | `39.7757` | `73` | `10.64%` |
| `r10_base` | `+$1,564.01` | `61.89%` | `45.15%` | `2.6874` | `7.1007` | `38.3838` | `74` | `10.64%` |
| `r10_loss_scale_25` | `+$1,396.22` | `55.25%` | `41.31%` | `2.6496` | `7.2448` | `38.5606` | `75` | `9.32%` |
| `r10_loss_scale_15` | `+$1,281.41` | `50.71%` | `38.60%` | `2.7634` | `7.2787` | `40.9187` | `68` | `8.53%` |
| `r10_profit_guard40` | `+$1,000.97` | `39.61%` | `31.59%` | `3.4058` | `8.5240` | `42.3443` | `46` | `7.76%` |

## What We Learned

- Lowering `InpMinReducedRiskPercent` cut drawdown, but it also crushed profit and trade quality.
- Equity peak giveback quality gates made the account safer mostly by reducing trade count too much.
- Realized-profit giveback gates were no-ops at the tested thresholds.
- Daily equity trailing gave only a tiny profit improvement and did not reduce drawdown.
- Loss-risk scaling reduced drawdown while preserving more profit than the hard gates, but not enough for strict promotion.
- Profit giveback guard was the cleanest lower-drawdown fallback, with better PF/recovery/Sharpe and about `7.76%` Model4 drawdown.

## Future-Data Warning

These tests use 2024-01-01 through 2026-07-12. That period is now research-seen data. It is useful for recent-market fitness, but it does not prove the strategy will keep working without maintenance.

Before any money-ready label, the branch still needs:

- Frozen out-of-sample validation on data not used to choose settings.
- Walk-forward validation.
- Exported full MT5 reports, not only tester-log rows.
- Monte Carlo trade stress.
- Spread/slippage/commission/broker-variation stress.
- Demo or tiny-size forward testing.
- A rule for disabling or revalidating the bot if live performance drifts.

## Evidence Files

- Full Model1 sweep package: `outputs/peak_r20_drawdown_sweep_package`
- Full Model1 results: `outputs/PEAK_R20_DRAWDOWN_RESULTS.csv`
- Full Model1 metrics: `outputs/PEAK_R20_DRAWDOWN_REPORT_METRICS.md`
- Model4 shortlist package: `outputs/peak_r20_drawdown_shortlist_validation_package`
- Model4 shortlist results: `outputs/PEAK_R20_DRAWDOWN_SHORTLIST_MODEL4_RESULTS.csv`
- Model4 shortlist metrics: `outputs/PEAK_R20_DRAWDOWN_SHORTLIST_MODEL4_METRICS.md`
- OOS yearly summary: `outputs/PEAK_R20_OOS_YEARLY_SUMMARY.md`
- OOS yearly results: `outputs/PEAK_R20_OOS_YEARLY_RESULTS.csv`
- Builder: `work/build_peak_r20_drawdown_sweep_package.ps1`
- Shortlist builder: `work/build_peak_r20_drawdown_shortlist_validation_package.ps1`
