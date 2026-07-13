# Source Manifest

Generated from the local EA source without launching MT5.

## Local EA Source

- File: `Professional_XAUUSD_EA.mq5`
- Mirrored file: `outputs/Professional_XAUUSD_EA.mq5`
- Lines: `19213`
- Size: `904009` bytes
- SHA-256: `B6AA1915D2CA7483B1066C227F2506D7A85756D918820FF1100BAF66B0FBDBBE`
- Last verified locally: `2026-07-13`

Both local source copies currently match this hash.

## Current Source Highlights

- Modular research EA for XAUUSD with no martingale, grid, averaging down, or recovery sizing.
- Current stability-best profile remains `Score7 Regime No-M1-Shock Dec-ISLP-Off + ISLP LowATR OrderFlow`.
- Adaptive Reverse remains quarantined behind default-off gates and smoke-test coverage.
- MT5 local launch lock remains active to avoid windows, sounds, and focus stealing.
- New default-off FMLR sweep-unlimited runner permission is present:
  - `FlatMonthLiquidityReclaimUnlimitedRunnerAllows`
  - `liquiditySweepRunner`
  - `FMLR sweep unlimited runner`
- New default-off FMLR tick-speed reclaim path is present:
  - `tickSpeedReclaim`
  - `FMLR tick-speed reclaim`
- Low-risk FMLR activity-blend package profiles are present:
  - `fmlr_activity_blend`
  - `fmlr_activity_blend_tight`
  - `outputs/CANDIDATE_FMLR_ACTIVITY_BLEND_PROFILE.set`
  - SHA-256 `149481621EC3194A08CF2B291033FEA38AE7D40B1EDA677820780A51F9A9DBDB`
  - `outputs/CANDIDATE_FMLR_ACTIVITY_BLEND_TIGHT_PROFILE.set`
  - SHA-256 `50F2000B153458B5DB494DD6AA873BDD6256F2C8B3AE11BABE5E4C615E2BC67A`
- Conservative demo/forward-test profile is present:
  - `outputs/CANDIDATE_TRADE_READINESS_PROFILE.set`
  - SHA-256 `B683100CA5BE912A9A848C3F715A67E4705473B00DEEF4B9070AE02BFDB708C5`

## Active FMLR Research Surface

- Full FMLR package: `480` Model4 configs, `40` profiles
- Fast FMLR screen: `162` Model4 configs, `27` profiles
- New isolated profiles:
  - `fmlr_sweep_unlimited_runner`
  - `fmlr_tick_speed_reclaim`
  - `fmlr_activity_blend`
  - `fmlr_activity_blend_tight`

## Static Checks

Latest local checks reported:

- `PRICE_ACTION_STRATEGY_MODULES_SMOKE_PASS`
- `EA_SOURCE_ARTIFACT_SYNC_SMOKE_PASS`
- `FLAT_MONTH_LIQUIDITY_RECLAIM_PROBE_PACKAGE_SMOKE_PASS`
- `FLAT_MONTH_LIQUIDITY_RECLAIM_FAST_PROBE_PACKAGE_SMOKE_PASS`
- `FLAT_MONTH_LIQUIDITY_RECLAIM_COMPACT_SOURCE_SMOKE_PASS`
- `TRADE_READINESS_PROFILE_SMOKE_PASS`
- `ADAPTIVE_REVERSE_QUARANTINE_SMOKE_PASS`
- `MT5_HIDDEN_LAUNCHER_LOCK_SMOKE_PASS`
- MT5 local safety audit: `PASS 39 / 39`

MT5 was not launched during this manifest refresh.

## GitHub Note

The full `.mq5` file is verified locally by the SHA-256 above. The current Codex workspace is not a valid Git checkout, and the connector file API is being used only for lightweight dashboard/evidence files. If an authenticated Git push path is restored, upload both `Professional_XAUUSD_EA.mq5` and `outputs/Professional_XAUUSD_EA.mq5`, then confirm the GitHub download hash matches `B6AA1915D2CA7483B1066C227F2506D7A85756D918820FF1100BAF66B0FBDBBE`.
