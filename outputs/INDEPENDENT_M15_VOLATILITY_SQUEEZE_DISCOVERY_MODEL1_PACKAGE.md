# Independent M15 Volatility-Squeeze Discovery Package

Standalone, date-independent continuation family. No configuration includes data after 2020.

- Source SHA-256: `A47F7A8ED05916A07A7CCF713340C64B1DFF950504E28744212EA8FD5CA94F29`
- Variants: `15`
- Discovery windows: `older_2015_2018, discovery_2019_2020, continuous_2015_2020`
- Configurations: `45`

Every profile requires consecutive M15 Bollinger bands inside a Keltner channel, followed by a closed fresh channel breakout with OHLC range, body, close-location, and expansion confirmation. H1 EMA alignment is the center regime; squeeze duration, Keltner width, breakout lookback, channel width, payoff, and trend length are isolated neighbors. The stop sits beyond the breakout candle, rejects distances above `$6`, uses broker-native `OrderCalcProfit` sizing at `0.10%` risk, never forces minimum volume, and keeps real-account trading disabled.

Frozen gate: Discovery only: both disjoint eras must be positive; continuous PF >= 1.20, trades >= 120, DD <= 5%, and an adjacent squeeze/breakout/payoff shape must pass before opening 2021-2026.
