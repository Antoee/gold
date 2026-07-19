# Three-Lane Trade-Ready RC2 Growth 1.25x Risk Audit

**Status: PASS.**

| Lane | Trades | Net | Maximum initial risk | Hard cap | Violations |
|---|---:|---:|---:|---:|---:|
| reversion | 38 | $1562.24 | 0.5507% | 0.5625% | 0 |
| momentum | 314 | $567.36 | 0.1875% | 0.1875% | 0 |
| adaptive_trend | 31 | $188.35 | 0.1222% | 0.1250% | 0 |

- Maximum conservative portfolio initial risk: `0.5507%` against a `0.94%` cap.
- Maximum simultaneously open positions: `3`.
- Lane-cap violations: `0`; portfolio-cap violations: `0`.
- Entry balance is reconstructed from closed report profit. Open-position risk is conservatively held at its full initial-stop amount until exit.
- Initial risk uses the report's entry, initial stop, volume, and the tested XAUUSD contract size of 100.
