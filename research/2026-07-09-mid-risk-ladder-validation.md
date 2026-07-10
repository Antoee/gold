# Mid-Risk Ladder Validation - 2026-07-09

## Purpose

Map the middle ground between the stable 1.00% risk candidate and the previously rejected 2.00%+ raw risk escalation.

## Method

Built `work/build_mid_risk_ladder_package.ps1` and ran 70 hidden MT5 tests using the compact-source workflow.

Parsed summary: `outputs/LOCAL_MT5_MID_RISK_LADDER_LOG_SUMMARY.csv`

## Results

| Profile | Continuous | 2026 YTD | 2025 | 2024 | Weak Sum | Worst Window | Decision |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| `block_r115` | 806.46 | 98.84 | 153.90 | 806.46 | -106.10 | -106.10 | Aggressive candidate |
| `base_r115` | 806.46 | 98.84 | 153.90 | 806.46 | -299.78 | -108.60 | Reject |
| `block_r100` | 801.84 | 84.72 | 124.51 | 801.84 | -84.88 | -84.88 | Safer benchmark |
| `base_r100` | 801.84 | 84.72 | 124.51 | 801.84 | -255.33 | -99.55 | Benchmark |
| `block_mfe_r125` | 660.82 | 112.96 | 140.64 | 660.82 | -106.10 | -106.10 | Reject |
| `mfe_r125` | 660.82 | 112.96 | 140.64 | 660.82 | -315.92 | -117.65 | Reject |
| `block_r125` | 607.19 | 112.96 | 140.64 | 607.19 | -106.10 | -106.10 | Reject |
| `base_r125` | 607.19 | 112.96 | 140.64 | 607.19 | -315.92 | -117.65 | Reject |
| `block_r150` | 262.45 | 124.36 | 179.56 | 262.45 | -148.54 | -148.54 | Reject |
| `base_r150` | 262.45 | 124.36 | 179.56 | 262.45 | -399.69 | -148.54 | Reject |

## Interpretation

The 1.15% risk version of the May/June risk-control profile is the only mid-risk setting that improved broad-window profit without collapsing the path.

It is still not a clean replacement for the safer profile because the weak-window loss worsened from `-84.88` to `-106.10`.

## Decision

Created aggressive candidate:

`outputs/CANDIDATE_PEAK15_BLOCK_MAY_JUN_R115_AGGRESSIVE_PROFILE.set`

Keep the safer primary candidate unchanged:

`outputs/CANDIDATE_PEAK15_LIQUIDITY_STOP_CHOP_PROFILE.set`

Keep the risk-calendar diagnostic:

`outputs/CANDIDATE_PEAK15_BLOCK_MAY_JUN_PROFILE.set`
