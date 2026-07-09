# M5 Regime Rescue Validation - 2026-07-09

## Purpose

Test whether the profitable recent M5 behavior can be used to materially improve the current XAUUSD candidate without simply raising risk or curve-fitting one weak month.

The current robust benchmark remains:

- `outputs/CANDIDATE_PEAK15_LIQUIDITY_STOP_CHOP_PROFILE.set`
- risk-calendar diagnostic: `outputs/CANDIDATE_PEAK15_BLOCK_MAY_JUN_PROFILE.set`

## Method

Built `work/build_m5_regime_rescue_package.ps1` and ran 110 hidden MT5 tests through the compact-source workflow:

- windows: `2024_to_2026`, `2026_ytd`, `2025_full`, `2024_full`
- stress windows: May/June 2024, May/June 2025
- known weak windows: March/May/June 2026
- profiles: M15 base, M15 May/June block, M15+M5 secondary lanes, and several standalone M5 variants

Compile proof:

- compact tester compile: `outputs/M5_REGIME_RESCUE_COMPILE.log`
- restore full-source compile: `outputs/M5_REGIME_RESCUE_RESTORE_FULL_COMPILE.log`
- both compiled with `0 errors, 0 warnings`

## Results

Parsed summary: `outputs/LOCAL_MT5_M5_REGIME_RESCUE_LOG_SUMMARY.csv`

| Profile | Continuous | 2026 YTD | 2025 | 2024 | Weak Sum | Worst Window | Decision |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| `m15_base` | 801.84 | 84.72 | 124.51 | 801.84 | -255.33 | -99.55 | Baseline |
| `m15_block_may_jun` | 801.84 | 84.72 | 124.51 | 801.84 | -84.88 | -84.88 | Useful risk-calendar diagnostic |
| `m5_trend_runner` | 243.67 | 201.97 | -473.74 | 243.67 | -255.81 | -473.74 | Reject |
| `m5_safe` | 36.94 | 201.97 | 128.65 | -242.70 | 92.20 | -242.70 | Reject as standalone |
| `m5_fq_r1` | 36.94 | 201.97 | 128.65 | -242.70 | 92.20 | -242.70 | Reject as standalone |
| `m5_no_march` | 28.20 | 201.97 | 128.65 | -188.53 | 186.06 | -188.53 | Reject as standalone |
| `m5_r125_guarded` | -81.78 | 16.75 | -14.76 | -222.19 | 28.77 | -222.19 | Reject |
| `m5_quality_no_adapt` | -270.06 | 201.97 | 128.65 | -160.06 | 92.20 | -270.06 | Reject |

The M15+M5 secondary rows did not produce reliable parsed balances in this run and should be repaired/retested separately before drawing conclusions from that branch.

## Interpretation

The M5 family does have a useful signal in recent 2026 data, especially June 2026, but it is not robust enough to promote as a standalone strategy. The key failure is 2024 stability: several M5 variants lose heavily in 2024 or 2025 even while improving 2026 YTD.

This means M5 should not be used as the main engine. If it is used, it should be a tightly capped secondary opportunity lane with strong regime gating and its own kill switch.

## Decision

Do not replace the current M15 candidate with an M5 profile.

Keep the current promoted candidate:

- `outputs/CANDIDATE_PEAK15_LIQUIDITY_STOP_CHOP_PROFILE.set`

Keep the May/June block as a diagnostic/risk-control candidate only:

- `outputs/CANDIDATE_PEAK15_BLOCK_MAY_JUN_PROFILE.set`

Next best work:

1. Repair and retest the M15+M5 secondary branch so it produces reliable parsed balances.
2. Add a default-off M5 rescue lane kill switch based on recent M5 R expectancy, not calendar months.
3. Continue searching for profit expansion through structure-based exits and selective add-on entries instead of raw risk escalation.
