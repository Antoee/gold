# Professional XAUUSD EA

Professional-grade MetaTrader 5 Expert Advisor research project for XAUUSD / Gold.

This is not a martingale, grid, averaging-down, or recovery-system bot. Risk control stays above profit chasing. Heavy optimization and validation should run locally, hidden in the background, not in GitHub Actions.

## Latest Status

Last updated: 2026-07-12.

Use this README as the status board. If you want to know what changed without asking Codex, start here.

## Best Bot So Far

Current stability-best research profile:

`Score7 Regime No-M1-Shock Dec-ISLP-Off + ISLP LowATR OrderFlow`

Short answer: this is the best and most stable bot we have so far, but it is still a provisional research candidate. It is not proven enough for real money.

Live trading status: **research only, not live-ready**.

Why it is the current stability leader:

- It keeps the prior Score7, Regime, No-M1-Shock, and Dec-ISLP-Off improvements.
- It adds a narrow rule: low-ATR ISLP trades require order-flow confirmation.
- It blocked the October 2024 low-ATR ISLP loser.
- It kept the June 2024 low-ATR ISLP winner because order flow confirmed.
- It passed sampled, monthly, and quarterly Model4 parsed-log validation against the previous Dec-ISLP-Off profile.

Important caution: the Dec-ISLP-Off component is still provisional. It was helped by a very small number of December observations, so it should be treated as a risk-control candidate pending older-data, forward, and walk-forward evidence.

## Current Numbers

| Test | Previous Dec-ISLP-Off | LowATR OrderFlow | Decision |
| --- | ---: | ---: | --- |
| Model4 sampled probe | `+$271.42` | `+$316.06` | LowATR OrderFlow wins |
| Sampled losing windows | `1` | `0` | Better stability |
| Model4 monthly gate | `+$3,637.53` | `+$3,682.17` | LowATR OrderFlow wins |
| Monthly losing windows | `1` | `0` | Better stability |
| Model4 quarterly gate | `+$3,421.49` | `+$3,435.65` | LowATR OrderFlow wins |
| Worst quarter | `-$44.64` | `-$30.48` | Better stability |

Older context:

- Old `$866 in 2.5 years` result: outdated baseline, not the current best.
- Best prior continuous research result: `+$10,127.76` on `Model=1`, `2024.01.01` to `2026.07.12`.
- Best prior continuous real-tick result: `+$4,507.51` on `Model=4`, `2024.01.01` to `2026.07.12`.
- Prior sampled Model4 aggregate validation-window net score: `+$7,469.00`. This is a comparison score, not a sequential account return.
- LowATR OrderFlow has not yet been rerun through full Model1/Model2 continuous validation.

Plain English: the current best is no longer the old `$866` bot. The most stable candidate is the LowATR OrderFlow version, but it still needs richer report stats before any live-trading decision.

## Current Best Profile

Profile name:

`Score7 Regime No-M1-Shock Dec-ISLP-Off + ISLP LowATR OrderFlow`

Local generated `.set` file:

`outputs/CANDIDATE_DEC_ISLP_OFF_ISLP_LOWATR_ORDERFLOW_PROFILE.set`

SHA-256:

`D0867E0333D3F110EF47410A2B2FF46402AAD96FC70B0DBF9506836124D633BC`

Settings that define the latest guard:

- `InpInSessionLiquidityPullbackMinATR=0.00`
- `InpInSessionLiquidityPullbackLowATRRequireOrderFlow=true`
- `InpInSessionLiquidityPullbackLowATRThreshold=5.00`

## How To Check Progress Without Asking Codex

Open these files on GitHub in this order:

1. `README.md` - highest-level status, current best, latest decision, and next task.
2. `outputs/CURRENT_RESEARCH_BEST_PROFILE.md` - current promoted profile and exact identity.
3. `research/` - human-readable notes explaining why a change was promoted or rejected.
4. `outputs/*DECISION_SUMMARY.csv` - compact result tables for each validation package.
5. `outputs/*PROFILE_SUMMARY.csv` - profile totals, losing-window counts, and worst windows.

What to look for:

- `Promoted` means the change became the new research-best.
- `Rejected` means it was tested and did not beat the current best.
- `Probe only` means the result was useful, but not enough to trust yet.
- `NO_REPORT` means MT5 did not export full reports, so only parsed log results should be trusted.
- `Model=4` means real ticks, which matters most for serious validation.

## Evidence Gaps

The biggest blocker is not another entry filter. The biggest blocker is missing complete risk and trade-quality evidence.

Every serious result still needs:

- Starting balance and ending balance.
- Maximum equity drawdown and relative drawdown percentage.
- Number of trades.
- Profit factor.
- Expected payoff.
- Average winner and average loser.
- Largest loss.
- Consecutive losses.
- Exposure time.
- Recovery factor.
- Monthly return percentages.
- Lot sizes and actual risk percentage used.
- Spread, commission, swap, and slippage assumptions.

The latest monthly and quarterly gates returned `NO_REPORT`, so they currently prove only parsed final-balance comparisons. They do not prove drawdown, trade count, or profit factor.

## Latest Promotion

ISLP LowATR OrderFlow was promoted as the stability-best research profile on 2026-07-12.

Diagnosis:

- The June 2024 low-ATR ISLP winner had `ISLP order flow` confirmation.
- The October 2024 low-ATR ISLP loser did not have order-flow confirmation.
- A blunt MinATR5 filter was rejected because it removed the October loser but also deleted the larger June winner.

Decision:

`Score7 Regime No-M1-Shock Dec-ISLP-Off + ISLP LowATR OrderFlow` is the current stability-best research profile.

Still not live-ready because:

- MT5 report export still returned `NO_REPORT` on these validation packages.
- Drawdown, profit factor, trade count, and hold-time stats still need richer extraction.
- Model1 and Model2 have not yet been rerun on this LowATR OrderFlow candidate.
- Local `Professional_XAUUSD_EA.mq5` is ahead of the GitHub source and contains the new optional guard.

## Evidence Files

Primary status:

- `outputs/CURRENT_RESEARCH_BEST_PROFILE.md`
- `research/2026-07-12-islp-lowatr-orderflow-promotion-note.md`

LowATR OrderFlow evidence:

- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_PROBE_DIFF.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_PROBE_PROFILE_SUMMARY.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_PROBE_DECISION_SUMMARY.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_MONTHLY_VALIDATION_DIFF.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_MONTHLY_VALIDATION_PROFILE_SUMMARY.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_MONTHLY_VALIDATION_DECISION_SUMMARY.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_QUARTERLY_VALIDATION_DIFF.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_QUARTERLY_VALIDATION_PROFILE_SUMMARY.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_QUARTERLY_VALIDATION_DECISION_SUMMARY.csv`

Important prior evidence:

- `research/2026-07-12-december-islp-guard-promotion-note.md`
- `research/2026-07-12-islp-min-atr-monthly-validation-note.md`
- `outputs/DEC_ISLP_GUARD_DECISION_SUMMARY.csv`

## Current Work Queue

Next local work, in priority order:

1. Fix report generation or build a reliable parser that extracts drawdown, profit factor, trade count, hold time, and trade-level stats from logs/history.
2. Sync the exact tested `.mq5` source, `.set` profile, MT5 build, broker/symbol specs, and test configuration so results are reproducible later.
3. Rerun Model1 and Model2 validation on the LowATR OrderFlow candidate.
4. Run older-data or walk-forward validation because 2024-2026 has already influenced strategy selection.
5. Add Monte Carlo stress tests for trade order, slippage, spread, execution delay, missed trades, and worse exits.
6. Test broker variation for XAUUSD contract size, spread, commission, swap, stop level, tick size, and session timing.
7. Continue seeking extra profit lanes only after the measurement and reproducibility blockers are improved.

Known caution: the full local EA source is too input-heavy for MT5 Strategy Tester, so current validation packages use compact tester-source generation until the input surface is reduced.

## Standing Rules

- No martingale.
- No grid.
- No averaging down.
- No unrealistic recovery systems.
- Adaptive Reverse remains disabled to avoid stop-and-reverse whipsaw.
- Risk control stays above profit chasing.
- GitHub Actions should stay manual-only; heavy MT5 runs belong on the local PC, a spare machine, or a VPS.

## Source Sync Status

Local `Professional_XAUUSD_EA.mq5` is ahead of the GitHub source. The README, research notes, builders, and result CSVs are the main synced dashboard right now. Do not assume GitHub contains every local EA source change until this section says the full EA source has been synced.
