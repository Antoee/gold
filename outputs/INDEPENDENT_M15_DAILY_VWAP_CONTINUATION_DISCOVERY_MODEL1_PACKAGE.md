# Independent M15 Daily-VWAP Continuation Discovery Package

Standalone, date-independent research family. No configuration includes data after 2020.

- Source SHA-256: `7EE4CD1CF4D47FA4EB34D33FF101A2C66323B8212047E4C4D5692C18A28A5849`
- Variants: `12`
- Discovery windows: `older_2015_2018, discovery_2019_2020, continuous_2015_2020`
- Configurations: `36`

Every profile requires an aligned and rising/falling H1 50/200 EMA regime, bounded H1 ADX, a pullback through the current day anchored VWAP, and a completed directional reclaim candle confirmed by OHLC body, close location, previous-bar progress, and optional tick volume. Stops sit behind the pullback structure, reject distances above `$8`, use broker-accurate `OrderCalcProfit` sizing at `0.10%` risk, and keep real-account trading disabled.
