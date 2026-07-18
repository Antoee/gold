# RDMC Diversified Repair Offline Pre-Screen

**Status: POSTHOC_ARCHITECTURE_GATE_PASS_NOT_A_NEW_BEST. No combined EA or MT5 result exists.**

The screen replaces the weak signal-range repair with four historical components: annual Model4 MTSM trades from the cap candidate, DI `-12` RC2 reversion trades filtered by the completed-D1 `12%` cap, annual DDB045 restart trades, and the exact R20 current-source annual report stream.

- Projected aggregate net: `$+2,217.13`; PF `1.9330`; trades `376`
- Positive annual/YTD windows: `12 / 12`
- Minimum projected annual net: `$+45.41`; minimum finite PF `1.1824`
- Daily cache SHA-256: `7DAE08D3C1FFBA81E74C31C4AFC1C3B4774EFCDC9BC0F9F45490690A18F5FBA2`; selection alignment `17 / 17`, maximum error `0.000000482`
- Exact R20 source SHA-256: `2219F6AE66CF1121972848C118213B50C01F91E783ABFE6D66F75105C655EB4D`; profile SHA-256: `3E6B806E2941A993579756C8E503B7886E06891F077A104D39428704E48545BC`

| Window | Momentum | DI12 + cap12 RRO | DDB045 | R20 | Post-hoc net | PF | Trades |
|---|---:|---:|---:|---:|---:|---:|---:|
| `2015` | $+64.76 | $+90.31 | $+33.19 | $+0.00 | $+188.26 | 2.2615 | 22 |
| `2016` | $+74.49 | $+140.00 | $+0.00 | $+0.00 | $+214.49 | 2.0952 | 36 |
| `2017` | $+125.25 | $+19.68 | $+0.00 | $+0.00 | $+144.93 | 1.4342 | 46 |
| `2018` | $+125.56 | $+177.59 | $-18.71 | $+0.00 | $+284.44 | 2.1372 | 50 |
| `2019` | $-3.77 | $+0.00 | $+4.88 | $+44.30 | $+45.41 | 1.2671 | 34 |
| `2020` | $+119.12 | $+46.94 | $+0.00 | $-22.92 | $+143.14 | 1.6950 | 27 |
| `2021` | $-111.56 | $+448.73 | $+0.00 | $+76.46 | $+413.63 | 2.6294 | 33 |
| `2022` | $-71.78 | $+88.00 | $+0.00 | $+37.31 | $+53.53 | 1.1824 | 44 |
| `2023` | $-5.70 | $+174.33 | $+0.00 | $+64.00 | $+232.63 | 1.9552 | 42 |
| `2024` | $+136.73 | $+68.41 | $+0.00 | $+15.79 | $+220.93 | 1.8349 | 34 |
| `2025` | $+17.78 | $+0.00 | $+0.00 | $+48.78 | $+66.56 | 5.1941 | 6 |
| `2026_ytd` | $+0.00 | $+209.18 | $+0.00 | $+0.00 | $+209.18 | INF | 2 |

## Hard Boundary

- This is a union of observed trades, not a combined executable or a recomputed equity curve.
- Filtering RC2 reversion trades can expose later entries, so the DI12 plus D1-cap path must be rerun in MT5.
- R20 reports used a `$1,000` starting deposit while the other components used `$10,000`; absolute trade P/L is retained without scaling. A new `$10,000` risk contract must be tested.
- Simultaneous positions, account-wide open-risk limits, daily-loss controls, margin, and drawdown interactions are not modeled.
- R20 contributes tested evidence only from 2019 through 2026 YTD; no zero-trade claim is made for 2015-2018.
- The failure years were inspected while choosing this architecture, so this is not untouched out-of-sample evidence.

The result only justifies freezing a combined source/profile and opening a small annual MT5 gate. It does not alter the registered forward candidate. The invalid `$100,000` demo still contributes zero evidence, and real-money trading remains locked.
