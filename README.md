# Professional XAUUSD EA

Professional-grade MetaTrader 5 Expert Advisor research project for XAUUSD / Gold.

No martingale. No grid. No averaging down. No recovery sizing. Risk control stays above profit chasing. Heavy optimization and validation should run locally, hidden in the background, not in GitHub Actions.

## Latest Status

Last updated: 2026-07-14 UTC.

Short answer: there is no newly validated best profile yet.

The current stability-best research profile is still:

`Score7 Regime No-M1-Shock Dec-ISLP-Off + ISLP LowATR OrderFlow`

The conservative trade-ready candidate is safer and better documented than the older baseline, but it is still paper/demo only. Today’s meaningful progress was a source-quality fix: the current EA source now compiles cleanly again after shortening six overlong FMLR input identifiers.

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
- Current-source compile gate: `PASS`, `0` errors / `0` warnings, source hash current
- Compile-evidence routing: `PASS`, already-routed canonical compile evidence is now idempotent across refreshes
- Reproducibility bundle: `PASS`, `49` pass / `0` pending / `0` fail
- GitHub publication sync: `PENDING`; local refreshed source/profile artifacts are not all published yet
- Real-account trading: locked

The current conservative candidate is not live-ready and should remain paper/demo only.

## Current Conservative Candidate

Profile:

`outputs/CANDIDATE_TRADE_READY_CONSERVATIVE_PROFILE.set`

SHA-256:

`0A97B46D7E3A3C3566EF4E787BCB63E2138D114C2F0F898F9A8B1A10F842BF90`

Source SHA-256:

`46770EACA60826F90E1E9A9B7425356F96F7C8F83CF8F8C1FBE271632866933E`

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

## Remaining Blockers

- Run/import the `8` first-pass MT5 reports.
- Import the `53` conservative validation reports plus `10` broker-proxy reports after first-pass evidence passes.
- Import conservative trade/deal logs with realized R for trade-quality and Monte Carlo gates.
- Add forward/demo evidence and second-broker evidence.
- Publish the refreshed source/profile artifacts to GitHub. The large EA source files remain the hardest publication blocker because this workspace is not a valid git checkout.

Until those gates pass, this is a serious research project, not a live-money bot.