# R10 Activity Probe Package

Offline package builder only. This does not launch MT5.

- Source hash: `2219F6AE66CF1121972848C118213B50C01F91E783ABFE6D66F75105C655EB4D`
- Base profile hash: `CB182D026A62AE499052949F88F514EF7FC67D8C071E9179AB069D29575C59B2`
- Model: `1`
- Candidates: `r10_a7_current, r10_a7_dfg_risk_25_45_50, r10_a7_fmlr_blend, r10_a7_fmlr_tight, r10_a7_dfg_fmlr_blend, r10_a7_dfg_fmlr_tight`
- Windows: `2020_full, 2022_full, 2024_full, 2025_full, 2026_ytd`
- Configs: `30`

## Purpose

This first-pass package targets the current stability lead's blocker years. It tests whether already-built low-risk FMLR activity logic can add participation without replacing the R10 A7 stability settings.

## Files

- Queue manifest: `outputs\R10_ACTIVITY_PROBE_QUEUE.csv`
- Runner manifest: `outputs\R10_ACTIVITY_PROBE_PACKAGE_MANIFEST.csv`
- Package dir: `outputs\r10_activity_probe_package`
