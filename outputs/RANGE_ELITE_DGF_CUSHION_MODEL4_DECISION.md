# Range-Elite DGF Cushion-Risk Model4 Decision

Date: 2026-07-14

Verdict: **USEFUL RISK-SHAPE PROBE, NO PROMOTION**

This run tested a default-off risk throttle for diagnostic-fallback trades. The idea is to reduce DGF position size until the account has a closed-profit cushion, instead of deleting whole sessions or months. This is a better risk-management shape than another hard calendar cutoff, but it still does not clear the broad-window stability gate.

## Source And Compile Evidence

- EA source hash: `C23144DDE1F26C29135489FC9DF065FC5B5575C0B3F1B388BECC01E70E5965B4`
- Root/mirror source sync: `PASS`
- Exposed MT5 tester inputs: `316 / 1000`
- Static preflight: `STATIC_MQL_COMPILE_PREFLIGHT_PASS checks=33 inputs=316`
- Hidden compile proof: `outputs/MT5_HIDDEN_COMPILE_DGF_CUSHION_RISK.log`
- Compile result: `0 errors, 0 warnings`

The source adds these default-off inputs:

- `InpUseDiagnosticFallbackCushionRiskThrottle`
- `InpDiagnosticFallbackCushionProfitPercent`
- `InpDiagnosticFallbackNoCushionRiskMultiplier`

When enabled, DGF trades use the configured reduced risk until closed profit reaches the configured cushion percentage.

## Model4 Evidence

- Cushion package: `outputs/RANGE_ELITE_DGF_CUSHION_MODEL4_PACKAGE.md`
- Cushion metrics: `outputs/RANGE_ELITE_DGF_CUSHION_MODEL4_REPORT_METRICS.md`
- August follow-up package: `outputs/RANGE_ELITE_DGF_CUSHION_AUG_MODEL4_PACKAGE.md`
- August follow-up metrics: `outputs/RANGE_ELITE_DGF_CUSHION_AUG_MODEL4_REPORT_METRICS.md`
- Model: `4` real ticks
- Windows: `2019`, `2021`, `2023`, `2024`, `2025`, `2026 YTD`
- Exported reports parsed: `54 / 54`
- Log-only rows: `0`

## Candidate Summary

| Candidate | Total Net | Worst Window | Worst DD % | Trades | Decision |
| --- | ---: | ---: | ---: | ---: | --- |
| `re_may140_late15_dgf_liq_reject1` | `+$3,218.26` | `-$40.20` | `24.72` | `30` | Higher-profit research lead, still red |
| `re_may140_late15_dgf_liq_reject1_cush50` | `+$2,770.74` | `-$38.49` | `20.84` | `36` | Best cushion risk shape, still red in 2019 |
| `re_may140_late15_dgf_liq_reject1_cush35` | `+$2,294.11` | `-$39.13` | `20.76` | `50` | More defensive, still red in 2019 |
| `re_may140_late15_dgf_liq_reject1_cush25` | `+$2,196.77` | `-$55.38` | `20.76` | `51` | Rejected: lower total and worse 2019 |
| `re_may140_late15_dgf_liq_reject1_cush50_augoff` | `+$2,764.89` | `-$20.95` | `20.84` | `29` | Rejected: calendar rule turns 2025 red |
| `re_may140_late15_dgf_liq_reject1_cush35_augoff` | `+$2,293.93` | `-$26.02` | `20.76` | `29` | Rejected: calendar rule turns 2025 red |

## Best Cushion Variant

`re_may140_late15_dgf_liq_reject1_cush50` is the best safety-shape candidate from this probe. It gives up about `+$447.52` versus the higher-profit research lead, but reduces worst drawdown from `24.72%` to `20.84%` and flips 2021 and 2025 green.

| Window | Net | Annualized Return % | PF | Trades | DD % |
| --- | ---: | ---: | ---: | ---: | ---: |
| 2019 | `-$38.49` | `-3.86` | `0.00` | `4` | `3.85` |
| 2021 | `+$12.98` | `1.30` | `1.44` | `2` | `14.51` |
| 2023 | `+$310.15` | `31.12` | `3.71` | `8` | `20.84` |
| 2024 | `+$2,105.17` | `210.66` | `5.47` | `7` | `14.58` |
| 2025 | `+$23.39` | `2.35` | `1.40` | `8` | `9.58` |
| 2026 YTD | `+$357.54` | `68.02` | `4.80` | `7` | `15.79` |

## August-Off Follow-Up

The August-off variants are rejected even though they remove the 2019 red trades. The rule is too calendar-specific, and in this package it created a new red 2025 window:

- `cush50_augoff`: 2025 `-$20.95`
- `cush35_augoff`: 2025 `-$26.02`

This is not a robust enough tradeoff.

## Decision

Keep the default-off DGF cushion-risk throttle in source for future risk-shape tests. Do not promote the profile. The best cushion variant is safer than the high-profit range-elite lead, but it still has a red 2019 window and drawdown remains above a money-ready target.
