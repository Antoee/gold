# RDMC Entry/Regime Rewrite v1 Contract

**NEW RESEARCH IDENTITY. ZERO INHERITED PROFIT, ZERO FORWARD EVIDENCE, AND NO REAL-MONEY APPROVAL.**

## Frozen Identity

- Source SHA-256: `41768D6A8C21A49B0B8465F90A4C3C254CA0FC714910AB6AAFBDE9B8D4402FED`
- Profile SHA-256: `D7C882EA36B34AE919A48407C7CA748579BE5D7D1C28103D688471C6AF1E1BD9`
- Explicit profile inputs: `600`
- Starting capital: `$10,000 USD`
- First admissible tests: Model1 2019 and 2022 only

## Mechanism Rewrite

The rejected predecessor let MTSM losses feed the primary lane's soft loss-streak sizing. Three early losses multiplied nominal risk by `0.5^3`, pushing both MTSM and unrelated low-risk R20 orders below XAUUSD's minimum lot. Hard account limits worked, but the soft state starved the intended diversifier.

This identity changes that mechanism without weakening account-wide loss protection:

- Primary soft loss streaks are calculated only from the primary magic.
- MTSM bypasses primary soft streak state and applies the same configured loss-size reduction and cooldown to its own closed trades.
- Daily, weekly, monthly, drawdown, margin, spread, exposure, funding, dedicated-account, and real-account locks remain portfolio-wide.
- Primary M15 entries receive first priority when a new H1 momentum bar coincides with a primary signal.
- MTSM requires 126-day and 21-day momentum agreement, a directional H1 body/close-location test, a bounded ATR expansion, and tick-volume expansion.

## Frozen New Inputs

| Input | Value |
|---|---:|
| `InpMOUseFastMomentumAgreement` | `true` |
| `InpMOFastMomentumLookbackBars` | `21` |
| `InpMOMinimumFastMomentumPercent` | `0.50` |
| `InpMOUseBreakoutQualityFilter` | `true` |
| `InpMOMinimumBreakoutBodyPercent` | `50.0` |
| `InpMOMinimumBreakoutCloseLocationPercent` | `70.0` |
| `InpMOMinimumBreakoutRangeATR` | `0.50` |
| `InpMOMaximumBreakoutRangeATR` | `2.00` |
| `InpMOUseTickVolumeExpansion` | `true` |
| `InpMOTickVolumeLookbackBars` | `20` |
| `InpMOMinimumTickVolumeRatio` | `1.10` |

## Fail-Closed Gate

Both 2019 and 2022 must have positive net, PF at least `1.05`, meet the predecessor's frozen activity floors, and remain below `3%` drawdown. A hard economic failure requires another code rewrite. Later waves remain closed until Wave 1 passes.
