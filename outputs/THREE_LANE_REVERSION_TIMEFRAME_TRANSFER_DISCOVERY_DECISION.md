# Reversion Timeframe-Transfer Discovery Decision

**Decision: rejected in frozen pre-2021 discovery. No holdout, Model 4, promotion, forward change, or live approval was opened.**

- Exact leader source SHA-256: `B6810B305549968E2273DAAF736A63759FE5C16F3B416F5C69E39840FBE5173E`
- Exact four-worker EX5 SHA-256: `D9B60597A7D44D142FD9283147B1C32BED61B7A4A7FD4EA2462D6E59439719B4`
- Reports: `21 / 21` parsed and identity-valid after two unchanged export recoveries.
- Risk: `0.45%` requested reversion risk; `0.75%` portfolio cap; minimum-lot refusal unchanged.
- Data: 2015-2020 Model 1 only.

| Candidate | Family | 2015-18 | 2019-20 | Continuous | CAGR | PF | Trades | DD | Recovery | Decision |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| `rvtf_h1_control` | `h1` | `+$482.90` | `+$89.73` | `+$568.70` | `0.93%` | `3.19` | `19` | `0.88%` | `6.45` | rejected |
| `rvtf_h2_local` | `h2` | `+$194.31` | `+$132.62` | `+$326.93` | `0.54%` | `3.77` | `7` | `0.91%` | `3.44` | rejected |
| `rvtf_h2_duration` | `h2` | `+$41.80` | `+$0.00` | `+$41.80` | `0.07%` | `2.17` | `2` | `0.71%` | `0.59` | rejected |
| `rvtf_h2_mid` | `h2` | `-$45.91` | `-$1.87` | `-$47.78` | `-0.08%` | `0.61` | `4` | `1.09%` | `-0.44` | rejected |
| `rvtf_m30_duration` | `m30` | `-$118.63` | `+$67.03` | `-$51.60` | `-0.09%` | `0.73` | `7` | `2.16%` | `-0.24` | rejected |
| `rvtf_m30_mid` | `m30` | `-$10.03` | `-$86.74` | `-$96.77` | `-0.16%` | `0.82` | `22` | `3.11%` | `-0.31` | rejected |
| `rvtf_m30_local` | `m30` | `+$5.68` | `-$307.99` | `-$302.31` | `-0.51%` | `0.38` | `20` | `5.04%` | `-0.59` | rejected |

The isolated H1 control remained profitable at `+$568.70`, PF `3.19`, and `0.93%/yr`, but produced only 19 trades. H2 local made `+$326.93` from seven trades; its two horizon neighbors failed. Every M30 row lost continuously, from `-$51.60` to `-$302.31`. No adjacent family supplied the required activity, broad-era profitability, and support.

- Reject M30/H2 timeframe transfer at these fixed horizons.
- Do not tune the failed M30 rows or open post-2020 data.
- Preserve the historical leader and invalid forward registration unchanged.
