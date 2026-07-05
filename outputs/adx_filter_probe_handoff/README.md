# ADX Filter Probe Handoff

Offline handoff pack. No MT5 process was launched to create this file.

## Purpose

This 4-run probe checks whether requiring `InpMinADX=18.0` improves 2026 YTD behavior by avoiding weak/ranging conditions. `InpMinADX=0.0` remains pinned in promoted profiles by default.

## Runs

| Config | Profile | Min ADX | Window |
|---|---|---:|---|
| `001_baseline_promoted_2026_ytd.ini` | `baseline_promoted` | `0.0` | `2026.01.01` to `2026.07.02` |
| `002_baseline_promoted_adx18_2026_ytd.ini` | `baseline_promoted_adx18` | `18.0` | `2026.01.01` to `2026.07.02` |
| `003_tp38_sl18_2026_ytd.ini` | `tp38_sl18` | `0.0` | `2026.01.01` to `2026.07.02` |
| `004_tp38_sl18_adx18_2026_ytd.ini` | `tp38_sl18_adx18` | `18.0` | `2026.01.01` to `2026.07.02` |

## Decision Gate

Pass only if each ADX-filter candidate:

- has a parsed report,
- has non-negative net profit,
- has net profit greater than or equal to its paired unfiltered baseline,
- has drawdown reviewed before expansion.

After reports exist, import them with:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\work\import_all_available_reports.ps1
```

This wrapper imports exported reports only and does not launch MT5.
