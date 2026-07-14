# GitHub Status Dashboard

Last updated: 2026-07-14 UTC after annualized-return/CAGR report metrics, strict returned-report routing, current-source money-ready audit refresh, local reproducibility-bundle rebuild, required-artifact sync-package generation, source-artifact upload-plan generation, first-pass hidden-runner plan generation, and hard-lock runner smoke testing.

## Short Answer

There is no newly validated best profile yet.

The current stability-best research profile is still:

`Score7 Regime No-M1-Shock Dec-ISLP-Off + ISLP LowATR OrderFlow`

The newer conservative trade-ready profile and FMLR research lanes are prepared, but they are not proven better yet because the required MT5 reports and live-readiness evidence are still missing. The latest local change is a safety/readiness improvement, not a new profit result.

## Current Best Evidence

Return math assumes a `$1,000` starting balance over `2024.01.01` to `2026.07.12`, about `2.53` years.

| Result | Type | Return Math | Status |
| --- | --- | --- | --- |
| `+$10,127.76` | Continuous Model1 | `+1012.78%` total, about `+159.47%/yr` CAGR | Best historical/current Model1 research result |
| `+$4,507.51` | Continuous Model4 | `+450.75%` total, about `+96.43%/yr` CAGR | Historical/stale until reproduced on current source |
| `+$1,195.69` | Continuous Model4 | `+119.57%` total, about `+36.51%/yr` CAGR | Most recent reproduced real-tick LowATR OrderFlow result before the `5D148DAE...` source update |
| `+$7,469.00` | Sampled Model4 total | Not annualizable | Aggregate validation-window score, not a sequential account curve |

## Money-Ready Status

- Overall money-ready refresh: `PENDING`
- Passing areas: `5`
- Pending areas: `10`
- Failed areas: `0`
- Money-ready scorecard: `NOT_READY_PENDING_EVIDENCE`
- Money-ready scorecard rows: `5` PASS / `14` PENDING / `0` FAIL
- Release-candidate gate: `NOT_RELEASEABLE_PENDING_EVIDENCE`
- Real-account trading: locked

## GitHub Publication Sync

- Overall: `PENDING`
- Required source/profile artifacts verified on GitHub: `5 / 7`; the source manifest, current-best note, conservative profile, money-ready profile, and trade-readiness alias profile now match connector-published GitHub blobs
- Required pending artifacts: `2`
- Required failed artifacts: `0`
- Evidence file: `outputs/GITHUB_PUBLICATION_SYNC.md`
- Exact local upload package: `outputs/GITHUB_REQUIRED_ARTIFACT_SYNC_PACKAGE.md`
- Source upload plan/helper: `outputs/GITHUB_SOURCE_ARTIFACT_UPLOAD_PLAN.md`

The source/profile publication gate is still blocking live-readiness because the local folder is not a valid git checkout and the two large EA source paths are not yet exact connector-verified matches. The profile artifacts are now connector-verified. The source upload plan is `READY`: the stale root EA source would be updated and the missing mirrored output EA source would be created when a noninteractive token is available. This is a reproducibility blocker, not a trading-profit result.

The current conservative candidate is not live-ready and should remain paper/demo only.

## Latest Background Check

- Local MT5 safety audit: `PASS`, `43 / 43`
- Static repo safety audit: `PASS`, `25` checks
- Static MQL compile preflight: `PASS`, `29` checks / `1802` inputs
- Report collector annualized return/CAGR smoke: `PASS`
- Minimum continuous annualized-return/CAGR gate smoke: `PASS`
- GitHub profile artifact sync: `PASS`, `3 / 3` profile artifacts connector-verified
- Static Safety workflow missing-script fix: `work/static_repo_safety_audit.py` and `work/static_mql_compile_preflight.py` now exist locally, pass locally, and have been published to GitHub
- GitHub publication sync smoke: `PASS`
- Required artifact sync package smoke: `PASS`, `5` required artifacts, `0` unsafe profile rows
- Source artifact upload plan smoke: `PASS`, root source `WOULD_UPDATE`, mirrored output source `WOULD_CREATE`
- First-pass hidden runner plan smoke: `PASS`, current state `LOCKED`, `4` configs, `0` MT5 processes launched
- First-pass hidden runner hard-lock smoke: `PASS`, accidental `-Run` exits before writing run outputs or launching MT5
- Trade-ready live-readiness smoke: `PASS`
- FMLR package smoke: `PASS`
- Money-ready refresh smoke: `PASS`
- Visible MT5/MetaEditor/Metatester/Git process check: clear
- Current EA source hash: `5D148DAE2335F9037BDED3C9A82BD916C1FCFB6F43EE2EC5EAAE7E67384ED412`
- First-pass active package: `4` fast Model1 configs for `trade_ready_conservative`, split into `4` window lanes
- First-pass active profile hash: current conservative `825308011021`
- First-pass comparison profile hash: current money-ready `553A967B5FCE` is available only when explicitly re-enabled
- Stale first-pass hashes `621F54A4...` and `0CF80057...`: removed from active run packages

## Current Conservative Candidate

Profile:

`outputs/CANDIDATE_TRADE_READY_CONSERVATIVE_PROFILE.set`

SHA-256:

`82530801102198E81E08E1EF772D5501B52FB88CCFD67E6651CE32EF1D055665`

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
- trade-environment guard enabled: stale quote, insufficient bars, invalid symbol spec, disabled/close-only trade mode, excessive stop/freeze levels, or missing tick value blocks new entries

## What Changed Locally

The local workspace now has a stricter offline evidence system:

- current-source trade-environment guard and safety-gate checks
- one-command refresh status
- first-pass report routing
- strict returned-report validation that rejects screenshots, balance-only snippets, and log-only rows
- annualized return and CAGR fields in exported-report CSV/Markdown summaries
- first-pass and full-validation decisions now require minimum continuous annualized return and CAGR
- live-evidence routing
- compile-evidence routing
- conservative full-validation routing
- trade-quality and Monte Carlo gates
- forward/demo and second-broker evidence gates
- local reproducibility bundle
- exact required-artifact sync package for source/profile publication
- exact source-artifact upload plan/helper for the two remaining large EA source files
- plan-only first-pass hidden runner guarded by the MT5 hard lock
- hard-lock smoke test proving the first-pass hidden runner fails closed if `-Run` is requested while locked
- evidence handoff package
- four parallel first-pass lanes for faster testing

Current first-pass package:

- `4` configs total
- split into `4` window-based lanes
- each lane contains the selected `trade_ready_conservative` config for one window

## Next Required Evidence

The next useful testing step is to run the `4` first-pass configs from either:

- `outputs/first_pass_next_run_package`
- `outputs/first_pass_parallel_lanes`
- `work/run_first_pass_package_hidden.ps1` in plan mode first; `-Run` is guarded by the MT5 hard-lock/unlock policy and covered by `work/test_first_pass_hidden_runner_lock.ps1`

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
- exact EA source publication from `outputs/GITHUB_SOURCE_ARTIFACT_UPLOAD_PLAN.md`

Current local reproducibility bundle:

- Status: `PASS`
- Passing rows: `69`
- Zip SHA-256: `1333B8102CEAB7E814F581F0362CB71BCFAC217139EB4146B5F91D4EC5C126AD`
- Reminder: this is a local hash freeze only; it does not clear the GitHub/source-publication sync gate.

## Why There Is No New Best On GitHub

The newer FMLR and trade-ready work is mostly code, package, safety, and evidence-gate preparation. It has not produced a validated better backtest yet.

The correct answer is:

Keep LowATR OrderFlow as the current research best, keep the conservative profile as the safest current test candidate, and do not promote anything else until broad-window MT5 evidence proves it.
