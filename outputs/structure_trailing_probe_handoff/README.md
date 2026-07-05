# Structure Trailing Probe Handoff

Offline planning artifact. No MT5 process was launched while creating this pack.

This is a four-run probe for the optional structure trailing stop in `Professional_XAUUSD_EA.mq5` version `1.06`.

## Purpose

The goal is to check whether trailing stops behind recent M15 structure can protect winners and improve 2026 robustness before spending time on a full walk-forward batch.

The module is disabled in the promoted root profiles so existing baseline evidence stays comparable. This pack only tests it as a candidate.

## Runs

| Row | Profile | Structure Trail | Window |
|---:|---|---|---|
| 1 | `baseline_promoted` | off | `2026_YTD` |
| 2 | `baseline_promoted_structure_trail` | on | `2026_YTD` |
| 3 | `tp38_sl18` | off | `2026_YTD` |
| 4 | `tp38_sl18_structure_trail` | on | `2026_YTD` |

## Import After Reports Exist

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\work\collect_validation_results.ps1 -ManifestPath "outputs\structure_trailing_probe_handoff\HANDOFF_MANIFEST.csv" -ReportDir "outputs" -ReportNameTemplate "structure_probe_{Profile}_{Window}" -OutResults "outputs\STRUCTURE_TRAILING_PROBE_REPORT_METRICS.csv" -OutSummary "outputs\STRUCTURE_TRAILING_PROBE_REPORT_SUMMARY.csv" -OutMarkdown "outputs\STRUCTURE_TRAILING_PROBE_REPORT_METRICS.md"
powershell -NoProfile -ExecutionPolicy Bypass -File .\work\build_structure_trailing_probe_decision.ps1
```

## Decision Rule

- If a structure-trailing candidate loses money or underperforms its unfiltered pair, do not expand it.
- If a structure-trailing candidate beats its unfiltered pair and stays profitable, expand it into stress micro and recent-OOS validation.
- Do not promote from this probe alone.
