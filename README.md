# Professional XAUUSD EA

Professional-grade MetaTrader 5 Expert Advisor research project for XAUUSD / Gold.

No martingale. No grid. No averaging down. No recovery sizing. Risk control stays above profit chasing. Heavy optimization and validation should run locally, hidden in the background, not in GitHub Actions.

## Latest Status

Last updated: 2026-07-14 UTC.

Short answer: there is no newly validated best profile yet.

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

The correct current reading is: the bot is better than the old `$866` baseline, but there is not a newly promoted better profile beyond LowATR OrderFlow.

## Money-Ready Status

- Overall money-ready refresh: `PENDING`
- Passing areas: `4`
- Pending areas: `10`
- Failed areas: `0`
- Money-ready scorecard: `NOT_READY_PENDING_EVIDENCE`
- Live-readiness gate: `PENDING`, `5` pass / `8` pending / `0` fail
- Release-candidate gate: `NOT_RELEASEABLE_PENDING_EVIDENCE`
- GitHub publication sync: `PENDING`, `5 / 7` required source/profile artifacts verified
- Real-account trading: locked

The current conservative candidate is not live-ready and should remain paper/demo only.

## Conservative Trade-Ready Candidate

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

This is the safest current test candidate, not a live-money profile.

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
- GitHub publication sync audit
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
- exact source/profile publication sync

## GitHub Publication Sync

`outputs/GITHUB_PUBLICATION_SYNC.md` is the dedicated source/profile publication audit. Current result is `PENDING`: `5` required artifacts pass, `2` are pending, and `0` failed.

Verified exact GitHub connector blob matches:

- conservative trade-ready profile
- money-ready profile
- trade-readiness alias profile
- source manifest
- current research-best profile doc

Still pending:

- root EA source: `Professional_XAUUSD_EA.mq5`
- mirrored output EA source: `outputs/Professional_XAUUSD_EA.mq5`

This does not mean the bot is worse. It means the repo still lacks independently verified publication for the exact current EA source files. Until that is fixed, the final live-readiness gate must stay pending.

## Why There Is No New Best Yet

The newer FMLR and trade-ready work is mostly code, package, safety, and evidence-gate preparation. It has not produced a validated better backtest yet.

Keep LowATR OrderFlow as the current research best, keep the conservative profile as the safest current test candidate, and do not promote anything else until broad-window MT5 evidence proves it.

## Status Files To Check

1. `outputs/GITHUB_STATUS_DASHBOARD.md` - compact GitHub-facing dashboard.
2. `outputs/MONEY_READY_REFRESH_STATUS.md` - one-command offline refresh result.
3. `outputs/GITHUB_PUBLICATION_SYNC.md` - source/profile publication hash audit.
4. `outputs/CURRENT_RESEARCH_BEST_PROFILE.md` - current promoted research profile.
5. `outputs/FIRST_PASS_PARALLEL_LANES.md` - faster first-pass lane split.
6. `outputs/SOURCE_MANIFEST.md` - current local source hash/status.

## GitHub Sync Note

This page is updated through the GitHub connector because the local Codex folder is not a valid Git checkout and local Git authentication is not usable non-interactively. Dashboard/status files can be refreshed through the connector, but the final live-readiness `reproducible-github-sync` gate remains pending until the exact EA source artifacts are published and hash-verified through a reproducible path.
