# RDMC Momentum Signal-Range Repair Contract

Frozen before generating or inspecting any signal-range-conditioned report for 2019 or 2022.

## Hypothesis

The multiscale momentum lane accepts a fresh H1 channel breakout even when the completed signal candle is small relative to current H1 ATR. Small breakout candles can represent weak range leakage rather than decisive momentum. An optional minimum completed signal-candle range, expressed in ATR units, is causal, date-independent, and known before entry.

The gate can only refuse a new momentum entry. It cannot add a trade, increase risk, widen a stop, alter an exit, or change the reversion lane. The parent D1 reversion cap, DI edge, portfolio controls, account locks, and real-account lock remain unchanged.

## Frozen Identity

- Research source SHA-256: `32DE39C13DBE06A6AE2BD733ED2183D7103C003884F08DD13024FDEE18BAD241`
- Parent profile SHA-256: `BC3ED745E8CEF680BF6785597044A7A24E488E1F45E498E1AC4EC7BCE3B5AEFC`
- Selection telemetry SHA-256: `B7828DF6F85C91660996F12051C8B1436941E597D761677D02E7D39E0978D3D1`
- Joined Model 4 selection ledger SHA-256: `2BA7856B36D144B57334037A2B1B2BD389E94495413549B6388465A52179B087`
- Bounded single-filter scan SHA-256: `64D99731455905B1E79F29658A79F5BDCB4832E2F56CC779E7AB436BDF11D4D3`

## Frozen Family

| Profile | Gate | Minimum completed H1 signal range |
| --- | --- | ---: |
| `srg_control` | Off | Parent behavior |
| `srg_min100` | On | 1.00 ATR |
| `srg_min125_center` | On | 1.25 ATR |
| `srg_min150` | On | 1.50 ATR |

The center is the rounded midpoint of two stable neighbors, not the highest-profit selection value. No threshold may move after the 2019 or 2022 reports are opened.

## Efficient Early Gate

Stage 1 uses Model 1 only on the already-known failure years 2019 and 2022. The family stops immediately unless:

1. The center is profitable in both years.
2. At least one adjacent threshold is also profitable in both years.
3. Each passing profile has at least 18 trades in each year.
4. The passing profile's combined 2019 plus 2022 net exceeds the unchanged control.

Only a Stage 1 pass may open Model 4 annual and continuous validation. Final promotion still requires every annual Model 4 window to be non-losing, continuous PF and drawdown no worse than the stability parent, adjacent-threshold support, cost stress, and Monte Carlo resilience.

This is a separate research lane. It does not alter the frozen forward candidate, its source/profile/binary identity, run label, evidence logs, account registration, or real-account lock.
