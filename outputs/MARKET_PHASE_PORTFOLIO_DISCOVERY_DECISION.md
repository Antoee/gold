# Market Phase Portfolio Discovery Decision

**Decision: rejected in pre-2021 discovery; holdout, Model 4, and promotion remain closed.**

The exact released Band/VWAP-reversion and E20 momentum entries/exits were retained. A closed-H1-bar efficiency-ratio controller could only reduce hostile-phase lane risk inside the existing 0.75% open-risk cap.

- Source SHA-256: `78F43A8281B213FBE82AF592F9876FBC4545BAA1DA62D61565CA0AA56375E8BF`
- Compile: `0 errors, 0 warnings`
- Correct-source Model 1 reports: `24 / 24`
- Fixed-risk control efficiency: `2.5054` return/DD
- Eligible market-phase profiles: `0 / 7`

| Candidate | 2015-18 | 2019-20 | Continuous | Return | CAGR | PF | Trades | DD | Return/DD | Quality | Neighbor | Decision |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|---|---|
| `mpp_lookback12` | +$832.12 | -$61.36 | +$747.49 | 7.47% | 1.21% | 1.48 | 224 | 2.58% | 2.8953 | True | False | REJECT_BEFORE_HOLDOUT |
| `mpp_fixed_control` | +$814.70 | -$105.45 | +$694.13 | 6.94% | 1.13% | 1.42 | 225 | 2.77% | 2.5054 | False | False | CONTROL_ONLY |
| `mpp_wide` | +$749.37 | -$98.83 | +$631.03 | 6.31% | 1.03% | 1.42 | 220 | 2.71% | 2.3284 | False | False | REJECT_BEFORE_HOLDOUT |
| `mpp_scale75` | +$766.19 | -$120.45 | +$629.12 | 6.29% | 1.02% | 1.41 | 225 | 2.79% | 2.2545 | False | False | REJECT_BEFORE_HOLDOUT |
| `mpp_narrow` | +$713.35 | -$121.57 | +$592.13 | 5.92% | 0.96% | 1.44 | 214 | 2.58% | 2.2946 | False | False | REJECT_BEFORE_HOLDOUT |
| `mpp_center` | +$703.62 | -$128.38 | +$568.19 | 5.68% | 0.93% | 1.4 | 218 | 2.66% | 2.1353 | False | False | REJECT_BEFORE_HOLDOUT |
| `mpp_lookback48` | +$667.92 | -$99.58 | +$551.93 | 5.52% | 0.9% | 1.44 | 212 | 2.38% | 2.3193 | False | False | REJECT_BEFORE_HOLDOUT |
| `mpp_scale25` | +$622.93 | -$154.07 | +$454.90 | 4.55% | 0.74% | 1.33 | 182 | 2.93% | 1.5529 | False | False | REJECT_BEFORE_HOLDOUT |
