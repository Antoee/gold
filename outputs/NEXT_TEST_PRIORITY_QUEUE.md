# Next Test Priority Queue

Offline planning artifact. No MT5 process was launched.

The goal is to spend the least tester time necessary before making the next decision. Do not run a larger batch if a smaller gate already rejects the candidate.

## Order

| Priority | Gate | Batch | Rows | Pass Action | Fail Action |
|---:|---|---|---:|---|---|
| 1 | STATIC_SAFETY | Static repository audit | 1 | Proceed to stress micro if static safety passes. | Fix source/config safety before tester work. |
| 2 | STRESS_MICRO | `tp38_sl18` vs baseline stress windows | 8 | Proceed to recent-OOS only if all paired stress windows pass. | Reject or deprioritize `tp38_sl18`. |
| 3 | RECENT_OOS | `tp38_sl18` vs baseline recent freshness | 8 | Proceed to full handoff only if all recent-OOS windows pass. | Reject or deprioritize `tp38_sl18`. |
| 4 | MTF_TREND_PROBE | H1 200 EMA trend filter probe | 4 | Expand only passing MTF candidates into stress/recent-OOS validation. | Stop spending tester time on failed MTF variants. |
| 5 | SESSION_PROBE | `tp38_sl18` session variants vs unfiltered baseline | 6 | Expand only passing session candidates into stress/recent-OOS validation. | Stop spending tester time on failed session variants. |
| 6 | FULL_HANDOFF | Full candidate validation | 24 | Build promotion packet only if all gates pass. | Keep current promoted baseline. |

## Commands After Reports Exist

All available report packs can be imported with the wrapper:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\work\import_all_available_reports.ps1
```

Stress micro:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\work\collect_validation_results.ps1 -ManifestPath "outputs\micro_test_handoff\HANDOFF_MANIFEST.csv" -ReportDir "outputs" -ReportNameTemplate "profit_search_{PhaseShort}_{Profile}_{Set}_{Window}" -OutResults "outputs\MICRO_TEST_REPORT_METRICS.csv" -OutSummary "outputs\MICRO_TEST_REPORT_SUMMARY.csv" -OutMarkdown "outputs\MICRO_TEST_REPORT_METRICS.md"
powershell -NoProfile -ExecutionPolicy Bypass -File .\work\build_micro_test_decision.ps1
```

Recent-OOS:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\work\collect_validation_results.ps1 -ManifestPath "outputs\recent_oos_handoff\HANDOFF_MANIFEST.csv" -ReportDir "outputs" -ReportNameTemplate "recent_oos_{Profile}_{Window}" -OutResults "outputs\RECENT_OOS_REPORT_METRICS.csv" -OutSummary "outputs\RECENT_OOS_REPORT_SUMMARY.csv" -OutMarkdown "outputs\RECENT_OOS_REPORT_METRICS.md"
powershell -NoProfile -ExecutionPolicy Bypass -File .\work\build_recent_oos_decision.ps1
```

MTF trend probe:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\work\collect_validation_results.ps1 -ManifestPath "outputs\mtf_trend_probe_handoff\HANDOFF_MANIFEST.csv" -ReportDir "outputs" -ReportNameTemplate "mtf_probe_{Profile}_{Window}" -OutResults "outputs\MTF_TREND_PROBE_REPORT_METRICS.csv" -OutSummary "outputs\MTF_TREND_PROBE_REPORT_SUMMARY.csv" -OutMarkdown "outputs\MTF_TREND_PROBE_REPORT_METRICS.md"
powershell -NoProfile -ExecutionPolicy Bypass -File .\work\build_mtf_trend_probe_decision.ps1
```

Session probe:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\work\collect_validation_results.ps1 -ManifestPath "outputs\session_variant_handoff\HANDOFF_MANIFEST.csv" -ReportDir "outputs" -ReportNameTemplate "session_variant_{Profile}_{Window}" -OutResults "outputs\SESSION_VARIANT_REPORT_METRICS.csv" -OutSummary "outputs\SESSION_VARIANT_REPORT_SUMMARY.csv" -OutMarkdown "outputs\SESSION_VARIANT_REPORT_METRICS.md"
powershell -NoProfile -ExecutionPolicy Bypass -File .\work\build_session_variant_decision.ps1
```

## Bottom Line

Keep the current promoted profile until a candidate survives the small gates and the full promotion evidence. Fast-pack evidence can justify more testing, but it cannot justify promotion.
