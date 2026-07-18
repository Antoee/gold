# Independent M15 Asian-Range Sweep Discovery Package

Frozen standalone research family. No configuration includes data after 2020.

- Source SHA-256: `C757E57C98EFABE7C9A84EEE912D181539AF346DCDCD0B6758F9F0AE22C71EFB`
- Variants: `10`
- Discovery windows: `older_2015_2018, repair_2019_2020, continuous_2015_2020`
- Configurations: `30`
- Risk per trade: `0.10%`
- Real-account trading default: `false`

The signal requires a fresh sweep and reclaim of the completed 00:00-06:00 broker-time range, a rejection candle, a structure stop beyond the sweep, and no more than one trade per day.

The package is a fast rejection screen. Passing Model 1 is permission to test exact survivors on holdout data, not evidence of money readiness.
