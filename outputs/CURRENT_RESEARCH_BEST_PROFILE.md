# Current Research Best Profile

- Profile: `outputs/CANDIDATE_PRIMARY_AUG40_REVERSE_OFF_FSD_STRICT_MFE_AUGUST_ONLY_MICRO_R035_RANGE_ELITE_PROFILE.set`
- SHA-256: `AD6C1D1607BD7809FFBBB25DD068A1AB18E4EE2FBC879114F6A02DBCA06D1894`
- Research note: `research/2026-07-12-range-elite-micro-promotion-note.md`

## Evidence

- Model 0 continuous: `6763.86` versus previous research-best `6754.43`
- 2026 YTD: unchanged at `1107.93`
- Full 2025: unchanged at `214.30`
- Full 2024: improved from `2465.45` to `2473.48`
- Validation losing windows: `0` for the promoted profile
- Adaptive Reverse remains explicitly disabled to avoid stop-and-reverse whipsaw risk.
- Flat Month Structural Displacement remains enabled as a tightly gated, low-risk opportunity lane.
- MFE profit-lock stop remains enabled only in August.
- Flat Month Micro Reversion is promoted only for July and October with risk multiplier `0.35`, after a clean rerun confirmed the broad windows and H2/Q3/Q4 validation set.
- Range Elite Micro Reversion is enabled as a strict, low-frequency range-opportunity lane after it added a small clean 2024 edge without harming 2025 or 2026 YTD.

This is the current research-best candidate, not a final production deployment profile. The next validation gate is higher-fidelity tick/spread/slippage stress testing and longer walk-forward confirmation.
