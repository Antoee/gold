# Stress Smoke Handoff

Offline handoff pack. No MT5 process was launched to create this file.

## Purpose

This 2-run smoke gate is the fastest rejection test before the full 8-run stress micro pack. It tests the top TP 3.80 candidate against the promoted baseline on the first priority stress window, `2024_Q1`.

## Runs

| Config | Profile | Window | Report |
|---|---|---|---|
| `001_tp38_sl18_stress_smoke_2024_Q1_phase1_fast_triage.ini` | `tp38_sl18` | `2024.01.01` to `2024.03.31` | `outputs\stress_smoke_phase1_tp38_sl18_2024_Q1` |
| `002_baseline_promoted_stress_smoke_2024_Q1_phase1_fast_triage.ini` | `baseline_promoted` | `2024.01.01` to `2024.03.31` | `outputs\stress_smoke_phase1_baseline_promoted_2024_Q1` |

## Decision Rule

If `tp38_sl18` loses money or underperforms the paired promoted baseline, stop and keep the promoted profile unchanged. If it passes, run the full 8-row `STRESS_MICRO` handoff next.

After reports exist, import them with:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\work\import_stress_smoke_reports.ps1
```

This imports exported reports only and does not launch MT5.
