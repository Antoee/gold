# Independent M15 Overnight-Drift Continuation Holdout Package

Frozen post-2020 holdout for the discovery center and two orthogonal one-factor survivors. Profiles were selected and hashed before these windows were opened.

- Source SHA-256: `B74E61CC7B473C03FCA79E1D8DC0C73C4512FCCF9596E439971E1D7C82149684`
- Variants: `3`
- Holdout windows: `early_2021_2022, middle_2023_2024, recent_2025_2026, continuous_2021_2026`
- Configurations: `12`

Every profile uses only completed prior-day and M15 bars, one trade per day during a fixed morning window, a fixed intraday exit, an Asian-range stop capped at `$8`, broker-accurate `OrderCalcProfit` sizing, `0.10%` risk, a `$10,000` initial-balance contract, a `1%` account-wide open-risk cap, a `0.75%` daily-loss cap, a `5%` equity-drawdown cap, and real-account trading disabled. Queue ranks intentionally route only to healthy portable workers 1 and 3.
