# Reversion Long-Distance Guard Repair Decision

**Decision: REJECTED IN REPAIR. The frozen forward candidate and real-account lock are unchanged.**

- Exact source: `7E8D680807B0565992ECC9B98E15C636A86AF34742194687DBB64D61CE2EFD7A`
- Exact contract: `6477C8F3D87B355F5AF397B5B6EE47D058108978EA8BAB95B3366A9D1C7278DE`
- Reports parsed: `8 / 8`; no identity retry
- Repair-eligible profiles: `0`

| Profile | 2019-20 net | Continuous net | Return | PF | Trades | DD | Recovery | Basic | Quality | Neighbor | Decision |
|---|---:|---:|---:|---:|---:|---:|---:|---|---|---|---|
| `rld_fixed_control` | $-105.45 | $+694.13 | 6.94% | 1.42 | 225 | 2.77% | 2.2843 | False | True | False | CONTROL_ONLY |
| `rld_m12` | $-105.45 | $+728.03 | 7.28% | 1.45 | 224 | 2.76% | 2.3959 | False | True | False | REJECT_BEFORE_HOLDOUT |
| `rld_m10` | $-66.15 | $+798.76 | 7.99% | 1.51 | 222 | 2.82% | 2.56 | False | False | False | REJECT_BEFORE_HOLDOUT |
| `rld_m8` | $-66.15 | $+746.54 | 7.47% | 1.49 | 219 | 2.83% | 2.3926 | False | False | False | REJECT_BEFORE_HOLDOUT |

## Interpretation

The `-10` and `-8 ATR` guards removed one 2019-2020 reversion stop-out and improved that window by `$39.30`, but both still lost `-$66.15`. The `-12 ATR` neighbor changed no weak-era trade. A better continuous PF cannot override a losing protected era.

The family is closed before post-2020 holdout and Model 4. No threshold may be moved after this result.

This rejection is research evidence, not forward evidence or real-money approval.
