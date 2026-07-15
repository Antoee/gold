# Range-Elite DGF No-Cushion Loss-Block Model4 Decision

Date: 2026-07-14

Verdict: **SUPERSEDED RESTART-WINDOW RESEARCH LEAD, NOT MONEY-READY**

## 2026-07-14 Continuous-Account Addendum

This decision has been superseded by `outputs/PEAK_TRAIL_UNBLOCK_CONTINUOUS_MODEL4_DECISION.md`.

The broad-window totals below are still useful for comparing restart-window behavior, but they are not achievable sequential account-return claims. A continuous 2019-2026 Model4 follow-up showed the original peak-trail-on high-profit and stability profiles stalled after only `3` trades (`-$7.36` and `+$0.68`). The only profitable DGF follow-up was `lossblock_highprofit_peaktrail_off` at `+$1,915.83`, PF `1.72`, `127` trades, and `24.58%` max equity DD. That is a high-profit research lead only, not trade-ready.

This run tested a default-off diagnostic-fallback entry gate. The gate blocks new DGF entries while the account has no closed-profit cushion if recent DGF performance is weak. This is not a month filter; it is a general capital-protection rule based on the strategy's own recent DGF results.

## Source And Compile Evidence

- EA source hash: `F254FDF07B932FD8009E1ABFD761D1C9195568596A559F0DCB73A8CD29157D8F`
- Root/mirror source sync: `PASS`
- Exposed MT5 tester inputs: `327 / 1000`
- Static preflight: `STATIC_MQL_COMPILE_PREFLIGHT_PASS checks=33 inputs=327`
- Hidden compile proof: `outputs/MT5_HIDDEN_COMPILE_DGF_LOSS_BLOCK.log`
- Compile result: `0 errors, 0 warnings`

The source adds these default-off inputs:

- `InpUseDiagnosticFallbackNoCushionLossBlock`
- `InpDiagnosticFallbackLossBlockCushionPercent`
- `InpDiagnosticFallbackLossBlockLookbackTrades`
- `InpDiagnosticFallbackLossBlockMinTrades`
- `InpDiagnosticFallbackLossBlockMaxAverageR`

## Evidence

- Fast-screen package: `outputs/RANGE_ELITE_DGF_LOSSBLOCK_MODEL1_PACKAGE.md`
- Fast-screen metrics: `outputs/RANGE_ELITE_DGF_LOSSBLOCK_MODEL1_REPORT_METRICS.md`
- Model4 package: `outputs/RANGE_ELITE_DGF_LOSSBLOCK_MODEL4_PACKAGE.md`
- Model4 metrics: `outputs/RANGE_ELITE_DGF_LOSSBLOCK_MODEL4_REPORT_METRICS.md`
- Model: `4` real ticks for final check
- Windows: `2019`, `2021`, `2023`, `2024`, `2025`, `2026 YTD`
- Exported Model4 reports parsed: `18 / 18`
- Log-only rows: `0`

## Model4 Summary

| Candidate | Total Net | Worst Window | Worst DD % | Min PF | Trades | Decision |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| `re_may140_late15_dgf_liq_reject1_cush50` | `+$2,770.74` | `-$38.49` | `20.84` | `0.00` | `36` | Prior cushion baseline |
| `re_may140_late15_dgf_liq_reject1_cush50_dgflossblock` | `+$2,800.21` | `-$7.36` | `20.84` | `0.88` | `32` | New high-profit research lead |
| `re_may140_late15_dgf_liq_reject1_cush35_dgflossblock` | `+$2,323.11` | `+$0.68` | `20.76` | `1.01` | `31` | New broad-window stability lead |

## High-Profit Lead

`re_may140_late15_dgf_liq_reject1_cush50_dgflossblock` improves total net and greatly reduces the worst broad-window loss while preserving the strong 2024 and 2026 engines.

| Window | Net | Annualized Return % | CAGR % | PF | Trades |
| --- | ---: | ---: | ---: | ---: | ---: |
| 2019 | `-$7.36` | `-0.74` | `-0.74` | `0.88` | `3` |
| 2021 | `+$12.98` | `1.30` | `1.30` | `1.44` | `2` |
| 2023 | `+$310.15` | `31.12` | `31.14` | `3.71` | `8` |
| 2024 | `+$2,105.17` | `210.66` | `210.76` | `5.47` | `7` |
| 2025 | `+$21.73` | `2.18` | `2.18` | `1.44` | `5` |
| 2026 YTD | `+$357.54` | `68.02` | `78.87` | `4.80` | `7` |

## Stability Lead

`re_may140_late15_dgf_liq_reject1_cush35_dgflossblock` is the only tested range-elite DGF loss-block candidate with no red broad windows in this package, but the margins are very thin in 2019, 2025, and 2026 YTD.

| Window | Net | Annualized Return % | CAGR % | PF | Trades |
| --- | ---: | ---: | ---: | ---: | ---: |
| 2019 | `+$0.68` | `0.07` | `0.07` | `1.01` | `3` |
| 2021 | `+$21.98` | `2.21` | `2.21` | `2.09` | `2` |
| 2023 | `+$271.62` | `27.26` | `27.27` | `3.47` | `8` |
| 2024 | `+$2,009.01` | `201.04` | `201.13` | `5.40` | `7` |
| 2025 | `+$2.48` | `0.25` | `0.25` | `1.04` | `5` |
| 2026 YTD | `+$17.34` | `3.30` | `3.32` | `1.42` | `6` |

## Decision

Promote the no-cushion DGF loss block as a useful default-off strategy control and record two new research leads:

- High-profit lead: `re_may140_late15_dgf_liq_reject1_cush50_dgflossblock`
- Broad-window stability lead: `re_may140_late15_dgf_liq_reject1_cush35_dgflossblock`

Profile aliases:

- High-profit file: `outputs/CANDIDATE_RANGE_ELITE_HIGH_PROFIT_DGF_LOSSBLOCK_PROFILE.set`
- High-profit SHA-256: `1C0CF498F243ED6002FB74BBE3EA0247348B40F410B12EA74CD4720B998A9543`
- Stability file: `outputs/CANDIDATE_RANGE_ELITE_STABILITY_DGF_LOSSBLOCK_PROFILE.set`
- Stability SHA-256: `306BB06F12768F7E9439827CC8C7125E7103BFF08742CD6B2B57EAD2C2C50B86`

Do not call either money-ready. The best drawdown is still about `20.76%`, trade counts are low in several years, and the stability lead's positive windows are too thin. Next validation should target drawdown reduction and full trade-quality/stress evidence before any live-money discussion.
