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
- Default-off FMLR sweep-unlimited runner permission is present.
- Default-off FMLR tick-speed reclaim path is present:
  - `tickSpeedReclaim`
  - `FMLR tick-speed reclaim`
- Conservative demo/forward-test profile is present locally:
  - `outputs/CANDIDATE_TRADE_READINESS_PROFILE.set`
  - SHA-256 `B683100CA5BE912A9A848C3F715A67E4705473B00DEEF4B9070AE02BFDB708C5`

## Active FMLR Research Surface

- Full FMLR package: `456` Model4 configs, `38` profiles
- Fast FMLR screen: `150` Model4 configs, `25` profiles
- New isolated profile: `fmlr_tick_speed_reclaim`

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
