# Independent M15 Dual-Regime Portfolio Discovery Decision

**Decision: FREEZE THE DISCOVERY SURVIVORS FOR A DISJOINT 2021-2026 MODEL 1 HOLDOUT. No Model 4, new best, or live approval is opened yet.**

The EA combines a trend-phase M15 volatility-squeeze continuation lane with a range-phase M15 volume-climax VWAP-reversion lane under one risk manager and one-position cap. Lane-specific comments preserve lane-specific exits. The compact neighborhood changes only previously screened lane settings and includes two diagnostic engine-only controls that cannot be promoted. Stops are capped at `$6`, use broker-native `OrderCalcProfit` sizing at `0.10%` risk, and never force minimum volume.

- Source SHA-256: `DEA3B16FB2D14E4A1253B422CCE80AEC4CB49DCF03067EDBCE96008F694FA5E1`
- Compile: `0 errors, 0 warnings`
- Correct-source Model 1 reports: `45 / 45`; report/source identity: `45 / 45`
- Stale portable exports reproduced unchanged on alternate workers: `3`; all final reports contain the correct source identity
- Discovery profiles with at least one continuous trade: `15 / 15`
- Numeric gate passes: `12 / 15`
- Eligible profiles with a passing adjacent neighbor: `12 / 15`

| Candidate | 2015-18 | PF | Trades | 2019-20 | PF | Trades | Continuous | CAGR | PF | Trades | DD | Decision |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| `m15drp_noextreme` | +$164.39 | 1.26 | 131 | +$160.69 | 1.42 | 87 | +$330.06 | 0.54% | 1.32 | 218 | 1.02% | DISCOVERY_ELIGIBLE |
| `m15drp_maxtrades3` | +$176.39 | 1.35 | 108 | +$101.80 | 1.28 | 77 | +$284.34 | 0.47% | 1.33 | 185 | 1.23% | DISCOVERY_ELIGIBLE |
| `m15drp_center` | +$176.39 | 1.35 | 108 | +$101.80 | 1.28 | 77 | +$284.34 | 0.47% | 1.33 | 185 | 1.23% | DISCOVERY_ELIGIBLE |
| `m15drp_vcr140` | +$203.65 | 1.42 | 104 | +$72.19 | 1.2 | 75 | +$281.72 | 0.46% | 1.33 | 179 | 1.04% | DISCOVERY_ELIGIBLE |
| `m15drp_kc140` | +$204.35 | 1.47 | 97 | +$60.42 | 1.21 | 60 | +$267.51 | 0.44% | 1.37 | 157 | 0.99% | DISCOVERY_ELIGIBLE |
| `m15drp_kc160` | +$189.48 | 1.32 | 128 | +$70.44 | 1.16 | 88 | +$264.64 | 0.44% | 1.25 | 216 | 1.48% | DISCOVERY_ELIGIBLE |
| `m15drp_trend50` | +$206.69 | 1.31 | 140 | +$38.97 | 1.1 | 83 | +$258.38 | 0.43% | 1.24 | 223 | 1.15% | DISCOVERY_ELIGIBLE |
| `m15drp_vcr150` | +$187.20 | 1.39 | 103 | +$59.59 | 1.17 | 74 | +$252.98 | 0.42% | 1.3 | 177 | 1.04% | DISCOVERY_ELIGIBLE |
| `m15drp_session18` | +$107.91 | 1.24 | 91 | +$112.94 | 1.36 | 66 | +$226.48 | 0.37% | 1.3 | 157 | 1.05% | DISCOVERY_ELIGIBLE |
| `m15drp_session22` | +$144.56 | 1.24 | 127 | +$79.14 | 1.19 | 87 | +$221.10 | 0.37% | 1.21 | 214 | 1.61% | DISCOVERY_ELIGIBLE |
| `m15drp_sqbreak10` | +$120.56 | 1.26 | 97 | +$95.83 | 1.32 | 66 | +$219.42 | 0.36% | 1.29 | 163 | 1.06% | DISCOVERY_ELIGIBLE |
| `m15drp_sq_only` | +$127.23 | 1.44 | 62 | +$71.37 | 1.37 | 43 | +$199.63 | 0.33% | 1.41 | 105 | 0.63% | REJECT_BEFORE_HOLDOUT |
| `m15drp_sqbreak6` | +$54.64 | 1.08 | 131 | +$123.27 | 1.31 | 85 | +$181.96 | 0.3% | 1.17 | 216 | 1.58% | REJECT_BEFORE_HOLDOUT |
| `m15drp_trend200` | +$66.06 | 1.16 | 86 | +$82.43 | 1.27 | 67 | +$150.38 | 0.25% | 1.21 | 153 | 0.93% | DISCOVERY_ELIGIBLE |
| `m15drp_vcr_only` | +$73.23 | 1.31 | 50 | +$35.37 | 1.22 | 34 | +$107.17 | 0.18% | 1.27 | 84 | 0.95% | REJECT_BEFORE_HOLDOUT |

The frozen dual-engine discovery survivors are `m15drp_center`, `m15drp_kc140`, `m15drp_kc160`, `m15drp_maxtrades3`, `m15drp_noextreme`, `m15drp_session18`, `m15drp_session22`, `m15drp_sqbreak10`, `m15drp_trend200`, `m15drp_trend50`, `m15drp_vcr140`, `m15drp_vcr150`. Only these exact source/profile identities may enter the disjoint holdout; no discovery threshold may be changed after this decision.
