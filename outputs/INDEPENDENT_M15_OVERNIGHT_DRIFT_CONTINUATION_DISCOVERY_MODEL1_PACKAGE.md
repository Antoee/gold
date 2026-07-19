# Independent M15 Overnight-Drift Continuation Discovery Package

Standalone, date-independent research family. No configuration includes data after 2020.

- Source SHA-256: `B74E61CC7B473C03FCA79E1D8DC0C73C4512FCCF9596E439971E1D7C82149684`
- Variants: `15`
- Discovery windows: `older_2015_2018, discovery_2019_2020, continuous_2015_2020`
- Configurations: `45`

Every profile uses only completed prior-day and M15 bars, one trade per day during a fixed morning window, a fixed intraday exit, an Asian-range stop capped at `$8`, broker-accurate `OrderCalcProfit` sizing, `0.10%` risk, a `$10,000` initial-balance contract, a `1%` account-wide open-risk cap, a `0.75%` daily-loss cap, a `5%` equity-drawdown cap, and real-account trading disabled. Queue ranks intentionally route only to healthy portable workers 1 and 3.
