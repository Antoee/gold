# Current Research Best Profile

- Profile: `outputs/CANDIDATE_PRIMARY_AUG40_REVERSE_OFF_FSD_STRICT_MFE_AUGUST_ONLY_MICRO_R035_PROFILE.set`
- SHA-256: `223530323A920E174957B67DBA56778B78996A8D2C454161A49665DEC8AB9CDF`
- Research note: `research/2026-07-12-micro-juloct-r035-promotion-note.md`

## Evidence

- Model 0 continuous: `6754.43` versus previous research-best `6633.61`
- 2026 YTD: unchanged at `1107.93`
- Full 2025: unchanged at `214.30`
- Full 2024: improved from `2406.27` to `2465.45`
- Validation losing windows: `0` for the promoted profile
- Adaptive Reverse remains explicitly disabled to avoid stop-and-reverse whipsaw risk.
- Flat Month Structural Displacement remains enabled as a tightly gated, low-risk opportunity lane.
- MFE profit-lock stop remains enabled only in August.
- Flat Month Micro Reversion is promoted only for July and October with risk multiplier `0.35`, after a clean rerun confirmed the broad windows and H2/Q3/Q4 validation set.

This is the current research-best candidate, not a final production deployment profile. The next validation gate is higher-fidelity tick/spread/slippage stress testing and longer walk-forward confirmation.
