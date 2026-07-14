# Source Manifest

Generated from the local EA source without launching MT5.

Last updated on GitHub: 2026-07-14 UTC.

## Local EA Source

- File: `Professional_XAUUSD_EA.mq5`
- Mirrored file: `outputs/Professional_XAUUSD_EA.mq5`
- Lines: `19508`
- Size: `919502` bytes
- SHA-256: `44D9EBA868C86EB6C57DF82C3B94D83ACFE994B1A665917EC05AB8313188A5F7`
- Last verified locally: `2026-07-13`

The local source, output mirror, money-ready package sources, and conservative package sources matched this hash when the local manifest was generated.

## Current Source Highlights

- Modular XAUUSD EA with no martingale, grid, averaging down, or recovery sizing.
- Current stability-best profile remains `Score7 Regime No-M1-Shock Dec-ISLP-Off + ISLP LowATR OrderFlow`.
- Adaptive Reverse remains quarantined behind default-off gates and smoke-test coverage.
- MT5 local launch lock remains active to avoid windows, sounds, and focus stealing.
- Trade-log evidence identity is present through `InpEvidenceProfileId`, `InpEvidenceSourceHash`, and `InpEvidenceRunLabel`.
- Real-account safety-lock instrumentation requires explicit approval identity before any real-account profile can be considered.
- Conservative trade-ready profile is present locally with hash `621F54A4BFE61761577D87DB212CF024163F25066209C205090E72227FE584A6`.
- Money-ready scorecard is `NOT_READY_PENDING_EVIDENCE` with `5` PASS, `14` PENDING, and `0` FAIL.
- Live-readiness decision is `PENDING` with `5` passing gates, `8` pending gates, and `0` failed gates.
- Evidence handoff package is ready with `8` first-pass configs, `4` first-pass parallel lanes, `53` validation configs, and `10` broker-proxy configs.

## Important GitHub Sync Caveat

The local Codex folder is not a valid git checkout and local `git`/`gh` are not installed. This file was updated through the GitHub connector as a status artifact.

That means the dashboard/source-manifest status is refreshed, but the final live-readiness `reproducible-github-sync` gate remains pending until the exact EA source/profile artifacts are fully published and hash-verified through a reproducible path.

## Current Recommendation

Do not treat the source as live-ready. Keep testing the conservative candidate through first-pass reports, full validation, trade-quality logs, Monte Carlo, forward/demo, and second-broker evidence before any live-money decision.
