# Source Manifest

Generated from the local EA source without launching MT5.

## Local EA Source

- File: `Professional_XAUUSD_EA.mq5`
- Mirrored file: `outputs/Professional_XAUUSD_EA.mq5`
- Lines: `19193`
- Size: `902802` bytes
- SHA-256: `0289641ABE4F1B93FB69D81FF098FFBAA28FFA14478282ACD0BCA4B3A1CBAFC3`
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

## Active FMLR Research Surface

- Full FMLR package: `444` Model4 configs, `37` profiles
- Fast FMLR screen: `144` Model4 configs, `24` profiles
- New isolated profile: `fmlr_sweep_unlimited_runner`

## Static Checks

Latest local checks reported:

- `PRICE_ACTION_STRATEGY_MODULES_SMOKE_PASS`
- `EA_SOURCE_ARTIFACT_SYNC_SMOKE_PASS`
- `FLAT_MONTH_LIQUIDITY_RECLAIM_PROBE_PACKAGE_SMOKE_PASS`
- `FLAT_MONTH_LIQUIDITY_RECLAIM_FAST_PROBE_PACKAGE_SMOKE_PASS`
- `FLAT_MONTH_LIQUIDITY_RECLAIM_COMPACT_SOURCE_SMOKE_PASS`
- `ADAPTIVE_REVERSE_QUARANTINE_SMOKE_PASS`
- `MT5_HIDDEN_LAUNCHER_LOCK_SMOKE_PASS`
- MT5 local safety audit: `PASS 39 / 39`

MT5 was not launched during this manifest refresh.

## GitHub Note

The full `.mq5` file is verified locally by the SHA-256 above. The current Codex workspace is not a valid Git checkout, and the connector file API is being used only for lightweight dashboard/evidence files. If an authenticated Git push path is restored, upload both `Professional_XAUUSD_EA.mq5` and `outputs/Professional_XAUUSD_EA.mq5`, then confirm the GitHub download hash matches `0289641ABE4F1B93FB69D81FF098FFBAA28FFA14478282ACD0BCA4B3A1CBAFC3`.
