# Independent M15 Inside-Day Breakout Discovery Package

Standalone, date-independent research family. No configuration includes data after 2020.

- Source SHA-256: `534D767F2B04A0ADB3ECC6C121CAEF6A3FB26652ACFE26C64EA45F146E67B427`
- Variants: `14`
- Discovery windows: `older_2015_2018, discovery_2019_2020, continuous_2015_2020`
- Configurations: `42`

Every profile reads only completed D1 compression bars, requires a fresh M15 break, uses a recent-M15 structure stop capped at `$8`, broker-accurate `OrderCalcProfit` sizing, `0.10%` risk, one strategy position, a `3%` account-wide open-risk cap, a `0.75%` daily-loss cap, a `5%` equity-drawdown cap, and real-account trading disabled. Queue ranks intentionally route only to the healthy portable workers 1 and 3.
