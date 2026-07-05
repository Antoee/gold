# Next Validation Queue

Do not promote these profiles until they pass full monthly, quarterly, yearly, half-year, and full-period validation.

Current promoted default:

- `InpRiskPercent=1.60`
- `InpStopATRMultiplier=1.80`
- `InpTakeProfitATRMultiplier=3.50`
- Full period `2024.01.01` to `2026.07.02`: `+$866.59`
- Monthly/quarter validation: `+$744.03`, worst window `$0.00`, 0 losing windows
- Split validation: `+$2,354.65` aggregate, worst window `$0.00`, 0 losing windows

Queued full-validation candidates:

- `risk160_sl18_tp38`: stress-window result `+$798.00`, worst `$0.00`, 0 losing windows.
- `risk160_sl16_tp38`: stress-window result `+$798.00`, worst `$0.00`, 0 losing windows.
- `risk160_sl18_tp35_giveback`: promoted core settings plus profit giveback guard.

Prepared standard validation pack:

- Generated configs: `work/generated_validation/`
- Manifest: `work/generated_validation/VALIDATION_MANIFEST.csv`
- Config count: 196
- Current collector status: 196 expected exported reports, 0 parsed, 196 missing.

Prepared profit-search pack:

- Generated configs: `work/generated_profit_search/`
- Candidate manifest: `work/generated_profit_search/PROFIT_SEARCH_PROFILES.csv`
- Config manifest: `work/generated_profit_search/PROFIT_SEARCH_CONFIG_MANIFEST.csv`
- Metrics report: `PROFIT_SEARCH_REPORT_METRICS.md`
- Candidate profiles: 16
- Phase 1: 128 fast triage configs using `Model=2`.
- Phase 2: 55 real-tick validation configs using `Model=4`.
- Current collector status: 183 expected exported reports, 0 parsed, 183 missing.
- Phase 1 is pruning only; candidates still need real-tick phase 2 plus full promotion-gate validation before promotion.

Local MT5 run safety:

- Local MT5 launch is hard-locked unless `ALLOW_MT5_FOCUS_RISK=1` is set and `work\ALLOW_MT5_LOCAL_LAUNCH.unlock` exists.
- The runner still needs a controlled hidden-desktop verification before unattended local validation resumes.
