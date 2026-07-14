# LowATR R20 Opportunity Sweep Summary

Generated 2026-07-14 from hidden local MT5 tester-log evidence.

MT5 did not export full HTML/XML reports for this batch, so these rows are first-pass research evidence only. Log-parsed rows are enough to reject weak ideas and identify candidates for deeper validation, but they are not enough for live/trade-ready promotion.

## Decision

No new strict safe-best was promoted.

The current strict R20-style baseline remains safer on drawdown:

| Profile | Model | Window | Net | Ann. Return | CAGR | PF | Recovery | Trades | Max DD |
| --- | ---: | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `peak_r20_base` / `lowatr_exit_peak_r20` | 1 | 2024-01-01 to 2026-07-12 | +$464.86 | 18.40% | 16.31% | 6.7890 | 5.1411 | 7 | 5.81% |

The new aggressive research frontier is:

| Profile | Model | Window | Net | Ann. Return | CAGR | PF | Recovery | Trades | Max DD |
| --- | ---: | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `peak_r20_no_peaktrail_r10` | 1 | 2024-01-01 to 2026-07-12 | +$1,716.76 | 67.94% | 48.51% | 2.8655 | 7.5227 | 76 | 10.62% |
| `peak_r20_no_peaktrail_r10` | 4 | 2024-01-01 to 2026-07-12 | +$1,564.01 | 61.89% | 45.15% | 2.6874 | 7.1007 | 74 | 10.64% |

This is not trade-ready because drawdown is above the strict safety band and full exported reports are still missing.

## Yearly Split Check

`peak_r20_no_peaktrail_r10` stayed green in all Model1 yearly splits:

| Window | Net | Ann. Return | CAGR | PF | Recovery | Trades | Win Rate | Max Losses | Max DD |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 2024 full | +$814.43 | 81.50% | 81.52% | 4.6128 | 6.5506 | 26 | 65.38% | 3 | 8.85% |
| 2025 full | +$186.95 | 18.76% | 18.76% | 1.7478 | 1.5867 | 30 | 46.67% | 5 | 10.01% |
| 2026 YTD | +$246.96 | 46.98% | 52.18% | 4.6382 | 4.2557 | 18 | 53.33% | 5 | 4.88% |

Aggregate yearly split score: +$1,248.34. This is a validation-window score, not a sequential account return.

## What Was Rejected

| Probe Group | Result | Decision |
| --- | --- | --- |
| May day/spread relaxation | Same as baseline | Rejected as no-op |
| August risk restoration | Same as baseline | Rejected as no-op |
| ISLP May/August and broader ISLP months | Same as baseline | Rejected as no-op |
| FMLR strict/sweep/FVG-OB lanes | Same as baseline | Rejected as no-op |
| Broad all-month except December trading | Worse profit and/or much higher drawdown | Rejected |
| Two-confirmation broad all-month trading | Negative net with 35.38% drawdown | Rejected |
| Lower reduced-risk floor variants | Lower drawdown only by giving up too much profit | Rejected |
| No equity peak trail at original/floored risk | Much higher profit, but 10-14% drawdown | Research frontier only |

## Interpretation

The strict R20 profile was too small because the equity profit peak trail effectively froze the continuous account after early gains. Removing that blocker lets the strategy keep trading and produces much better profit and trade count, including a green 2025 split. The cost is higher drawdown.

Follow-up complete on 2026-07-14: `outputs/PEAK_R20_DRAWDOWN_SWEEP_SUMMARY.md` records a 22-variant R10 drawdown sweep plus a 5-profile Model4 shortlist. The best lower-drawdown fallback was `r10_profit_guard40`, which made `+$1,000.97` on Model4 with `7.76%` drawdown, PF `3.4058`, and recovery `8.5240`. The best high-profit branch still has about `10.6%` drawdown. No trade-ready profile was promoted.

The next useful work is not to raise risk. It is to validate the lower-drawdown fallback and/or make a strategy-code/risk-shape change that preserves later-year participation while cutting the 2025 drawdown path.

## Artifacts

- Full sweep results: `outputs/LOWATR_R20_OPPORTUNITY_RESULTS.csv`
- Sweep metrics: `outputs/LOWATR_R20_OPPORTUNITY_REPORT_METRICS.md`
- Yearly split results: `outputs/PEAK_R20_NO_PEAKTRAIL_R10_SPLIT_RESULTS.csv`
- Yearly split metrics: `outputs/PEAK_R20_NO_PEAKTRAIL_R10_SPLIT_REPORT_METRICS.md`
- Model4 continuous result: `outputs/PEAK_R20_NO_PEAKTRAIL_R10_MODEL4_RESULTS.csv`
- Model4 metrics: `outputs/PEAK_R20_NO_PEAKTRAIL_R10_MODEL4_REPORT_METRICS.md`
- R10 drawdown sweep summary: `outputs/PEAK_R20_DRAWDOWN_SWEEP_SUMMARY.md`
- R10 drawdown Model1 results: `outputs/PEAK_R20_DRAWDOWN_RESULTS.csv`
- R10 drawdown Model4 shortlist results: `outputs/PEAK_R20_DRAWDOWN_SHORTLIST_MODEL4_RESULTS.csv`
- Candidate profile: `outputs/lowatr_r20_opportunity_sweep_package/profiles/peak_r20_no_peaktrail_r10.set`
