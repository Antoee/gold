# Current Research Best Profile

- Profile: `outputs/CANDIDATE_PRIMARY_RANGE_ELITE_MFE_FAILURE_MARCH_ISLP_JUN_OCTDEC_PROFILE.set`
- Builder: `work/build_current_best_mfe_failure_march_islp_jun_octdec_profile.ps1`
- SHA-256: `7DA01C9F084D81CE6852FE3AAD56E4AF6CA03A8B69A86569ADC4855374876E3F`
- Research note: `research/2026-07-12-islp-jun-octdec-promotion-note.md`

## Evidence

- Fast-model continuous: `9512.09` versus previous research-best `9065.41`
- 2026 YTD: unchanged at `1375.04`
- Full 2025: unchanged at `214.18`
- Full 2024: `3349.39` versus previous research-best `3095.13`
- Validation losing windows: `0` for the promoted profile
- Adaptive Reverse remains explicitly disabled to avoid stop-and-reverse whipsaw risk.
- Flat Month Structural Displacement remains enabled as a tightly gated, low-risk opportunity lane.
- MFE profit-lock stop remains enabled only in August.
- Flat Month Micro Reversion is promoted only for July and October with risk multiplier `0.35`, after a clean rerun confirmed the broad windows and H2/Q3/Q4 validation set.
- Range Elite Micro Reversion is enabled as a strict, low-frequency range-opportunity lane after it added a small clean 2024 edge without harming 2025 or 2026 YTD.
- MFE Failure Exit is enabled only in March after the all-month version was rejected and the month-gated version improved continuous and 2026 YTD performance with zero losing quarter windows.
- In-Session Liquidity Pullback is enabled only in June, October, November, and December after broad validation improved the continuous equity path without reducing 2025, 2026 YTD, or quarter-window results.
- TP150/Risk050 was rejected after a higher-fidelity `Model=1` check reduced continuous validation from `7210.30` on the previous profile to `1974.32`.

This is the current research-best candidate, not a final production deployment profile. The next validation gate is higher-fidelity tick/spread/slippage stress testing and longer walk-forward confirmation.
