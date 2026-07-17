# Independent Multiscale Momentum Discovery Package

Standalone date-independent discovery using only 2015-2020 data.

- Source SHA-256: `92F7B079CD029E1A15F5BB8BA3BE53B1455B389AB39C77310DC98A4E4F593F69`
- Variants: `7`
- Windows: `older_2015_2018, discovery_2019_2020, continuous_2015_2020`
- Configurations: `21`
- Starting balance: `$10,000`
- Risk per trade: `0.10%`

The direction signal is the sign of the trailing 3/6/12-month D1 return. Execution requires a fresh H1 channel breakout, and the stop uses recent H1 structure with a hard `$10` distance cap. No calendar gate or forced minimum lot is present.

Discovery only: require both disjoint eras profitable, continuous PF >= 1.20, at least 100 continuous trades, DD <= 5%, and at least two adjacent momentum/entry/target shapes passing before any 2021+ run.
