# Portfolio-Solo Strong Reversion Lot-Cap Discovery Decision

**Decision: rejected in frozen pre-2021 discovery. No post-2020 test, Model 4 run, promotion, forward change, or live approval was opened.**

- Research source SHA-256: `726BCABFA64C25FA3D22E78B41AB4868EA8D5235609294F7ED68DC3DB9088EEE`
- Four-worker EX5 SHA-256: `712BA114BB0589E34AC32D1A487A958CB6BAD0C4CEC3417F03400119A99EBFC8`
- Reports: `15 / 15` parsed and identity-valid after one unchanged export recovery.
- Data: 2015-2020 Model 1 only; newer data remained unopened for this exact code rule.

| Candidate | Solo cap | 2015-18 | Change | 2019-20 | Change | Continuous | Change | CAGR | PF | Trades | DD | Recovery | Gate |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| `rvsolo_low017` | `0.17` | `+$1,056.38` | `1.95%` | `+$388.33` | `4.78%` | `+$1,417.85` | `2.75%` | `2.23%` | `1.91` | `261` | `1.15%` | `11.63` | `fail/control` |
| `rvsolo_control015` | `0.18` | `+$1,036.19` | `0.00%` | `+$370.60` | `0.00%` | `+$1,379.93` | `0.00%` | `2.18%` | `1.88` | `261` | `1.05%` | `11.68` | `fail/control` |
| `rvsolo_center018` | `0.18` | `+$1,058.66` | `2.17%` | `+$388.33` | `4.78%` | `+$1,416.50` | `2.65%` | `2.23%` | `1.90` | `261` | `1.17%` | `11.40` | `fail/control` |
| `rvsolo_high019` | `0.19` | `+$1,060.94` | `2.39%` | `+$388.33` | `4.78%` | `+$1,427.65` | `3.46%` | `2.25%` | `1.90` | `261` | `1.20%` | `11.28` | `fail/control` |
| `rvsolo_boundary020` | `0.20` | `+$1,058.60` | `2.16%` | `+$388.33` | `4.78%` | `+$1,425.31` | `3.29%` | `2.25%` | `1.90` | `261` | `1.22%` | `11.06` | `fail/control` |

The fixed center and its neighborhood did not satisfy the frozen broad-era gate. The lot cap is not moved after observation.

- The published leader, frozen forward candidate, invalid $100,000 demo registration, and real-account lock remain unchanged.
