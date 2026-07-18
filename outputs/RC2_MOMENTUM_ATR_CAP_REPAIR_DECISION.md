# RC2 Momentum ATR-Cap Repair Decision

**Decision: REJECTED IN REPAIR. The frozen forward candidate and real-account lock are unchanged.**

- Exact source: `9141137A9550F3394DE85E1725E018671B4F2A2FF0F43A3EF23F9FB1238CD302`
- Exact contract: `484985776EF02F5C21D85AC3932B49B5DB9943F1946729C6BE12306700336D60`
- Reports parsed: `8 / 8`; one fixed-control identity retry
- Repair-eligible profiles: `0`

| Profile | 2019-20 net | Continuous net | Return | PF | Trades | DD | Recovery | Basic | Quality | Neighbor | Decision |
|---|---:|---:|---:|---:|---:|---:|---:|---|---|---|---|
| `mac_fixed_control` | $-105.45 | $+694.13 | 6.94% | 1.42 | 225 | 2.77% | 2.2843 | False | True | False | CONTROL_ONLY |
| `mac_cap024` | $-149.28 | $+672.32 | 6.72% | 1.47 | 185 | 2.76% | 2.2197 | False | False | False | REJECT_BEFORE_HOLDOUT |
| `mac_cap026` | $-156.32 | $+739.58 | 7.4% | 1.5 | 196 | 2.69% | 2.4867 | False | True | False | REJECT_BEFORE_HOLDOUT |
| `mac_cap028` | $-153.76 | $+747.44 | 7.47% | 1.49 | 204 | 2.91% | 2.3208 | False | True | False | REJECT_BEFORE_HOLDOUT |

## Interpretation

All three ATR caps improved selection-era momentum statistics, but each made the reserved 2019-2020 loss worse than the unchanged control. Continuous PF improvement therefore came from excluding trades in the already-inspected selection era, not from repairing the weak era.

The family is closed before post-2020 holdout and Model 4. No threshold may be moved after this result.

This rejection is research evidence, not forward evidence or real-money approval.
