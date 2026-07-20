# Strong-Breakout Target Extension Discovery Contract

**Status: FROZEN BEFORE RUNNING THE NEW TARGET-EXTENSION CODE. THIS IS NOT A PROMOTION OR LIVE APPROVAL.**

## Hypothesis

The existing momentum lane enters fresh completed-H1 breakouts with a fixed `2.0R` target. A breakout candle that closes directionally near its extreme with a large real body may have enough follow-through to justify a farther target without changing the entry, initial stop, position risk, or account-wide exposure.

The default-off center uses:

- completed H1 body / range at least `0.50`;
- directional completed H1 close location at least `0.75`;
- strong-breakout target `3.0R` instead of `2.0R`;
- unchanged `0.15%` momentum risk and `0.75%` account-wide open-risk cap.

The source may read only completed bar `1`. It may not add an entry, close, stop-modification, sizing, averaging, grid, martingale, recovery, calendar, funding, forward-substitution, or real-account path. When disabled, it must reproduce the exact published leader.

## Frozen Neighborhood

| Profile | Body minimum | Close-location minimum | Strong target |
|---|---:|---:|---:|
| Disabled control | - | - | `2.0R` |
| Lower target | `0.50` | `0.75` | `2.5R` |
| **Center** | **`0.50`** | **`0.75`** | **`3.0R`** |
| Upper target | `0.50` | `0.75` | `3.5R` |
| Lower body | `0.45` | `0.75` | `3.0R` |
| Upper body | `0.55` | `0.75` | `3.0R` |
| Lower close | `0.50` | `0.70` | `3.0R` |
| Upper close | `0.50` | `0.80` | `3.0R` |

## Discovery Data And Gate

Model 1, XAUUSD M15, `$10,000`, exact leader profile. Use `2015-2018`, `2019-2020`, and continuous `2015-2020`. These years are consumed research data and are not described as pristine out-of-sample evidence.

The center may open reserved `2021-2022` Model 1 validation only if:

1. every report is profitable and identity-valid;
2. the disabled control reproduces the exact leader behavior;
3. the center changes behavior and is no worse than control in both disjoint discovery eras;
4. continuous center net is at least `3%` above control and CAGR is at least `0.05` percentage point higher;
5. center PF is at least `97%` of control, recovery and return/drawdown are each at least `95%` of control;
6. center drawdown is no more than control plus `0.20` percentage point and no more than `1.30%`;
7. center retains at least `98%` of control trades; and
8. at least three of six one-factor neighbors independently satisfy the era, growth, PF, drawdown, recovery, return/drawdown, and activity requirements.

Failure closes this family without moving thresholds or opening post-2020 data. A discovery pass permits only frozen `2021-2022` Model 1 validation; it does not permit Model 4, promotion, forward replacement, or real-account trading.
