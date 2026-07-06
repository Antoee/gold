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
- Updated `work/refresh_offline_validation_state.ps1` locally to rebuild external package report metrics and external micro decisions during the standard offline refresh.
- Updated the external MT5 package audit to require the new 16-row micro-batch shape.

## Regenerated Local Evidence

- Profit-search manifest: 259 configs total.
- Phase 1 fast triage: 171 configs.
- Phase 2 real-tick validation: 88 configs.
- Micro batch: 16 runs.
- Micro batch estimated tester runtime: 5.27 minutes before platform overhead.
- Micro batch includes 4 fast `2026_ytd` runs: promoted baseline, drawdown-guard baseline, `risk12_tp38_sl18`, and `risk14_tp38_sl18`.
- External micro decision now lists 3 candidates and 12 expected decision rows: `baseline_dd4`, `risk12_tp38_sl18`, and `risk14_tp38_sl18`, each across 4 windows.
- Offline refresh now has 18 steps, including external report import and micro-decision rebuild.
- External MT5 validation package zip SHA-256: `BAFBFF8685A8FE28414C80637A3D219C958E066B1A30DB17AB7345C1C85E6E17`.
- Risk-adjusted micro handoff zip SHA-256: `AF7C4D599B2B1BA54CE6AD66F2284188BF24B6B62ED4CFB4D255D95C826E8DE3`.

## Verification

- `work/test_external_mt5_micro_decision.ps1`: `EXTERNAL_MT5_MICRO_DECISION_SMOKE_PASS`.
- `work/test_risk_adjusted_micro_batch_frontier.ps1`: `RISK_ADJUSTED_MICRO_BATCH_FRONTIER_SMOKE_PASS`.
- `work/refresh_offline_validation_state.ps1`: PASS, 18 steps, 0 failed.
- `outputs/EXTERNAL_MT5_PACKAGE_AUDIT.md`: PASS, 22/22 checks, 16 configs packaged.
- `outputs/EXTERNAL_MT5_MICRO_DECISION.md`: contains `## Candidate Summary` and 12 waiting report rows for the current 3-candidate micro set.
- `outputs/REPORT_IMPORT_PREFLIGHT.md`: external micro decision smoke PASS, risk-adjusted micro frontier smoke PASS, parser/risk guards/MT5 hidden launcher lock/source sync/handoff/local safety/external package PASS.
- Final local process scan: `NO_MT5_OR_METAEDITOR_PROCESSES_FOUND`.

## Important Caveat

The local generated scripts and outputs are updated in the workspace. This status note records the change on GitHub; the large script files still need a normal git push or connector full-file update to fully synchronize the repository.
