# Time Exit Probe Handoff

Offline handoff pack. No MT5 process was launched to create this file.

## Purpose

This 4-run probe checks whether closing stale positions after 240 minutes improves 2026 YTD behavior. Time exit is disabled in promoted profiles by default.

## Runs

| Config | Profile | Time Exit | Window |
|---|---|---:|---|
| `001_baseline_promoted_2026_ytd.ini` | `baseline_promoted` | off | `2026.01.01` to `2026.07.02` |
| `002_baseline_promoted_time_exit_2026_ytd.ini` | `baseline_promoted_time_exit` | on | `2026.01.01` to `2026.07.02` |
| `003_tp38_sl18_2026_ytd.ini` | `tp38_sl18` | off | `2026.01.01` to `2026.07.02` |
| `004_tp38_sl18_time_exit_2026_ytd.ini` | `tp38_sl18_time_exit` | on | `2026.01.01` to `2026.07.02` |

## Decision Gate

Pass only if each time-exit candidate:

- has a parsed report,
- has non-negative net profit,
- has net profit greater than or equal to its paired no-time-exit baseline,
- has drawdown reviewed before expansion.

After reports exist, import them with:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\work\import_all_available_reports.ps1
```

This wrapper imports exported reports only and does not launch MT5.
