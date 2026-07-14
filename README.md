# Professional XAUUSD EA

Professional-grade MetaTrader 5 Expert Advisor research project for XAUUSD / Gold.

No martingale. No grid. No averaging down. No recovery sizing. Risk control stays above profit chasing. Heavy optimization and validation should run locally, hidden in the background, not in GitHub Actions.

## Latest Status

Last updated: 2026-07-14 UTC after first-pass hidden-runner plan generation, hard-lock runner smoke testing, source-artifact upload-plan generation, current-source money-ready audit refresh, and local reproducibility-bundle rebuild.

Short answer: there is no newly validated best profile yet.

The current stability-best research profile is still:

`Score7 Regime No-M1-Shock Dec-ISLP-Off + ISLP LowATR OrderFlow`

The conservative trade-ready candidate is the safest current test candidate, but it is still paper/demo only. The latest progress is execution discipline: `work/run_first_pass_package_hidden.ps1` writes a no-launch first-pass plan, and `work/test_first_pass_hidden_runner_lock.ps1` proves accidental `-Run` requests fail closed while the MT5 hard lock is present.

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
- First-pass decision: `PENDING`, `5` pass / `21` pending / `0` fail
- Money-ready scorecard: `NOT_READY_PENDING_EVIDENCE`, `5` pass / `14` pending / `0` fail
- Live-readiness gate: `PENDING`, `5` pass / `8` pending / `0` fail
- Release-candidate gate: `NOT_RELEASEABLE_PENDING_EVIDENCE`
- First-pass hidden runner: `LOCKED`, `4` configs, `0` reports found, `0` MT5 processes launched
- First-pass hidden runner hard-lock smoke: `PASS`; accidental `-Run` exits before writing run outputs or launching MT5
- Reproducibility bundle: `PASS`, `69` pass / `0` pending / `0` fail
- Reproducibility bundle SHA-256: `1333B8102CEAB7E814F581F0362CB71BCFAC217139EB4146B5F91D4EC5C126AD`
- GitHub publication sync: `PENDING`, `5` required artifacts pass / `2` pending / `0` fail
- GitHub source upload plan: `READY`; root EA source `WOULD_UPDATE`, mirrored output EA source `WOULD_CREATE`
- Real-account trading: locked

The current conservative candidate is not live-ready and should remain paper/demo only.

## Latest Offline Progress

- First-pass hidden runner added: `work/run_first_pass_package_hidden.ps1`.
- First-pass hidden runner lock test added: `work/test_first_pass_hidden_runner_lock.ps1`.
- First-pass hidden plan added: `outputs/FIRST_PASS_HIDDEN_RUN_PLAN.md` and `.csv`.
- Source upload helper added: `work/upload_github_required_source_artifacts.ps1`.
- Source upload plan added: `outputs/GITHUB_SOURCE_ARTIFACT_UPLOAD_PLAN.md` and `.csv`.
- Three required profile artifacts are connector-verified on GitHub: conservative, money-ready, and trade-readiness alias.
- Remaining required GitHub publication blockers: `Professional_XAUUSD_EA.mq5` and `outputs/Professional_XAUUSD_EA.mq5`.
- Reproducibility bundle now includes `69` passing rows and the first-pass hidden runner plus hard-lock smoke test.
- MT5, MetaEditor, and Metatester were not launched.

## Current Conservative Candidate

Profile:

`outputs/CANDIDATE_TRADE_READY_CONSERVATIVE_PROFILE.set`

SHA-256:

`82530801102198E81E08E1EF772D5501B52FB88CCFD67E6651CE32EF1D055665`

Source SHA-256:

`5D148DAE2335F9037BDED3C9A82BD916C1FCFB6F43EE2EC5EAAE7E67384ED412`

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
- trade-environment guard enabled
- real-account approval fields disabled

## Next Evidence Needed

1. Publish the exact refreshed EA source files to GitHub using `outputs/GITHUB_SOURCE_ARTIFACT_UPLOAD_PLAN.md` when a noninteractive token is available.
2. Run/import the current `4` first-pass MT5 reports from `outputs/first_pass_next_run_package`, `outputs/first_pass_parallel_lanes`, or `work/run_first_pass_package_hidden.ps1 -Run` after local MT5 execution is explicitly re-enabled.
3. If first-pass evidence is trusted, import the `53` conservative validation reports plus `10` broker-proxy reports.
4. Import conservative trade/deal logs with realized R for trade-quality and Monte Carlo gates.
5. Add forward/demo evidence and second-broker evidence.

## Key Status Files

- `outputs/GITHUB_STATUS_DASHBOARD.md`
- `outputs/FIRST_PASS_HIDDEN_RUN_PLAN.md`
- `outputs/GITHUB_SOURCE_ARTIFACT_UPLOAD_PLAN.md`
- `outputs/GITHUB_PUBLICATION_SYNC.md`
- `outputs/MONEY_READY_REFRESH_STATUS.md`
- `outputs/MONEY_READY_PROOF_RUNWAY.md`
- `outputs/TRADE_READY_REPRODUCIBILITY_BUNDLE.md`

Until those gates pass, this is a serious research project, not a live-money bot.
