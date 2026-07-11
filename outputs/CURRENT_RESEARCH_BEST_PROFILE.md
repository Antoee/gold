# Current Research Best Profile

- Profile: `outputs/CANDIDATE_PRIMARY_AUG40_REVERSE_OFF_MICRO_JULOCT_PROFILE.set`
- SHA-256: `43FD53C09EDA74BA449B5754B502EADA68EADD53AAE74AE89153BB2DA122E96D`
- Research note: `research/2026-07-11-adaptive-reverse-off-promotion-note.md`

## Evidence

- Model 0 continuous: `5814.52` versus previous research-best `5340.46`
- 2026 YTD: unchanged at `1107.93`
- Full 2025: unchanged at `214.30`
- Full 2024: improved from previous research-best `2179.44` to `2371.39`
- August attribution: August 2024 improved from `57.67` to `84.50`; August 2025 improved from `38.14` to `59.32`
- Losing windows: `0`
- Adaptive Reverse is explicitly disabled after Model 2 and Model 0 ablation showed `reverse_off` matched the Aug40 baseline exactly on the tested full/recent/year/May/flat windows. This keeps the same measured profit while reducing hidden stop-and-reverse whipsaw exposure.

This is the current research-best candidate, not a final production deployment profile. The next validation gate is higher-fidelity tick/spread/slippage stress testing.
