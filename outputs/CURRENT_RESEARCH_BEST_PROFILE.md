# Current Research Best Profile

- Profile: `outputs/CANDIDATE_PRIMARY_RANGE_ELITE_MFE_FAILURE_MARCH_PROFILE.set`
- Builder: `work/build_current_best_mfe_failure_march_profile.ps1`
- SHA-256: `690C546EC57D2DB3BBE666B3A81DF61C871F36D59853EB3DDCCD1D3D17207693`
- Research note: `research/2026-07-12-mfe-failure-march-promotion-note.md`

## Evidence

- Fast-model continuous: `7756.74` versus previous research-best `6763.86`
- 2026 YTD: improved from `1107.90` to `1375.04`
- Full 2025: effectively unchanged at `214.18`
- Full 2024: `2459.19` versus previous research-best `2473.48`
- Validation losing windows: `0` for the promoted profile
- Adaptive Reverse remains explicitly disabled to avoid stop-and-reverse whipsaw risk.
- Flat Month Structural Displacement remains enabled as a tightly gated, low-risk opportunity lane.
- MFE profit-lock stop remains enabled only in August.
- Flat Month Micro Reversion is promoted only for July and October with risk multiplier `0.35`, after a clean rerun confirmed the broad windows and H2/Q3/Q4 validation set.
- Range Elite Micro Reversion is enabled as a strict, low-frequency range-opportunity lane after it added a small clean 2024 edge without harming 2025 or 2026 YTD.
- MFE Failure Exit is enabled only in March after the all-month version was rejected and the month-gated version improved continuous and 2026 YTD performance with zero losing quarter windows.

This is the current research-best candidate, not a final production deployment profile. The next validation gate is higher-fidelity tick/spread/slippage stress testing and longer walk-forward confirmation.
