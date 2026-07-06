# Recent 2026 Fast-Triage Status

Generated locally without launching MT5.

## Local Change Summary

- Added a phase-1 fast-triage `2026_ytd` window to the profit-search config generator.
- Added `risk14_tp38_sl18`, a middle-ground candidate with `InpRiskPercent=1.40` and `InpTakeProfitATRMultiplier=3.80`.
- Updated the risk-adjusted micro batch to compare four profiles across four compact windows: `baseline_promoted`, `baseline_dd4`, `risk12_tp38_sl18`, and `risk14_tp38_sl18` on `2026_Q2`, `2026_ytd`, `2024_Q1`, and `2025_Q2`.
- Added `work/test_risk_adjusted_micro_batch_frontier.ps1` locally to protect the 16-run frontier shape, require `2026_ytd`, block aggressive-risk profiles, keep model 2 only, and cap estimated runtime at 6 minutes.
- Wired the frontier smoke into report-import preflight as `Risk-adjusted micro frontier smoke`.
- Updated external MT5 package handling locally so returned reports produce a candidate summary, report-return completeness audit, and run-return checklist.
- Added `work/build_local_pipeline_manifest.ps1` locally to hash important EA, package, audit, batch, and decision artifacts.
- Updated `work/refresh_offline_validation_state.ps1` locally so the standard offline refresh now rebuilds the local pipeline manifest before report-import preflight.
- Added `work/start_mt5_focus_watchdog_hidden.ps1` locally and updated the safety audit for active quiet-shield mode. It starts a detached hidden watchdog that only hides/stops MT5-family processes if they appear; it does not launch MT5.

## Regenerated Local Evidence

- Profit-search manifest: 259 configs total.
- Phase 1 fast triage: 171 configs.
- Phase 2 real-tick validation: 88 configs.
- Micro batch: 16 runs.
- Micro batch estimated tester runtime: 5.27 minutes before platform overhead.
- Micro batch includes 4 fast `2026_ytd` runs: promoted baseline, drawdown-guard baseline, `risk12_tp38_sl18`, and `risk14_tp38_sl18`.
- Local pipeline manifest: 22 tracked artifacts, 0 missing.
- Offline refresh: 20 steps, 0 failed.
- Local MT5 safety audit: PASS, 39/39 checks, 56 runner scripts guarded.
- Hidden MT5 focus watchdog: active in quiet-shield mode; stop marker absent; MT5/MetaEditor process scan clean.
- External package includes `RUN_RETURN_CHECKLIST.md` and `RUN_RETURN_CHECKLIST.csv`.
- External report return audit checks 16 expected reports and 16 imported metric rows.
- External micro decision lists 3 candidates and 12 expected decision rows: `baseline_dd4`, `risk12_tp38_sl18`, and `risk14_tp38_sl18`, each across 4 windows.
- External MT5 validation package zip SHA-256: `6DE0C6D6607CCC2323B1F9D425F33FBCF4FBE44CDCBB1613A9CCE57F97528513`.
- Risk-adjusted micro handoff zip SHA-256: `AF7C4D599B2B1BA54CE6AD66F2284188BF24B6B62ED4CFB4D255D95C826E8DE3`.

## Verification

- `work/audit_mt5_local_safety.ps1`: PASS, 39/39 checks, hidden quiet-shield mode accepted, no MT5/MetaEditor process running.
- `work/build_local_pipeline_manifest.ps1`: PASS, 22 tracked artifacts, 0 missing.
- `work/refresh_offline_validation_state.ps1`: PASS, 20 steps, 0 failed.
- `work/audit_external_report_return_completeness.ps1`: PASS, 9/9 checks, 0 parsed, 16 missing, 0 unparsed.
- `work/test_external_mt5_micro_decision.ps1`: `EXTERNAL_MT5_MICRO_DECISION_SMOKE_PASS`.
- `work/test_risk_adjusted_micro_batch_frontier.ps1`: `RISK_ADJUSTED_MICRO_BATCH_FRONTIER_SMOKE_PASS`.
- `outputs/EXTERNAL_MT5_PACKAGE_AUDIT.md`: PASS, 25/25 checks; run-return checklist included, package shape valid, config report targets match expected names, zip archive has 33 entries.
- `outputs/EXTERNAL_MT5_REPORT_RETURN_AUDIT.md`: PASS, expected checklist matches manifest, imported metrics match manifest, current 4x4 micro frontier metrics present, no unexpected returned report files.
- `outputs/REPORT_IMPORT_PREFLIGHT.md`: local pipeline manifest PASS, local safety PASS, external report return PASS, risk-adjusted micro frontier smoke PASS, external micro decision is `COMPILE_REQUIRED` because compile trust remains stale and 12 reports are still waiting.
- Final local process scan: `NO_MT5_OR_METAEDITOR_PROCESSES_FOUND`.

## Important Caveat

The local generated scripts and outputs are updated in the workspace. This status note records the change on GitHub; the large script files still need a normal git push or connector full-file update to fully synchronize the repository.
