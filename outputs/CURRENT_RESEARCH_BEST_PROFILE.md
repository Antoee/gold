# Current Research Best Profile

- Profile: `outputs/CANDIDATE_PRIMARY_RANGE_ELITE_MFE_FAILURE_MARCH_ISLP_JUN_OCTDEC_SCORE7_PROFILE.set`
- Builder: `work/build_current_best_mfe_failure_march_islp_jun_octdec_score7_profile.ps1`
- SHA-256: `E36378232B722A2A09C1EFD2494F04385B7020CAE1F1679DDE903E05D8BC12D0`
- Research note: `research/2026-07-12-islp-score7-promotion-note.md`

## Evidence

- Fast-model continuous from the previous gate: `9512.09` over `2024.01.01` to `2026.07.12`
- Higher-fidelity `Model=1` continuous: `7970.70` versus previous robust best `7210.30` over `2024.01.01` to `2026.07.12`
- `Model=1` full 2024: unchanged at `2507.85`
- `Model=1` full 2025: unchanged at `214.18`
- `Model=1` 2026 YTD: unchanged at `1375.04`
- `Model=1` quarter gate: `3638.18` versus previous robust best `3585.86`; same worst quarter `-0.50`; same losing quarter count `1`
- Validation files: `outputs/MODEL1_ISLP_VARIANT_SWEEP_LOG_RESULTS.csv` and `outputs/MODEL1_SCORE7_QTR_LOG_RESULTS.csv`
- The higher-profit `risk045_tp150` variant reached `8112.91` on continuous `Model=1`, but reduced full 2024 from `2507.85` to `2209.66`, so it was rejected.
- Adaptive Reverse remains explicitly disabled to avoid stop-and-reverse whipsaw risk.
- Flat Month Structural Displacement remains enabled as a tightly gated, low-risk opportunity lane.
- MFE profit-lock stop remains enabled only in August.
- Flat Month Micro Reversion is promoted only for July and October with risk multiplier `0.35`, after a clean rerun confirmed the broad windows and H2/Q3/Q4 validation set.
- Range Elite Micro Reversion is enabled as a strict, low-frequency range-opportunity lane after it added a small clean 2024 edge without harming 2025 or 2026 YTD.
- MFE Failure Exit is enabled only in March after the all-month version was rejected and the month-gated version improved continuous and 2026 YTD performance with zero losing quarter windows.
- In-Session Liquidity Pullback is enabled only in June, October, November, and December after broad validation improved the continuous equity path without reducing 2025, 2026 YTD, or quarter-window results.
- In-Session Liquidity Pullback minimum score is raised from `6` to `7` after `Model=1` validation improved continuous profit without worsening any broad or quarter validation window.
- TP150/Risk050 was rejected after a higher-fidelity `Model=1` check reduced continuous validation from `7210.30` on the previous profile to `1974.32`.

This is the current research-best candidate, not a final production deployment profile. The next validation gate is higher-fidelity tick/spread/slippage stress testing and longer walk-forward confirmation.
