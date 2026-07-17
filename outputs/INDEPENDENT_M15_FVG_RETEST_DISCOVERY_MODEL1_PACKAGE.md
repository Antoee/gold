# Independent M15 Displacement FVG Retest Discovery Package

Standalone, date-independent research family. No configuration includes data after 2020.

- Source SHA-256: `E46DB3A2E01435B83D68349BB1F40CA279723813FD34DBBD81D7A9CAFFE6751C`
- Variants: `10`
- Discovery windows: `older_2015_2018, discovery_2019_2020, continuous_2015_2020`
- Configurations: `30`

Every profile requires a BOS displacement candle, a three-candle fair-value gap, and a later touch-and-hold retest. Stops sit behind the retest/gap structure, reject distances above `$10`, use broker-accurate `OrderCalcProfit` sizing at `0.10%` risk, and keep real-account trading disabled.
