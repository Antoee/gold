# Recent Out-of-Sample Handoff

Fast freshness check for the protected `tp38_sl18` candidate against the current promoted baseline.

This package is intentionally small. It is not a promotion gate by itself; it tells us whether the candidate still deserves tester time on late-2025 and 2026 history.

## Included Windows

Each window is paired candidate vs baseline:

- `2025_Q4`: 2025.10.01 to 2025.12.31
- `2026_Q1`: 2026.01.01 to 2026.03.31
- `2026_Q2`: 2026.04.01 to 2026.06.30
- `2026_YTD`: 2026.01.01 to 2026.07.02

## Files

- Manifest: `outputs/recent_oos_handoff/HANDOFF_MANIFEST.csv`
- Configs: `outputs/recent_oos_handoff/configs/*.ini`
- Expert expected by configs: `Professional_XAUUSD_EA.ex5`
- Decision gate: `work/build_recent_oos_decision.ps1`

## Safety

Do not run these configs on the active desktop while normal PC use must remain uninterrupted. Run them on a VM, spare Windows machine, VPS, or a deliberate controlled local session. All configs use `Visual=0` and `ShutdownTerminal=1`, but MT5 can still flash on some machines.

## Decision Rule

- If `tp38_sl18` loses any recent-OOS paired window, keep the promoted baseline and deprioritize the candidate.
- If `tp38_sl18` matches or improves every paired window, continue to the full handoff and phase-2 real-tick validation.
- Do not promote from this handoff alone.

## Import And Decide

After reports are exported into `outputs`, parse and decide with:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\work\collect_validation_results.ps1 -ManifestPath "outputs\recent_oos_handoff\HANDOFF_MANIFEST.csv" -ReportDir "outputs" -ReportNameTemplate "recent_oos_{Profile}_{Window}" -OutResults "outputs\RECENT_OOS_REPORT_METRICS.csv" -OutSummary "outputs\RECENT_OOS_REPORT_SUMMARY.csv" -OutMarkdown "outputs\RECENT_OOS_REPORT_METRICS.md"
powershell -NoProfile -ExecutionPolicy Bypass -File .\work\build_recent_oos_decision.ps1
```

Review:

- `outputs\RECENT_OOS_REPORT_METRICS.md`
- `outputs\RECENT_OOS_DECISION.md`

Only continue to the full validation queue if the decision gate returns `PASS_RECENT_OOS`.
