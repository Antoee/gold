# Four-Lane M15 Squeeze Target Interaction Decision

**Decision: rejected in frozen pre-2021 discovery. No post-2020 test, Model 4 run, promotion, forward change, or live approval was opened.**

- Research source SHA-256: `5D756F58DDAB31D2DC909B8DD800C8D888582691A7208FFD7FD1E3F597D3A5C6`
- Reused four-worker EX5 SHA-256: `9BC3BAEC7D5BA0945E6974C960AC900D6F019C5A174D217712FF8B7E8137C32A`
- Reports: `18 / 18` parsed and identity-valid after three unchanged export recoveries.
- Data: 2015-2020 Model 1 only; newer data remained unopened for this exact interaction.
- Disabled capacity control exact: `True`; enabled 1.50R reference exact: `True`.

| Candidate | Target | 2015-18 | 2019-20 | Continuous | Change | CAGR | PF | PF retained | Trades | DD | Recovery | Gate |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| `sqt_capacity_control` | `1.50R` | `+$1,036.19` | `+$370.60` | `+$1,379.93` | `0.00%` | `2.18%` | `1.88` | `100.00%` | `261` | `1.05%` | `11.68` | `fail/control` |
| `sqt_exact_control` | `1.50R` | `+$1,036.19` | `+$370.60` | `+$1,379.93` | `0.00%` | `2.18%` | `1.88` | `100.00%` | `261` | `1.05%` | `11.68` | `fail/control` |
| `sqt_reference150` | `1.50R` | `+$1,141.49` | `+$459.89` | `+$1,575.70` | `14.19%` | `2.47%` | `1.78` | `94.68%` | `350` | `1.10%` | `13.44` | `fail/control` |
| `sqt_low175` | `1.75R` | `+$1,188.87` | `+$481.00` | `+$1,656.33` | `20.03%` | `2.59%` | `1.82` | `96.81%` | `350` | `1.10%` | `14.13` | `fail/control` |
| `sqt_center200` | `2.00R` | `+$1,188.37` | `+$478.80` | `+$1,658.76` | `20.21%` | `2.59%` | `1.82` | `96.81%` | `350` | `1.10%` | `13.40` | `fail/control` |
| `sqt_high225` | `2.25R` | `+$1,231.44` | `+$512.55` | `+$1,753.53` | `27.07%` | `2.73%` | `1.87` | `99.47%` | `350` | `1.10%` | `14.16` | `pass` |

The 2.25R upper edge met the numeric neighbor gate and had the highest headline result, but the preregistered 2.00R center retained only 96.81% of control PF versus the required 98%. Selecting the observed upper edge or moving the center after observation is forbidden.

- The published leader, frozen forward candidate, invalid $100,000 demo registration, and real-account lock remain unchanged.
