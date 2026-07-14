# Money-Ready Refresh Status

Generated offline. This does not launch MT5, MetaEditor, Git, or GitHub Actions.

- Overall: **PENDING**
- Passing areas: `4`
- Pending areas: `10`
- Failed areas: `0`

The bot remains pending evidence. The next useful action is the first pending/ready evidence step below.

## Areas

| Area | Status | Actual | Evidence | Next Action |
| --- | --- | --- | --- | --- |
| first-pass-report-routing | PENDING | routed=0; missing=8; duplicates=0; invalid=0; unmatched=0 | outputs\FIRST_PASS_RETURNED_REPORT_ROUTING.md | Drop the 8 exported MT5 reports into outputs\returned_mt5_reports\first_pass_inbox with exact ExpectedReportName base names. |
| live-evidence-routing | PENDING | routed=0; missing=3; duplicates=0; invalid=0; unmatched=0 | outputs\TRADE_READY_LIVE_EVIDENCE_ROUTING.md | Drop trade log, forward evidence, and second-broker evidence CSVs into outputs\returned_mt5_reports\live_evidence_inbox; external evidence must include expected payoff, Sharpe, and win-rate columns. |
| compile-evidence-routing | PENDING | routed=0; missing=2; duplicates=0; invalid=0; imported=0; warnings=0; failed=0; waiting=1 | outputs\MT5_COMPILE_EVIDENCE_ROUTING.md | Drop one MetaEditor compile log plus the exact compiled .mq5 source copy into outputs\returned_mt5_reports\compile_inbox. |
| conservative-report-routing | PENDING | routed=0; validationRouted=0; brokerRouted=0; missing=63; duplicates=0; invalid=0; unmatched=0 | outputs\TRADE_READY_CONSERVATIVE_RETURNED_REPORT_ROUTING.md | After first-pass passes, drop the 53 validation and 10 broker-proxy MT5 reports into outputs\returned_mt5_reports\trade_ready_conservative_validation_inbox. |
| first-pass-refresh | PENDING | reports=parsed=0; missing=44; unparsed=0; expected=44; decision=pass=7; pending=38; fail=0; trusted=promote=0; wait=2; fail=0; nextPackage=packagedConfigs=8; selectedConfigs=8 | outputs\FIRST_PASS_REFRESH_STATUS.md | Import routed reports and wait for trusted first-pass promotion before full validation. |
| first-pass-parallel-lanes | PASS | lanes=4; laneConfigs=8; zipExists=True | outputs\FIRST_PASS_PARALLEL_LANES.md | Use the four first-pass lane folders when you want to run the current 8 fast checks in parallel chunks. |
| local-safety-audit | PASS | rows=43; failures=0 | outputs\MT5_LOCAL_SAFETY_AUDIT.md | Fix local safety failures before running tester/live work. |
| live-readiness | PENDING | rows=13; pass=5; pending=8; fail=0 | outputs\TRADE_READY_LIVE_READINESS_DECISION.md | Close compile, validation, trade-quality, Monte Carlo, forward, second-broker, and reproducibility gates. |
| money-ready-scorecard | PENDING | verdict=NOT_READY_PENDING_EVIDENCE; rows=19; pass=5; pending=14; fail=0 | outputs\MONEY_READY_STATUS_SCORECARD.md | Do not consider live review until scorecard has zero pending and zero fail rows. |
| release-candidate | PENDING | verdict=NOT_RELEASEABLE_PENDING_EVIDENCE; rows=6; pass=2; pending=4; fail=0 | outputs\TRADE_READY_RELEASE_CANDIDATE_DECISION.md | Manual live-review profile remains blocked until evidence and explicit approval identity pass. |
| proof-runway | PENDING | rows=8; ready=1; pendingOrWaiting=7; fail=0 | outputs\MONEY_READY_PROOF_RUNWAY.md | Follow the first READY runway step. |
| reproducibility-bundle | PASS | rows=49; pass=49; pending=0; fail=0; zipExists=True | outputs\TRADE_READY_REPRODUCIBILITY_BUNDLE.md | Use this local source/profile hash freeze for reproducibility; it does not replace the live-readiness GitHub sync gate. |
| github-publication-sync | PENDING | required=7; pass=5; pending=2; fail=0 | outputs\GITHUB_PUBLICATION_SYNC.md | Publish exact source/profile artifacts to GitHub until required SHA-256 checks pass. |
| evidence-handoff | PASS | firstPassConfigs=8; firstPassLanes=4; firstPassLaneConfigs=8; fullValidationConfigs=63; compileEvidenceFiles=2; liveEvidenceFiles=3; missingFiles=0 | outputs\MONEY_READY_EVIDENCE_HANDOFF.md | Use the handoff folder or zip when running/returning MT5 evidence outside this repo. |
