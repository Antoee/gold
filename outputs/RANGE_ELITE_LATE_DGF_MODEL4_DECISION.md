# Range-Elite Late Diagnostic-Fallback Guard Decision

Date: 2026-07-14

Verdict: **REJECTED, NO NEW BEST**

This follow-up tested a narrower strategy-code guard for weak diagnostic-fallback entries late in the New York session. The guard is useful as a diagnostic tool, but none of the tested variants cleared the broad-window stability gate.

## Source And Compile Evidence

- EA source hash: `129A489FECFE46470E5417FAD8C98B83E14A691D1370CA493F52A5E59B1E022B`
- Root/mirror source sync: `PASS`
- Exposed MT5 tester inputs: `311 / 1000`
- Static preflight: `STATIC_MQL_COMPILE_PREFLIGHT_PASS checks=33 inputs=311`
- Hidden compile proof: `outputs/MT5_HIDDEN_COMPILE_DGF_LATE_SESSION_GUARD.log`
- Compile result: `0 errors, 0 warnings`

The source adds these default-off inputs:

- `InpUseDiagnosticFallbackLateSessionGuard`
- `InpDiagnosticFallbackLateSessionStartHour`
- `InpDiagnosticFallbackLateSessionPureOnly`

When enabled, the guard blocks pure diagnostic-fallback entries at or after the configured late-session hour. It does not change default behavior.

## Model4 Evidence

- Shortlist package: `outputs/RANGE_ELITE_GUARD_MODEL4_SHORTLIST_PACKAGE.md`
- Shortlist metrics: `outputs/RANGE_ELITE_GUARD_MODEL4_SHORTLIST_REPORT_METRICS.md`
- Late-DGF package: `outputs/RANGE_ELITE_LATE_DGF_MODEL4_PACKAGE.md`
- Late-DGF metrics: `outputs/RANGE_ELITE_LATE_DGF_MODEL4_REPORT_METRICS.md`
- Late15 May140 package: `outputs/RANGE_ELITE_LATE15_MAY140_MODEL4_PACKAGE.md`
- Late15 May140 metrics: `outputs/RANGE_ELITE_LATE15_MAY140_MODEL4_REPORT_METRICS.md`
- Model: `4` real ticks
- Windows: `2019`, `2021`, `2023`, `2024`, `2025`, `2026 YTD`
- Exported reports parsed: `60 / 60` across the three focused packages
- Log-only rows: `0`

## Candidate Summary

| Candidate | Total Net | Worst Window | Worst DD % | Trades | Decision |
| --- | ---: | ---: | ---: | ---: | --- |
| `re_base` | `+$2,854.93` | `-$131.33` | `27.87` | `57` | Baseline only |
| `re_blockliq` | `+$2,854.93` | `-$131.33` | `27.87` | `57` | No effect versus base |
| `re_may140` | `+$3,166.19` | `-$140.18` | `24.28` | `41` | Rejected: still red in 2019/2021/2023 |
| `re_may140_late16_pure` | `+$3,209.31` | `-$140.18` | `24.28` | `39` | Slight total improvement, still 3 red windows |
| `re_dgf_late16_pure` | `+$2,033.04` | `-$131.33` | `31.55` | `39` | Rejected: lower total, worse DD |
| `re_dgf_late15_pure` | `+$1,906.27` | `-$62.11` | `31.55` | `24` | Rejected: fewer red windows but lower total and worse DD |
| `re_may140_late15_pure` | `+$3,108.10` | `-$62.11` | `24.72` | `26` | Rejected: improves worst window, gives back 2026 profit and stays red in 2019/2021 |

## Best Diagnostic Finding

`re_may140_late15_pure` is the most informative variant. It turned 2023 positive and reduced the worst losing window from `-$140.18` to `-$62.11`, but it also cut 2026 YTD from `+$871.35` to `+$472.36`, lowered total net versus `re_may140_late16_pure`, and still lost in 2019 and 2021.

Per-window evidence:

| Window | Net | Annualized Return % | PF | Trades | DD % |
| --- | ---: | ---: | ---: | ---: | ---: |
| 2019 | `-$40.20` | `-4.03` | `0.00` | `1` | `4.02` |
| 2021 | `-$62.11` | `-6.23` | `0.40` | `2` | `20.85` |
| 2023 | `+$157.60` | `15.81` | `2.31` | `3` | `14.53` |
| 2024 | `+$2,366.15` | `236.78` | `5.66` | `7` | `14.51` |
| 2025 | `+$214.30` | `21.50` | `4.96` | `3` | `11.97` |
| 2026 YTD | `+$472.36` | `89.86` | `2.32` | `10` | `24.72` |

## Decision

Do not promote any late-session diagnostic-fallback guard profile. Keep the default-off guard in source because it gives a clean switch for future testing, but the current evidence still shows older-year fragility.

Next strategy work should focus on why 2019 and 2021 produce low-quality diagnostic-fallback trades at all. A market-phase or structure-quality entry filter is more likely to help than another calendar/session-only cutoff.
