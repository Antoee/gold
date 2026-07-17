# Transferable Portfolio Forward-Test Candidate

**Decision: forward-test candidate; real-account trading remains disabled.**

This is the exact combined MT5 EA for the date-independent H1 Band/VWAP reversion lane and the diversifying E20 multiscale-momentum lane. It is the strongest balanced executable candidate currently reproduced on real ticks, but it is not a promise of future profit or an approval to fund a live account.

## Frozen Identity

- Source SHA-256: `5BADDE1BC7C1E8020E64F00793058AD5C6174370A866F5D3002FA1FA12248FC3`
- Profile SHA-256: `ECBD1693D09AF6A04CB92F2756442DF8BF0B604118834D1C5E0F50CC57FFEC3E`
- Model4 ledger SHA-256: `2F7A8A8854F8F33325498AE0F194202E7BB15F28F2644FC4F9B08DE8B740413B`
- Continuous report SHA-256: `2354EAD1526FA308211BF9E09167200BFC87313F3575E995A6D2C5B2A116BFFE`
- Real-account trading default: `false` with explicit safety lock and approval code required
- Requested risk: `0.45%` reversion + `0.15%` momentum; shared open-risk cap `0.75%`

## Continuous Model4

| Window | Start | Net | Total return | CAGR | PF | Trades | Max equity DD | Recovery |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| 2015-01-01 to 2026-07-16 | $10,000 | $1,615.36 | 16.15% | 1.31% | 1.58 | 362 | 2.83% | 5.22 |

Model1 and Model4 both reproduce every independent lane entry and exit. Model4 changed the expected count from 370 to 362 but kept net nearly unchanged (`+$1,615.36` versus `+$1,616.49`) and reduced reported equity drawdown from `3.24%` to `2.83%`.

## Annual Returns

| Year | Trades | Start | Net | End | Return | PF |
|---|---:|---:|---:|---:|---:|---:|
| 2015 | 21 | $10,000.00 | $155.07 | $10,155.07 | 1.551% | 2.039 |
| 2016 | 36 | $10,155.07 | $209.32 | $10,364.39 | 2.061% | 2.041 |
| 2017 | 46 | $10,364.39 | $170.94 | $10,535.33 | 1.649% | 1.507 |
| 2018 | 50 | $10,535.33 | $270.77 | $10,806.10 | 2.570% | 2.028 |
| 2019 | 33 | $10,806.10 | $-38.30 | $10,767.80 | -0.354% | 0.825 |
| 2020 | 31 | $10,767.80 | $-44.44 | $10,723.36 | -0.413% | 0.891 |
| 2021 | 30 | $10,723.36 | $359.78 | $11,083.14 | 3.355% | 2.500 |
| 2022 | 36 | $11,083.14 | $40.07 | $11,123.21 | 0.362% | 1.170 |
| 2023 | 40 | $11,123.21 | $144.99 | $11,268.20 | 1.303% | 1.492 |
| 2024 | 31 | $11,268.20 | $132.90 | $11,401.10 | 1.179% | 1.452 |
| 2025 | 6 | $11,401.10 | $5.08 | $11,406.18 | 0.045% | 1.042 |
| 2026 | 2 | $11,406.18 | $209.18 | $11,615.36 | 1.834% | INF |

Broad-era net is positive:
- `2015-2018`: `$806.10`
- `2019-2022`: `$317.11`
- `2023-2026`: `$492.15`

## Fresh Starts

Each window resets the account to $10,000 with the exact frozen source/profile.

| Reset window | Net | Return | CAGR | PF | Trades | DD | Gate |
|---|---:|---:|---:|---:|---:|---:|---|
| 2019-01-01 to 2026-07-16 | $776.17 | 7.76% | 1.00% | 1.47 | 209 | 3.16% | CAPITAL_PASS_ACTIVITY_SHORTFALL |
| 2021-01-01 to 2026-07-16 | $854.52 | 8.55% | 1.49% | 1.78 | 145 | 1.49% | PASS |
| 2024-01-01 to 2026-07-16 | $353.89 | 3.54% | 1.38% | 1.97 | 39 | 1.56% | PASS |

The 2019 reset passes profit, PF, and drawdown gates but has 209 trades versus the predeclared 220-trade activity floor. That shortfall is retained instead of moving the threshold after seeing the result.

## Stress

- Extreme deterministic extra cost: `$726.62`, PF `1.222`, closed-trade DD `3.671%`; all broad eras remain positive.
- Standard 10,000-trial Monte Carlo: 5th-percentile net `+$896.54`, median PF `1.378`, 95th-percentile closed DD `4.366%`, `0.000%` red trials.
- Severe 10,000-trial Monte Carlo: 5th-percentile net `+$286.74`, median PF `1.178`, 95th-percentile closed DD `5.770%`, `0.090%` red trials.
- Operational warning: randomized 95th-percentile loss streaks are 14 and 16 trades, above advisory limits of 12 and 14. The warning remains open.

## Remaining Gates

1. Run demo/forward trading for at least 90 calendar days and continue until at least 30 closed trades are observed.
2. Reproduce the frozen profile on a second broker's XAUUSD contract with its own spread, commission, swap, stop-level, and timezone specifications.
3. Review forward slippage, missed signals, disconnect behavior, and the loss-streak warning before any manual live approval.
4. Keep real-account trading disabled until those gates pass; never increase risk to compensate for the modest historical CAGR.

No historical backtest can make this work forever without oversight. The correct future workflow is frozen forward observation, drift monitoring, and a stop/review process, not continuous retuning to recent data.
