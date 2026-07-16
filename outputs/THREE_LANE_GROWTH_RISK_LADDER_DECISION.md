# Three-Lane Growth Risk Ladder Decision

**Decision: keep the frozen 0.50% stability control. No higher-risk profile is promoted.**

The exact three-lane source and DDB `0.45x` profile were tested at four base-risk levels. Entry logic, exit logic, lane allocation, and calendar behavior were unchanged. Effective-risk and account-wide open-risk caps were raised only enough to permit each declared level.

| Candidate | Base risk | Continuous net | Annualized | CAGR | PF | Trades | Max DD | Recovery | Decision |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| `three_lane_risk050` | `0.50%` | `+$545.91` | `+0.47%/yr` | `+0.46%/yr` | `2.83` | `57` | `0.77%` | `6.79` | Keep control |
| `three_lane_risk065` | `0.65%` | `+$488.96` | `+0.42%/yr` | `+0.41%/yr` | `2.18` | `61` | `0.79%` | `5.95` | Dominated |
| `three_lane_risk080` | `0.80%` | `+$229.61` | `+0.20%/yr` | `+0.20%/yr` | `5.37` | `8` | `1.03%` | `2.15` | Profit-trail lock |
| `three_lane_risk100` | `1.00%` | `+$252.72` | `+0.22%/yr` | `+0.22%/yr` | `3.54` | `11` | `1.08%` | `2.25` | Profit-trail lock |

All four broad eras remained positive, but returns did not scale with risk. At `0.80%` and `1.00%`, the account reached the equity-profit protection threshold early, gave back enough to trigger the permanent review lock, and correctly stopped accepting entries. Disabling or loosening that safeguard solely to increase backtest profit is rejected.

The `0.65%` neighbor remained active but earned less with worse PF, drawdown, and recovery than the `0.50%` control. No higher-risk candidate justified annual or Model 4 promotion.

## Exact Evidence

- Source SHA-256: `45B3D0704CFAD1B30E1E5E4C7C7079B6188A674546F8F2EB70DC72BF1A97EF90`
- Frozen DDB045 profile SHA-256: `2E02246D24250D71DEC59A42AD1D7DE793614EBECEB309A879FE873D8F886312`
- Model 1 results: `outputs/THREE_LANE_GROWTH_RISK_LADDER_MODEL1_RESULTS.csv`
- Compile result: `0 errors, 0 warnings`

This experiment improves confidence in the stability control but does not solve its low activity or low annual return. It remains a demo-forward research candidate, not a money-ready bot.
