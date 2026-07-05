# Robust Candidate Ranking

Generated from existing summary CSV files only. No MT5 test was launched.

Scoring favors net profit, but heavily penalizes losing windows, negative worst-window results, and thin validation coverage. Promotion candidates require at least 7 windows.

## Top Promotion Candidates

| Rank | Candidate | Source | Score | Total | Worst | Losing | Windows |
| ---: | --- | --- | ---: | ---: | ---: | ---: | ---: |
| 1 | `BOS_SWEEP_SPLIT_SUMMARY_risk1p6_sl18_tp35` | `BOS_SWEEP_SPLIT_SUMMARY_risk1p6_sl18_tp35.csv` | 2396.65 | 2354.65 | 0 | 0 | 9 |
| 2 | `BOS_SWEEP_SPLIT_SUMMARY_risk2` | `BOS_SWEEP_SPLIT_SUMMARY_risk2.csv` | 983.16 | 965.16 | 0 | 0 | 9 |
| 3 | `risk160_sl16_tp38` | `RISK16_NEIGHBORHOOD_SUMMARY.csv` | 808 | 798 | 0 | 0 | 7 |
| 4 | `risk160_sl18_tp38` | `RISK16_NEIGHBORHOOD_SUMMARY.csv` | 808 | 798 | 0 | 0 | 7 |
| 5 | `risk170_sl18_tp35` | `RISK16_NEIGHBORHOOD_SUMMARY.csv` | 795.49 | 785.49 | 0 | 0 | 7 |
| 6 | `risk165_sl18_tp35` | `RISK16_NEIGHBORHOOD_SUMMARY.csv` | 767.1 | 757.1 | 0 | 0 | 7 |
| 7 | `base_risk160_sl18_tp35` | `RISK16_NEIGHBORHOOD_SUMMARY.csv` | 754.03 | 744.03 | 0 | 0 | 7 |
| 8 | `risk160_sl16_tp35` | `RISK16_NEIGHBORHOOD_SUMMARY.csv` | 754.03 | 744.03 | 0 | 0 | 7 |
| 9 | `risk160_sl17_tp35` | `RISK16_NEIGHBORHOOD_SUMMARY.csv` | 754.03 | 744.03 | 0 | 0 | 7 |
| 10 | `quarter` | `BOS_SWEEP_WINDOW_SUMMARY_risk1p6_sl18_tp35.csv` | 748.03 | 744.03 | 0 | 0 | 10 |

## Top Research Candidates

| Rank | Candidate | Source | Score | Total | Worst | Losing | Windows |
| ---: | --- | --- | ---: | ---: | ---: | ---: | ---: |
| 21 | `MOMENTUM_SWEEP_SPLIT_SUMMARY` | `MOMENTUM_SWEEP_SPLIT_SUMMARY.csv` | 1131.57 | 2113.53 | -15.49 | 1 | 9 |
| 22 | `DATE_BUY_BLOCK_STANDARD_REAL_TICK_SUMMARY` | `DATE_BUY_BLOCK_STANDARD_REAL_TICK_SUMMARY.csv` | 577.16 | 2037.16 | 0 | 1 | 5 |
| 23 | `BOS_SWEEP_SPLIT_SUMMARY_risk1p5_sl18_tp35` | `BOS_SWEEP_SPLIT_SUMMARY_risk1p5_sl18_tp35.csv` | -15.17 | 1536.79 | -148.99 | 1 | 9 |
| 24 | `BOS_SWEEP_SPLIT_SUMMARY_risk1p5` | `BOS_SWEEP_SPLIT_SUMMARY_risk1p5.csv` | -192.72 | 1362.32 | -149.76 | 1 | 9 |
| 25 | `BOS_SWEEP_SPLIT_SUMMARY_risk1` | `BOS_SWEEP_SPLIT_SUMMARY_risk1.csv` | -432.72 | 922.64 | -99.84 | 1 | 9 |
| 26 | `sl18_tp35` | `ROBUST_PROFILE_VARIANT_SUMMARY.csv` | -1025.54 | 355.54 | -98.27 | 1 | 7 |
| 27 | `quarter` | `BOS_SWEEP_WINDOW_SUMMARY.csv` | -1036.3 | 157.38 | -49.92 | 1 | 10 |
| 28 | `risk160_sl19_tp35` | `RISK16_NEIGHBORHOOD_SUMMARY.csv` | -1038.37 | 585.15 | -158.88 | 1 | 7 |
| 29 | `sl18_tp35` | `BOS_SWEEP_PROFIT_EXTENSION_SUMMARY.csv` | -1043.45 | 540.51 | -148.99 | 1 | 7 |
| 30 | `quarter` | `BOS_SWEEP_WINDOW_SUMMARY_risk1p5_sl18_tp35.csv` | -1049.45 | 540.51 | -148.99 | 1 | 10 |

## Recommended Next Action

Validate only the highest-ranked promotion candidates across monthly, quarterly, yearly, half-year, and full-period windows once local MT5 can run without affecting normal PC use.
