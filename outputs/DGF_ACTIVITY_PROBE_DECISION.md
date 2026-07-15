# DGF Activity Probe Decision

Current source hash: `3C738B730A47A089ECE11A53EC9E726DE2E64B63E53866B9731253C5035A114C`.

## Verdict

**Rejected for promotion.** All `45 / 45` hidden local Model1 reports parsed. Removing the DGF no-cushion loss block restored activity only at higher representable risk, but no candidate met both growth and broad-window stability requirements.

| Candidate | Continuous Net | Annualized | PF | Trades | DD | Losing Years |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `dfa_lb_off_fullrisk` | `+$62.38` | `0.83%/yr` | `1.38` | `109` | `3.60%` | `3` |
| `dfa_lb_off_throttle075` | `+$1.18` | `0.02%/yr` | `1.01` | `61` | `2.52%` | `4` |
| `dfa_lb_off_throttle025` | `-$0.96` | `-0.01%/yr` | `0.81` | `5` | `0.82%` | `3` |
| `dfa_lb_on_throttle050` | `-$1.34` | `-0.02%/yr` | `0.91` | `11` | `1.13%` | `6` |
| `dfa_lb_off_throttle050` | `-$12.06` | `-0.16%/yr` | `0.26` | `11` | `1.84%` | `6` |

The best candidate lost in 2019, 2022, and 2025. Its 2024 window made `+8.05%`, while 2026 YTD took zero trades. It remains recent-regime dependent and economically too weak.

Evidence: `outputs/DGF_ACTIVITY_PROBE_RESULTS.csv`, `outputs/DGF_ACTIVITY_PROBE_SUMMARY.csv`, and `outputs/DGF_ACTIVITY_PROBE_METRICS.md`.
