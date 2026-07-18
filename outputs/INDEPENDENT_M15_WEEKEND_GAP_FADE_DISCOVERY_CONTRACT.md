# Independent M15 Weekend-Gap Fade Discovery Contract

Frozen before source implementation or any tester result was inspected on 2026-07-17.

## Research question

Does XAUUSD exhibit a durable, independently useful mean-reversion edge after the Friday close to the first broker week-open M15 bar, without date-specific rules, recovery sizing, grid logic, or averaging down?

This is a separate research lane. It does not change the registered forward candidate, its source/profile/binary identity, its evidence log, its run label, or the real-account lock.

## Fixed strategy shape

- Signal timeframe: M15.
- Volatility reference: completed D1 ATR(14).
- Event: the completed first M15 bar after a Friday-to-Sunday/Monday pause of at least 24 hours.
- Direction: fade the opening gap toward the final pre-weekend M15 close.
- Confirmation: the first bar must move toward the prior close by a configurable fraction of the original gap without already filling it.
- Target: exact prior-week final M15 close, adjusted only for broker stop-distance validity.
- Stop: beyond the first week-open bar extreme plus a completed-D1-ATR buffer.
- Entry limit: at most one evaluation and one trade per detected weekend event.
- Position limit: one managed position and no other account position at entry.
- Time exit: 48 M15 bars.
- Risk: 0.10% of current equity calculated with `OrderCalcProfit`; never force the broker minimum lot.
- Maximum lots: 1.00.
- Maximum equity drawdown stop: 5.00%.
- Maximum daily loss: 0.75%.
- Maximum consecutive losses: 3 with a 168-hour cooldown.
- Real-account trading: disabled by default and protected by a hard safety lock.

## Frozen neighborhood

The center is `wgf_center`: minimum gap 0.08 D1 ATR, maximum gap 0.50 D1 ATR, minimum confirmation 0.15, maximum confirmation 0.80, stop buffer 0.03 D1 ATR, and minimum target-to-stop RR 1.15.

Six one-axis neighbors surround the center:

| Profile | Changed input |
|---|---:|
| `wgf_gap005` | Minimum gap 0.05 D1 ATR |
| `wgf_gap012` | Minimum gap 0.12 D1 ATR |
| `wgf_confirm000` | Minimum confirmation 0.00 |
| `wgf_confirm030` | Minimum confirmation 0.30 |
| `wgf_maxgap035` | Maximum gap 0.35 D1 ATR |
| `wgf_maxgap065` | Maximum gap 0.65 D1 ATR |

No additional variant may be introduced after results are visible in this discovery run.

## Locked discovery data

Model 1 is used only as a fast rejection screen on:

- `older_2015_2018`: 2015-01-01 through 2018-12-31.
- `repair_2019_2020`: 2019-01-01 through 2020-12-31.
- `continuous_2015_2020`: 2015-01-01 through 2020-12-31.

No data after 2020 may be tested until the discovery gate passes.

## Frozen discovery gate

A profile is eligible only if all conditions pass:

1. Source, profile, run-label, and report identities match exactly.
2. Net profit is positive in both disjoint eras.
3. Continuous profit factor is at least 1.20.
4. Continuous trades are at least 40.
5. Continuous relative equity drawdown is at most 2.50% at 0.10% risk.
6. Continuous expected payoff is positive and return-to-drawdown is at least 1.00.
7. At least one directly adjacent profile also passes conditions 1 through 6.

Any losing broad era rejects the profile. A single isolated winner rejects the family. No profile is promoted by aggregate net profit alone.

## Holdout and precision policy

Only exact eligible profiles may open two disjoint Model 1 holdouts: 2021-2023 and 2024-2026. Both must be profitable; combined holdout PF must be at least 1.20, combined trades at least 35, and maximum holdout DD at most 3.00%. Deterministic spread/cost stress must pass before any Model 4 confirmation. Model 4 real ticks are required before the family can be considered for portfolio use.

This discovery cannot make an EA money-ready or authorize real trading. It can only reject the family or earn the next validation stage.
