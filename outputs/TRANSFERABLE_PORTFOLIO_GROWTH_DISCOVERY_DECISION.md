# Transferable Portfolio Growth Allocation Model1 Decision

**Decision: REJECTED IN MODEL 1. No Model 4 growth test, new best, or live approval was opened.**

The exact released source was tested without changing signals, exits, stops, schedules, or safety controls. Only reversion and momentum requested-risk allocations varied inside the unchanged `0.75%` shared open-risk cap.

- Source SHA-256: `5BADDE1BC7C1E8020E64F00793058AD5C6174370A866F5D3002FA1FA12248FC3`
- Reports: `28 / 28` parsed with embedded exact-source identity
- Same-source control net: `+$1,616.49`
- Numeric growth passes: `0 / 6`
- Neighbor-supported Model 4 profiles: `0 / 6`

| Profile | RV | MOM | 2015-18 | 2019-22 | 2023-26 | Continuous | Improvement | CAGR | PF | Trades | DD | Recovery | Decision |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| `tpg_rv055_mo015` | 0.55% | 0.15% | +$810.14 | +$248.31 | +$592.59 | +$1,710.85 | 5.837% | 1.38% | 1.59 | 370 | 4.26% | 3.6662 | REJECT_BEFORE_MODEL4 |
| `tpg_rv060_mo015` | 0.60% | 0.15% | +$810.14 | +$223.21 | +$737.85 | +$1,686.58 | 4.336% | 1.36% | 1.57 | 370 | 4.56% | 3.3685 | REJECT_BEFORE_MODEL4 |
| `tpg_rv045_mo015_control` | 0.45% | 0.15% | +$814.70 | +$239.64 | +$553.67 | +$1,616.49 | 0% | 1.31% | 1.58 | 370 | 3.24% | 4.5567 | CONTROL |
| `tpg_rv055_mo010` | 0.55% | 0.10% | +$635.91 | +$270.94 | +$541.89 | +$1,589.29 | -1.683% | 1.29% | 1.74 | 370 | 4.15% | 3.5567 | REJECT_BEFORE_MODEL4 |
| `tpg_rv050_mo015` | 0.50% | 0.15% | +$810.14 | +$242.85 | +$570.88 | +$1,576.21 | -2.492% | 1.28% | 1.55 | 370 | 3.86% | 3.7267 | REJECT_BEFORE_MODEL4 |
| `tpg_rv060_mo010` | 0.60% | 0.10% | +$635.91 | +$247.03 | +$687.15 | +$1,563.85 | -3.256% | 1.27% | 1.72 | 370 | 4.43% | 3.2825 | REJECT_BEFORE_MODEL4 |
| `tpg_rv050_mo010` | 0.50% | 0.10% | +$635.91 | +$283.82 | +$512.56 | +$1,439.86 | -10.927% | 1.17% | 1.68 | 370 | 3.88% | 3.4451 | REJECT_BEFORE_MODEL4 |

Passing this screen does not promote a profile. It only freezes the supported neighborhood for exact Model 4, deterministic cost stress, and Monte Carlo validation. The existing forward-demo candidate and its identity remain unchanged.
