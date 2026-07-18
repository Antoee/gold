# RC2 Reversion 2019 Diagnostic Contract

Behavior-preserving diagnostic; no filter threshold is selected by this package.

- Source SHA-256: `13CF38517BF6859CCD620C3CF658CF278452B3387E5690D44391F4E95B141BC4`
- Profile SHA-256: `A2703884664EDE0ADFC706AF0EA7586BB437D7EBE3DBD3556645E31E6226BB2F`
- Window: `2019-01-01` through `2019-12-31`
- Model: `1`; deposit: `$10,000`
- Behavior: exact RC2 strategy plus entry-reason telemetry only
- Independent validation year retained: `2020`

Telemetry fields: aligned D1/H1 momentum, D1/H1 efficiency, long-horizon price location, ADX/DI/RSI, ATR and band width, rejection geometry, target/stop geometry, and tick-volume ratio.

Diagnostic only. The two 2019 reversion losses may identify a mechanism, but thresholds must be supported by 2015-2018 telemetry and validated on 2020 without movement.
