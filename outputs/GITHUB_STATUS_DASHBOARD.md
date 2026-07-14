# GitHub Status Dashboard

Last updated: 2026-07-14 UTC.

## Short Answer

There is no newly validated best profile yet.

The current stability-best research profile is still:

`Score7 Regime No-M1-Shock Dec-ISLP-Off + ISLP LowATR OrderFlow`

The newer conservative trade-ready profile and FMLR research lanes are prepared, but they are not proven better yet because the required MT5 reports and live-readiness evidence are still missing.

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
- Passing areas: `4`
- Pending areas: `10`
- Failed areas: `0`
- Money-ready scorecard: `NOT_READY_PENDING_EVIDENCE`
- Release-candidate gate: `NOT_RELEASEABLE_PENDING_EVIDENCE`
- Real-account trading: locked

## GitHub Publication Sync

- Overall: `PENDING`
- Required source/profile artifacts verified on GitHub: `0 / 7`
- Required pending artifacts: `7`
- Required failed artifacts: `0`
- Evidence file: `outputs/GITHUB_PUBLICATION_SYNC.md`

The source/profile publication gate is still blocking live-readiness because the local folder is not a valid git checkout and the connector audit sees the required GitHub artifacts as stale or missing. This is a reproducibility blocker, not a trading-profit result.

The current conservative candidate is not live-ready and should remain paper/demo only.

## Current Conservative Candidate

Profile:

`outputs/CANDIDATE_TRADE_READY_CONSERVATIVE_PROFILE.set`

SHA-256:

`621F54A4BFE61761577D87DB212CF024163F25066209C205090E72227FE584A6`

Risk shape:

- `0.10%` trade risk
- `0.20%` open-risk cap
- `0.01` max lots
- one position
- max `2` trades/day
- `120` minutes between trades
- `0.20%` daily loss cap
- `0.60%` weekly loss cap
- `1.25%` monthly loss cap
- `3.00%` equity drawdown cap
- real-account approval fields disabled

## What Changed Locally

The local workspace now has a stricter offline evidence system:

- one-command refresh status
- first-pass report routing
- live-evidence routing
- compile-evidence routing
- conservative full-validation routing
- trade-quality and Monte Carlo gates
- forward/demo and second-broker evidence gates
- local reproducibility bundle
- evidence handoff package
- four parallel first-pass lanes for faster testing

Current first-pass package:

- `8` configs total
- split into `4` window-based lanes
- each lane contains both candidate configs for one window

## Next Required Evidence

The next useful testing step is to run the `8` first-pass configs from either:

- `outputs/first_pass_next_run_package`
- `outputs/first_pass_parallel_lanes`

Then export reports into:

`outputs/returned_mt5_reports/first_pass_inbox`

Required before any live-money review:

- current-source compile proof
- first-pass MT5 reports
- full conservative validation reports
- broker-proxy reports
- trade/deal logs with realized R
- Monte Carlo trade-stress pass
- forward/demo evidence
- second-broker evidence
- source/profile reproducibility sync

## Why There Is No New Best On GitHub

The newer FMLR and trade-ready work is mostly code, package, safety, and evidence-gate preparation. It has not produced a validated better backtest yet.

The correct answer is:

Keep LowATR OrderFlow as the current research best, keep the conservative profile as the safest current test candidate, and do not promote anything else until broad-window MT5 evidence proves it.
