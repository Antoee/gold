# Recent 2026 Fast-Triage Status

Generated locally without launching MT5.

## Local Change Summary

- Added `buyblock2_dd4`, a research-only candidate based on the strongest existing historical evidence: `SECOND_BUY_BLOCK_STANDARD_REAL_TICK` showed positive 2024, 2025, 2026 YTD, walk-forward, and full-period results in prior real-tick evidence.
- `buyblock2_dd4` enables `InpUseDateBuyBlock2=true` for `2025.07.01 00:00` through `2025.12.31 23:59` and keeps `InpMaxEquityDrawdownPercent=4.00`.
- Guardrails deliberately mark `buyblock2_dd4` as `REJECT_PROMOTION` because date blocks are overfit-prone. It can be tested for upside, but cannot replace the promoted profile unless later generalized or validated through broader out-of-sample evidence.
- Expanded the risk-adjusted micro batch from 16 to 20 runs: `baseline_promoted`, `baseline_dd4`, `buyblock2_dd4`, `risk12_tp38_sl18`, and `risk14_tp38_sl18` across `2026_Q2`, `2026_ytd`, `2024_Q1`, and `2025_Q2`.
- Updated the frontier smoke, external package audit, return-completeness audit, handoff integrity audit, local pipeline manifest wording, and generated package README/checklists for the 20-report shape.
- Kept local MT5 launch hard-locked. The hidden quiet-shield watchdog remains a cleanup-only helper and does not launch MT5.

## Regenerated Local Evidence

- Profit-search profiles: 20.
- Profit-search manifest: 279 configs total.
- Phase 1 fast triage: 180 configs.
- Phase 2 real-tick validation: 99 configs.
- Micro batch: 20 runs.
- Micro profiles: `baseline_promoted`, `baseline_dd4`, `buyblock2_dd4`, `risk12_tp38_sl18`, `risk14_tp38_sl18`.
- Micro windows: `2026_Q2`, `2026_ytd`, `2024_Q1`, `2025_Q2`.
- External report return audit checks 20 expected reports and 20 imported metric rows.
- External micro decision lists 4 candidates and 16 expected candidate decision rows.
- External MT5 validation package zip SHA-256: `558B2AE2A7CFF45D37EDF9D2F71D80EB7CD41487D5A8289FBF66A36907C05FEB`.
- Risk-adjusted micro handoff zip SHA-256: `DD2BBB0455CA2FA9C209C5C7C77E0C53EBF27469FB364D39AC43A64EFF058272`.

## Verification

- `work/test_generate_profit_search_configs.ps1`: `GENERATE_PROFIT_SEARCH_CONFIGS_SMOKE_PASS`.
- `work/test_risk_adjusted_micro_batch_frontier.ps1`: `RISK_ADJUSTED_MICRO_BATCH_FRONTIER_SMOKE_PASS`.
- `work/refresh_offline_validation_state.ps1`: PASS, 20 steps, 0 failed.
- `outputs/OPTIMIZATION_GUARDRAIL_AUDIT.csv`: `buyblock2_dd4` is `REJECT_PROMOTION`, score 80, risk 1.60%, `date_block_enabled` overfit flag present.
- `outputs/EXTERNAL_MT5_PACKAGE_AUDIT.csv`: PASS, 0 failed checks.
- `outputs/EXTERNAL_MT5_REPORT_RETURN_AUDIT.csv`: PASS, 9/9 checks, 0 parsed, 20 missing, 0 unparsed.
- `outputs/EXTERNAL_MT5_MICRO_DECISION.md`: overall `COMPILE_REQUIRED`; candidates are `baseline_dd4`, `buyblock2_dd4`, `risk12_tp38_sl18`, and `risk14_tp38_sl18`; 16 candidate windows are waiting for reports.
- `outputs/REPORT_IMPORT_PREFLIGHT.csv`: local pipeline manifest PASS, local safety PASS, external report return PASS, risk-adjusted micro frontier smoke PASS; external micro decision is `COMPILE_REQUIRED` because compile trust remains stale and reports are still waiting.
- Final local process scan: `NO_MT5_OR_METAEDITOR_PROCESSES_FOUND`.

## Important Caveat

The local generated scripts and outputs are updated in the workspace. This status note records the change on GitHub; the large script files still need a normal git push or connector full-file update to fully synchronize the repository.
