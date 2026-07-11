# Current Research Best Profile

- Profile: `outputs/CANDIDATE_PRIMARY_AUG40_REVERSE_OFF_FSD_STRICT_MICRO_JULOCT_PROFILE.set`
- SHA-256: `0E32FC5BC6558B969DF0F08B18EF5DBAEE3D5E65CD7FDC4E7F0E2F91C3FA7A40`
- Research note: `research/2026-07-11-fsd-strict-promotion-note.md`

## Evidence

- Model 0 continuous: `6222.35` versus previous research-best `5814.52`
- 2026 YTD: unchanged at `1107.93`
- Full 2025: unchanged at `214.30`
- Full 2024: improved from previous research-best `2371.39` to `2390.20`
- Losing windows: `0`
- Adaptive Reverse is explicitly disabled after Model 2 and Model 0 ablation showed `reverse_off` matched the Aug40 baseline exactly on the tested full/recent/year/May/flat windows. This keeps the same measured profit while reducing hidden stop-and-reverse whipsaw exposure.
- Flat Month Structural Displacement (`FSD`) is enabled as a tightly gated, low-risk opportunity lane after Model 2 and Model 0 confirmation improved continuous profit without adding losing tested windows.

This is the current research-best candidate, not a final production deployment profile. The next validation gate is higher-fidelity tick/spread/slippage stress testing.
