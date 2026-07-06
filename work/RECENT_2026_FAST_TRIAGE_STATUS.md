# Recent 2026 Fast-Triage Status

Generated locally without launching MT5.

## Local Change Summary

- Added a phase-1 fast-triage `2026_ytd` window to the profit-search config generator.
- Added `risk14_tp38_sl18`, a middle-ground candidate with `InpRiskPercent=1.40` and `InpTakeProfitATRMultiplier=3.80`.
- Updated the risk-adjusted micro batch to compare four profiles across four compact windows: `baseline_promoted`, `baseline_dd4`, `risk12_tp38_sl18`, and `risk14_tp38_sl18` on `2026_Q2`, `2026_ytd`, `2024_Q1`, and `2025_Q2`.
- Updated the external MT5 package audit to require the new 16-row micro-batch shape.

## Regenerated Local Evidence

- Profit-search manifest: 259 configs total.
- Phase 1 fast triage: 171 configs.
- Phase 2 real-tick validation: 88 configs.
- Micro batch: 16 runs.
- Micro batch estimated tester runtime: 5.27 minutes before platform overhead.
- Micro batch includes 4 fast `2026_ytd` runs: promoted baseline, drawdown-guard baseline, `risk12_tp38_sl18`, and `risk14_tp38_sl18`.
- External MT5 validation package zip SHA-256: `BAFBFF8685A8FE28414C80637A3D219C958E066B1A30DB17AB7345C1C85E6E17`.
- Risk-adjusted micro handoff zip SHA-256: `AF7C4D599B2B1BA54CE6AD66F2284188BF24B6B62ED4CFB4D255D95C826E8DE3`.

## Verification

- `work/refresh_offline_validation_state.ps1`: PASS, 16 steps, 0 failed.
- `outputs/EXTERNAL_MT5_PACKAGE_AUDIT.md`: PASS, 22/22 checks, 16 configs packaged.
- `outputs/REPORT_IMPORT_PREFLIGHT.md`: PASS for parser, risk guards, MT5 hidden launcher lock, source sync, handoff integrity, micro handoff, local safety, and external package.
- Final local process scan: `NO_MT5_OR_METAEDITOR_PROCESSES_FOUND`.

## Important Caveat

The local generated scripts and outputs are updated in the workspace. This status note records the change on GitHub; the large script files still need a normal git push or connector full-file update to fully synchronize the repository.
