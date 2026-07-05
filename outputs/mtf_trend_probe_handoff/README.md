# MTF Trend Probe Handoff

Offline planning artifact. No MT5 process was launched while creating this pack.

This is a four-run probe for the new optional higher-timeframe EMA trend filter in `Professional_XAUUSD_EA.mq5` version `1.05`.

## Purpose

The goal is to check whether an H1 200 EMA directional filter improves 2026 robustness before spending time on a full walk-forward batch.

The filter is disabled in the promoted root profiles so existing baseline evidence stays comparable. This pack only tests it as a candidate.

## Runs

| Row | Profile | MTF Filter | Window |
|---:|---|---|---|
| 1 | `baseline_promoted` | off | `2026_YTD` |
| 2 | `baseline_promoted_h1_mtf` | H1 EMA 200 | `2026_YTD` |
| 3 | `tp38_sl18` | off | `2026_YTD` |
| 4 | `tp38_sl18_h1_mtf` | H1 EMA 200 | `2026_YTD` |

## Files

- Manifest: `outputs/mtf_trend_probe_handoff/HANDOFF_MANIFEST.csv`
- Configs: `outputs/mtf_trend_probe_handoff/configs/*.ini`
- Expected reports: `outputs/mtf_probe_<profile>_2026_YTD.*`

## Import After Reports Exist

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\work\collect_validation_results.ps1 -ManifestPath "outputs\mtf_trend_probe_handoff\HANDOFF_MANIFEST.csv" -ReportDir "outputs" -ReportNameTemplate "mtf_probe_{Profile}_{Window}" -OutResults "outputs\MTF_TREND_PROBE_REPORT_METRICS.csv" -OutSummary "outputs\MTF_TREND_PROBE_REPORT_SUMMARY.csv" -OutMarkdown "outputs\MTF_TREND_PROBE_REPORT_METRICS.md"
powershell -NoProfile -ExecutionPolicy Bypass -File .\work\build_mtf_trend_probe_decision.ps1
```

## Decision Rule

- If an H1 MTF candidate loses money or underperforms its unfiltered pair, do not expand it.
- If an H1 MTF candidate beats its unfiltered pair and stays profitable, expand it into stress micro and recent-OOS validation.
- Do not promote from this probe alone.
