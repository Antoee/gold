# Momentum Partial-Runner Interaction Holdout Decision

**Decision: REJECTED IN HOLDOUT. No Model 4 run, promotion, forward change, or real trading is permitted. NO NEW BEST.**

- Exact accepted Model 1 reports: `12/12`; preserved identity refusals: `2`; successful exact recoveries: `2`
- Source SHA-256: `1092D9AD0036C6C4E7A0F61CB7318B31CDCE75F9311762388CF256AFFB6BFEA9`
- EX5 SHA-256: `8B72A5B1457BCBF79118381AA5F2F8B1D709DA703611BE60778C4DB518DCD130`
- Manifest SHA-256: `C4F01E5DB151660484D3BE6301ABEFB1667D9C2FA05422932610FC2CCD723A72`
- Test contract: XAUUSD M15, `$10,000`, Model 1, post-2020 feature holdout only.

| Candidate | Close | Target | 2021-23 | 2024-26 | Continuous | CAGR | PF | Trades | DD | Recovery | Return/DD | Gate |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| Disabled control | 60% | 4R | +$629.61 | +$434.36 | +$1,046.44 | 1.82%/yr | 2.08 | 143 | 1.21% | 8.129 | 8.6446 | CONTROL |
| 70% / 4R component | 70% | 4R | +$624.14 | +$441.89 | +$1,044.24 | 1.81%/yr | 2.07 | 157 | 1.22% | 8.1119 | 8.5574 | False |
| 60% / 5R component | 60% | 5R | +$643.16 | +$437.97 | +$1,054.08 | 1.83%/yr | 2.08 | 157 | 1.22% | 8.1883 | 8.6393 | False |
| **70% / 5R interaction** | 70% | 5R | +$634.72 | +$437.97 | +$1,050.90 | 1.83%/yr | 2.08 | 157 | 1.22% | 8.1636 | 8.6148 | False |

## Interpretation

The interaction raised post-2020 continuous net by only `+$4.46` (`0.43%`), from `+$1,046.44` to `+$1,050.90`. That is far below the frozen 5% growth and +0.10-point CAGR requirements.

Neither individual component passed its 2% holdout growth gate. The best headline row, the 5R component at `+$1,054.08`, improved control by less than 1%. The partial-runner branch is closed without Model 4 threshold chasing.

The verified Model 4 same-side exit-cooldown leader remains unchanged. The invalid `$100,000` demo is not forward evidence, the registered candidate is unchanged, and real-account trading remains disabled.
