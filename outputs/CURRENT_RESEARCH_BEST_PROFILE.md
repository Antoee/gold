# Current Research Best Profile

- Profile: `outputs/CANDIDATE_PRIMARY_RANGE_ELITE_MFE_FAILURE_MARCH_ISLP_JUN_OCTDEC_TP150_RISK050_PROFILE.set`
- Builder: `work/build_current_best_mfe_failure_march_islp_jun_octdec_tp150_risk050_profile.ps1`
- SHA-256: `E0411FF8D997E32856A728BCE81588A812239F7FC7FD21A235CC890E2D21B2A5`
- Research note: `research/2026-07-12-islp-tp150-risk050-promotion-note.md`

## Evidence

- Fast-model continuous: `10687.20` versus previous research-best `9512.09`
- 2026 YTD: unchanged at `1375.04`
- Full 2025: unchanged at `214.18`
- Full 2024: `3048.13` versus previous research-best `3349.39`
- Validation losing windows: `0` for the promoted profile
- Adaptive Reverse remains explicitly disabled to avoid stop-and-reverse whipsaw risk.
- Flat Month Structural Displacement remains enabled as a tightly gated, low-risk opportunity lane.
- MFE profit-lock stop remains enabled only in August.
- Flat Month Micro Reversion is promoted only for July and October with risk multiplier `0.35`, after a clean rerun confirmed the broad windows and H2/Q3/Q4 validation set.
- Range Elite Micro Reversion is enabled as a strict, low-frequency range-opportunity lane after it added a small clean 2024 edge without harming 2025 or 2026 YTD.
- MFE Failure Exit is enabled only in March after the all-month version was rejected and the month-gated version improved continuous and 2026 YTD performance with zero losing quarter windows.
- In-Session Liquidity Pullback is enabled only in June, October, November, and December with risk multiplier `0.50`, take-profit `1.50 ATR`, and minimum RR `0.90`; this improves continuous and quarter validation while keeping all broad windows profitable, though the standalone 2024 reset window is lower.

This is the current research-best candidate, not a final production deployment profile. The next validation gate is higher-fidelity tick/spread/slippage stress testing and longer walk-forward confirmation.
