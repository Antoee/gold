# Latest Background Check

Generated locally on `2026-07-14 06:30:11 -05:00`.

This check did not launch MT5, MetaEditor, metatester, Git, or GitHub Actions.

## Result

There is no newly validated best profile yet.

The current stability-best research profile remains:

`Score7 Regime No-M1-Shock Dec-ISLP-Off + ISLP LowATR OrderFlow`

The conservative trade-ready candidate remains a paper/demo-only test candidate until the missing MT5 evidence is returned.

## Routed Evidence Status

| Area | Status | Routed | Missing | Invalid | Notes |
| --- | --- | ---: | ---: | ---: | --- |
| First-pass reports | Pending | 0 | 4 | 0 | No first-pass MT5 reports were found in `outputs/returned_mt5_reports/first_pass_inbox`. |
| Conservative validation reports | Pending | 0 | 63 | 0 | Full validation and broker-proxy reports are still missing. |
| Compile proof | Pending | 0 | 2 | 0 | Current-source compile log and matching source copy are still missing; one stale prior compile row is waiting. |
| Live evidence | Pending | 0 | 3 | 0 | Forward/demo, second-broker, and trade/deal evidence are still missing. |

## Refresh Status

- Overall: `PENDING`
- Passing areas: `5`
- Pending areas: `10`
- Failed areas: `0`

## Smoke Tests Passed

- `FIRST_PASS_RETURNED_REPORT_ROUTING_SMOKE_PASS`
- `TRADE_READY_CONSERVATIVE_REPORT_ROUTING_SMOKE_PASS`
- `MT5_COMPILE_EVIDENCE_ROUTING_SMOKE_PASS`
- `FIRST_PASS_HIDDEN_RUNNER_LOCK_SMOKE_PASS`
- `STATIC_REPO_SAFETY_AUDIT_PASS checks=25`
- `TRADE_READY_REPRODUCIBILITY_BUNDLE_SMOKE_PASS`
- `MONEY_READY_REFRESH_STATUS_SMOKE_PASS`
- `NO_MT5_PROCESSES`

## Next Useful Step

Run or return the 4 first-pass MT5 reports for the current conservative candidate, then drop the exported reports into:

`outputs/returned_mt5_reports/first_pass_inbox`

The expected report base names are listed in `outputs/FIRST_PASS_RETURNED_REPORT_ROUTING.md`.