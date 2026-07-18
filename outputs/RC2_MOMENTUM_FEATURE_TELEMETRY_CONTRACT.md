# RC2 Momentum Feature Telemetry Contract

Frozen before inspecting any feature-conditioned result.

- Source SHA-256: `9BC49EFDCB95F46C1B473072CBD7A67B3794BACA0D2AE190979CC75C51D84ACC`
- Profile SHA-256: `0AC5B74A001DA33D1492FE6B9EA45B72D7624A8E825DBFC164316C07C8504AA1`
- Window: `2015-01-01` through `2018-12-31`
- Model: `1`; deposit: `$10,000`
- Behavior: exact RC2 strategy plus entry-reason telemetry only
- Reserved repair window: `2019-01-01` through `2020-12-31`

Telemetry fields: channel width/ATR, breakout distance/ATR, H1 and D1 efficiency ratios, D1 momentum percent, ATR percent, body ratio, close location, range/ATR, tick-volume ratio, and stop distance/ATR.

Telemetry only. Feature selection may use 2015-2018 outcomes; 2019-2020 remains unopened until one threshold family and its neighbors are frozen.
