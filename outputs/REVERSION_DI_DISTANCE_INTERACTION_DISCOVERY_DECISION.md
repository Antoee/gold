# Reversion DI and Distance Interaction Discovery Decision

**Decision: REJECTED BEFORE HOLDOUT. The frozen forward candidate and real-account lock are unchanged.**

- Exact source: `7E8D680807B0565992ECC9B98E15C636A86AF34742194687DBB64D61CE2EFD7A`
- Exact contract: `875BFDDD2F2A3A3A91B9CEA2A621B7854DAFDD71385D209995AED0F13878270B`
- Reports parsed: `20 / 20`; three exact identity-failed ranks were retried
- Post-2020 reports opened: `0`
- Holdout-eligible profiles: `0`

| Profile | 2015-18 | 2019 / PF | 2020 / PF | Continuous / PF | Trades | DD | Era | Quality | Parent | Neighbor | Decision |
|---|---:|---:|---:|---:|---:|---:|---|---|---|---|---|
| `rddi_released_control` | $+814.70 | $-4.98 / 0.98 | $-100.47 / 0.77 | $+694.13 / 1.42 | 225 | 2.77% | False | False | True | False | CONTROL_ONLY |
| `rddi_di10_parent` | $+663.37 | $-4.98 / 0.98 | $+66.30 / 1.25 | $+719.25 / 1.51 | 216 | 1.49% | False | True | True | False | PARENT_ONLY |
| `rddi_di10_m12` | $+724.77 | $-4.98 / 0.98 | $+66.30 / 1.25 | $+780.65 / 1.56 | 215 | 1.48% | False | True | True | False | REJECT_BEFORE_HOLDOUT |
| `rddi_di10_m10_center` | $+724.77 | $-4.98 / 0.98 | $+105.60 / 1.47 | $+819.95 / 1.61 | 214 | 1.47% | False | True | True | False | REJECT_BEFORE_HOLDOUT |
| `rddi_di10_m8` | $+659.14 | $-4.98 / 0.98 | $+105.60 / 1.47 | $+754.32 / 1.57 | 212 | 1.48% | False | True | True | False | REJECT_BEFORE_HOLDOUT |

## Interpretation

The fixed interaction improved the nominated center to `+$819.95`, PF `1.61`, and `1.47%` drawdown over continuous 2015-2020. It also kept 2020 profitable at `+$105.60`.

It did not repair the other protected year: the center and both distance neighbors each returned exactly `-$4.98`, PF `0.98`, in 2019. The contract requires every broad era to be profitable, so better continuous statistics cannot open newer data.

The family is closed before post-2020 holdout and Model 4. Neither threshold may move after this result.

This rejection is research evidence, not forward evidence or real-money approval.
