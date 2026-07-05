# Controlled Profit Test Runbook

This project is currently in evidence-gathering mode. Do not promote a new profile because it looks promising in configuration alone; promotion requires parsed MT5 reports.

## Current Baseline

- Current promoted profile: `risk1p6_sl18_tp35` / `ROBUST_BOS_SWEEP_PROFILE.set`
- Known full-period result, 2024-01-01 to 2026-07-02: `+$866.59`
- Known split aggregate: `+$2354.65`
- Known validation outcome: zero losing split windows in the existing evidence

## Current Candidate

- Candidate: `tp38_sl18`
- Key override: `InpTakeProfitATRMultiplier=3.80`
- Risk guard: `InpMaxEquityDrawdownPercent=4.00`
- Promotion packet status: `MISSING_EVIDENCE`
- Promotion is blocked until reports are parsed and every gate passes.

## Test Prerequisite

The MT5 terminal used for testing must have `Professional_XAUUSD_EA.ex5` installed in its Experts folder before any handoff config can run. The configs reference that compiled expert directly.

The GitHub source is present as `Professional_XAUUSD_EA.mq5`, but it has not been compiled or tested in this remote-only safety pass. Do not treat the repo as fully runnable until the EA source/compiled expert is confirmed available in the tester environment.

## No-Popup Rule

Do not run MT5 tests on the active desktop while normal PC use must remain uninterrupted. Local tester launch is intentionally locked by `work/MT5_LOCAL_LAUNCH_DISABLED.lock`, and guarded helpers must refuse to start while that file exists.

Current policy for this workspace:

1. Do not launch `terminal.exe`, `terminal64.exe`, `metatester.exe`, `metatester64.exe`, `MetaEditor.exe`, or `metaeditor64.exe` from this thread.
2. If any of those processes are already running and causing focus flashes, stop them only; do not start a replacement tester.
3. Use `work/stop_mt5_stray_processes.ps1` only as a cleanup tool. It starts no MT5 process.
4. Run future backtests on a separate Windows VM, spare machine, VPS, or a local window where focus stealing is explicitly acceptable.
5. Keep `Visual=0`, `ShutdownTerminal=1`, dashboard disabled, and logging low in every tester config.

## Priority Queue

Use `outputs/NEXT_TEST_PRIORITY_QUEUE.md` as the source of truth for what to run next.

Fastest safe order:

1. Static safety audit through GitHub Actions.
2. Stress micro handoff.
3. Recent out-of-sample handoff through 2026.
4. Optional session-variant probe.
5. Full 24-config handoff only after the fast gates pass.

Do not run a larger batch if a smaller gate already rejects the candidate.

## Stress Micro

Use the stress micro handoff first:

- Manifest: `outputs/micro_test_handoff/HANDOFF_MANIFEST.csv`
- Configs: `outputs/micro_test_handoff/configs/*.ini`
- Candidate/baseline pairs: 8 rows total
- Windows: `2024_Q1`, `2024_Q3`, `2025_Q2`, `2025_Q3`

Decision rule:

- If `tp38_sl18` loses any paired stress window, keep the current promoted profile and deprioritize it.
- If `tp38_sl18` matches or improves every paired stress window, continue to the recent out-of-sample pack before the full 24-config handoff.

## Recent Out-of-Sample Pack

After the stress micro pass is clean, run the recent-OOS pack to check late-2025 and 2026 behavior before spending time on the full handoff:

- Manifest: `outputs/recent_oos_handoff/HANDOFF_MANIFEST.csv`
- Configs: `outputs/recent_oos_handoff/configs/*.ini`
- Candidate/baseline pairs: 8 rows total
- Windows: `2025_Q4`, `2026_Q1`, `2026_Q2`, `2026_YTD`

Decision rule:

- If `tp38_sl18` loses any recent-OOS paired window, keep the current promoted profile and deprioritize it.
- If `tp38_sl18` matches or improves every paired recent-OOS window, continue to the full 24-config handoff.
- Do not promote from recent-OOS evidence alone.

## Session Variant Probe

The session probe is optional and small. It should be used only to decide whether session filtering deserves a broader validation batch.

- Manifest: `outputs/session_variant_handoff/HANDOFF_MANIFEST.csv`
- Configs: `outputs/session_variant_handoff/configs/*.ini`
- Candidate/baseline pairs: 6 rows total
- Window: `2026_YTD`
- Candidate sessions: London `07-16`, New York `13-22`, overlap `13-16`

Decision rule:

- If a session candidate loses or underperforms its paired unfiltered baseline, do not spend more tester time on that session.
- If a session candidate beats its paired baseline and stays profitable, expand it into stress micro and recent-OOS validation.
- Do not promote from the session probe alone.

## Full Handoff After Fast Gates

Use the full handoff only after the relevant fast checks are clean:

- Manifest: `outputs/next_test_handoff/HANDOFF_MANIFEST.csv`
- Expected rows: 24
- Includes stress, full-period, and opportunity checks for the top candidate, baseline, and high-guardrail alternates.

## Promotion Evidence Required

A candidate may only move from `MISSING_EVIDENCE` to promotion review after all of these are true:

- Every required phase-2 report is parsed.
- Full-period net profit beats the current baseline `+$866.59`.
- Split aggregate beats the current baseline `+$2354.65`.
- No phase-2 validation window is losing.
- Worst window is non-negative.
- Drawdown and profit factor are parsed and reviewed.
- Equity drawdown guard is active for non-baseline candidates.
- Overfit flags are reviewed, especially `adaptive_reverse_requires_walk_forward`.

## After Reports Are Exported

Import commands for each fast pack are listed in `outputs/NEXT_TEST_PRIORITY_QUEUE.md`.

After imports, refresh:

- `outputs/PROFIT_SEARCH_REPORT_METRICS.csv`
- `outputs/RESULT_IMPORT_DECISION_MATRIX.csv`
- `outputs/PROFIT_READINESS_SNAPSHOT.csv`
- `outputs/promotion_packets/<profile>_promotion_packet.md`
- `outputs/REPORT_IMPORT_PREFLIGHT.csv`

## Bottom Line

The fastest safe route is not more unfiltered optimization on the active desktop. It is static safety, paired stress micro validation, recent out-of-sample validation through 2026, optional session probing, then full handoff validation and promotion gates. Until those reports exist, keep the current promoted profile.
