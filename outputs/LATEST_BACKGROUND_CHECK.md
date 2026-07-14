# Latest Background Check

Generated locally on `2026-07-14 06:39:22 -05:00`.

This check did not launch MT5, MetaEditor, metatester, Git, or GitHub Actions.

## Result

There is no newly validated best profile yet.

The current stability-best research profile remains:

`Score7 Regime No-M1-Shock Dec-ISLP-Off + ISLP LowATR OrderFlow`

The conservative trade-ready candidate remains a paper/demo-only test candidate until the missing MT5 evidence is returned.

This pass hardened the EA source: `RealAccountSafetyLockAllows()` now fails closed on real accounts if `InpUseRealAccountSafetyLock=false`, so the real-account lock can no longer be bypassed by disabling that input.

Current source hash:

`FF1BCDB06E5D628F37039B7A2E6D96CE0EC60E2F0D33F2A1F8E3FF2EE4130394`

Current conservative profile hash:

`F708C68A68016C13C4ADAECFE472A270748F4DAD9F2DF8C12F9870C2324DA13F`

Current reproducibility bundle zip hash:

`24F22DFBF1720276A3F0FB223F6982EE725AACC6ECAED842EAB0566C8DB403F7`

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
- `STATIC_MQL_COMPILE_PREFLIGHT_PASS checks=32 inputs=1802`
- `MONEY_READY_SAFETY_CONTRACT_PASS`
- `TRADE_READY_REPRODUCIBILITY_BUNDLE_SMOKE_PASS`
- `MONEY_READY_REFRESH_STATUS_SMOKE_PASS`
- `NO_MT5_PROCESSES`

## Next Useful Step

Run or return the 4 first-pass MT5 reports for the current conservative candidate, then drop the exported reports into:

`outputs/returned_mt5_reports/first_pass_inbox`

The expected report base names are listed in `outputs/FIRST_PASS_RETURNED_REPORT_ROUTING.md`.