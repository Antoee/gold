# Three-Lane Trade-Ready RC2 ATB 1.50x Risk Audit

**Status: PASS.**

| Lane | Trades | Net | Maximum initial risk | Hard cap | Violations |
|---|---:|---:|---:|---:|---:|
| reversion | 38 | $1366.48 | 0.4341% | 0.4500% | 0 |
| momentum | 314 | $661.79 | 0.1497% | 0.1500% | 0 |
| adaptive_trend | 52 | $76.81 | 0.1491% | 0.1500% | 0 |

- Maximum conservative portfolio initial risk: `0.4448%` against a `0.75%` cap.
- Maximum simultaneously open positions: `3`.
- Lane-cap violations: `0`; portfolio-cap violations: `0`.
- Entry balance is reconstructed from closed report profit. Open-position risk is conservatively held at its full initial-stop amount until exit.
- Initial risk uses the report's entry, initial stop, volume, and the tested XAUUSD contract size of 100.
