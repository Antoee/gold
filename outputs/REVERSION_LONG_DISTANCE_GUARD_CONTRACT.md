# Reversion Long-Distance Guard Contract

Frozen before any 2019-2020 report for this source or profile family was generated or inspected.

## Hypothesis

The exact RC2 weak-era loss is concentrated in the H1 Band/VWAP reversion lane: 2019-2020 momentum made `+$147.65`, while reversion lost `-$264.23` on 10 trades with nine stop-outs. A mean-reversion entry taken extremely far against the completed H1 200-bar average is more likely to be a continuation regime than a temporary excursion.

The guard measures completed-bar close minus the prior 200 completed H1 closes, normalizes by completed H1 ATR(14), and signs the distance in the proposed trade direction. It can only refuse a new reversion entry. Momentum, all existing reversion conditions, stops, targets, sizing, exits, account locks, exposure limits, and portfolio loss controls remain unchanged. It has no date, month, year, outcome, or future-bar input.

## Frozen Identities

- Research source SHA-256: `7E8D680807B0565992ECC9B98E15C636A86AF34742194687DBB64D61CE2EFD7A`
- Research binary SHA-256: `F97E596B4981E75FBB27146EEBCAC72854B08E7E4CE81C6AA0E84B84E0BFC776`
- Base RC2 source SHA-256: `9141137A9550F3394DE85E1725E018671B4F2A2FF0F43A3EF23F9FB1238CD302`
- Compile result: `0 errors, 0 warnings`

## Selection Evidence

Behavior-preserving telemetry used 2015-2018 only. The unchanged reversion lane made `+$374.62`, PF `2.97`, on 17 trades. Rounded lower bounds of `-12`, `-10`, and `-8 ATR` made `+$408.52`, `+$431.92`, and `+$394.62`, respectively; every setting remained profitable in each selection year.

## Frozen Profiles

| Profile | Guard | Minimum aligned distance | Lookback |
|---|---|---:|---:|
| `rld_fixed_control` | off | n/a | 200 H1 bars |
| `rld_m12` | on | -12 ATR | 200 H1 bars |
| `rld_m10` | on | -10 ATR | 200 H1 bars |
| `rld_m8` | on | -8 ATR | 200 H1 bars |

All profiles retain `0.45%` reversion risk, `0.15%` momentum risk, and the `0.75%` shared open-risk cap.

## Repair Gate

Model 1 runs cover disjoint 2019-2020 and continuous 2015-2020. Post-2020 data remains closed unless a non-control profile passes every gate:

1. Exact source, profile, and contract identities in every report.
2. Positive net profit in 2019-2020.
3. Continuous PF at least `1.45`, at least `180` trades, and maximum equity drawdown no more than `2.80%`.
4. Continuous net profit at least as high as the fixed control, with drawdown no worse than the control.
5. At least one adjacent guard threshold independently passes gates 2-4.

Only repair-eligible profiles may enter separately reported 2021-2023 and 2024-2026 YTD Model 1 holdouts. Both holdout eras must be profitable before Model 4, annual restart, cost, and Monte Carlo validation can open.

No threshold may move after the repair result. This is a separate research lane; the frozen forward candidate, registration, profile, binary, run label, evidence logs, invalid account attachment, and real-account lock remain unchanged.
