# Independent Opening-Range Breakout Discovery Decision

**Decision: reject every tested opening-range breakout variant. Do not open the 2021-2026 holdout.**

Six date-independent XAUUSD M15 opening-range breakout shapes were screened on discovery data only. The first era covered 2015-2018 and the second covered 2019-2020. Promotion required both disjoint eras to be profitable, PF of at least `1.20`, at least `30` continuous trades, drawdown no higher than `5%`, and support from a neighboring profitable shape.

| Candidate | 2015-2018 net | PF | 2019-2020 net | PF | Continuous net | PF | Trades | Max DD | Decision |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| `orb_london_adx18` | `-$160.44` | `0.86` | `-$522.85` | `0.33` | `-$160.44` | `0.86` | `23` | `6.14%` | Reject |
| `orb_london_noadx` | `+$178.20` | `1.09` | `-$458.03` | `0.42` | `+$178.20` | `1.09` | `43` | `5.04%` | Reject |
| `orb_london_adx18_body35` | `+$45.95` | `1.03` | `-$522.85` | `0.33` | `+$45.95` | `1.03` | `35` | `5.70%` | Reject |
| `orb_newyork_adx18` | `-$577.56` | `0.00` | `-$233.94` | `0.68` | `-$577.56` | `0.00` | `6` | `5.78%` | Reject |
| `orb_dual_adx18` | `-$497.42` | `0.22` | `-$265.72` | `0.74` | `-$497.42` | `0.22` | `9` | `5.83%` | Reject |
| `orb_dual_adx18_volume` | `-$545.96` | `0.47` | `-$495.27` | `0.48` | `-$545.96` | `0.47` | `18` | `5.46%` | Reject |

All six candidates lost money in the independent 2019-2020 discovery era. None reached the minimum PF gate in both eras, and every continuous run exceeded the `5%` permanent review-lock threshold. The continuous rows therefore stopped accepting entries after the lock and must not be read as complete 2015-2020 account paths.

The strategy remains a standalone experimental source only. No recent holdout, Model 4, cost-stress, or Monte Carlo testing is justified.

## Exact Evidence

- Source: `work/Independent_XAUUSD_Opening_Range_Breakout.mq5`
- Source SHA-256: `EF81808036448D5969BC3C16E12F0304EBBE0220D8DC02A751B2AE446AC029EF`
- Model 1 results: `outputs/INDEPENDENT_ORB_DISCOVERY_MODEL1_RESULTS.csv`
- Package manifest: `outputs/INDEPENDENT_ORB_DISCOVERY_MODEL1_PACKAGE_MANIFEST.csv`
- Compile result: `0 errors, 0 warnings`
- Reports parsed: `18 / 18`

This rejection preserves 2021-2026 as untouched evidence for a future independent strategy.
