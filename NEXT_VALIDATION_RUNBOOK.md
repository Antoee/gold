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
2. `work/build_fast_probe_readiness_snapshot.ps1`
3. `work/build_next_fast_batch_selector.ps1`
4. `work/import_mt5_compile_log.ps1` against the latest exported MetaEditor compile log
5. `work/build_external_mt5_validation_package.ps1`
6. `work/test_external_mt5_validation_package.ps1`
7. `work/import_external_mt5_validation_package_reports.ps1`
8. `work/build_external_mt5_micro_decision.ps1`
9. `work/build_external_validation_readiness.ps1`
10. `work/build_profit_readiness_snapshot.ps1`
11. `work/build_report_import_preflight.ps1`
12. `work/audit_handoff_config_integrity.ps1`
13. `work/audit_mt5_local_safety.ps1`

Expected current state:

- Optimization guardrails: 16 profiles audited, 16 require promotion review
- Fast-probe readiness: waiting for exported reports until the fast handoff packs are run/imported
- Next fast batch: `STRESS_SMOKE`, 2 rows, because it is the first pending gate
- External MT5 package: PASS, 8 micro configs packaged, 17 zip entries
- External validation readiness: `WAITING_FOR_REPORTS` until the four paired micro reports return
- Compile status: PASS only when the imported MetaEditor log shows `0 errors, 0 warnings`
- Readiness: `NOT_READY`
- Report import preflight: parser, manifest, guardrails, handoff, safety, and compile status pass; reports still missing
- Handoff integrity: PASS
- Local safety: PASS, no MT5 processes, unlock files absent, hard local launch lock present

## External MT5 Micro Package

`work/build_external_mt5_validation_package.ps1` creates `outputs/xauusd_micro_validation_package.zip` from `outputs/micro_test_handoff`. It packages:

- 8 paired stress-window configs for `tp38_sl18` versus `baseline_promoted`
- EA source
- promoted/candidate `.set` files
- manifest and expected-report checklist
- README for the external MT5 machine

`work/test_external_mt5_validation_package.ps1` audits the package offline. `work/build_external_validation_readiness.ps1` summarizes compile, package, and micro-decision state into one external-readiness snapshot. Passing the package does not prove profitability; it only makes the next external/non-interrupting MT5 run ready.

## After Reports Are Exported

1. Copy returned package reports into `outputs/external_mt5_validation_package/reports_here`.
2. Import the latest MetaEditor compile log with `work/import_mt5_compile_log.ps1`.
3. Run `work/import_external_mt5_validation_package_reports.ps1`.
4. Run `work/build_external_mt5_micro_decision.ps1`.
5. Run `work/build_external_validation_readiness.ps1`.
6. If external validation readiness is `READY_FOR_FULL_VALIDATION`, continue to the full handoff and phase-2 real-tick validation.
7. If broader profit-search reports changed, rerun `work/import_all_available_reports.ps1`, `work/analyze_profit_search.ps1`, `work/build_result_import_decision_matrix.ps1`, `work/build_optimization_guardrail_audit.ps1`, and `work/build_report_import_preflight.ps1`.
8. Build promotion packets only for candidates with complete evidence.

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