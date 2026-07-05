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

Offline robust-candidate ranking:

- Local generated ranking file: `ROBUST_CANDIDATE_RANKING.csv`
- GitHub report file: `ROBUST_CANDIDATE_RANKING.md`
- Regeneration script: `work/analyze_robust_candidates.ps1`
- The current promoted split profile ranks #1 because it has the strongest multi-window evidence: 9 windows, `+$2,354.65`, worst `$0.00`, 0 losing windows.
- The next unvalidated candidates are ranked #3 and #4: `risk160_sl16_tp38` and `risk160_sl18_tp38`.
- Single-period high-profit date-block summaries are treated as benchmark-only by the analyzer because they do not prove start-window robustness.

Prepared validation pack:

- Runbook: `NEXT_VALIDATION_RUNBOOK.md`
- Generated configs: `work/generated_validation/`
- Manifest: `work/generated_validation/VALIDATION_MANIFEST.csv`
- Configs were generated without launching MT5.
- The pack contains 147 configs: 49 windows for each of the two queued candidates plus the current promoted baseline.

Local MT5 run safety:

- Local MT5 launch is disabled unless `ALLOW_MT5_FOCUS_RISK=1` is set.
- The runner now attempts to launch MT5 on a separate hidden desktop, but this still needs a controlled test before unattended local validation resumes.
