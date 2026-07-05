# Micro Test Decision

Generated from exported MT5 report metrics only. No MT5 process was launched.

- Metrics source: `outputs\MICRO_TEST_REPORT_METRICS.csv`
- Manifest source: `outputs\micro_test_handoff\HANDOFF_MANIFEST.csv`
- Candidate: `tp38_sl18`
- Baseline: `baseline_promoted`
- Overall decision: **WAITING_FOR_REPORTS**
- Next action: Run/export/import the paired micro handoff reports.

## Paired Windows

| Window | Candidate | Baseline | Delta | Candidate DD | Baseline DD | Decision | Reason |
|---|---:|---:|---:|---:|---:|---|---|
| 2024_Q1 |  |  |  |  |  | WAITING_FOR_REPORTS | Candidate and baseline reports must both parse before judging this window. |
| 2024_Q3 |  |  |  |  |  | WAITING_FOR_REPORTS | Candidate and baseline reports must both parse before judging this window. |
| 2025_Q2 |  |  |  |  |  | WAITING_FOR_REPORTS | Candidate and baseline reports must both parse before judging this window. |
| 2025_Q3 |  |  |  |  |  | WAITING_FOR_REPORTS | Candidate and baseline reports must both parse before judging this window. |

## Rule

A candidate that loses money or underperforms the paired baseline in any stress window is rejected for this iteration. A micro pass only earns a full handoff; it does not authorize promotion.
