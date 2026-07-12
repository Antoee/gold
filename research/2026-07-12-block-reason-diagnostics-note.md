# Block Reason Diagnostics Pass - 2026-07-12

Added an opt-in blocker diagnostic CSV writer:

- `InpUseBlockReasonDiagnostics`
- `InpBlockReasonDiagnosticsFile`

The diagnostic records one row per new-bar decision when enabled: time, month/day/hour, trend bias, signal bias, confirmations, quality score, price-action score, lane labels, spread, ATR, and the current block/entry reason.

## Validation

- Full hidden compile: `outputs/MT5_HIDDEN_COMPILE_FSD_BYPASS.log`
- Result: `0 errors, 0 warnings`
- Compact diagnostic compile: `outputs/MT5_HIDDEN_COMPILE_BLOCK_DIAGNOSTICS_COMPACT.log`
- Result: `0 errors, 0 warnings`
- Local MT5 safety audit: `PASS 39/39`
- CI-equivalent PowerShell smoke sequence was run locally and passed end-to-end.

## Diagnostic Windows

Package: `outputs/block_reason_diagnostic_package`

Windows:

- `2024_Q3`
- `2024_Q4`
- `2025_Q2`
- `2025_Q4`
- `2026_YTD`

The hidden tester completed all windows but did not emit HTML reports, so the useful artifact for this pass is the common-files diagnostic CSV and summarized exports:

- `outputs/BLOCK_REASON_DIAGNOSTIC_TOP_REASONS.csv`
- `outputs/BLOCK_REASON_DIAGNOSTIC_TOP_MONTH_REASONS.csv`

## Top Block Reasons

| Reason | Count |
| --- | ---: |
| session closed | 22,973 |
| no setup | 5,884 |
| month filter | 5,067 |
| month day window | 825 |
| equity profit peak trail | 363 |
| month start filter | 83 |
| daily profit lock | 72 |
| spread | 66 |
| max positions | 40 |
| minimum RR | 28 |
| spread ATR | 16 |
| daily loss limit | 11 |

## Interpretation

Most dormant time is session-filtered. The largest in-session opportunity bottleneck is still `month filter`, followed by weak/no setups. Only 19 month-filter blocks had `quality_score >= 5`; those were mostly flat structural-displacement signals. That made FSD bypass the smallest evidence-based next test, but the side-by-side result did not improve profit.
