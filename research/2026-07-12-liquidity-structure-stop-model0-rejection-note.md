# Liquidity Structure Stop Model 0 Rejection Note

Date: 2026-07-12

## Purpose

Retest structure- and liquidity-aware stop variants on the current MFE-August research-best profile. This directly targets the pure ATR-stop weakness: an ATR stop can sit inside nearby liquidity instead of behind meaningful structure.

## Evidence

- Builder: `work/build_current_best_liquidity_structure_stop_model0_package.ps1`
- Package: `work/local_mt5_current_best_liquidity_structure_stop_model0_package`
- Compact source audit: `outputs/CURRENT_BEST_LIQUIDITY_STRUCTURE_STOP_MODEL0_COMPACT_SOURCE_AUDIT.csv`
- Compile log: `outputs/CURRENT_BEST_LIQUIDITY_STRUCTURE_STOP_MODEL0_COMPACT_COMPILE.log`
- Run log: `outputs/CURRENT_BEST_LIQUIDITY_STRUCTURE_STOP_MODEL0_RUN.csv`
- Parsed results: `outputs/CURRENT_BEST_LIQUIDITY_STRUCTURE_STOP_MODEL0_LOG_RESULTS.csv`
- Summary: `outputs/CURRENT_BEST_LIQUIDITY_STRUCTURE_STOP_MODEL0_LOG_SUMMARY.csv`

The first full-source run hit MT5 Strategy Tester's input limit: `too many input parameters (1495)`. The package was then rerun using the compact tester-source workflow, keeping 283 required inputs and converting 1202 unused tester inputs to globals.

## Results

| Profile | Parsed | Expected | Total Net | Continuous | 2026 YTD | Full 2025 | Full 2024 | Worst Window | Losing Windows |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| base_mfe_aug | 7 | 7 | 10513.73 | 6633.61 | 1107.93 | 214.30 | 2406.27 | 0.00 | 0 |
| liq_conflict_guard | 7 | 7 | 10513.73 | 6633.61 | 1107.93 | 214.30 | 2406.27 | 0.00 | 0 |
| liq_cluster_pocket | 7 | 7 | 1431.51 | 523.44 | 72.04 | 233.11 | 523.44 | 0.00 | 0 |
| liq_balanced | 7 | 7 | 589.89 | 7.34 | 521.18 | 0.38 | 15.25 | -55.66 | 1 |
| liq_balanced_cluster | 7 | 7 | 159.11 | 152.83 | -190.08 | 0.38 | 155.15 | -190.08 | 2 |
| liq_full_guarded | 7 | 7 | 159.11 | 152.83 | -190.08 | 0.38 | 155.15 | -190.08 | 2 |

## Decision

Do not promote liquidity-aware stop widening, cluster extension, or pocket shifting. They reduced continuous profit sharply and some variants reintroduced losing windows.

Do not promote `liq_conflict_guard` either. It matched the current baseline exactly in this batch, which means it did not harm results, but it also did not prove an improvement. Keep it available as a default-off safety tool for future targeted stop-conflict tests.

Current best remains:

`outputs/CANDIDATE_PRIMARY_AUG40_REVERSE_OFF_FSD_STRICT_MFE_AUGUST_ONLY_PROFILE.set`

## Interpretation

The evidence says the current strategy should not move to wider liquidity stops globally. The next stop-loss work should be narrower and entry-context-specific, such as applying structure-stop behavior only to the FSD lane or only after a confirmed sweep/retest where the structural invalidation level is explicit.
