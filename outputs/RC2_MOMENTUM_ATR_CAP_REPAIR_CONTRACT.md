# RC2 Momentum ATR-Cap Repair Contract

Frozen before any 2019-2020 report for this family was generated or inspected.

## Hypothesis

The RC2 momentum lane accepts H1 breakouts across an extremely broad ATR/price range. Behavior-preserving telemetry on 2015-2018 found that unusually high H1 ATR regimes carried weak aggregate expectancy, while rounded neighboring upper bounds retained positive results in every selection year. A maximum entry ATR percentage is causal, date-independent, known on the completed signal bar, and already enforced by the released strategy's volatility-regime code.

The reversion lane, entries, exits, stops, targets, sizing, account locks, exposure cap, and all portfolio loss controls remain unchanged. The filter can only refuse a new momentum entry. It cannot add a trade, increase risk, widen a stop, or change position management.

## Frozen Profiles

All profiles use exact RC2 source SHA-256 `9141137A9550F3394DE85E1725E018671B4F2A2FF0F43A3EF23F9FB1238CD302`, `0.45%` reversion risk, `0.15%` momentum risk, and the `0.75%` shared open-risk cap.

| Profile | Maximum momentum H1 ATR/price |
|---|---:|
| `mac_fixed_control` | 2.50% |
| `mac_cap024` | 0.24% |
| `mac_cap026` | 0.26% |
| `mac_cap028` | 0.28% |

The center and neighbors were rounded and frozen from the 2015-2018 telemetry result. No value may move after the repair window is opened.

## Repair Gate

Model 1 runs cover disjoint 2019-2020 and continuous 2015-2020. Post-2020 data remains closed unless a non-control profile passes every gate:

1. Exact source, profile, and contract identities in all reports.
2. Positive net profit in 2019-2020.
3. Continuous PF at least `1.45`, at least `180` trades, and maximum equity drawdown no more than `2.80%`.
4. Continuous net profit at least as high as the fixed control, with drawdown no worse than `10%` above control.
5. At least one adjacent ATR cap independently passes gates 2-4.

Only qualifying profiles may enter the untouched 2021-2026 YTD Model 1 holdout. Model 4, annual restart, cost, and Monte Carlo validation remain closed until that holdout passes.

This is a separate research lane. The frozen forward candidate, registered source/profile/binary identities, run label, evidence logs, invalid account attachment, and real-account lock are unchanged.
