# Fast Experiment Matrix

Offline planning artifact. No MT5 process was launched.

This matrix keeps tester time focused on the shortest gates that can reject a candidate before larger batches run.

| Priority | Experiment | Rows | Main Question | Pass Gate | If Pass |
|---:|---|---:|---|---|---|
| 1 | `STRESS_SMOKE` | 2 | Does `tp38_sl18` survive the first priority stress window? | Candidate parsed, non-negative, and >= paired baseline | Run stress micro |
| 2 | `STRESS_MICRO` | 8 | Does `tp38_sl18` survive known stress windows? | No losses, parsed reports, candidate >= baseline in every pair | Run recent-OOS |
| 3 | `RECENT_OOS` | 8 | Does `tp38_sl18` stay robust on 2025 Q4 and 2026 data? | No losses, parsed reports, candidate >= baseline in every pair | Run full handoff |
| 4 | `CONFIRMATION_PROBE` | 4 | Does requiring 3 confirmations improve 2026 behavior? | Candidate >= paired confirmation-2 profile and non-negative | Expand passing confirmation profile |
| 5 | `BREAKEVEN_PROBE` | 4 | Does break-even reduce risk without damaging 2026 profit? | Candidate >= paired BE-off profile and non-negative, or drawdown improves with small profit tradeoff | Expand passing break-even profile |
| 6 | `ADX_FILTER_PROBE` | 4 | Does ADX 18 filtering improve 2026 behavior? | Candidate >= paired no-ADX profile and non-negative | Expand passing ADX profile |
| 7 | `SPREAD_GUARD_PROBE` | 4 | Does ATR-relative spread filtering improve 2026 behavior? | Candidate >= paired unguarded profile and non-negative | Expand passing spread-guard profile |
| 8 | `TIME_EXIT_PROBE` | 4 | Does a 240-minute stale-trade exit improve 2026 behavior? | Candidate >= paired no-time-exit profile and non-negative | Expand passing time-exit profile |
| 9 | `MTF_TREND_PROBE` | 4 | Does H1 EMA 200 filtering help? | Candidate >= paired unfiltered profile and non-negative | Expand passing MTF profile |
| 10 | `STRUCTURE_TRAIL_PROBE` | 4 | Does structure trailing protect winners? | Candidate >= paired unfiltered profile and non-negative | Expand passing structure-trailing profile |
| 11 | `SESSION_PROBE` | 6 | Does session filtering improve 2026 behavior? | Candidate >= paired baseline and non-negative | Expand passing session profile |
| 12 | `FULL_HANDOFF` | 24 | Does a survivor beat the promoted baseline broadly? | Full net > `$866.59`, split aggregate > `$2354.65`, no losing required window | Build promotion packet |

## Rules

- Do not promote from any fast probe alone.
- Do not expand a candidate that loses money in its fast probe.
- Do not expand a candidate that underperforms its paired baseline unless the probe is explicitly a risk-reduction review with materially lower drawdown and only a small profit tradeoff.
- If reports are missing or unparsed, repair report export/parsing before making a decision.
- Keep `ROBUST_BOS_SWEEP_PROFILE.set` promoted until a survivor passes the full promotion gate.

## Import Shortcut

All available report packs can be imported with the wrapper:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\work\import_all_available_reports.ps1
```

Stress smoke can also be imported alone with:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\work\import_stress_smoke_reports.ps1
```

Break-even reports can also be imported alone with:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\work\import_breakeven_probe_reports.ps1
```

All wrappers import exported reports only and do not launch MT5.
