# Next Validation Queue

Do not promote these profiles until they pass full monthly, quarterly, yearly, half-year, and full-period validation.

Current promoted default:

- `InpRiskPercent=1.60`
- `InpStopATRMultiplier=1.80`
- `InpTakeProfitATRMultiplier=3.50`
- Full period `2024.01.01` to `2026.07.02`: `+$866.59`
- Monthly/quarter validation: `+$744.03`, worst window `$0.00`, 0 losing windows
- Split validation: `+$2,354.65` aggregate, worst window `$0.00`, 0 losing windows

Candidate 1: `risk160_sl18_tp38`

- Settings file: `CANDIDATE_RISK16_SL18_TP38_PROFILE.set`
- `InpRiskPercent=1.60`
- `InpStopATRMultiplier=1.80`
- `InpTakeProfitATRMultiplier=3.80`
- Stress-window result: `+$798.00`, worst window `$0.00`, 0 losing windows
- Status: needs full monthly/quarter/split validation before promotion

Candidate 2: `risk160_sl16_tp38`

- Settings file: `CANDIDATE_RISK16_SL16_TP38_PROFILE.set`
- `InpRiskPercent=1.60`
- `InpStopATRMultiplier=1.60`
- `InpTakeProfitATRMultiplier=3.80`
- Stress-window result: `+$798.00`, worst window `$0.00`, 0 losing windows
- Status: needs full monthly/quarter/split validation before promotion

Candidate 3: `risk160_sl18_tp35_giveback`

- Settings file: `CANDIDATE_RISK16_SL18_TP35_GIVEBACK_PROFILE.set`
- Same core settings as the current promoted no-date BOS/sweep profile
- `InpUseProfitGivebackGuard=true`
- Daily/weekly/monthly giveback threshold: `35%`
- Minimum period profit before protection: `0.50%`
- Status: needs full loss-control validation before promotion

Prepared profit-search pack:

- Generator: `work/generate_profit_search_configs.ps1`
- Generated configs: `work/generated_profit_search/`
- Config manifest: `work/generated_profit_search/PROFIT_SEARCH_CONFIG_MANIFEST.csv`
- Metrics report: `PROFIT_SEARCH_REPORT_METRICS.md`
- Ranking report: `PROFIT_SEARCH_RANKING.md`
- Result-import decision matrix: `RESULT_IMPORT_DECISION_MATRIX.md`
- Profit readiness snapshot: `PROFIT_READINESS_SNAPSHOT.md`
- Fast-probe readiness snapshot: `FAST_PROBE_READINESS_SNAPSHOT.md`
- Optimization guardrail audit: `OPTIMIZATION_GUARDRAIL_AUDIT.md`
- Report import preflight: `REPORT_IMPORT_PREFLIGHT.md`
- Handoff integrity report: `HANDOFF_CONFIG_INTEGRITY.md`
- MT5 local safety audit report: `MT5_LOCAL_SAFETY_AUDIT.md`
- Strategy research brief: `STRATEGY_RESEARCH_BRIEF.md`
- Contains 16 generated candidate profiles.
- Phase 1: 128 fast triage configs using `Model=2`.
- Phase 2: 55 real-tick validation configs using `Model=4`.
- Current profit-search collector status: 183 expected exported reports, 0 parsed, 183 missing.
- Current profit-search ranking status: all 21 profile/phase rows are `MissingEvidence`; no candidate is recommended yet.
- Current next-batch status: 24 prioritized configs, starting with fast stress-window triage for the baseline and highest-priority TP/SL candidates.
- Current result-import decision status: all 21 profile/phase rows are `RunMissingReports`; no profile is ready for phase-2 advancement or promotion-packet review until reports are exported and parsed.
- Current fast-probe readiness status: waiting for exported fast-probe reports; no probe can promote a profile by itself.
- Current profit readiness status: `NOT_READY`; keep the current promoted profile because no candidate has enough imported evidence to replace it.
- Current optimization guardrail status: 16 profiles audited, all 16 are test-eligible but require promotion review; top score is `giveback25_tp38=87`. Guardrails must be checked before spending tester time or building promotion packets.
- Current report-import preflight status: parser, manifest, optimization guardrails, handoff, and local safety checks pass; imported metrics are still `WAITING_FOR_REPORTS`.
- Current local MT5 safety audit: PASS, 24/24 checks, 56 runner scripts guarded, 0 raw terminal-launch bypasses, no MT5/MetaEditor process running, both unlock files absent, both MT5 unlock env flags off, watchdog stopped but script available.
- Phase 1 is pruning only; candidates still need real-tick phase 2 plus full promotion-gate validation before promotion.

Local MT5 run safety:

- Local MT5 launch is hard-locked in the shared launcher and all legacy MT5 runner scripts unless both `ALLOW_MT5_FOCUS_RISK=1` and `ALLOW_MT5_HIDDEN_DESKTOP_ACK=1` are set and both `work\ALLOW_MT5_LOCAL_LAUNCH.unlock` and `work\ALLOW_MT5_HIDDEN_DESKTOP_ACK.unlock` exist.
- The runner now attempts to launch MT5 on a separate hidden desktop, but this still needs a controlled test before unattended local validation resumes.
- A temporary local watchdog can be started with `work/mt5_focus_watchdog.ps1`; it stops `terminal64`, `metatester64`, and `MetaEditor` immediately if anything tries to open them. Stop it with `work/stop_mt5_focus_watchdog.ps1`.
