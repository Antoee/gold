# GitHub Status Dashboard

Last updated: 2026-07-14 UTC.

## Short Answer

There is no newly validated best profile yet.

The current stability-best research profile is still:

`Score7 Regime No-M1-Shock Dec-ISLP-Off + ISLP LowATR OrderFlow`

The current meaningful progress is source quality and evidence workflow, not a new profit record: the EA source compiles cleanly again after shortening six overlong FMLR input identifiers, and compile evidence routing is now idempotent across refreshes.

## Current Best Evidence

Return math assumes a `$1,000` starting balance over `2024.01.01` to `2026.07.12`, about `2.53` years.

| Result | Type | Return Math | Status |
| --- | --- | --- | --- |
| `+$10,127.76` | Continuous Model1 | `+1012.78%` total, about `+159.47%/yr` CAGR | Best historical/current Model1 research result |
| `+$4,507.51` | Continuous Model4 | `+450.75%` total, about `+96.43%/yr` CAGR | Historical/stale until reproduced on current source |
| `+$1,195.69` | Continuous Model4 | `+119.57%` total, about `+36.51%/yr` CAGR | Fresh current-source real-tick LowATR OrderFlow result |
| `+$7,469.00` | Sampled Model4 total | Not annualizable | Aggregate validation-window score, not a sequential account curve |

## Money-Ready Status

- Overall money-ready refresh: `PENDING`
- Passing areas: `5`
- Pending areas: `9`
- Failed areas: `0`
- Live-readiness gate: `PENDING`, `6` pass / `7` pending / `0` fail
- Money-ready scorecard: `NOT_READY_PENDING_EVIDENCE`, `6` pass / `13` pending / `0` fail
- Current-source compile: `PASS`, `0` errors / `0` warnings
- Reproducibility bundle: `PASS`, `49` pass / `0` pending / `0` fail
- Release-candidate gate: `NOT_RELEASEABLE_PENDING_EVIDENCE`
- Real-account trading: locked

## Current Conservative Candidate

- Profile: `outputs/CANDIDATE_TRADE_READY_CONSERVATIVE_PROFILE.set`
- Profile SHA-256: `0A97B46D7E3A3C3566EF4E787BCB63E2138D114C2F0F898F9A8B1A10F842BF90`
- Source SHA-256: `46770EACA60826F90E1E9A9B7425356F96F7C8F83CF8F8C1FBE271632866933E`
- Risk: `0.10%` per trade, `0.20%` open-risk cap, `0.01` max lots, one position, max `2` trades/day
- Real-account approval fields: disabled

## GitHub Publication Sync

- Overall: `PENDING`
- Current local audit after source-hash refresh: `1 / 7` required source/profile artifacts verified on GitHub
- Known remaining blockers: refreshed profiles/source manifest need republishing, and the two large EA source paths remain stale/missing on GitHub
- This is a reproducibility blocker, not a trading-profit result

## Next Required Evidence

Run/import the `8` first-pass MT5 reports, then only advance to full validation if those reports include complete exported MT5 stats and pass risk-adjusted gates.

Required before any live-money review:

- first-pass MT5 reports
- full conservative validation reports
- broker-proxy reports
- trade/deal logs with realized R
- Monte Carlo trade-stress pass
- forward/demo evidence
- second-broker evidence
- source/profile reproducibility sync

The bot remains research/demo only.