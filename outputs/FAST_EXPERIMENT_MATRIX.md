# Fast Experiment Matrix

Offline planning artifact. No MT5 process was launched.

This matrix keeps tester time focused on the shortest gates that can reject a candidate before larger batches run.

| Priority | Experiment | Rows | Main Question | Pass Gate | If Pass |
|---:|---|---:|---|---|---|
| 1 | `STRESS_MICRO` | 8 | Does `tp38_sl18` survive known stress windows? | No losses, parsed reports, candidate >= baseline in every pair | Run recent-OOS |
| 2 | `RECENT_OOS` | 8 | Does `tp38_sl18` stay robust on 2025 Q4 and 2026 data? | No losses, parsed reports, candidate >= baseline in every pair | Run full handoff |
| 3 | `MTF_TREND_PROBE` | 4 | Does H1 EMA 200 filtering help? | Candidate >= paired unfiltered profile and non-negative | Expand passing MTF profile |
| 4 | `STRUCTURE_TRAIL_PROBE` | 4 | Does structure trailing protect winners? | Candidate >= paired unfiltered profile and non-negative | Expand passing structure-trailing profile |
| 5 | `SESSION_PROBE` | 6 | Does session filtering improve 2026 behavior? | Candidate >= paired baseline and non-negative | Expand passing session profile |
| 6 | `FULL_HANDOFF` | 24 | Does a survivor beat the promoted baseline broadly? | Full net > `$866.59`, split aggregate > `$2354.65`, no losing required window | Build promotion packet |

## Rules

- Do not promote from any fast probe alone.
- Do not expand a candidate that loses money in its fast probe.
- Do not expand a candidate that underperforms its paired baseline.
- If reports are missing or unparsed, repair report export/parsing before making a decision.
- Keep `ROBUST_BOS_SWEEP_PROFILE.set` promoted until a survivor passes the full promotion gate.

## Import Shortcut

After reports exist, use:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\work\import_all_available_reports.ps1
```

That wrapper imports available report packs and rebuilds their decision files without launching MT5.
