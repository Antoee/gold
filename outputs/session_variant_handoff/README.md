# Session Variant Handoff

Fast first-pass check for session-filtered `tp38_sl18` variants against the current unfiltered promoted baseline.

This is not a promotion gate. It is a small probe to see whether session filtering deserves more tester time.

## Included Window

- `2026_YTD`: 2026.01.01 to 2026.07.02

## Candidate Sessions

Server-time assumptions:

- `tp38_sl18_london_07_16`: `InpUseSessionFilter=true`, hours `7` to `16`
- `tp38_sl18_newyork_13_22`: `InpUseSessionFilter=true`, hours `13` to `22`
- `tp38_sl18_overlap_13_16`: `InpUseSessionFilter=true`, hours `13` to `16`

Each candidate is paired with an unfiltered `baseline_promoted_*_pair` config on the same date window.

## Files

- Manifest: `outputs/session_variant_handoff/HANDOFF_MANIFEST.csv`
- Configs: `outputs/session_variant_handoff/configs/*.ini`
- Decision gate: `work/build_session_variant_decision.ps1`

## Safety

Do not run these configs on the active desktop while normal PC use must remain uninterrupted. Run them on a VM, spare Windows machine, VPS, or a deliberate controlled local session. All configs use `Visual=0` and `ShutdownTerminal=1`, but MT5 can still flash on some machines.

## Import And Decide

After reports are exported into `outputs`, parse and decide with:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\work\collect_validation_results.ps1 -ManifestPath "outputs\session_variant_handoff\HANDOFF_MANIFEST.csv" -ReportDir "outputs" -ReportNameTemplate "session_variant_{Profile}_{Window}" -OutResults "outputs\SESSION_VARIANT_REPORT_METRICS.csv" -OutSummary "outputs\SESSION_VARIANT_REPORT_SUMMARY.csv" -OutMarkdown "outputs\SESSION_VARIANT_REPORT_METRICS.md"
powershell -NoProfile -ExecutionPolicy Bypass -File .\work\build_session_variant_decision.ps1
```

Review:

- `outputs\SESSION_VARIANT_REPORT_METRICS.md`
- `outputs\SESSION_VARIANT_DECISION.md`

Only expand a session variant into stress micro and recent-OOS testing if it is profitable, beats its paired baseline, and does not create a drawdown concern.
