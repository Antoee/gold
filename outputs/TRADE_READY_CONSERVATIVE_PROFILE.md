# Conservative Trade-Ready Candidate

Last updated: 2026-07-14.

## Decision

Created a strict paper/demo or tiny-size evaluation profile:

- Profile: `outputs/CANDIDATE_TRADE_READY_CONSERVATIVE_PROFILE.set`
- Profile SHA-256: `82530801102198E81E08E1EF772D5501B52FB88CCFD67E6651CE32EF1D055665`
- EA source SHA-256: `5D148DAE2335F9037BDED3C9A82BD916C1FCFB6F43EE2EC5EAAE7E67384ED412`
- Audit: `outputs/TRADE_READY_CONSERVATIVE_AUDIT.md`
- Audit result: `110` PASS, `5` OPEN, `0` FAIL
- Validation package: `outputs/trade_ready_conservative_validation_package`
- Validation manifest: `outputs/TRADE_READY_CONSERVATIVE_VALIDATION_MANIFEST.csv`
- Broker-proxy package: `outputs/trade_ready_conservative_broker_proxy_package`
- Broker-proxy manifest: `outputs/TRADE_READY_CONSERVATIVE_BROKER_PROXY_MANIFEST.csv`
- Report importer: `work/import_trade_ready_conservative_validation_reports.ps1`
- Imported validation results: `outputs/TRADE_READY_CONSERVATIVE_VALIDATION_RESULTS.csv`
- Imported broker-proxy results: `outputs/TRADE_READY_CONSERVATIVE_BROKER_PROXY_RESULTS.csv`
- Decision gate: `outputs/TRADE_READY_CONSERVATIVE_VALIDATION_DECISION.md`
- Trade-quality gate: `outputs/TRADE_READY_CONSERVATIVE_TRADE_QUALITY.md`
- Monte Carlo gate: `outputs/TRADE_READY_CONSERVATIVE_MONTE_CARLO.md`
- Forward/demo evidence gate: `outputs/TRADE_READY_CONSERVATIVE_FORWARD_TEST.md`
- Second-broker evidence gate: `outputs/TRADE_READY_CONSERVATIVE_SECOND_BROKER_DECISION.md`
- Live-readiness gate: `outputs/TRADE_READY_LIVE_READINESS_DECISION.md`
- Current imported report status: `0 / 53` validation reports parsed and `0 / 10` broker-proxy reports parsed.
- Current decision: `PENDING`, with `2` passing prep/import gates, `23` pending result/evidence gates, and `0` failures.
- Current trade-quality status: `PENDING`, with `0` trade-log files found, `0` closed rows, `2` pending gates, and `0` failures.
- Current Monte Carlo status: `PENDING`, with `0` returned trade logs, `0` R trades, `3` pending gates, and `0` failures.
- Current forward/demo status: `PENDING`, with `0` returned evidence rows and `0` failures.
- Current second-broker status: `PENDING`, with `0` returned evidence rows and `0` failures.
- Current live-readiness status: `PENDING`, with `5` passing gates, `8` pending gates, and `0` failures.
- Evidence identity expected in returned trade logs: `profile_id=trade_ready_conservative`, `source_hash=5D148DAE2335F9037BDED3C9A82BD916C1FCFB6F43EE2EC5EAAE7E67384ED412`, and a non-empty `run_label`.

This is the safest current candidate profile, but it is not approved for meaningful real money until the open proof gaps are closed.

## Risk Shape

- Risk per trade: `0.10%`
- Effective risk cap: `0.10%`
- Open risk cap: `0.20%`
- Max lots: `0.01`
- Max simultaneous positions: `1`
- Max trades per day: `2`
- Minimum minutes between trades: `120`
- Daily loss cap: `0.20%`
- Weekly loss cap: `0.60%`
- Monthly loss cap: `1.25%`
- Equity drawdown cap: `3.00%`
- Max daily loss count: `1`
- Max consecutive losses: `2`
- Loss cooldown: `720` minutes

## Hard Safety Gate

The profile enables:

- `InpUseTradeReadinessSafetyGate=true`
- `InpUseSymbolSafetyLock=true`
- `InpUseRealAccountSafetyLock=true`
- `InpUseTradeEnvironmentGuard=true`
- `InpTradeEnvMinSignalBars=300`
- `InpTradeEnvMaxQuoteAgeSeconds=30`
- `InpTradeEnvMaxStopsLevelPoints=250.0`
- `InpTradeEnvMaxFreezeLevelPoints=250.0`
- `InpTradeEnvRequireTickValue=true`
- `InpAllowRealAccountTrading=false`
- `InpRealAccountApprovalCode=DISABLED`
- `InpRealAccountApprovalProfileId=DISABLED`
- `InpRealAccountApprovalSourceHash=DISABLED`
- `InpEvidenceProfileId=trade_ready_conservative`
- `InpEvidenceSourceHash=5D148DAE2335F9037BDED3C9A82BD916C1FCFB6F43EE2EC5EAAE7E67384ED412`
- `InpEvidenceRunLabel=trade_ready_conservative_validation`

The EA source contains `TradeReadinessSafetyGateAllows()` and returns `INIT_PARAMETERS_INCORRECT` if this gate is enabled and the profile is loosened past the configured risk, spread, margin, loss, or exit-protection caps.
The EA source also contains `TradeEnvironmentAllows()` and blocks new entries when enabled if quotes are stale/invalid, the signal timeframe has too little history, broker symbol specs are invalid, trade mode is disabled/close-only, stop/freeze levels exceed the cap, or tick value is unavailable.
The EA source also contains `SymbolSafetyLockAllows()` and refuses initialization when attached to a chart whose symbol does not contain `InpAllowedSymbol`.
The EA source also contains `RealAccountSafetyLockAllows()` and refuses real-account initialization unless real trading is explicitly enabled, the approval code is set to `ALLOW_REAL_ACCOUNT_TRADING`, the trade-readiness gate is enabled, and the approval profile/source identity matches the evidence profile/source identity.

## Protection Settings

- Adaptive Reverse: off
- Winner scale-in: off
- FMLR research lane: off
- Tick-speed impulse: off
- Martingale/grid/averaging down: not used
- Min-lot risk overflow: off
- Unprotected exposure: blocked
- Spread-adjusted RR filter: on
- Trade environment guard: on
- Trading-cost guard: on
- Spread regime guard: on
- M1 spread-shock guard: on
- Margin guard: on
- Margin-aware lot cap: on
- Break-even: on
- ATR trailing: on
- Structure stop: on
- Liquidity-aware stop: on
- MFE profit-lock stop: on
- MFE giveback exit: on
- Daily/weekly/monthly profit locks: on
- Profit giveback guard: on

## Validation Status

Static checks passed without launching MT5:

- `TRADE_READY_CONSERVATIVE_PROFILE_SMOKE_PASS`
- `TRADE_READY_CONSERVATIVE_VALIDATION_PACKAGE_SMOKE_PASS`
- `TRADE_READY_CONSERVATIVE_BROKER_PROXY_PACKAGE_SMOKE_PASS`
- `TRADE_READY_CONSERVATIVE_VALIDATION_DECISION_SMOKE_PASS`
- `TRADE_READY_CONSERVATIVE_REPORT_IMPORT_SMOKE_PASS`
- `TRADE_QUALITY_ANALYZER_SMOKE_PASS`
- `MONTE_CARLO_TRADE_STRESS_SMOKE_PASS`
- `TRADE_READY_EXTERNAL_EVIDENCE_SMOKE_PASS`
- `TRADE_READY_LIVE_READINESS_SMOKE_PASS`
- `TRADE_READY_CLOSED_DEAL_LOGGING_SMOKE_PASS`
- `TRADE_READY_CONSERVATIVE_AUDIT_WRITTEN`
- `MONEY_READY_PROFILE_SMOKE_PASS`
- `MONEY_READY_SAFETY_CONTRACT_PASS`
- `MONEY_READY_VALIDATION_PACKAGE_SMOKE_PASS`
- `MONEY_READY_BROKER_PROXY_PACKAGE_SMOKE_PASS`
- `MONEY_READY_VALIDATION_DECISION_SMOKE_PASS`
- `MT5_HIDDEN_LAUNCHER_LOCK_SMOKE_PASS`
- `FIRST_PASS_NEXT_RUN_PACKAGE_SMOKE_PASS`
- `FIRST_PASS_PARALLEL_LANES_SMOKE_PASS`
- `MT5_COMPILE_EVIDENCE_ROUTING_SMOKE_PASS`
- MT5 local safety audit: `PASS 43 / 43`
- Current-source compile evidence: `PENDING`; previous compile proof is stale for old source hash `46770EACA60826F90E1E9A9B7425356F96F7C8F83CF8F8C1FBE271632866933E`

Open proof gaps:

- Conservative validation decision gate is still `PENDING` until staged Model4/fast/stress/broker-proxy reports are returned and parsed.
- Conservative trade/deal log quality statistics have not been returned.
- Conservative Monte Carlo trade-stress evidence is prepared but still `PENDING` until returned logs include realized R.
- Forward/demo evidence gate is prepared but still `PENDING` until paper/demo evidence is returned.
- Second-broker evidence gate is prepared but still `PENDING` until broker-specific evidence is returned.

The final live-readiness gate remains `PENDING` while any of these proof gaps remain open.

## Practical Use

Use this profile before the higher-risk money-ready profile when the priority is protecting the account while collecting forward-test evidence. Expect lower profit than the research profile because the risk is deliberately much smaller.
