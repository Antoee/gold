# ATR Spread Guard Probe Handoff

Offline handoff pack. No MT5 process was launched to create this file.

## Purpose

This is a small 4-run probe for `InpUseATRSpreadGuard`. It compares the current fixed spread limit against an optional volatility-relative spread filter on 2026 YTD data.

The guard is disabled in the promoted profiles by default. A passing probe only earns more testing; it does not promote the feature by itself.

## Runs

| Config | Profile | Guard | Window |
|---|---|---:|---|
| `001_baseline_promoted_2026_ytd.ini` | `baseline_promoted` | off | `2026.01.01` to `2026.07.02` |
| `002_baseline_promoted_atr_spread_guard_2026_ytd.ini` | `baseline_promoted_atr_spread_guard` | on | `2026.01.01` to `2026.07.02` |
| `003_tp38_sl18_2026_ytd.ini` | `tp38_sl18` | off | `2026.01.01` to `2026.07.02` |
| `004_tp38_sl18_atr_spread_guard_2026_ytd.ini` | `tp38_sl18_atr_spread_guard` | on | `2026.01.01` to `2026.07.02` |

## Decision Gate

Pass only if each guarded candidate:

- has a parsed report,
- has non-negative net profit,
- has net profit greater than or equal to its paired unguarded baseline,
- has drawdown reviewed before expansion.

After reports exist, import them with:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\work\import_all_available_reports.ps1
```

This wrapper imports exported reports only and does not launch MT5.
