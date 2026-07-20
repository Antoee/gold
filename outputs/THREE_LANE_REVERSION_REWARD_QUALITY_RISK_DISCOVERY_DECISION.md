# Reversion Reward-Quality Risk Discovery Decision

**Decision: rejected in frozen pre-2021 discovery. No holdout, Model 4, promotion, forward change, or live approval was opened.**

- Research source SHA-256: `A300713711328CE221447E452B889C0A2F9E449E2BF721BE7E49E0A354A4C416`
- Exact four-worker EX5 SHA-256: `65745C6F0F6651AA0050B8DEDDB76B4746DC06C2956CB1AD771B06103F713FA4`
- Reports: `21 / 21` parsed and identity-valid after two unchanged export recoveries.
- Data: 2015-2020 Model 1 only; no post-2020 data was opened.
- Risk: existing body-based `0.15`-lot cap retained; experimental strong risk `0.65%-0.75%`; portfolio cap and minimum-lot refusal unchanged.

| Candidate | Role | 2015-18 | 2019-20 | Continuous | Change | CAGR | PF | Trades | DD | Recovery | Decision |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| `rqri_control` | `control` | `+$1,036.19` | `+$370.60` | `+$1,379.93` | `0.00%` | `2.18%` | `1.88` | `261` | `1.05%` | `11.68` | rejected |
| `rqri_rr165` | `reward_upper` | `+$1,029.41` | `+$354.88` | `+$1,369.88` | `-0.73%` | `2.16%` | `1.87` | `261` | `1.06%` | `11.59` | rejected |
| `rqri_risk065` | `risk_lower` | `+$1,029.41` | `+$354.88` | `+$1,369.88` | `-0.73%` | `2.16%` | `1.87` | `261` | `1.06%` | `11.59` | rejected |
| `rqri_risk075` | `risk_upper` | `+$1,029.41` | `+$354.88` | `+$1,369.88` | `-0.73%` | `2.16%` | `1.87` | `261` | `1.06%` | `11.59` | rejected |
| `rqri_body070` | `body_risk_diagnostic` | `+$1,029.41` | `+$354.88` | `+$1,369.88` | `-0.73%` | `2.16%` | `1.87` | `261` | `1.06%` | `11.59` | rejected |
| `rqri_rr135` | `reward_lower` | `+$1,029.41` | `+$354.88` | `+$1,369.88` | `-0.73%` | `2.16%` | `1.87` | `261` | `1.06%` | `11.59` | rejected |
| `rqri_center150_070` | `center` | `+$1,029.41` | `+$354.88` | `+$1,369.88` | `-0.73%` | `2.16%` | `1.87` | `261` | `1.06%` | `11.59` | rejected |

The exact control remained best at `+$1,379.93`, `2.18%/yr` CAGR, PF `1.88`, and `1.05%` drawdown. Every strong-risk or reward-quality row returned the same `+$1,369.88`, `2.16%/yr` CAGR, PF `1.87`, and `1.06%` drawdown. Recent-era profit retention was only `95.76%`; recovery and return/drawdown also declined. The fixed RR thresholds did not discriminate among the body-qualified trades, so the interaction supplied no stable gain.

- Reject this reward-quality strong-risk interaction at the preregistered thresholds.
- Do not tune thresholds against post-2020 data or spend real-tick runs on this failed branch.
- Preserve the historical leader and invalid forward registration unchanged.
