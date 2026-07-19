# Independent M15 Overnight-Drift Structure V2 Discovery Package

Standalone, date-independent research family. No configuration includes data after 2020.

- Source SHA-256: `2E98481FBE42F58B61CB824652CA58FED62C0A005FD14EEB6C5B4110D4C56AE6`
- Variants: `13`
- Discovery windows: `older_2015_2018, discovery_2019_2020, continuous_2015_2020`
- Configurations: `39`

Every profile uses only completed prior-day and M15 bars, one trade per day during a fixed morning window, a fixed intraday exit, a local M15 structure stop capped by ATR and `$8`, broker-accurate `OrderCalcProfit` sizing, `0.10%` risk, a `$10,000` initial-balance contract, a `1%` account-wide open-risk cap, a `0.75%` daily-loss cap, a `5%` equity-drawdown cap, and real-account trading disabled. Queue ranks intentionally route only to healthy portable workers 1 and 3.
