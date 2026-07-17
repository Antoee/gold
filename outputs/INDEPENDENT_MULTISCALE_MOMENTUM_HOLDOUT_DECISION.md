# Independent Multiscale Momentum Holdout Decision

**Decision: REJECTED BEFORE MODEL4.**

The four-profile plateau passed the registered 2015-2020 discovery gate, then every profile lost money in the disjoint 2021-2023 holdout. All four were profitable in 2024 through July 16, 2026, demonstrating why recent-period profit alone is not evidence of future robustness.

## Frozen gate

Before Model4, a profile required positive net profit in both 2021-2023 and 2024-2026, 2021-2026 PF >= 1.20, at least 100 holdout trades, holdout drawdown <= 5%, full-history PF >= 1.20, and an adjacent survivor. Passed: **0 of 4**.

| Profile | 2015-20 net / PF | 2021-23 net / PF | 2024-26 net / PF | 2021-26 net / PF | Full net / PF | Full CAGR | Full DD | Decision |
|---|---:|---:|---:|---:|---:|---:|---:|---|
| `mtsm_m126_e20_r200` | +$335.18 / 1.50 | -$74.79 / 0.80 | +$116.71 / 2.20 | +$41.92 / 1.09 | +$377.10 / 1.33 | 0.32% | 1.22% | REJECT_BEFORE_MODEL4 |
| `mtsm_m126_e10_r200` | +$402.59 / 1.26 | -$158.30 / 0.81 | +$135.47 / 1.57 | -$22.83 / 0.98 | +$374.71 / 1.14 | 0.32% | 2.26% | REJECT_BEFORE_MODEL4 |
| `mtsm_m126_e10_r250` | +$381.39 / 1.25 | -$126.84 / 0.85 | +$111.80 / 1.47 | -$15.04 / 0.99 | +$360.93 / 1.14 | 0.31% | 2.16% | REJECT_BEFORE_MODEL4 |
| `mtsm_m126_e10_r150` | +$314.47 / 1.20 | -$206.87 / 0.76 | +$103.27 / 1.45 | -$96.85 / 0.91 | +$183.60 / 1.07 | 0.16% | 3.04% | REJECT_BEFORE_MODEL4 |

## Interpretation

- The recent gold regime favored the logic, but 2021-2023 did not. The family is regime-dependent rather than future-ready.
- The best full-history result was only $377.10 from a $10,000 starting balance, or 0.32% CAGR at 0.10% risk per trade.
- Raising risk would multiply both profit and drawdown but would not repair the losing holdout or PF failure.
- No Model4 run is justified because the faster registered gate already failed.

## Identity

- Source SHA-256: `92F7B079CD029E1A15F5BB8BA3BE53B1455B389AB39C77310DC98A4E4F593F69`
- mtsm_m126_e10_r200: 278B08BD964CF8DBCBD8AE2A21849DD7CCDAB2B39A4787B765D436A09EE3109F
- mtsm_m126_e20_r200: 5068419F5047FA3C94FCBA954D7B5779432F51DA6112FEE93C674DD365E373E7
- mtsm_m126_e10_r150: C434682C625B700ACEC7A770A072A06E213A85117469E174060EB664C5B878F8
- mtsm_m126_e10_r250: ED8CB644D29EECAC4260819E32AE3901CCA7D35E6D49C3787E259E4121FF5BD5
