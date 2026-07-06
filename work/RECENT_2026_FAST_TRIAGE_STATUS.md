# Recent 2026 Fast-Triage Status

Generated locally without launching MT5.

## Local Change Summary

- Added `work/build_fully_pinned_research_retest_package.ps1` locally to generate a clean research retest package for old profitable clues without relying on cached MT5 inputs.
- Added `work/test_fully_pinned_research_retest_package.ps1` locally to verify the retest configs are non-visual, non-optimization, shutdown-after-run, fully pinned, and research-only where appropriate.
- The package retests three profiles across six windows: `baseline_promoted`, `buyblock2_dd4`, and `sweep_only_dd4` on `2024_Q1`, `2024_Q3`, `2025_Q2`, `2025_Q3`, `2026_ytd`, and `full`.
- `sweep_only_dd4` translates the old mislabeled `no_date_momentum_sweep` clue into explicit fully pinned settings: BOS off, liquidity sweep on, momentum candle off, no date blocks, and 4% equity drawdown guard.
- Wired the research retest package into offline refresh, report-import preflight, and local pipeline manifest.
- The main 20-run external micro package remains the current promotion-path source of truth; this new 18-run package is research-only and cannot promote a profile by itself.
- Kept local MT5 launch hard-locked. The hidden quiet-shield watchdog remains cleanup-only and does not launch MT5.

## Current Local Evidence

- Main profit-search profiles: 20.
- Main profit-search manifest: 279 configs total.
- Main micro batch: 20 runs.
- Fully pinned research retest package: 3 profiles, 18 configs.
- Research retest profiles: `baseline_promoted`, `buyblock2_dd4`, `sweep_only_dd4`.
- Research retest zip SHA-256: `81B1DF71AD9FC8F345D6DF85B705EC076E8856CACEF7EC3F14DAEA4DB4E03B4F`.
- Local pipeline manifest: 28 tracked artifacts, 0 missing.
- Legacy evidence pin audit: 4 evidence sets checked, 4 pin-incomplete.
- External MT5 validation package zip SHA-256: `558B2AE2A7CFF45D37EDF9D2F71D80EB7CD41487D5A8289FBF66A36907C05FEB`.
- Risk-adjusted micro handoff zip SHA-256: `DD2BBB0455CA2FA9C209C5C7C77E0C53EBF27469FB364D39AC43A64EFF058272`.

## Verification

- `work/test_fully_pinned_research_retest_package.ps1`: `FULLY_PINNED_RESEARCH_RETEST_PACKAGE_SMOKE_PASS`.
- `work/refresh_offline_validation_state.ps1`: PASS, 22 steps, 0 failed.
- `outputs/REPORT_IMPORT_PREFLIGHT.csv`: fully pinned research retest `READY_RESEARCH`; legacy evidence input pins REVIEW; local pipeline manifest PASS; local safety PASS; external report return PASS; external micro decision `COMPILE_REQUIRED`.
- `outputs/LOCAL_PIPELINE_MANIFEST.csv`: PASS, 28 artifacts, 0 missing.
- `outputs/EXTERNAL_MT5_REPORT_RETURN_AUDIT.csv`: PASS, 9/9 checks, 0 parsed, 20 missing, 0 unparsed.
- Final local process scan: `NO_MT5_OR_METAEDITOR_PROCESSES_FOUND`.

## Important Caveat

The local generated scripts and outputs are updated in the workspace. This status note records the change on GitHub; the large script files still need a normal git push or connector full-file update to fully synchronize the repository.
