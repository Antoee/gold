# Recent 2026 Fast-Triage Status

Generated locally without launching MT5.

## Local Change Summary

- Added a phase-1 fast-triage `2026_ytd` window to the profit-search config generator.
- Added `risk14_tp38_sl18`, a middle-ground candidate with `InpRiskPercent=1.40` and `InpTakeProfitATRMultiplier=3.80`.
- Updated the risk-adjusted micro batch to compare four profiles across four compact windows: `baseline_promoted`, `baseline_dd4`, `risk12_tp38_sl18`, and `risk14_tp38_sl18` on `2026_Q2`, `2026_ytd`, `2024_Q1`, and `2025_Q2`.
- Added `work/test_risk_adjusted_micro_batch_frontier.ps1` locally to protect the 16-run frontier shape, require `2026_ytd`, block aggressive-risk profiles, keep model 2 only, and cap estimated runtime at 6 minutes.
- Wired the frontier smoke into report-import preflight as `Risk-adjusted micro frontier smoke`.
- Updated `work/build_external_mt5_micro_decision.ps1` locally so returned reports produce a candidate summary table with score, parsed/pass/fail/waiting counts, risk percent, total net delta, risk-adjusted delta, and drawdown delta.
- Extended `work/test_external_mt5_micro_decision.ps1` locally to cover the `risk14_tp38_sl18` middle-ground candidate and verify the summary section is written.
- Added `work/audit_external_report_return_completeness.ps1` locally to compare `HANDOFF_MANIFEST.csv`, `EXPECTED_REPORTS.csv`, returned report files, and imported metrics before decisions are trusted.
- Updated `work/build_external_mt5_validation_package.ps1` locally to generate `RUN_RETURN_CHECKLIST.md` and `RUN_RETURN_CHECKLIST.csv` inside the external package.
- Updated `work/test_external_mt5_validation_package.ps1` locally to verify the run-return checklist is present, matches the current 16-report micro shape, and every packaged config `Report=` basename matches `EXPECTED_REPORTS.csv`.
- Updated `work/refresh_offline_validation_state.ps1` locally to rebuild external package report metrics, audit report-return completeness, and rebuild external micro decisions during the standard offline refresh.
- Wired report-return completeness into report-import preflight as `External report return`.
- Updated the external MT5 package audit to require the new 16-row micro-batch shape.

## Regenerated Local Evidence

- Profit-search manifest: 259 configs total.
- Phase 1 fast triage: 171 configs.
- Phase 2 real-tick validation: 88 configs.
- Micro batch: 16 runs.
- Micro batch estimated tester runtime: 5.27 minutes before platform overhead.
- Micro batch includes 4 fast `2026_ytd` runs: promoted baseline, drawdown-guard baseline, `risk12_tp38_sl18`, and `risk14_tp38_sl18`.
- External package now includes `RUN_RETURN_CHECKLIST.md` and `RUN_RETURN_CHECKLIST.csv`.
- External report return audit checks 16 expected reports and 16 imported metric rows.
- External micro decision now lists 3 candidates and 12 expected decision rows: `baseline_dd4`, `risk12_tp38_sl18`, and `risk14_tp38_sl18`, each across 4 windows.
- Offline refresh has 19 steps, including external report import, return completeness audit, and micro-decision rebuild.
- External MT5 validation package zip SHA-256: `6DE0C6D6607CCC2323B1F9D425F33FBCF4FBE44CDCBB1613A9CCE57F97528513`.
- Risk-adjusted micro handoff zip SHA-256: `AF7C4D599B2B1BA54CE6AD66F2284188BF24B6B62ED4CFB4D255D95C826E8DE3`.

## Verification

- `work/audit_external_report_return_completeness.ps1`: PASS, 9/9 checks, 0 parsed, 16 missing, 0 unparsed.
- `work/test_external_mt5_micro_decision.ps1`: `EXTERNAL_MT5_MICRO_DECISION_SMOKE_PASS`.
- `work/test_risk_adjusted_micro_batch_frontier.ps1`: `RISK_ADJUSTED_MICRO_BATCH_FRONTIER_SMOKE_PASS`.
- `work/refresh_offline_validation_state.ps1`: PASS, 19 steps, 0 failed.
- `outputs/EXTERNAL_MT5_PACKAGE_AUDIT.md`: PASS, 25/25 checks; run-return checklist included, package shape valid, config report targets match expected names, zip archive has 33 entries.
- `outputs/external_mt5_validation_package/RUN_RETURN_CHECKLIST.md`: lists all 16 expected report names and the no-promotion micro-triage rule.
- `outputs/EXTERNAL_MT5_REPORT_RETURN_AUDIT.md`: PASS, expected checklist matches manifest, imported metrics match manifest, current 4x4 micro frontier metrics present, no unexpected returned report files.
- `outputs/EXTERNAL_MT5_MICRO_DECISION.md`: contains `## Candidate Summary` and 12 waiting report rows for the current 3-candidate micro set.
- `outputs/REPORT_IMPORT_PREFLIGHT.md`: external report return PASS, external micro decision smoke PASS, risk-adjusted micro frontier smoke PASS, parser/risk guards/MT5 hidden launcher lock/source sync/handoff/local safety/external package PASS.
- Final local process scan: `NO_MT5_OR_METAEDITOR_PROCESSES_FOUND`.

## Important Caveat

The local generated scripts and outputs are updated in the workspace. This status note records the change on GitHub; the large script files still need a normal git push or connector full-file update to fully synchronize the repository.
