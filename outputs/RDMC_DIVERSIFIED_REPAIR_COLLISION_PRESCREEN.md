# RDMC Diversified Repair Collision Pre-Screen

**Status: POSTHOC_COLLISION_GATE_PASS_NOT_A_NEW_BEST. This remains post-hoc and cannot promote the combined EA.**

The replay applies the frozen source order (MTSM, primary R20/DGF, capped RRO, then independent DDB) and permits only one open account position. A standalone trade whose entry occurs before the accepted trade exits is marked blocked and contributes no profit or loss.

- Collision-adjusted net: `$+2,067.64`; PF `1.8942`; accepted `368`; blocked `8`
- Positive annual/YTD windows: `12 / 12`; minimum window net `$+40.53`
- Broad nets: older `$+687.51`, middle `$+650.83`, recent `$+729.30`
- Approximate closed-trade drawdown on `$10,000`: `$100.48` / `0.8658%`
- Across all 24 lane-priority permutations: best `$+2,067.64`, worst `$+2,067.64`, minimum positive windows `12 / 12`

| Window | Adjusted net | PF | Accepted | Blocked | Blocked opportunity net | Positive |
|---|---:|---:|---:|---:|---:|---|
| `2015` | $+139.40 | 2.3667 | 18 | 4 | $+48.86 | True |
| `2016` | $+214.49 | 2.0952 | 36 | 0 | $+0.00 | True |
| `2017` | $+144.93 | 1.4342 | 46 | 0 | $+0.00 | True |
| `2018` | $+188.69 | 1.8094 | 47 | 3 | $+95.75 | True |
| `2019` | $+40.53 | 1.2384 | 33 | 1 | $+4.88 | True |
| `2020` | $+143.14 | 1.6950 | 27 | 0 | $+0.00 | True |
| `2021` | $+413.63 | 2.6294 | 33 | 0 | $+0.00 | True |
| `2022` | $+53.53 | 1.1824 | 44 | 0 | $+0.00 | True |
| `2023` | $+232.63 | 1.9552 | 42 | 0 | $+0.00 | True |
| `2024` | $+220.93 | 1.8349 | 34 | 0 | $+0.00 | True |
| `2025` | $+66.56 | 5.1941 | 6 | 0 | $+0.00 | True |
| `2026_ytd` | $+209.18 | INF | 2 | 0 | $+0.00 | True |

## Blocked Trades By Lane

| Blocked lane | Trades | Opportunity net removed |
|---|---:|---:|
| `MTSM_CAP12_ANNUAL` | 2 | $-13.24 |
| `R20_CURRENT_SOURCE_ANNUAL` | 0 | $+0.00 |
| `RRO_DI12_CAP12_CONTINUOUS` | 5 | $+157.85 |
| `DDB045_ANNUAL_RESTART` | 1 | $+4.88 |

## Collision Pairs

| Active lane | Blocked lane | Trades | Blocked opportunity net |
|---|---|---:|---:|
| `DDB045_ANNUAL_RESTART` | `MTSM_CAP12_ANNUAL` | 2 | $-13.24 |
| `DDB045_ANNUAL_RESTART` | `RRO_DI12_CAP12_CONTINUOUS` | 3 | $+45.10 |
| `MTSM_CAP12_ANNUAL` | `DDB045_ANNUAL_RESTART` | 1 | $+4.88 |
| `MTSM_CAP12_ANNUAL` | `RRO_DI12_CAP12_CONTINUOUS` | 2 | $+112.75 |

## Hard Boundary

- This replay uses historical standalone trades. Blocking an entry changes cooldowns, daily limits, monthly caps, and future signals, so later ledger rows are not a valid executable path.
- Component reports came from different source versions and starting balances. Raw observed dollar P/L is retained without rescaling.
- Intrabar order timing, spread, slippage, margin, equity-based lot sizing, and open drawdown are not recomputed.
- Failure years were already inspected when this architecture was selected. This is not untouched out-of-sample evidence.
- Only a clean compile and frozen MT5 Model1/Model4 runs can establish a combined result. The registered forward candidate remains unchanged and real-money trading remains locked.
