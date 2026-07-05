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
4. `work/build_profit_readiness_snapshot.ps1`
5. `work/build_report_import_preflight.ps1`
6. `work/audit_handoff_config_integrity.ps1`
7. `work/audit_mt5_local_safety.ps1`

Expected current state:

- Optimization guardrails: 16 profiles audited, 16 require promotion review, top score `giveback25_tp38=87`
- Fast-probe readiness: waiting for exported reports until the fast handoff packs are run/imported
- Next fast batch: `STRESS_MICRO`, 8 rows, because it is the first pending gate
- Readiness: `NOT_READY`
- Report import preflight: parser, manifest, guardrails, handoff, and safety pass; reports still missing
- Handoff integrity: PASS
- Local safety: PASS 24/24, no MT5 processes, both unlock files absent

## After Reports Are Exported

1. Copy MT5 HTML reports into the expected output folder.
2. Rerun `work/import_all_available_reports.ps1` to import available reports, rebuild probe decisions, refresh readiness snapshots, and select the next smallest useful batch.
3. Rerun `work/analyze_profit_search.ps1` if full profit-search reports changed.
4. Rerun `work/build_result_import_decision_matrix.ps1` if full profit-search reports changed.
5. Rerun `work/build_optimization_guardrail_audit.ps1`.
6. Rerun `work/build_report_import_preflight.ps1`.
7. Build promotion packets only for candidates with complete evidence.

## Promotion Rule

Never promote from phase 1 or a single strong window. A replacement must pass profit, no-loss windows, drawdown/profit-factor checks, promotion gate, optimization guardrails, fast-probe readiness, next-batch selector review, profile-input audit, handoff integrity, local-safety audit, decision matrix, readiness snapshot, report-import preflight, strategy thesis, and coverage checks.

## Optimization Guardrails

`work/build_optimization_guardrail_audit.ps1` reads generated profile `.set` files and the profit-search manifest, then writes:

- `outputs/OPTIMIZATION_GUARDRAIL_AUDIT.csv`
- `outputs/OPTIMIZATION_GUARDRAIL_AUDIT.md`

It ranks test-eligible candidates while flagging risk and overfit concerns before tester time is spent. Current top test-eligible profiles are `giveback25_tp38`, `giveback35_tp38`, `baseline_promoted`, and `tp38_sl18`; all require promotion review because equity drawdown guard is disabled and adaptive reverse needs walk-forward proof.

## Fast-Probe Readiness

`work/build_fast_probe_readiness_snapshot.ps1` reads all imported fast-probe decision CSVs and writes:

- `outputs/FAST_PROBE_READINESS_SNAPSHOT.csv`
- `outputs/FAST_PROBE_READINESS_SNAPSHOT.md`

It summarizes stress micro, recent-OOS, confirmation, break-even, ADX, spread guard, time exit, MTF trend, structure trailing, and session probes. Fast-probe evidence can justify expanding a candidate into broader validation, but it cannot promote a profile by itself.

## Next Fast Batch Selector

`work/build_next_fast_batch_selector.ps1` reads the fast experiment matrix and readiness snapshot, then writes:

- `outputs/NEXT_FAST_BATCH_SELECTION.csv`
- `outputs/NEXT_FAST_BATCH_SELECTION.md`

It chooses the first pending or blocking gate in priority order, so tester time is spent on the smallest useful next batch instead of running everything at once.

## Local MT5 Safety

`work/audit_mt5_local_safety.ps1` is a fail-closed preflight for the user's PC usability requirement. Current expected result is `PASS`: no MT5 process running, both local unlock files absent, both MT5 unlock env flags off, all MT5 runner scripts guarded, no raw terminal launch bypass, watchdog available, and handoff integrity passing.
