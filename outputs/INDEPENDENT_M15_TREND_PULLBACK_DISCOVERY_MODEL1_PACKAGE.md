# Independent M15 Trend-Pullback Continuation Discovery Package

Standalone, date-independent research family. No configuration includes data after 2020.

- Source SHA-256: `2452BA2254D7848F768EF729C09D615DB6147D100318F4D72B73C86525CF0636`
- Variants: `10`
- Discovery windows: `older_2015_2018, discovery_2019_2020, continuous_2015_2020`
- Configurations: `30`

Every profile requires an aligned and rising/falling H1 50/200 EMA regime, bounded H1 ADX, a prior M15 impulse, an M15 EMA pullback, and a directional rejection candle confirmed by OHLC body, wick, close-location, and optional tick volume. Stops sit behind the pullback structure, reject distances above `$8`, use broker-accurate `OrderCalcProfit` sizing at `0.10%` risk, and keep real-account trading disabled.
