# RC2 Reversion Feature Telemetry Contract

Frozen before inspecting any feature-conditioned result.

- Source SHA-256: `13CF38517BF6859CCD620C3CF658CF278452B3387E5690D44391F4E95B141BC4`
- Profile SHA-256: `B591E4C447202775C93C628BBE08D79DB79D75D2ADD728E8E41E0A8CB480595B`
- Window: `2015-01-01` through `2018-12-31`
- Model: `1`; deposit: `$10,000`
- Behavior: exact RC2 strategy plus entry-reason telemetry only
- Reserved repair window: `2019-01-01` through `2020-12-31`

Telemetry fields: aligned D1/H1 momentum, D1/H1 efficiency, long-horizon price location, ADX/DI/RSI, ATR and band width, rejection geometry, target/stop geometry, and tick-volume ratio.

Telemetry only. Feature selection may use 2015-2018 outcomes; 2019-2020 remains unopened until one threshold family and its neighbors are frozen.
