# First-Pass Hidden Run Plan

Generated offline unless `-Run` is supplied. Plan mode does not launch MT5, MetaEditor, Git, GitHub CLI, or GitHub Actions.

- Overall: **LOCKED**
- Run requested: `False`
- MT5 hard lock present: `True`
- Terminal path exists: `True`
- Config rows: `4`
- Reports found: `0`

No tester run was started. The workspace MT5 hard lock is still present, which is the correct no-popup/no-focus state.

When local MT5 testing is explicitly allowed again, remove the hard lock, create the required unlock acknowledgements, set the required environment variables, then rerun this script with `-Run`.

## Rows

| Rank | Candidate | Window | Model | Status | Action | Expected Report | Evidence |
| ---: | --- | --- | --- | --- | --- | --- | --- |
| 1 | trade_ready_conservative | continuous_2024_2026 | 1 | LOCKED | UNLOCK_REQUIRED | first_pass_trade_ready_conservative_001_validation_continuous_2024_2026 | Plan only. MT5 hard lock is present, so no local tester run can start. |
| 2 | trade_ready_conservative | 2024_full | 1 | LOCKED | UNLOCK_REQUIRED | first_pass_trade_ready_conservative_002_validation_2024_full | Plan only. MT5 hard lock is present, so no local tester run can start. |
| 3 | trade_ready_conservative | 2025_full | 1 | LOCKED | UNLOCK_REQUIRED | first_pass_trade_ready_conservative_003_validation_2025_full | Plan only. MT5 hard lock is present, so no local tester run can start. |
| 4 | trade_ready_conservative | 2026_ytd | 1 | LOCKED | UNLOCK_REQUIRED | first_pass_trade_ready_conservative_004_validation_2026_ytd | Plan only. MT5 hard lock is present, so no local tester run can start. |
