# Profit Search Batch Rationale

Generated without launching MT5. This explains why the current next batch is worth tester time.

- Batch source: `outputs\NEXT_PROFIT_SEARCH_BATCH.csv`
- Profiles source: `work\generated_profit_search\PROFIT_SEARCH_PROFILES.csv`
- Runs explained: 24
- Phase-1 fast triage runs: 24
- Phase-2 real-tick runs: 0

## Rationale Summary

| Tier | Runs |
|---|---:|
| Adjacent upside | 11 |
| Evidence-backed upside | 8 |
| Baseline anchor | 5 |

## Profile Coverage In This Batch

| Profile | Runs | First Rank | Tier | Family | Risk Note |
|---|---:|---:|---|---|---|
| `baseline_promoted` | 5 | 1 | Baseline anchor | baseline | normal |
| `tp38_sl18` | 4 | 5 | Evidence-backed upside | take_profit_stop | normal |
| `tp42_sl18` | 4 | 9 | Adjacent upside | take_profit_stop | normal |
| `tp38_sl16` | 4 | 13 | Evidence-backed upside | take_profit_stop | normal |
| `tp42_sl16` | 4 | 17 | Adjacent upside | take_profit_stop | normal |
| `tp45_sl18` | 3 | 22 | Adjacent upside | take_profit_stop | normal |

## Run-Level Rationale

| Rank | Profile | Set | Window | Model | Tier | Why | Decision |
|---:|---|---|---|---:|---|---|---|
| 1 | `baseline_promoted` | stress | 2024_Q1 | 2 | Baseline anchor | Required comparison anchor for detecting data drift and candidate uplift. | Run as fast prune only; do not promote from this result. |
| 2 | `baseline_promoted` | stress | 2024_Q3 | 2 | Baseline anchor | Required comparison anchor for detecting data drift and candidate uplift. | Run as fast prune only; do not promote from this result. |
| 3 | `baseline_promoted` | stress | 2025_Q2 | 2 | Baseline anchor | Required comparison anchor for detecting data drift and candidate uplift. | Run as fast prune only; do not promote from this result. |
| 4 | `baseline_promoted` | stress | 2025_Q3 | 2 | Baseline anchor | Required comparison anchor for detecting data drift and candidate uplift. | Run as fast prune only; do not promote from this result. |
| 5 | `tp38_sl18` | stress | 2024_Q1 | 2 | Evidence-backed upside | Matches the TP 3.8 / SL 1.6-1.8 thesis from existing zero-loss stress evidence. | Run as fast prune only; do not promote from this result. |
| 6 | `tp38_sl18` | stress | 2024_Q3 | 2 | Evidence-backed upside | Matches the TP 3.8 / SL 1.6-1.8 thesis from existing zero-loss stress evidence. | Run as fast prune only; do not promote from this result. |
| 7 | `tp38_sl18` | stress | 2025_Q2 | 2 | Evidence-backed upside | Matches the TP 3.8 / SL 1.6-1.8 thesis from existing zero-loss stress evidence. | Run as fast prune only; do not promote from this result. |
| 8 | `tp38_sl18` | stress | 2025_Q3 | 2 | Evidence-backed upside | Matches the TP 3.8 / SL 1.6-1.8 thesis from existing zero-loss stress evidence. | Run as fast prune only; do not promote from this result. |
| 9 | `tp42_sl18` | stress | 2024_Q1 | 2 | Adjacent upside | Nearby TP expansion around the current evidence-backed profit search. | Run as fast prune only; do not promote from this result. |
| 10 | `tp42_sl18` | stress | 2024_Q3 | 2 | Adjacent upside | Nearby TP expansion around the current evidence-backed profit search. | Run as fast prune only; do not promote from this result. |
| 11 | `tp42_sl18` | stress | 2025_Q2 | 2 | Adjacent upside | Nearby TP expansion around the current evidence-backed profit search. | Run as fast prune only; do not promote from this result. |
| 12 | `tp42_sl18` | stress | 2025_Q3 | 2 | Adjacent upside | Nearby TP expansion around the current evidence-backed profit search. | Run as fast prune only; do not promote from this result. |
| 13 | `tp38_sl16` | stress | 2024_Q1 | 2 | Evidence-backed upside | Matches the TP 3.8 / SL 1.6-1.8 thesis from existing zero-loss stress evidence. | Run as fast prune only; do not promote from this result. |
| 14 | `tp38_sl16` | stress | 2024_Q3 | 2 | Evidence-backed upside | Matches the TP 3.8 / SL 1.6-1.8 thesis from existing zero-loss stress evidence. | Run as fast prune only; do not promote from this result. |
| 15 | `tp38_sl16` | stress | 2025_Q2 | 2 | Evidence-backed upside | Matches the TP 3.8 / SL 1.6-1.8 thesis from existing zero-loss stress evidence. | Run as fast prune only; do not promote from this result. |
| 16 | `tp38_sl16` | stress | 2025_Q3 | 2 | Evidence-backed upside | Matches the TP 3.8 / SL 1.6-1.8 thesis from existing zero-loss stress evidence. | Run as fast prune only; do not promote from this result. |
| 17 | `tp42_sl16` | stress | 2024_Q1 | 2 | Adjacent upside | Nearby TP expansion around the current evidence-backed profit search. | Run as fast prune only; do not promote from this result. |
| 18 | `tp42_sl16` | stress | 2024_Q3 | 2 | Adjacent upside | Nearby TP expansion around the current evidence-backed profit search. | Run as fast prune only; do not promote from this result. |
| 19 | `tp42_sl16` | stress | 2025_Q2 | 2 | Adjacent upside | Nearby TP expansion around the current evidence-backed profit search. | Run as fast prune only; do not promote from this result. |
| 20 | `tp42_sl16` | stress | 2025_Q3 | 2 | Adjacent upside | Nearby TP expansion around the current evidence-backed profit search. | Run as fast prune only; do not promote from this result. |
| 21 | `baseline_promoted` | full | full | 2 | Baseline anchor | Required comparison anchor for detecting data drift and candidate uplift. | Run as fast prune only; do not promote from this result. |
| 22 | `tp45_sl18` | stress | 2024_Q1 | 2 | Adjacent upside | Nearby TP expansion around the current evidence-backed profit search. | Run as fast prune only; do not promote from this result. |
| 23 | `tp45_sl18` | stress | 2024_Q3 | 2 | Adjacent upside | Nearby TP expansion around the current evidence-backed profit search. | Run as fast prune only; do not promote from this result. |
| 24 | `tp45_sl18` | stress | 2025_Q2 | 2 | Adjacent upside | Nearby TP expansion around the current evidence-backed profit search. | Run as fast prune only; do not promote from this result. |

## Guardrail

This rationale does not prove profitability. It only prioritizes scarce tester time. A candidate still needs parsed reports, phase-2 real ticks, zero losing validation windows, and the promotion gate before replacing the promoted default.
