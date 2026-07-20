# Momentum Same-Side Exit Cooldown Model 4 Risk Audit

**Status: PASS.**

| Lane | Trades | Net | Maximum initial risk | Hard cap | Violations |
|---|---:|---:|---:|---:|---:|
| reversion | 38 | $1671.93 | 0.4431% | 0.4500% | 0 |
| momentum | 310 | $712.17 | 0.1499% | 0.1500% | 0 |
| adaptive_trend | 52 | $108.15 | 0.1487% | 0.1500% | 0 |

- Maximum conservative portfolio initial risk: `0.5869%` against a `0.75%` cap.
- Maximum simultaneously open positions: `3`.
- Lane-cap violations: `0`; portfolio-cap violations: `0`.
- Entry balance is reconstructed from closed report profit. Open-position risk is conservatively held at its full initial-stop amount until exit.
- Initial risk uses the report's entry, initial stop, volume, and the tested XAUUSD contract size of 100.
