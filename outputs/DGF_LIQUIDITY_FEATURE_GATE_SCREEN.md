# DGF Liquidity Feature Gate Screen

Offline, trade-stream diagnostic only. It cannot account for path-dependent cooldown, sizing, or entry changes; every survivor requires an exact MT5 rerun.

- Frozen discovery: `2019-2022`
- Frozen feature holdout: `2023-2025`
- Liquidity-only telemetry trades: `41`
- One-feature threshold rows: `220`
- Discovery-qualified rows: `1`
- Holdout-qualified discovery rows: `0`
- Neighbor-supported offline survivors: `0`

A qualified scope requires every year positive, every yearly PF at least 1.20, and at least three total strategy trades per year. An offline survivor also needs an adjacent threshold pass and at least eight retained liquidity trades.

## Offline Survivors

No one-feature gate survived discovery, chronological holdout, yearly PF/activity, and neighbor-plateau requirements.

The holdout is consumed by this report. Do not retune feature thresholds against 2023-2025 after reading it; use exact MT5 replay and then newer frozen forward data.
