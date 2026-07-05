# Controlled Profit Test Runbook

This project is currently in evidence-gathering mode. Do not promote a new profile because it looks promising in configuration alone; promotion requires parsed MT5 reports.

## Current Baseline

- Current promoted profile: `risk1p6_sl18_tp35` / `ROBUST_BOS_SWEEP_PROFILE.set`
- Known full-period result, 2024-01-01 to 2026-07-02: `+$866.59`
- Known split aggregate: `+$2354.65`
- Known validation outcome: zero losing split windows in the existing promoted evidence

## Current Candidate

- Candidate: `tp38_sl18`
- Key override: `InpTakeProfitATRMultiplier=3.80`
- Risk guard: `InpMaxEquityDrawdownPercent=4.00`
- Promotion packet status: `MISSING_EVIDENCE`
- Promotion is blocked until reports are parsed and every gate passes.

## No-Interruption Rule

Do not run MT5 tests on the active desktop while normal PC use must remain uninterrupted. Local tester launch is intentionally locked by `work/MT5_LOCAL_LAUNCH_DISABLED.lock` and the helper must refuse to start while that file exists.

Preferred options for testing:

1. Run on a separate Windows VM or spare machine.
2. Run only during a controlled local tester window when focus stealing is acceptable.
3. Keep `Visual=0`, `ShutdownTerminal=1`, dashboard disabled, and logging low in every tester config.

## Fast First Pass

Use the micro handoff first:

- Manifest: `outputs/micro_test_handoff/HANDOFF_MANIFEST.csv`
- Candidate/baseline pairs: 8 rows total
- Windows:
  - `2024_Q1`
  - `2024_Q3`
  - `2025_Q2`
  - `2025_Q3`

Decision rule:

- If `tp38_sl18` loses any paired stress window, keep the current promoted profile and deprioritize it.
- If `tp38_sl18` matches or improves every paired stress window, continue to the full 24-config handoff.

## Micro Import Workflow

After the 8 micro reports are exported into `outputs`, parse and compare them with:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\work\collect_validation_results.ps1 -ManifestPath "outputs\micro_test_handoff\HANDOFF_MANIFEST.csv" -ReportDir "outputs" -ReportNameTemplate "profit_search_{PhaseShort}_{Profile}_{Set}_{Window}" -OutResults "outputs\MICRO_TEST_REPORT_METRICS.csv" -OutSummary "outputs\MICRO_TEST_REPORT_SUMMARY.csv" -OutMarkdown "outputs\MICRO_TEST_REPORT_METRICS.md"
powershell -NoProfile -ExecutionPolicy Bypass -File .\work\build_micro_test_decision.ps1
```

Review:

- `outputs/MICRO_TEST_REPORT_METRICS.csv`
- `outputs/MICRO_TEST_DECISION.md`

Micro outcomes:

- `WAITING_FOR_REPORTS`: finish exporting the paired reports.
- `REPAIR_REPORTS`: re-export or fix parser coverage.
- `REJECT_CANDIDATE`: keep the promoted baseline and stop spending tester time on this candidate.
- `REVIEW_DRAWDOWN`: inspect drawdown before allowing the candidate into the full handoff.
- `PASS_MICRO`: continue to the full 24-config handoff, not promotion.

## Full Handoff After Micro Pass

Use the full handoff only after the micro pass is clean:

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

Import the reports, rebuild metrics, then refresh:

- `outputs/PROFIT_SEARCH_REPORT_METRICS.csv`
- `outputs/RESULT_IMPORT_DECISION_MATRIX.csv`
- `outputs/PROFIT_READINESS_SNAPSHOT.csv`
- `outputs/promotion_packets/<profile>_promotion_packet.md`
- `outputs/REPORT_IMPORT_PREFLIGHT.csv`

## Bottom Line

The fastest safe route is not more unfiltered optimization. It is paired micro validation first, then full handoff validation, then promotion gates. Until those reports exist, keep the current promoted profile.
