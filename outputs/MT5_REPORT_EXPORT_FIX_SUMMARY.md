# MT5 Report Export Fix Summary

Generated: 2026-07-14.

## Decision

The MT5 report-export blocker is fixed locally. This does not promote a new bot, but it removes a major evidence gap: current-source Model4 yearly tests can now return and parse full `.htm` tester reports instead of relying on final-balance logs.

## Root Cause

This MT5 install silently skipped report export when tester configs used an absolute `Report=` path. Plain report filenames work. The hidden runner now collects those reports from the terminal data root and routes them into the package `reports_here` folder.

## Tooling Changes

- `work/seasonal_gate_helpers.ps1` now writes `Report=<plain file name>`.
- `work/run_first_pass_package_hidden.ps1` now searches the terminal data root for returned reports.
- `work/route_first_pass_returned_reports.ps1` accepts this platform's `Maximum consecutive losses ($)` report label.
- `work/import_first_pass_hidden_log_results.ps1` now parses exported MT5 `.htm/.html/.xml` reports first and only falls back to logs when no report exists.
- `work/build_peak_r20_oos_yearly_package.ps1` now stamps copied profiles with the current source hash and safe tester/live-lock fields.

## Smoke Evidence

File: `outputs/MT5_REPORT_EXPORT_SMOKE.md`

| Variant | Result |
| --- | --- |
| Absolute `Report=` without extension | `NO_REPORT` |
| Absolute `Report=` with `.htm` | `NO_REPORT` |
| Plain `Report=` without extension | `REPORT_FOUND` |
| Plain `Report=` with `.htm` | `REPORT_FOUND` |

Runner smoke: `outputs/MT5_REPORT_EXPORT_RUNNER_SMOKE_PARSED.md`

- Expected rows: `1`
- Parsed exported reports: `1`
- Parsed from tester log: `0`

## Current-Source Model4 Proof

Files:

- Package manifest: `outputs/PEAK_R20_REGIME_COMBO_MODEL4_YEARLY_PACKAGE_MANIFEST.csv`
- Hidden run: `outputs/PEAK_R20_REGIME_COMBO_MODEL4_CURRENT_SOURCE_REPORT_RUN.md`
- Routing: `outputs/PEAK_R20_REGIME_COMBO_MODEL4_CURRENT_SOURCE_REPORT_ROUTING.md`
- Parsed metrics: `outputs/PEAK_R20_REGIME_COMBO_MODEL4_CURRENT_SOURCE_REPORT_METRICS.md`
- Parsed rows: `outputs/PEAK_R20_REGIME_COMBO_MODEL4_CURRENT_SOURCE_REPORT_RESULTS.csv`

Identity:

- Source SHA-256: `2219F6AE66CF1121972848C118213B50C01F91E783ABFE6D66F75105C655EB4D`
- Current-source yearly profile SHA-256: `3E6B806E2941A993579756C8E503B7886E06891F077A104D39428704E48545BC`
- MT5 platform: `MetaQuotes-Demo (Build 5989)`
- Reports returned: `8 / 8`
- Parsed exported reports: `8 / 8`
- Parsed from logs: `0`

## Model4 Yearly Metrics

Each yearly window starts from a `$1,000` tester deposit. The percent-per-year columns are per-window annualized return and CAGR, not a sequential live-account curve.

| Window | Net | Ann. Return | CAGR | PF | Sharpe | Trades | Max Loss Streak | Max DD | Recovery |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 2019 | `+$44.30` | `+4.45%/yr` | `+4.45%/yr` | `0.00` | `0.71` | `1` | `0` | `2.39%` | `1.82` |
| 2020 | `-$22.92` | `-2.29%/yr` | `-2.29%/yr` | `0.00` | `-4.80` | `1` | `1` | `2.36%` | `-0.97` |
| 2021 | `+$76.46` | `+7.67%/yr` | `+7.67%/yr` | `4.27` | `2.63` | `3` | `1` | `4.59%` | `1.49` |
| 2022 | `+$37.31` | `+3.74%/yr` | `+3.74%/yr` | `1.49` | `4.16` | `8` | `2` | `6.05%` | `0.57` |
| 2023 | `+$64.00` | `+6.42%/yr` | `+6.42%/yr` | `0.00` | `1.82` | `2` | `0` | `3.65%` | `1.59` |
| 2024 | `+$15.79` | `+1.58%/yr` | `+1.58%/yr` | `1.30` | `1.07` | `4` | `3` | `7.09%` | `0.22` |
| 2025 | `+$48.78` | `+4.89%/yr` | `+4.90%/yr` | `8.41` | `2.10` | `3` | `1` | `3.06%` | `1.47` |
| 2026 YTD | `$0.00` | `0.00%/yr` | `0.00%/yr` | `0.00` | `0.00` | `0` | `0` | `0.00%` | `0.00` |

Summary:

- Total validation-window net score: `+$263.72`
- Worst window: `2020`, `-$22.92`
- Worst annualized return: `-2.29%/yr`
- Worst drawdown: `7.09%`
- Total trades: `22`

## Conclusion

`r10_pg40_atr085_adapt7` remains the current stability lead, but it is still not trade-ready. The full current-source Model4 reports confirm the same blocker: 2020 is red and 2026 YTD has no trades. The next strategy work should solve that robustness problem without calendar overfitting, then rerun this same exported-report gate.
