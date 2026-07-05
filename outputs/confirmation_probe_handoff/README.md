# Confirmation Strictness Probe Handoff

Offline handoff pack. No MT5 process was launched to create this file.

## Purpose

This 4-run probe checks whether requiring `InpMinimumConfirmations=3` improves 2026 YTD behavior compared with the promoted default of `2`. The idea is fewer but higher-quality entries, which may reduce drawdown and weak signals.

## Runs

| Config | Profile | Confirmations | Window |
|---|---|---:|---|
| `001_baseline_promoted_2026_ytd.ini` | `baseline_promoted` | `2` | `2026.01.01` to `2026.07.02` |
| `002_baseline_promoted_confirm3_2026_ytd.ini` | `baseline_promoted_confirm3` | `3` | `2026.01.01` to `2026.07.02` |
| `003_tp38_sl18_2026_ytd.ini` | `tp38_sl18` | `2` | `2026.01.01` to `2026.07.02` |
| `004_tp38_sl18_confirm3_2026_ytd.ini` | `tp38_sl18_confirm3` | `3` | `2026.01.01` to `2026.07.02` |

## Decision Gate

Pass only if each stricter-confirmation candidate:

- has a parsed report,
- has non-negative net profit,
- has net profit greater than or equal to its paired confirmation-2 baseline,
- has drawdown reviewed before expansion.

After reports exist, import them with:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\work\import_all_available_reports.ps1
```

This wrapper imports exported reports only and does not launch MT5.
