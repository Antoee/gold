# Trade-Ready Live Readiness Decision

Generated: 2026-07-14 00:48:29

- Overall: **PENDING**
- Passing gates: `6`
- Pending gates: `7`
- Failed gates: `0`
- Profile hash: `0A97B46D7E3A3C3566EF4E787BCB63E2138D114C2F0F898F9A8B1A10F842BF90`
- Source hash: `46770EACA60826F90E1E9A9B7425356F96F7C8F83CF8F8C1FBE271632866933E`

This is the final approval gate for the conservative candidate. It does not launch MT5 and it does not unlock real-account trading.

| Gate | Status | Required | Actual | Evidence | Next Action |
| --- | --- | --- | --- | --- | --- |
| profile-artifact | PASS | Conservative trade-ready profile exists | hash=0A97B46D7E3A3C3566EF4E787BCB63E2138D114C2F0F898F9A8B1A10F842BF90 | outputs\CANDIDATE_TRADE_READY_CONSERVATIVE_PROFILE.set | Generate outputs\CANDIDATE_TRADE_READY_CONSERVATIVE_PROFILE.set. |
| source-artifact-sync | PASS | Root EA source and mirrored output source have the same SHA-256 | root=46770EACA60826F90E1E9A9B7425356F96F7C8F83CF8F8C1FBE271632866933E; mirror=46770EACA60826F90E1E9A9B7425356F96F7C8F83CF8F8C1FBE271632866933E | Professional_XAUUSD_EA.mq5 + outputs\Professional_XAUUSD_EA.mq5 | Sync source artifacts before compiling or testing. |
| real-account-lock | PASS | InpUseRealAccountSafetyLock=true, InpAllowRealAccountTrading=false, InpRealAccountApprovalCode=DISABLED, InpRealAccountApprovalProfileId=DISABLED, InpRealAccountApprovalSourceHash=DISABLED | InpUseRealAccountSafetyLock=true; InpAllowRealAccountTrading=false; InpRealAccountApprovalCode=DISABLED; InpRealAccountApprovalProfileId=DISABLED; InpRealAccountApprovalSourceHash=DISABLED | outputs\CANDIDATE_TRADE_READY_CONSERVATIVE_PROFILE.set | Keep real-account trading blocked until every proof gate passes and the user explicitly approves a separate live profile. |
| local-pc-safety | PASS | MT5 local safety audit exists with zero failed checks | rows=43; failures=0 | outputs\MT5_LOCAL_SAFETY_AUDIT.csv | Fix local safety audit failures before any tester/live work. |
| current-source-compile | PASS | Current mirrored EA source compiles with 0 errors/warnings, SourceHashStatus=MATCH, and currentSourceStatus=CURRENT | status=PASS; hashStatus=MATCH; currentSourceStatus=CURRENT; compileHash=46770EACA60826F90E1E9A9B7425356F96F7C8F83CF8F8C1FBE271632866933E; currentHash=46770EACA60826F90E1E9A9B7425356F96F7C8F83CF8F8C1FBE271632866933E; errors=0; warnings=0 | outputs\MT5_COMPILE_STATUS.csv | Import a fresh compile log for the exact current source hash before trusting tester/live evidence. |
| conservative-audit | PENDING | Conservative profile audit exists with 0 FAIL and 0 OPEN rows | pass=103; open=5; fail=0 | outputs\TRADE_READY_CONSERVATIVE_AUDIT.csv | Close every open proof gap before live approval. |
| model4-validation-decision | PENDING | Conservative validation decision has 0 FAIL and 0 PENDING gates | rows=25; pass=2; pending=23; fail=0 | outputs\TRADE_READY_CONSERVATIVE_VALIDATION_DECISION.csv | Return and import all staged Model4/fast/stress/broker-proxy reports. |
| trade-quality-decision | PENDING | Trade-quality analyzer status is PASS with enough closed trades and acceptable PF/expectancy/loss/R/spread evidence | status=PENDING; trades=0; pending=2; fail=0 | outputs\TRADE_READY_CONSERVATIVE_TRADE_QUALITY.csv | Return conservative closed-trade logs and rerun work\analyze_trade_ready_conservative_trade_quality.ps1. |
| monte-carlo-trade-stress | PENDING | Monte Carlo trade-stress analyzer status is PASS under seeded slippage/delay/spread/missed-winner stress | status=PENDING; trials=1000; rTrades=0; pending=3; fail=0; failureRate= | outputs\TRADE_READY_CONSERVATIVE_MONTE_CARLO.csv | Return conservative closed-trade logs with realized R and rerun work\analyze_trade_ready_conservative_monte_carlo.ps1. |
| forward-paper-demo | PENDING | Forward paper/demo evidence status is PASS on a sufficiently long non-red sample | status=PENDING; rows=0; parsed=0; pending=1; fail=0 | outputs\TRADE_READY_CONSERVATIVE_FORWARD_TEST.csv | Export paper/demo evidence to outputs\TRADE_READY_CONSERVATIVE_FORWARD_TEST_EVIDENCE.csv, then rerun work\analyze_trade_ready_conservative_forward_test.ps1. |
| second-broker-validation | PENDING | Second-broker XAUUSD validation status is PASS on broker-specific symbol conditions | status=PENDING; rows=0; parsed=0; pending=1; fail=0 | outputs\TRADE_READY_CONSERVATIVE_SECOND_BROKER_DECISION.csv | Export second-broker evidence to outputs\TRADE_READY_CONSERVATIVE_SECOND_BROKER_EVIDENCE.csv, then rerun work\analyze_trade_ready_conservative_second_broker.ps1. |
| local-reproducibility-freeze | PASS | Local reproducibility bundle manifest exists, zip exists, required checks pass, and every bundle row is PASS | rows=49; pass=49; pending=0; fail=0; zipExists=True; missingRequiredChecks=0 | outputs\TRADE_READY_REPRODUCIBILITY_BUNDLE_MANIFEST.csv + outputs\trade_ready_reproducibility_bundle.zip | Keep rebuilding the bundle after every source/profile/status change; this local freeze does not replace GitHub/source-publication sync. |
| reproducible-github-sync | PENDING | Either workspace is a valid Git checkout, or required source/profile artifacts match GitHub by SHA-256 through connector publication audit | gitHead=False; gitConfig=False; publicationRows=7; publicationPass=2; publicationPending=5; publicationFail=0 | .git + outputs\GITHUB_PUBLICATION_SYNC.csv | Restore a valid Git checkout or publish exact source/profile artifacts through the connector until outputs\GITHUB_PUBLICATION_SYNC.md has zero required pending/fail rows. |

## Bottom Line

The conservative profile is not live-ready yet. Missing or stale proof remains, so real-account trading stays blocked.
