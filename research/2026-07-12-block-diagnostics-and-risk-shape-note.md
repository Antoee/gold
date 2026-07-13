# 2026-07-12 Block Diagnostics and Risk-Shape Note

## Decision

Keep the current research-best profile:

```text
outputs/CANDIDATE_DEC_ISLP_OFF_ISLP_LOWATR_ORDERFLOW_PROFILE.set
```

Do not promote the month-filter bypass candidates or the March/May risk-shape ladder.

## Block-Reason Diagnostics

Diagnostics were run across 12 weak/flat/control Model4 real-tick windows after fixing the diagnostics filename generation and raw parser.

Top block reasons:

| Reason | Count | Percent | Signal Rows |
| --- | ---: | ---: | ---: |
| session closed | 14733 | 64.81 | 7556 |
| no setup | 4021 | 17.69 | 0 |
| month filter | 3235 | 14.23 | 3235 |
| month day window | 481 | 2.12 | 481 |
| spread | 80 | 0.35 | 80 |

Interpretation:

- Most rows are outside active sessions and are not useful entry candidates.
- The actionable blocker was the month filter, especially for some flat structural displacement signals.
- Forcing those signals through the month filter needed validation before any promotion.

Artifacts:

- `outputs/BLOCK_REASON_DIAGNOSTICS_REASON_SUMMARY.csv`
- `outputs/BLOCK_REASON_DIAGNOSTICS_LANE_REASON_SUMMARY.csv`
- `outputs/BLOCK_REASON_DIAGNOSTICS_WINDOW_SUMMARY.csv`
- `outputs/BLOCK_REASON_DIAGNOSTICS_TOP_SIGNAL_REASONS.csv`

## Month-Filter Bypass Probe

Tested profiles:

- `current`
- `fsd_q6_pa18`
- `highpa_q5_pa24`
- `combo`

Result:

| Profile | Total Net | Active Windows | Losing Windows | Trades | Worst DD % |
| --- | ---: | ---: | ---: | ---: | ---: |
| current | 508.07 | 3 | 0 | 6 | 30.9408 |
| highpa_q5_pa24 | 508.07 | 3 | 0 | 6 | 30.9408 |
| fsd_q6_pa18 | 434.29 | 6 | 3 | 9 | 30.9408 |
| combo | 434.29 | 6 | 3 | 9 | 30.9408 |

Decision:

Reject. The high-price-action bypass made no trade-set difference. The FSD bypass added losing trades in `2024_10`, `2025_04`, and `2025_06`.

Artifacts:

- `outputs/MONTH_FILTER_BYPASS_PROBE_RESULTS.csv`
- `outputs/MONTH_FILTER_BYPASS_PROBE_SUMMARY.csv`

## Fresh Continuous Check

A same-source Model4 continuous check was run because the README still showed an older `+4507.51` Dec-ISLP-Off continuous result.

Fresh current-source parsed results:

| Profile | Continuous | 2024 Full | 2025 Full | 2026 YTD | Worst DD % |
| --- | ---: | ---: | ---: | ---: | ---: |
| dec_islp_off | 1195.04 | 1340.55 | 214.30 | 955.21 | 28.2997 |
| islp_lowatr_of | 1195.69 | 1353.53 | 214.30 | 955.21 | 28.2785 |

Interpretation:

- LowATR OrderFlow still beats Dec-ISLP-Off on the fresh same-source check, but only slightly on continuous profit.
- The old `+4507.51` number should be treated as historical/stale against the current local source and compact tester path.

Artifacts:

- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_CONTINUOUS_CHECK_RESULTS.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_CONTINUOUS_CHECK_SUMMARY.csv`

## March/May Risk-Shape Ladder

Tested whether March profit could be safely scaled while lowering May risk.

Result:

| Profile | Continuous | 2026 YTD | Full 2025 | Worst Window | Losing Windows | Worst DD % |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| current | 1195.69 | 955.21 | 214.30 | 214.30 | 0 | 30.9408 |
| mar200_may220 | 993.28 | 1238.40 | 105.51 | -196.16 | 1 | 28.6598 |
| mar175_may280 | 464.46 | 1032.92 | -8.60 | -8.60 | 2 | 30.9408 |
| mar150_may280 | 395.91 | 901.82 | -8.35 | -8.35 | 2 | 30.9408 |
| mar150_may240 | 395.91 | 931.99 | -8.35 | -8.35 | 2 | 35.9388 |
| mar125_may280 | 73.92 | 691.74 | 262.02 | -122.22 | 1 | 30.9408 |

Decision:

Reject. `mar200_may220` improves 2026 YTD and reduces worst DD slightly, but it introduces a `2025_03` loss and lowers continuous profit. The current profile remains the best stability candidate in this ladder.

Artifacts:

- `outputs/CURRENT_BEST_MARCH_MAY_RISK_SHAPE_MODEL4_RESULTS.csv`
- `outputs/CURRENT_BEST_MARCH_MAY_RISK_SHAPE_MODEL4_SUMMARY.csv`

## Tooling Fixes

- `work/seasonal_gate_helpers.ps1` now writes `InpBlockReasonDiagnosticsFile` as a plain string input.
- `work/summarize_block_reason_diagnostics.ps1` now handles MT5 tab-separated diagnostics with explicit headers and safe numeric parsing.
- `work/collect_local_mt5_log_results.ps1` now recognizes both `2024_to_2026` and `continuous_2024_2026` window names.

Compile/safety:

- Compact compiles completed with `0 errors, 0 warnings`.
- MT5 local safety audit passed `39 / 39`.
