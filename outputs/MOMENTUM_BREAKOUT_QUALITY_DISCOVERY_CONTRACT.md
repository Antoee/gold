# Momentum Breakout Quality Discovery Contract

Frozen before any new tester report was generated or inspected.

## Objective

Test whether completed-H1-bar price action can improve the existing multiscale momentum lane without changing the reversion lane, exits, stops, targets, risk, schedule, or portfolio safety controls. The filter uses no calendar exclusions and no future bar.

## Source Change

The unchanged signal still requires 126-day directional momentum and a fresh close beyond the prior 20 completed H1 bars. Optional entry quality then requires:

- a candle body aligned with the breakout direction;
- minimum real-body percentage of the H1 range;
- minimum directional close location within the H1 range;
- minimum H1 range relative to completed-bar ATR(20);
- optionally, completed-bar tick volume relative to the prior 20 completed H1 bars.

The filter can only refuse a new momentum entry. It cannot add a trade, increase size, widen a stop, delay a protective exit, or alter the reversion lane.

## Frozen Discovery Profiles

All profiles keep reversion risk at `0.45%`, momentum risk at `0.15%`, and shared open-risk cap at `0.75%`.

| Profile | Body | Directional close | Range/ATR | Tick-volume ratio |
|---|---:|---:|---:|---:|
| `mbq_fixed_control` | off | off | off | off |
| `mbq_price_loose` | 25% | 0.58 | 0.35 | off |
| `mbq_price_center` | 35% | 0.65 | 0.50 | off |
| `mbq_price_strict` | 45% | 0.72 | 0.65 | off |
| `mbq_center_vol090` | 35% | 0.65 | 0.50 | 0.90 |
| `mbq_center_vol100` | 35% | 0.65 | 0.50 | 1.00 |
| `mbq_center_vol110` | 35% | 0.65 | 0.50 | 1.10 |

## Discovery Data and Gate

Model1 only, with three separately reported windows: 2015-2018, 2019-2020, and continuous 2015-2020. No post-2020 report may be generated unless a non-control profile passes every gate:

1. Exact source and profile identities in every report.
2. Positive net in both 2015-2018 and 2019-2020.
3. Continuous PF at least `1.45`, at least `150` trades, and equity drawdown no more than `2.80%`.
4. Continuous net at least `85%` of the fixed control.
5. Either return/drawdown at least `5%` better than control, or continuous PF at least `0.05` above control with drawdown no worse than control.
6. At least one adjacent non-control profile passes gates 2-5.

Adjacency is frozen as loose-center-strict for price thresholds and 0.90-1.00-1.10 for volume thresholds. A lone winner is rejected.

## Later Validation

Only discovery-eligible profiles may enter disjoint 2021-2023 and 2024-2026 YTD Model1 holdout. Both holdout eras must be profitable, combined holdout PF must be at least `1.20`, and no profile may be promoted from recent-period profit alone. Model4, annual restart, cost, bootstrap, and second-broker work remain closed until the holdout passes.

This is research only. The frozen forward candidate, forward registration, account contract, evidence logs, binary identity, and real-account lock remain unchanged.
