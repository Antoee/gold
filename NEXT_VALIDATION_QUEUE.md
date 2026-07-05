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

Local MT5 run safety:

- Local MT5 launch is disabled unless `ALLOW_MT5_FOCUS_RISK=1` is set and `work\ALLOW_MT5_LOCAL_LAUNCH.unlock` exists.
- The runner now attempts to launch MT5 on a separate hidden desktop, but this still needs a controlled test before unattended local validation resumes.
