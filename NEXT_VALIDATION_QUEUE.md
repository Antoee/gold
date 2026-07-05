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

Offline robust-candidate ranking:

- Local generated ranking file: `ROBUST_CANDIDATE_RANKING.csv`
- GitHub report file: `ROBUST_CANDIDATE_RANKING.md`
- Regeneration script: `work/analyze_robust_candidates.ps1`
- Loss-control report: `LOSS_CONTROL_REPORT.md`
- Loss-control script: `work/analyze_loss_control.ps1`
- Promotion gate report: `PROMOTION_GATE_REPORT.md`
- Promotion gate script: `work/analyze_promotion_gate.ps1`
- Profile input audit report: `PROFILE_INPUT_AUDIT.md`
- Profile input audit script: `work/audit_profile_inputs.ps1`
- Validation report metrics: `VALIDATION_REPORT_METRICS.md`
- Validation report collector: `work/collect_validation_results.ps1`
- The current promoted split profile ranks #1 because it has the strongest multi-window evidence: 9 windows, `+$2,354.65`, worst `$0.00`, 0 losing windows.
- The next unvalidated candidates are ranked #3 and #4: `risk160_sl16_tp38` and `risk160_sl18_tp38`.
- Single-period high-profit date-block summaries are treated as benchmark-only by the analyzer because they do not prove start-window robustness.
- For the updated goal, no-date candidates with zero losing windows rank above higher-profit date-block benchmarks.
- Profit giveback guard candidates should be judged primarily by whether they preserve or improve zero-loss windows without reducing full-period profit too much.
- Current promotion gate result: only `promoted_risk160_sl18_tp35` passes. All queued candidates still need full, split, quarter, and month evidence.
- Current profile input audit result: all four active `.set` files pass with 35/35 critical inputs pinned and no duplicate or unknown inputs.

Prepared validation pack:

- Runbook: `NEXT_VALIDATION_RUNBOOK.md`
- Generated configs: `work/generated_validation/`
- Manifest: `work/generated_validation/VALIDATION_MANIFEST.csv`
- Configs were generated without launching MT5.
- The pack contains 196 configs: 49 windows for each of the three queued candidates plus the current promoted baseline.
- Current collector status: 196 expected exported reports, 0 parsed, 196 missing. This is expected until MT5 reports are exported.

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
- Promotion packet builder: `work/build_profit_promotion_packet.ps1`
- Promotion packet outputs: `outputs/promotion_packets/`
- Coverage audit report: `PROFIT_SEARCH_COVERAGE_AUDIT.md`
- Coverage audit script: `work/audit_profit_search_coverage.ps1`
- Next-test handoff folder: `outputs/next_test_handoff/`
- Next-test handoff archive: `outputs/next_test_handoff.zip`
- Next-test handoff builder: `work/build_next_test_handoff.ps1`
- Contains 16 generated candidate profiles.
- Phase 1: 128 fast triage configs using `Model=2`.
- Phase 2: 55 real-tick validation configs using `Model=4`.
- Current profit-search collector status: 183 expected exported reports, 0 parsed, 183 missing.
- Current profit-search ranking status: all 21 profile/phase rows are `MissingEvidence`; no candidate is recommended yet.
- Current next-batch status: 24 prioritized configs, starting with fast stress-window triage for the baseline and highest-priority TP/SL candidates.
- Current promotion-packet status: baseline and `tp38_sl18` both correctly report `MISSING_EVIDENCE` because phase-2 reports have not been exported yet.
- Current coverage audit status: 16 profiles, 5 phase-2 seeds, 1 aggressive-risk candidate (`risk20_tp38_sl18`) kept phase-1 only, with TP/SL, trailing, RR, risk, giveback, breakeven, baseline, and reduced-risk coverage present.
- Current handoff status: 24 prioritized `.ini` configs copied into `outputs/next_test_handoff/configs/` and zipped for the next safe testing window.
- Phase 1 is pruning only; candidates still need real-tick phase 2 plus full promotion-gate validation before promotion.

Local MT5 run safety:

- Local MT5 launch is hard-locked in the shared launcher and all legacy MT5 runner scripts unless `ALLOW_MT5_FOCUS_RISK=1` is set and `work\ALLOW_MT5_LOCAL_LAUNCH.unlock` exists.
- The runner now attempts to launch MT5 on a separate hidden desktop, but this still needs a controlled test before unattended local validation resumes.
- A temporary local watchdog can be started with `work/mt5_focus_watchdog.ps1`; it stops `terminal64`, `metatester64`, and `MetaEditor` immediately if anything tries to open them. Stop it with `work/stop_mt5_focus_watchdog.ps1`.
