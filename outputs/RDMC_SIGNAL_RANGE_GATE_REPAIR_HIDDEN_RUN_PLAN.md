# First-Pass Hidden Run Plan

Generated offline unless -Run is supplied. Plan mode does not launch MT5, MetaEditor, Git, GitHub CLI, or GitHub Actions.

- Overall: **LOCKED**
- Run requested: `False`
- Resume existing reports: `False`
- MT5 hard lock present: `True`
- Terminal path exists: `True`
- Resource budget: max `80%` logical-processor affinity plus below-normal process priority
- Config rows: `8`
- Reports found: `0`

No tester run was started. The workspace MT5 hard lock is still present, which is the correct no-popup/no-focus state.

When local MT5 testing is explicitly allowed again, remove the hard lock, create the required unlock acknowledgements, set the required environment variables, then rerun this script with -Run.

## Rows

| Rank | Candidate | Window | Model | Status | Action | Max CPU % | Expected Report | Evidence |
| ---: | --- | --- | --- | --- | --- | ---: | --- | --- |
| 1 | srg_control | year_2019 | 1 | LOCKED | UNLOCK_REQUIRED | 80 | srg_control_year_2019_m1 | Plan only. MT5 hard lock is present, so no local tester run can start. |
| 2 | srg_control | year_2022 | 1 | LOCKED | UNLOCK_REQUIRED | 80 | srg_control_year_2022_m1 | Plan only. MT5 hard lock is present, so no local tester run can start. |
| 3 | srg_min100 | year_2019 | 1 | LOCKED | UNLOCK_REQUIRED | 80 | srg_min100_year_2019_m1 | Plan only. MT5 hard lock is present, so no local tester run can start. |
| 4 | srg_min100 | year_2022 | 1 | LOCKED | UNLOCK_REQUIRED | 80 | srg_min100_year_2022_m1 | Plan only. MT5 hard lock is present, so no local tester run can start. |
| 5 | srg_min125_center | year_2019 | 1 | LOCKED | UNLOCK_REQUIRED | 80 | srg_min125_center_year_2019_m1 | Plan only. MT5 hard lock is present, so no local tester run can start. |
| 6 | srg_min125_center | year_2022 | 1 | LOCKED | UNLOCK_REQUIRED | 80 | srg_min125_center_year_2022_m1 | Plan only. MT5 hard lock is present, so no local tester run can start. |
| 7 | srg_min150 | year_2019 | 1 | LOCKED | UNLOCK_REQUIRED | 80 | srg_min150_year_2019_m1 | Plan only. MT5 hard lock is present, so no local tester run can start. |
| 8 | srg_min150 | year_2022 | 1 | LOCKED | UNLOCK_REQUIRED | 80 | srg_min150_year_2022_m1 | Plan only. MT5 hard lock is present, so no local tester run can start. |
