# Money-Ready Status Scorecard

Generated offline. This does not launch MT5, MetaEditor, Git, or GitHub Actions.

- Verdict: **NOT_READY_PENDING_EVIDENCE**
- Best current candidate: `trade_ready_conservative`
- Profile hash: `82530801102198E81E08E1EF772D5501B52FB88CCFD67E6651CE32EF1D055665`
- Source hash: `5D148DAE2335F9037BDED3C9A82BD916C1FCFB6F43EE2EC5EAAE7E67384ED412`
- Passing rows: `5`
- Pending rows: `14`
- Failed rows: `0`

The bot is not money-ready yet because required evidence is still missing or stale. Real-account trading remains locked.

## Scorecard

| Area | Status | Actual | Required | Evidence | Next Action |
| --- | --- | --- | --- | --- | --- |
| candidate | PASS | profileHash=82530801102198E81E08E1EF772D5501B52FB88CCFD67E6651CE32EF1D055665; sourceHash=5D148DAE2335F9037BDED3C9A82BD916C1FCFB6F43EE2EC5EAAE7E67384ED412 | Strict conservative trade-ready profile exists and hashes are captured | outputs\CANDIDATE_TRADE_READY_CONSERVATIVE_PROFILE.set | Generate the conservative profile before evaluating readiness. |
| real-account-lock | PASS | allowReal=false; approvalCode=DISABLED; approvalProfile=DISABLED; approvalSource=DISABLED | Real-account trading disabled until separate explicit approval identity is created | outputs\CANDIDATE_TRADE_READY_CONSERVATIVE_PROFILE.set | Keep disabled while validation and forward evidence are pending. |
| risk-shape | PASS | risk=0.10; openRisk=0.20; lots=0.01; dailyLoss=0.20; weeklyLoss=0.60; monthlyLoss=1.25; equityDD=3.00 | 0.10% risk, 0.20% open risk, 0.01 lots, 0.20/0.60/1.25% loss caps, 3.00% equity DD cap | outputs\CANDIDATE_TRADE_READY_CONSERVATIVE_PROFILE.set | Do not loosen these caps before proof gates pass. |
| local-pc-safety | PASS | rows=43; failures=0 | MT5/GitHub/local-launch safety audit has zero failures | outputs\MT5_LOCAL_SAFETY_AUDIT.csv | Fix local safety audit before running tester work. |
| guardrail-audit | PENDING | pass=110; open=5; fail=0 | Profile audit has 0 FAIL and 0 OPEN proof gaps | outputs\TRADE_READY_CONSERVATIVE_AUDIT.csv | Close open proof gaps; do not promote while any remain. |
| model4-validation | PENDING | pass=2; pending=25; fail=0 | All validation, stress, and broker-proxy result gates pass | outputs\TRADE_READY_CONSERVATIVE_VALIDATION_DECISION.csv | Return MT5 reports and rerun the importer/decision gate. |
| quality:exact-continuous-return-floor | PENDING | continuousReturnPct=; continuousNet= | continuous return >= 1% on starting balance 1000 | outputs\TRADE_READY_CONSERVATIVE_VALIDATION_DECISION.csv | This quality gate must pass before live approval review. |
| quality:exact-continuous-return-drawdown-efficiency | PENDING | returnToDD=; returnPct=; ddPct= | continuous return % / equity DD % >= 1 | outputs\TRADE_READY_CONSERVATIVE_VALIDATION_DECISION.csv | This quality gate must pass before live approval review. |
| quality:profit-factor-floor | PENDING | minPF=; samples=0 | min nonzero PF >= 1.2 | outputs\TRADE_READY_CONSERVATIVE_VALIDATION_DECISION.csv | This quality gate must pass before live approval review. |
| quality:recovery-factor-floor | PENDING | minRecovery=; samples=0 | min recovery >= 1 on active rows | outputs\TRADE_READY_CONSERVATIVE_VALIDATION_DECISION.csv | This quality gate must pass before live approval review. |
| quality:drawdown-within-cap | PENDING | worstDD= | max equity DD <= 3% | outputs\TRADE_READY_CONSERVATIVE_VALIDATION_DECISION.csv | This quality gate must pass before live approval review. |
| live:current-source-compile | PENDING | status=PASS; hashStatus=MATCH; currentSourceStatus=STALE; compileHash=46770EACA60826F90E1E9A9B7425356F96F7C8F83CF8F8C1FBE271632866933E; currentHash=5D148DAE2335F9037BDED3C9A82BD916C1FCFB6F43EE2EC5EAAE7E67384ED412; errors=0; warnings=0 | Current mirrored EA source compiles with 0 errors/warnings, SourceHashStatus=MATCH, and currentSourceStatus=CURRENT | outputs\TRADE_READY_LIVE_READINESS_DECISION.csv | Import a fresh compile log for the exact current source hash before trusting tester/live evidence. |
| live:trade-quality-decision | PENDING | status=PENDING; trades=0; pending=2; fail=0 | Trade-quality analyzer status is PASS with enough closed trades and acceptable PF/expectancy/loss/R/spread evidence | outputs\TRADE_READY_LIVE_READINESS_DECISION.csv | Return conservative closed-trade logs and rerun work\analyze_trade_ready_conservative_trade_quality.ps1. |
| live:monte-carlo-trade-stress | PENDING | status=PENDING; trials=1000; rTrades=0; pending=3; fail=0; failureRate= | Monte Carlo trade-stress analyzer status is PASS under seeded slippage/delay/spread/missed-winner stress | outputs\TRADE_READY_LIVE_READINESS_DECISION.csv | Return conservative closed-trade logs with realized R and rerun work\analyze_trade_ready_conservative_monte_carlo.ps1. |
| live:forward-paper-demo | PENDING | status=PENDING; rows=0; parsed=0; pending=1; fail=0 | Forward paper/demo evidence status is PASS on a sufficiently long non-red sample | outputs\TRADE_READY_LIVE_READINESS_DECISION.csv | Export paper/demo evidence to outputs\TRADE_READY_CONSERVATIVE_FORWARD_TEST_EVIDENCE.csv, then rerun work\analyze_trade_ready_conservative_forward_test.ps1. |
| live:second-broker-validation | PENDING | status=PENDING; rows=0; parsed=0; pending=1; fail=0 | Second-broker XAUUSD validation status is PASS on broker-specific symbol conditions | outputs\TRADE_READY_LIVE_READINESS_DECISION.csv | Export second-broker evidence to outputs\TRADE_READY_CONSERVATIVE_SECOND_BROKER_EVIDENCE.csv, then rerun work\analyze_trade_ready_conservative_second_broker.ps1. |
| live:local-reproducibility-freeze | PASS | rows=60; pass=60; pending=0; fail=0; zipExists=True; missingRequiredChecks=0 | Local reproducibility bundle manifest exists, zip exists, required checks pass, and every bundle row is PASS | outputs\TRADE_READY_LIVE_READINESS_DECISION.csv | Keep rebuilding the bundle after every source/profile/status change; this local freeze does not replace GitHub/source-publication sync. |
| live:reproducible-github-sync | PENDING | gitValid=False; gitDetail=fatal: not a git repository (or any of the parent directories): .git; publicationRows=7; publicationPass=5; publicationPending=2; publicationFail=0 | Either workspace is a clean pushed GitHub checkout with tracked required source/profile artifacts, or required source/profile artifacts match GitHub by SHA-256 through connector publication audit | outputs\TRADE_READY_LIVE_READINESS_DECISION.csv | Restore a valid Git checkout or publish exact source/profile artifacts through the connector until outputs\GITHUB_PUBLICATION_SYNC.md has zero required pending/fail rows. |
| first-pass-refresh | PENDING | promote=0; wait=1; fail=0; nextBatch=READY | Trusted first-pass evidence is PASS before spending full tester time | outputs\FIRST_PASS_REFRESH_STATUS.csv | Run the current first-pass next package, import reports, then refresh. |
