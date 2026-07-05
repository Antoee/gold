# Next Validation Runbook

No MT5 process should be launched from this workspace during normal PC use. Local launch is hard-locked and requires all four explicit controls: `ALLOW_MT5_FOCUS_RISK=1`, `ALLOW_MT5_HIDDEN_DESKTOP_ACK=1`, `work\ALLOW_MT5_LOCAL_LAUNCH.unlock`, and `work\ALLOW_MT5_HIDDEN_DESKTOP_ACK.unlock`.

## Current Default

Keep `risk1p6_sl18_tp35` promoted until a candidate passes phase-2 real ticks and the full promotion gate.

Current evidence:

- Full period `2024.01.01` to `2026.07.02`: `+$866.59`
- Split aggregate: `+$2,354.65`, worst `$0.00`, 0 losing windows
- Monthly/quarter aggregate: `+$744.03`, worst `$0.00`, 0 losing windows

## Offline Preflight Order

Run these without launching MT5:

1. `work/build_optimization_guardrail_audit.ps1`
2. `work/build_risk_adjusted_micro_batch.ps1`
3. `work/build_next_test_handoff.ps1 -BatchCsv outputs\RISK_ADJUSTED_MICRO_BATCH.csv -OutDir outputs\risk_adjusted_micro_handoff -ZipPath outputs\risk_adjusted_micro_handoff.zip`
4. `work/audit_handoff_config_integrity.ps1 -ManifestPath outputs\risk_adjusted_micro_handoff\HANDOFF_MANIFEST.csv -OutCsv outputs\RISK_ADJUSTED_MICRO_HANDOFF_INTEGRITY.csv -OutMarkdown outputs\RISK_ADJUSTED_MICRO_HANDOFF_INTEGRITY.md -ZipPath outputs\risk_adjusted_micro_handoff.zip`
5. `work/build_fast_probe_readiness_snapshot.ps1`
6. `work/build_next_fast_batch_selector.ps1`
7. `work/import_mt5_compile_log.ps1` against the latest exported MetaEditor compile log
8. `work/build_external_mt5_validation_package.ps1`
9. `work/test_external_mt5_validation_package.ps1`
10. `work/import_external_mt5_validation_package_reports.ps1`
11. `work/test_external_mt5_micro_decision.ps1`
12. `work/build_external_mt5_micro_decision.ps1`
13. `work/build_external_validation_readiness.ps1`
14. `work/build_profit_readiness_snapshot.ps1`
15. `work/build_report_import_preflight.ps1`
16. `work/audit_handoff_config_integrity.ps1`
17. `work/audit_mt5_local_safety.ps1`

Expected current state:

- Optimization guardrails: 17 profiles audited, 17 require promotion review
- Profit-search manifest: 202 expected configs, 136 phase-1 fast triage and 66 phase-2 real-tick validation
- Risk-adjusted micro batch: 12 rows selected from 202 configs, with baseline anchors plus `baseline_dd4` and `tp38_sl18` stress windows
- Risk-adjusted micro handoff integrity: PASS, 12 configs checked, 12 passed
- Fast-probe readiness: waiting for exported reports until the fast handoff packs are run/imported
- Next fast batch: `STRESS_SMOKE`, 2 rows, because it is the first pending gate
- External MT5 package: PASS, 8 micro configs packaged, 17 zip entries
- External micro decision smoke: PASS for pass/reject/repair/waiting branches
- External validation readiness: `WAITING_FOR_REPORTS` until the four paired micro reports return
- Compile status: PASS only when the imported MetaEditor log shows `0 errors, 0 warnings`
- Readiness: `NOT_READY`
- Report import preflight: parser, manifest, guardrails, handoff, safety, and compile status pass; reports still missing
- Handoff integrity: PASS
- Local safety: PASS, no MT5 processes, unlock files absent, hard local launch lock present

## Risk-Adjusted Micro Batch

`work/build_risk_adjusted_micro_batch.ps1` writes `outputs/RISK_ADJUSTED_MICRO_BATCH.csv` and `outputs/RISK_ADJUSTED_MICRO_BATCH.md` without launching MT5. It is the first choice when tester time is limited because it:

- repairs unparsed reports before adding more runs
- includes same-window baseline anchors for fair comparison
- prioritizes cheap phase-1 stress windows
- caps rows per profile so one idea cannot consume the whole testing window
- penalizes higher risk, far TP extensions, tighter stops, and promotion-rejected profiles

The current local selection is 12 runs: 5 `baseline_promoted` anchors, 4 `baseline_dd4` stress windows, and 3 `tp38_sl18` stress windows. `baseline_dd4` changes only `InpMaxEquityDrawdownPercent=4.00`, so it tests drawdown protection without changing entry or exit logic. The handoff package is built with:

`work/build_next_test_handoff.ps1 -BatchCsv outputs\RISK_ADJUSTED_MICRO_BATCH.csv -OutDir outputs\risk_adjusted_micro_handoff -ZipPath outputs\risk_adjusted_micro_handoff.zip`

Audit it with:

`work/audit_handoff_config_integrity.ps1 -ManifestPath outputs\risk_adjusted_micro_handoff\HANDOFF_MANIFEST.csv -OutCsv outputs\RISK_ADJUSTED_MICRO_HANDOFF_INTEGRITY.csv -OutMarkdown outputs\RISK_ADJUSTED_MICRO_HANDOFF_INTEGRITY.md -ZipPath outputs\risk_adjusted_micro_handoff.zip`

This batch can only produce triage evidence. Never promote from it alone.

## External MT5 Micro Package

`work/build_external_mt5_validation_package.ps1` creates `outputs/xauusd_micro_validation_package.zip` from `outputs/micro_test_handoff`. It packages:

- 8 paired stress-window configs for `tp38_sl18` versus `baseline_promoted`
- EA source
- promoted/candidate `.set` files
- manifest and expected-report checklist
- README for the external MT5 machine

`work/test_external_mt5_validation_package.ps1` audits the package offline. `work/test_external_mt5_micro_decision.ps1` verifies the decision gate with synthetic metrics. `work/build_external_validation_readiness.ps1` summarizes compile, package, and micro-decision state into one external-readiness snapshot. Passing the package does not prove profitability; it only makes the next external/non-interrupting MT5 run ready.

## After Reports Are Exported

1. Copy returned package reports into `outputs/external_mt5_validation_package/reports_here`.
2. Import the latest MetaEditor compile log with `work/import_mt5_compile_log.ps1`.
3. Run `work/import_external_mt5_validation_package_reports.ps1`.
4. Run `work/test_external_mt5_micro_decision.ps1`.
5. Run `work/build_external_mt5_micro_decision.ps1`.
6. Run `work/build_external_validation_readiness.ps1`.
7. If external validation readiness is `READY_FOR_FULL_VALIDATION`, continue to the full handoff and phase-2 real-tick validation.
8. If broader profit-search reports changed, rerun `work/import_all_available_reports.ps1`, `work/analyze_profit_search.ps1`, `work/build_result_import_decision_matrix.ps1`, `work/build_optimization_guardrail_audit.ps1`, `work/build_risk_adjusted_micro_batch.ps1`, and `work/build_report_import_preflight.ps1`.
9. Build promotion packets only for candidates with complete evidence.

## Promotion Rule

Never promote from phase 1 or a single strong window. A replacement must pass profit, no-loss windows, drawdown/profit-factor checks, promotion gate, optimization guardrails, fast-probe readiness, next-batch selector review, profile-input audit, handoff integrity, local-safety audit, compile status, decision matrix, readiness snapshot, report-import preflight, strategy thesis, and coverage checks.

## Fast-Probe Readiness

`work/build_fast_probe_readiness_snapshot.ps1` reads all imported fast-probe decision CSVs and writes `outputs/FAST_PROBE_READINESS_SNAPSHOT.md`. It summarizes stress smoke, stress micro, recent-OOS, confirmation, break-even, ADX, spread guard, time exit, news filter, MTF trend, structure trailing, and session probes. Fast-probe evidence can justify expanding a candidate into broader validation, but it cannot promote a profile by itself.

## Next Fast Batch Selector

`work/build_next_fast_batch_selector.ps1` writes `outputs/NEXT_FAST_BATCH_SELECTION.md`. It chooses the first pending or blocking gate in priority order, so tester time is spent on the smallest useful next batch instead of running everything at once.

## Compile Status

`work/import_mt5_compile_log.ps1` parses an exported MetaEditor compile log into `outputs/MT5_COMPILE_STATUS.csv` and `outputs/MT5_COMPILE_STATUS.md`. It starts nothing. Treat `PASS` as compile proof only; it does not prove profitability.

## Local MT5 Safety

`work/audit_mt5_local_safety.ps1` is a fail-closed preflight for the user's PC usability requirement. Expected result is `PASS`: no MT5 process running, local unlock files absent, MT5 unlock env flags off, hard local launch lock present, all MT5 runner scripts guarded, no raw terminal launch bypass, watchdog available, and handoff integrity passing.