# 2026-07-10 Flat-Month Momentum Validation

## Purpose

Test whether carefully gated momentum/price-action lanes can add activity outside the current March/May seasonal profile without breaking the risk-first rule.

The stable promoted profile remains:

- March enabled at 1.00x risk
- May enabled at 2.25x risk
- All other months disabled

## Source Changes Tested

- Added `InpAllowFlatMonthMomentumOutsideMonthFilter`, default `false`.
- Allowed power trend continuation, session impulse, and high-efficiency trend signals to optionally bypass the month filter.
- Reused the flat-month probe month filter so bypasses can still be month-gated.
- Added configurable session impulse candle anatomy inputs:
  - `InpSessionImpulseMinBodyPercent`
  - `InpSessionImpulseMinRangeATR`
  - `InpSessionImpulseMinCloseLocation`
- Fixed risk multiplier clamps for continuation lanes:
  - `PowerTrendContinuationRiskMultiplier()`
  - `SessionImpulseRiskMultiplier()`

Before this fix, exploratory low-risk multipliers below 1.0 were silently raised to 1.0. That made flat-month experiments riskier than intended.

## Real-Tick Monthly Results

File: `outputs/LOCAL_MT5_FLAT_SESSION_IMPULSE_STRICT_MONTHLY_FIXEDRISK_REALTICK_LOG_SUMMARY.csv`

| Profile | Parsed | Total Net | Worst Window | Losing Windows |
| --- | ---: | ---: | ---: | ---: |
| session_anatomy_ultra | 30/30 | 3155.25 | -16.02 | 6 |
| session_anatomy_strict | 30/30 | 3147.22 | -16.02 | 9 |

The risk clamp fix worked: losing months became small. However, the profiles still produced red months.

## Real-Tick Broad Results

File: `outputs/LOCAL_MT5_FLAT_SESSION_IMPULSE_STRICT_BROAD_FIXEDRISK_REALTICK_LOG_SUMMARY.csv`

| Profile | Parsed | Total Net | Continuous 2024-2026 | 2026 YTD | 2025 Full | 2024 Full | Worst Window | Losing Windows |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| session_anatomy_ultra | 9/9 | 2369.67 | 1066.83 | 64.65 | 214.30 | 1066.83 | -16.02 | 4 |
| session_anatomy_strict | 9/9 | 2184.47 | 976.45 | 64.65 | 217.75 | 976.45 | -16.02 | 4 |

## Decision

Reject these flat-month momentum profiles as promoted candidates.

Reasons:

- They add activity, but introduce losing windows.
- Broad continuous performance remains below the stable March/May candidate.
- The current project rule favors no-red validation windows over extra trades.

## Current Best Candidate

Keep `outputs/CANDIDATE_SEASONAL_MAR1_MAY225_PROFILE.set` as the stable main candidate.

Known strong validation:

- `outputs/LOCAL_MT5_MONTH_SPECIFIC_RISK_225_REALTICK_LOG_SUMMARY.csv`
- `mar1_may2p25`
- TotalNet: 3451.27
- Continuous 2024-2026: 1277.57
- 2026 YTD: 158.91
- 2025 Full: 214.30
- 2024 Full: 1277.57
- WorstWindow: 0
- LosingWindows: 0

## Next Research Direction

The EA needs higher profit without paying for it with red windows. The next promising direction is not broader flat-month trading, but better extraction inside already validated months:

- selective March risk escalation with continuous-window protection
- intra-month profit lock and stop-trading-after-target rules
- partial exit/runner tuning in March and May only
- out-of-sample validation before any promotion
