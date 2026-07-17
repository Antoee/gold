# Independent M30 Compression-Expansion Discovery Package

Standalone, date-independent continuation family. No configuration includes data after 2020.

- Source SHA-256: `15F22472BE6FCF3AD195B212727C55EEF1669CD961F25422DD6F6EC397462440`
- Variants: `15`
- Discovery windows: `older_2015_2018, discovery_2019_2020, continuous_2015_2020`
- Configurations: `45`

Every profile requires a bounded M30 compression box followed by a closed expansion candle outside the box. OHLC range, body, close location, and expansion ratio define the signal; tick volume, H1 EMA alignment, and bounded ADX are isolated variants. The stop sits beyond the breakout candle, rejects distances above `$8`, uses broker-native `OrderCalcProfit` sizing at `0.10%` risk, never forces minimum volume, and keeps real-account trading disabled.

Frozen gate: Discovery only: both disjoint eras must be positive; continuous PF >= 1.20, trades >= 100, DD <= 5%, and an adjacent compression/payoff shape must pass before opening 2021-2026.
