# Current Research Best Profile

- Profile: `outputs/CANDIDATE_PRIMARY_AUG40_REVERSE_OFF_FSD_STRICT_MFE_AUGUST_ONLY_PROFILE.set`
- SHA-256: `DD3C357C4E830B17D744A310B57A83254467B92DB8CD94D90215B5BEA9C7C77E`
- Research note: `research/2026-07-12-mfe-month-filter-promotion-note.md`

## Evidence

- Model 0 continuous: `6633.61` versus previous research-best `6222.35`
- 2026 YTD: unchanged at `1107.93`
- Full 2025: unchanged at `214.30`
- Full 2024: improved from previous research-best `2390.20` to `2406.27`
- Losing windows: `0`
- Adaptive Reverse is explicitly disabled after Model 2 and Model 0 ablation showed `reverse_off` matched the Aug40 baseline exactly on the tested full/recent/year/May/flat windows. This keeps the same measured profit while reducing hidden stop-and-reverse whipsaw exposure.
- Flat Month Structural Displacement (`FSD`) is enabled as a tightly gated, low-risk opportunity lane after Model 2 and Model 0 confirmation improved continuous profit without adding losing tested windows.
- MFE profit-lock stop is enabled only in August after month-filter validation improved the continuous run without reducing 2026 YTD or adding losing tested windows.

This is the current research-best candidate, not a final production deployment profile. The next validation gate is higher-fidelity tick/spread/slippage stress testing.
