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
- Candidate manifest: `work/generated_profit_search/PROFIT_SEARCH_PROFILES.csv`
- Config manifest: `work/generated_profit_search/PROFIT_SEARCH_CONFIG_MANIFEST.csv`
- Metrics report: `PROFIT_SEARCH_REPORT_METRICS.md`
- Ranking report: `PROFIT_SEARCH_RANKING.md`
- Ranking script: `work/analyze_profit_search.ps1`
- Next-batch report: `NEXT_PROFIT_SEARCH_BATCH.md`
- Next-batch CSV: `NEXT_PROFIT_SEARCH_BATCH.csv`
- Next-batch builder: `work/build_next_profit_search_batch.ps1`
- Next-batch rationale report: `PROFIT_SEARCH_BATCH_RATIONALE.md`
- Next-batch rationale script: `work/build_profit_search_batch_rationale.ps1`
- Result-import decision matrix: `RESULT_IMPORT_DECISION_MATRIX.md`
- Result-import decision script: `work/build_result_import_decision_matrix.ps1`
- Promotion packet builder: `work/build_profit_promotion_packet.ps1`
- Coverage audit report: `PROFIT_SEARCH_COVERAGE_AUDIT.md`
- Next-test handoff folder: `outputs/next_test_handoff/`
- Next-test handoff archive: `outputs/next_test_handoff.zip`
- Handoff integrity report: `HANDOFF_CONFIG_INTEGRITY.md`
- MT5 local safety audit report: `MT5_LOCAL_SAFETY_AUDIT.md`
- Strategy research brief: `STRATEGY_RESEARCH_BRIEF.md`

Current status:

- Contains 16 generated candidate profiles.
- Phase 1: 128 fast triage configs using `Model=2`.
- Phase 2: 55 real-tick validation configs using `Model=4`.
- Current profit-search collector status: 183 expected exported reports, 0 parsed, 183 missing.
- Current profit-search ranking status: all 21 profile/phase rows are `MissingEvidence`; no candidate is recommended yet.
- Current next-batch status: 24 prioritized configs, starting with fast stress-window triage for the baseline and highest-priority TP/SL candidates.
- Current next-batch rationale: 24 phase-1 prune runs only, covering 6 profiles: 5 baseline-anchor runs, 8 evidence-backed TP `3.8` runs, and 11 adjacent TP-expansion runs. No phase-2 run is queued until phase-1 evidence exists.
- Current result-import decision status: all 21 profile/phase rows are `RunMissingReports`; no profile is ready for phase-2 advancement or promotion-packet review until reports are exported and parsed.
- Current promotion-packet status: baseline and `tp38_sl18` both correctly report `MISSING_EVIDENCE` because phase-2 reports have not been exported yet.
- Current coverage audit status: 16 profiles, 5 phase-2 seeds, 1 aggressive-risk candidate (`risk20_tp38_sl18`) kept phase-1 only, with TP/SL, trailing, RR, risk, giveback, breakeven, baseline, and reduced-risk coverage present.
- Current handoff status: 24 prioritized `.ini` configs copied into `outputs/next_test_handoff/configs/` and zipped for the next safe testing window.
- Current handoff integrity status: 24/24 configs pass static checks for `Visual=0`, `ShutdownTerminal=1`, `Optimization=0`, XAUUSD/M15, expected report names, critical EA inputs, and file hashes. Current handoff zip SHA256: `8FE19B8A55A058579F9696C2C8E7B2B47F38F1521EBCA8EB1823A022FD149AE3`.
- Current local MT5 safety audit: PASS, 18/18 checks, 56 runner scripts guarded, 0 raw terminal-launch bypasses, no MT5/MetaEditor process running, unlock absent, focus-risk env flag off, watchdog stopped but script available.
- Current strategy research brief: keep `risk1p6_sl18_tp35` promoted, prioritize TP `3.8` with SL `1.6` to `1.8` as the next evidence-backed profit search, treat momentum+sweep as research-only because it has one losing split window, and keep date-block logic benchmark-only until a general regime rule explains it.
- Phase 1 is pruning only; candidates still need real-tick phase 2 plus full promotion-gate validation before promotion.

Local MT5 run safety:

- Local MT5 launch is hard-locked in the shared launcher and all legacy MT5 runner scripts unless `ALLOW_MT5_FOCUS_RISK=1` is set and `work\ALLOW_MT5_LOCAL_LAUNCH.unlock` exists.
- No local MT5 run should be started while the PC is in normal use.
- A temporary local watchdog can be started with `work/mt5_focus_watchdog.ps1`; it stops `terminal64`, `metatester64`, and `MetaEditor` immediately if anything tries to open them. Stop it with `work/stop_mt5_focus_watchdog.ps1`.
