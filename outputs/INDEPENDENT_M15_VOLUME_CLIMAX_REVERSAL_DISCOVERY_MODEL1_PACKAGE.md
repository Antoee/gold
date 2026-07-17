# Independent M15 Volume-Climax Reversal Discovery Package

Standalone, date-independent exhaustion-reversion family. No configuration includes data after 2020.

- Source SHA-256: `914C5F3832D61DFD3AD2E4F885C70EFBF35E35B6CFFFFE1B8387EDA96AC56A36`
- Variants: `15`
- Discovery windows: `older_2015_2018, discovery_2019_2020, continuous_2015_2020`
- Configurations: `45`

Every profile requires an M15 tick-volume climax, ATR-sized range, rejection wick, fresh local extreme, and meaningful deviation from the day anchored VWAP. The center profile also avoids strongly trending H1 ADX/EMA-distance phases. The target is the pre-signal daily VWAP capped by R and is rejected below the minimum RR. The stop sits beyond the climax wick, rejects distances above `$6`, uses broker-native `OrderCalcProfit` sizing at `0.10%` risk, never forces minimum volume, and keeps real-account trading disabled.

Frozen gate: Discovery only: both disjoint eras must be positive; continuous PF >= 1.20, trades >= 120, DD <= 5%, and an adjacent volume/wick/VWAP/phase shape must pass before opening 2021-2026.
