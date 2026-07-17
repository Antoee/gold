# Independent M15 Previous-Day Liquidity Sweep Discovery Package

Standalone, date-independent research family. No configuration includes data after 2020.

- Source SHA-256: `DE93CFC433C0F3A9B19A6F8D58AAF32894FC8FE6DC41F98A3745FD209C787E8E`
- Variants: `10`
- Discovery windows: `older_2015_2018, discovery_2019_2020, continuous_2015_2020`
- Configurations: `30`

Every profile requires a fresh M15 sweep and reclaim of the previous D1 high or low, uses a structure stop beyond the sweep wick, rejects stop distances above `$10`, sizes with broker-accurate `OrderCalcProfit` at `0.10%` risk, and keeps real-account trading disabled.
