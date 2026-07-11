# Latest Candidate

Updated: 2026-07-11

The previous README status showing roughly `+$866` over 2024-01-01 to 2026-07-02 is superseded by the current promoted research candidate:

- Candidate: `CANDIDATE_MAR10_MAY10_CONTINUOUS_PROFILE`
- Base: `CANDIDATE_LIQUIDITY_STOP_CONFLICT_MARCH_MAY280_MAYCAP17_PROFILE`
- Key overrides: `InpUseMonthDayWindowFilter=true`, `InpMarchMaxDay=10`, `InpMayMaxDay=10`
- Current-source continuous full-period net: `+$3,746.45`
- Full-period final balance on `$1,000` deposit: `$4,746.45`
- 2026 YTD: `+$1,107.93`
- 2025 full: `+$214.30`
- 2024 full: `+$1,409.57`
- Worst broad validation window: `$0.00`
- Losing broad validation windows: `0`
- Monthly shortlist: `30/30` parsed, total `+$3,358.64`, worst month `$0.00`, losing months `0`

Evidence files:

- `outputs/EA_CANDIDATE_STATE_2026-07-11_MAR10_MAY10_CONTINUOUS.txt`
- `outputs/CANDIDATE_MAR10_MAY10_CONTINUOUS_PROFILE_OVERRIDES.set`
- `outputs/MAR10_MAY10_CURRENT_LOG_SUMMARY.csv`
- `outputs/MAR10_MAY10_CURRENT_LOG_RESULTS.csv`

Risk note: this is a promoted research candidate, not a live-trading guarantee. It relies on March/May day-window filtering, so it needs continued walk-forward and post-July-2026 out-of-sample validation before any live use.
