# Trade-Ready Live Readiness Decision

Generated: 2026-07-16 10:48:55

- Overall: **PENDING**
- Passing gates: `7`
- Pending gates: `7`
- Failed gates: `0`
- Profile hash: `7AA4135B6FBA2FFC59B48E6EB68E0F7E954AB9BA18054BCA3E658AC0FEAD6BAF`
- Source hash: `A167CDB787E09F6E97B961D46963452527936434245FC42C7593E94EDF504622`

This is the final approval gate for the conservative candidate. It does not launch MT5 and it does not unlock real-account trading.

| Gate | Status | Required | Actual | Evidence | Next Action |
| --- | --- | --- | --- | --- | --- |
| profile-artifact | PASS | Conservative trade-ready profile exists | hash=7AA4135B6FBA2FFC59B48E6EB68E0F7E954AB9BA18054BCA3E658AC0FEAD6BAF | outputs\CANDIDATE_TRADE_READY_CONSERVATIVE_PROFILE.set | Generate outputs\CANDIDATE_TRADE_READY_CONSERVATIVE_PROFILE.set. |
| source-artifact-sync | PASS | Root EA source and mirrored output source have the same SHA-256 | root=A167CDB787E09F6E97B961D46963452527936434245FC42C7593E94EDF504622; mirror=A167CDB787E09F6E97B961D46963452527936434245FC42C7593E94EDF504622 | Professional_XAUUSD_EA.mq5 + outputs\Professional_XAUUSD_EA.mq5 | Sync source artifacts before compiling or testing. |
| real-account-lock | PASS | InpUseRealAccountSafetyLock=true, InpAllowRealAccountTrading=false, InpRealAccountApprovalCode=DISABLED, InpRealAccountApprovalProfileId=DISABLED, InpRealAccountApprovalSourceHash=DISABLED | InpUseRealAccountSafetyLock=true; InpAllowRealAccountTrading=false; InpRealAccountApprovalCode=DISABLED; InpRealAccountApprovalProfileId=DISABLED; InpRealAccountApprovalSourceHash=DISABLED | outputs\CANDIDATE_TRADE_READY_CONSERVATIVE_PROFILE.set | Keep real-account trading blocked until every proof gate passes and the user explicitly approves a separate live profile. |
| local-pc-safety | PASS | MT5 local safety audit exists with zero failed checks | rows=44; failures=0 | outputs\MT5_LOCAL_SAFETY_AUDIT.csv | Fix local safety audit failures before any tester/live work. |
| current-source-compile | PASS | Current mirrored EA source compiles with 0 errors/warnings, SourceHashStatus=MATCH, and currentSourceStatus=CURRENT | status=PASS; hashStatus=MATCH; currentSourceStatus=CURRENT; compileHash=A167CDB787E09F6E97B961D46963452527936434245FC42C7593E94EDF504622; currentHash=A167CDB787E09F6E97B961D46963452527936434245FC42C7593E94EDF504622; errors=0; warnings=0 | outputs\MT5_COMPILE_STATUS.csv | Import a fresh compile log for the exact current source hash before trusting tester/live evidence. |
| conservative-audit | PENDING | Conservative profile audit exists with 0 FAIL and 0 OPEN rows | pass=110; open=5; fail=0 | outputs\TRADE_READY_CONSERVATIVE_AUDIT.csv | Close every open proof gap before live approval. |
| model4-validation-decision | PENDING | Conservative validation decision has 0 FAIL and 0 PENDING gates | rows=28; pass=3; pending=25; fail=0 | outputs\TRADE_READY_CONSERVATIVE_VALIDATION_DECISION.csv | Return and import all staged Model4/fast/stress/broker-proxy reports. |
| money-ready-efficiency-audit | PENDING | Money-ready efficiency audit has 0 FAIL and 0 PENDING gates: broad evidence clears growth, return/drawdown, drawdown, no-red-window, PF, recovery, recent-data, and broker/stress targets | rows=17; pass=0; pending=17; fail=0 | outputs\MONEY_READY_EFFICIENCY_AUDIT.csv | Return full exported MT5 reports and require the strategy to be both safe and worth the capital/time before live review. |
| trade-quality-decision | PENDING | Trade-quality analyzer status is PASS with enough closed trades and acceptable PF/expectancy/loss/R/spread evidence | status=PENDING; trades=0; pending=2; fail=0 | outputs\TRADE_READY_CONSERVATIVE_TRADE_QUALITY.csv | Return conservative closed-trade logs and rerun work\analyze_trade_ready_conservative_trade_quality.ps1. |
| monte-carlo-trade-stress | PENDING | Monte Carlo trade-stress analyzer status is PASS under seeded slippage/delay/spread/missed-winner stress | status=PENDING; trials=1000; rTrades=0; pending=3; fail=0; failureRate= | outputs\TRADE_READY_CONSERVATIVE_MONTE_CARLO.csv | Return conservative closed-trade logs with realized R and rerun work\analyze_trade_ready_conservative_monte_carlo.ps1. |
| forward-paper-demo | PENDING | Forward paper/demo evidence status is PASS on a sufficiently long non-red sample | status=PENDING; rows=0; parsed=0; pending=1; fail=0 | outputs\TRADE_READY_CONSERVATIVE_FORWARD_TEST.csv | Export paper/demo evidence to outputs\TRADE_READY_CONSERVATIVE_FORWARD_TEST_EVIDENCE.csv, then rerun work\analyze_trade_ready_conservative_forward_test.ps1. |
| second-broker-validation | PENDING | Second-broker XAUUSD validation status is PASS on broker-specific symbol conditions | status=PENDING; rows=0; parsed=0; pending=1; fail=0 | outputs\TRADE_READY_CONSERVATIVE_SECOND_BROKER_DECISION.csv | Export second-broker evidence to outputs\TRADE_READY_CONSERVATIVE_SECOND_BROKER_EVIDENCE.csv, then rerun work\analyze_trade_ready_conservative_second_broker.ps1. |
| local-reproducibility-freeze | PASS | Local reproducibility bundle manifest exists, zip exists, required checks pass, and every bundle row is PASS | rows=83; pass=83; pending=0; fail=0; zipExists=True; missingRequiredChecks=0 | outputs\TRADE_READY_REPRODUCIBILITY_BUNDLE_MANIFEST.csv + outputs\trade_ready_reproducibility_bundle.zip | Keep rebuilding the bundle after every source/profile/status change; this local freeze does not replace GitHub/source-publication sync. |
| reproducible-github-sync | PASS | Either workspace is a clean pushed GitHub checkout with tracked required source/profile artifacts, or required source/profile artifacts match GitHub by SHA-256 through connector publication audit | gitValid=False; gitDetail=fatal: not a git repository (or any of the parent directories): .git; publicationRows=7; publicationPass=7; publicationPending=0; publicationFail=0 | .git + outputs\GITHUB_PUBLICATION_SYNC.csv | Restore a valid Git checkout or publish exact source/profile artifacts through the connector until outputs\GITHUB_PUBLICATION_SYNC.md has zero required pending/fail rows. |

## Bottom Line

The conservative profile is not live-ready yet. Missing or stale proof remains, so real-account trading stays blocked.
