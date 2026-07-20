# Four-Lane M15 Squeeze Diversifier Discovery Decision

**Decision: rejected in frozen pre-2021 discovery. No post-2020 test, Model 4 run, promotion, forward change, or live approval was opened.**

- Research source SHA-256: `5D756F58DDAB31D2DC909B8DD800C8D888582691A7208FFD7FD1E3F597D3A5C6`
- Four-worker EX5 SHA-256: `9BC3BAEC7D5BA0945E6974C960AC900D6F019C5A174D217712FF8B7E8137C32A`
- Reports: `15 / 15` parsed and identity-valid after one unchanged export recovery.
- Data: 2015-2020 Model 1 only; newer data remained unopened for this exact integration.
- Disabled four-position capacity control exactly reproduced the leader control: `True`.

| Candidate | SQ risk | 2015-18 | 2019-20 | Continuous | Change | CAGR | PF | PF retained | Trades | DD | Recovery | Gate |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| `sq_low0075` | `0.075%` | `+$1,101.86` | `+$436.32` | `+$1,503.41` | `8.95%` | `2.36%` | `1.79` | `95.21%` | `350` | `1.10%` | `12.83` | `fail/control` |
| `sq_exact_control` | `0.100%` | `+$1,036.19` | `+$370.60` | `+$1,379.93` | `0.00%` | `2.18%` | `1.88` | `100.00%` | `261` | `1.05%` | `11.68` | `fail/control` |
| `sq_capacity_control` | `0.100%` | `+$1,036.19` | `+$370.60` | `+$1,379.93` | `0.00%` | `2.18%` | `1.88` | `100.00%` | `261` | `1.05%` | `11.68` | `fail/control` |
| `sq_center0100` | `0.100%` | `+$1,141.49` | `+$459.89` | `+$1,575.70` | `14.19%` | `2.47%` | `1.78` | `94.68%` | `350` | `1.10%` | `13.44` | `fail/control` |
| `sq_high0125` | `0.125%` | `+$1,163.54` | `+$487.70` | `+$1,626.16` | `17.84%` | `2.54%` | `1.76` | `93.62%` | `350` | `1.10%` | `13.87` | `fail/control` |

Dollar profit, CAGR, activity, drawdown, recovery, and return/drawdown improved, but every enabled row failed the frozen 98% profit-factor retention requirement. The center is not rescued by weakening that gate after observation.

- The published leader, frozen forward candidate, invalid $100,000 demo registration, and real-account lock remain unchanged.
