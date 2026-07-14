# Professional XAUUSD EA

Professional-grade MetaTrader 5 Expert Advisor research project for XAUUSD / Gold.

No martingale. No grid. No averaging down. No recovery sizing. Risk control stays above profit chasing. Heavy optimization and validation should run locally, hidden in the background, not in GitHub Actions.

## Latest Status

Last updated: 2026-07-14 UTC after connector-syncing the three required profile artifacts, adding minimum annualized-return/CAGR validation gates, current-source money-ready audit refresh, and local reproducibility-bundle rebuild.

Short answer: there is no newly validated best profile yet.

The current stability-best research profile is still:

`Score7 Regime No-M1-Shock Dec-ISLP-Off + ISLP LowATR OrderFlow`

The conservative trade-ready candidate is the safest current test candidate, but it is still paper/demo only. The latest progress is reproducibility: the conservative profile, money-ready profile, and trade-readiness alias profile now match GitHub connector blobs. The two remaining publication blockers are the large root EA source and mirrored output EA source.

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
- Reproducibility bundle: `PASS`, `60` pass / `0` pending / `0` fail
- GitHub publication sync: `PENDING`, `5` required artifacts pass / `2` pending / `0` fail
- Real-account trading: locked

The current conservative candidate is not live-ready and should remain paper/demo only.

## Latest Offline Progress

- Three required profile artifacts are now connector-verified on GitHub: conservative, money-ready, and trade-readiness alias.
- Remaining required GitHub publication blockers: `Professional_XAUUSD_EA.mq5` and `outputs/Professional_XAUUSD_EA.mq5`.
- Exported-report summaries calculate total return %, annualized return %, and CAGR %.
- First-pass validation requires the continuous exact real-tick report to clear `>= 1%` annualized return and `>= 1%` CAGR.
- Full money-ready/conservative validation applies the same continuous annualized-return and CAGR floors.
- Reproducibility bundle hash: `CE4258019616FDB829ADC0335C54BF9548BCC93C3198A938F4106A5DFCA5DDAC`.
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

1. Run/import the current `4` first-pass MT5 reports from `outputs/first_pass_next_run_package` or `outputs/first_pass_parallel_lanes`.
2. If first-pass evidence is trusted, import the `53` conservative validation reports plus `10` broker-proxy reports.
3. Import conservative trade/deal logs with realized R for trade-quality and Monte Carlo gates.
4. Add forward/demo evidence and second-broker evidence.
5. Publish the exact refreshed EA source files to GitHub. The large source files remain the hardest publication blocker because this workspace is not a valid git checkout and noninteractive git auth is unavailable.

## Key Status Files

- `outputs/GITHUB_STATUS_DASHBOARD.md`
- `outputs/GITHUB_PUBLICATION_SYNC.md`
- `outputs/MONEY_READY_REFRESH_STATUS.md`
- `outputs/FIRST_PASS_VALIDATION_QUEUE_DECISION.md`
- `outputs/TRADE_READY_REPRODUCIBILITY_BUNDLE.md`

Until those gates pass, this is a serious research project, not a live-money bot.
