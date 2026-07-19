# Three-Lane Adaptive Trend Risk Audit

**Status: PASS.**

| Lane | Trades | Net | Maximum initial risk | Hard cap | Violations |
|---|---:|---:|---:|---:|---:|
| reversion | 38 | $1414.60 | 0.4370% | 0.45% | 0 |
| momentum | 314 | $475.66 | 0.1494% | 0.15% | 0 |
| adaptive_trend | 15 | $104.36 | 0.0998% | 0.10% | 0 |

- Maximum conservative portfolio initial risk: `0.4453%` against a `0.75%` cap.
- Maximum simultaneously open positions: `3`.
- Lane-cap violations: `0`; portfolio-cap violations: `0`.
- Entry balance is reconstructed from closed report profit. Open-position risk is conservatively held at its full initial-stop amount until exit.
- Initial risk uses the report's entry, initial stop, volume, and the tested XAUUSD contract size of 100.
