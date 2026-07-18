# RC2 Momentum-Risk Extension Model1 Decision

**Decision: MODEL1 GATE PASSED. Exact Model4 is permitted only for the frozen center and two neighbors; no candidate is promoted.**

The exact RC2 source was tested with unchanged signals, exits, stops, sessions, safety controls, and the same 0.75% shared open-risk cap. Only momentum requested risk varied.

- Source SHA-256: `9141137A9550F3394DE85E1725E018671B4F2A2FF0F43A3EF23F9FB1238CD302`
- Reports: `28 / 28` parsed
- Control net: `+$1,616.49`
- Center pass: `True`; lower neighbor: `True`; upper neighbor: `True`

| Profile | MOM risk | 2015-18 | 2019-22 | 2023-26 | Continuous | Improvement | PF | Trades | DD | Recovery | Gate |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| `mre_mo015_control` | 0.15% | +$814.70 | +$239.64 | +$553.67 | +$1,616.49 | 0% | 1.58 | 370 | 3.24% | 4.5567 | False |
| `mre_mo0175` | 0.175% | +$866.02 | +$252.38 | +$488.60 | +$1,764.04 | 9.128% | 1.54 | 370 | 3.79% | 4.2186 | True |
| `mre_mo020_center` | 0.20% | +$936.30 | +$261.58 | +$636.22 | +$1,866.25 | 15.451% | 1.51 | 370 | 3.68% | 4.5415 | True |
| `mre_mo0225` | 0.225% | +$1,003.42 | +$253.06 | +$656.86 | +$1,926.06 | 19.151% | 1.47 | 370 | 3.56% | 4.8252 | True |
| `mre_mo025` | 0.25% | +$1,081.19 | +$264.08 | +$628.89 | +$2,004.30 | 23.991% | 1.44 | 370 | 4.07% | 4.3471 | False |
| `mre_mo0275` | 0.275% | +$1,104.88 | +$226.06 | +$672.83 | +$2,136.55 | 32.172% | 1.43 | 370 | 4.16% | 4.4977 | False |
| `mre_mo030` | 0.30% | +$1,294.69 | +$258.26 | +$768.46 | +$2,301.51 | 42.377% | 1.43 | 370 | 4.05% | 4.886 | False |

The operational RC2 source/profile, unregistered forward drafts, evidence logs, and real-account lock remain unchanged.
