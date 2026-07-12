# Current Research Best Profile

- Profile: `outputs/CANDIDATE_PRIMARY_RANGE_ELITE_MFE_FAILURE_MARCH_ISLP_OCTDEC_PROFILE.set`
- Builder: `work/build_current_best_mfe_failure_march_islp_octdec_profile.ps1`
- SHA-256: `6C34F17F3AF0741A4C9FAFAD86485576E618EB1EC41F6210198B906A2A6BD2B1`
- Research note: `research/2026-07-12-islp-octdec-promotion-note.md`

## Evidence

- Fast-model continuous: `9065.41` versus previous research-best `7756.74`
- 2026 YTD: unchanged at `1375.04`
- Full 2025: unchanged at `214.18`
- Full 2024: `3095.13` versus previous research-best `2459.19`
- Validation losing windows: `0` for the promoted profile
- Adaptive Reverse remains explicitly disabled to avoid stop-and-reverse whipsaw risk.
- Flat Month Structural Displacement remains enabled as a tightly gated, low-risk opportunity lane.
- MFE profit-lock stop remains enabled only in August.
- Flat Month Micro Reversion is promoted only for July and October with risk multiplier `0.35`, after a clean rerun confirmed the broad windows and H2/Q3/Q4 validation set.
- Range Elite Micro Reversion is enabled as a strict, low-frequency range-opportunity lane after it added a small clean 2024 edge without harming 2025 or 2026 YTD.
- MFE Failure Exit is enabled only in March after the all-month version was rejected and the month-gated version improved continuous and 2026 YTD performance with zero losing quarter windows.
- In-Session Liquidity Pullback is enabled only in October, November, and December after broad and quarter validation improved 2024/Q4 opportunity capture without reducing 2025 or 2026 YTD results.

This is the current research-best candidate, not a final production deployment profile. The next validation gate is higher-fidelity tick/spread/slippage stress testing and longer walk-forward confirmation.
