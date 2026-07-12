# Professional XAUUSD EA

Professional-grade MetaTrader 5 Expert Advisor research project for XAUUSD / Gold.

This is not a martingale, grid, averaging-down, or recovery-system bot. Risk control stays above profit chasing. Heavy optimization and validation should run locally, hidden in the background, not in GitHub Actions.

## Latest Status

Last updated: 2026-07-12.

Use this README as the status board. If you want to know what changed without asking Codex, start here.

## Read This First

Quick answer:

- Current best research profile: `Score7 Regime No-M1-Shock Dec-ISLP-Off`
- Old `$866 in 2.5 years` result: outdated baseline, not the current best
- Best current continuous research result: `+$10,127.76` on `Model=1`, `2024.01.01` to `2026.07.12`
- Best current real-tick continuous result: `+$4,507.51` on `Model=4`, `2024.01.01` to `2026.07.12`
- Best sampled real-tick validation total: `+$7,469.00` across six Model4 windows
- Latest promoted change: December ISLP disabled with `InpISLPTradeDecember=false`
- Latest rejected probe: FMR location-extreme strict mode tied the current profile and was not promoted
- Live trading status: research only, not live-ready
- GitHub Actions status: keep manual-only to protect monthly Actions usage
- Source status: local EA source is still ahead of GitHub

Current decision: keep `Score7 Regime No-M1-Shock Dec-ISLP-Off` as the research-best profile while continuing local hidden MT5 validation.

| Item | Current State |
| --- | --- |
| Current research-best | `Score7 Regime No-M1-Shock Dec-ISLP-Off` |
| What changed | Disabled only December trades for the In-Session Liquidity Pullback lane |
| Best continuous result | `+$10,127.76` on `Model=1`, `2024.01.01` to `2026.07.12` |
| Best real-tick result | `+$4,507.51` continuous on `Model=4`, `2024.01.01` to `2026.07.12` |
| Full sampled real-tick total | `+$7,469.00` across the six Model4 validation windows |
| Monthly real-tick gate | Dec-ISLP-Off beat prior profile `+$3,779.52` vs `+$3,687.00`, with `0` losing months vs `2` |
| Quarterly real-tick gate | Dec-ISLP-Off beat prior profile `+$3,455.89` vs `+$3,404.59`, with `0` losing quarters vs `1` |
| Latest code probe | FMR location-extreme strict mode tied `+$204.86` vs `+$204.86`; not promoted |
| Old `$866` result | Outdated baseline, no longer the current research-best |
| Live-ready? | No. Still a research candidate |
| GitHub Actions | Manual-only; do not use for heavy tester runs |
| Local MT5 safety | Latest audit passed `39 / 39` checks |

Plain English: the bot is no longer at the old `$866 in 2.5 years` baseline. The newest promoted profile is much better in research tests, and the monthly plus quarterly real-tick parsed-log gates support it. It is still not a live-profit promise. The next job is getting richer report/trade-stat evidence and continuing walk-forward validation.

## How To Check Progress Without Asking Codex

Open these files on GitHub in this order:

1. `README.md` - highest-level status, current best, latest decision, and next task.
2. `outputs/CURRENT_RESEARCH_BEST_PROFILE.md` - current promoted profile and exact `.set` identity.
3. `research/` - human-readable notes explaining why a change was promoted or rejected.
4. `outputs/*DECISION_SUMMARY.csv` - compact result tables for each validation package.
5. `outputs/*PROFILE_SUMMARY.csv` - profile totals, losing-window counts, and worst windows.

What to look for:

- `Promoted` means the change became the new research-best.
- `Rejected` means it was tested and did not beat the current best.
- `Probe only` means the result was useful, but not enough to trust yet.
- `NO_REPORT` means MT5 did not export full reports, so only parsed log results should be trusted.
- `Model=4` means real ticks, which matters most for serious validation.

## Current Work Queue

Next local work:

1. Diagnose the current `2024_10` Model4 losing window because it does not match older Q4 diagnostics.
2. Compare that losing October against the winning `2025_10` window.
3. Only add a new guard if the diagnostics show a clear repeatable weakness.
4. Keep all heavy tests local and hidden, not on GitHub Actions.

Known caution: the full local EA source is too input-heavy for MT5 Strategy Tester, so current validation packages use compact tester-source generation until the input surface is reduced.

## Current Best Profile

Profile name:

`Score7 Regime No-M1-Shock Dec-ISLP-Off`

Generated locally by:

`work/build_score7_regime_no_m1shock_dec_islp_off_profile.ps1`

Local generated `.set` file:

`outputs/CANDIDATE_PRIMARY_RANGE_ELITE_MFE_FAILURE_MARCH_ISLP_JUN_OCTDEC_SCORE7_REGIME_NO_M1SHOCK_DEC_ISLP_OFF_PROFILE.set`

SHA-256:

`D1B665E193A5126B879E0DCA08A85CB5C8E1D1C9D2007075D6C2EA6ABBF82672`

Important GitHub note: the builder and status files are synced; the full local EA source and generated `.set` may be ahead of GitHub. Treat GitHub as the research dashboard unless the source-sync section says otherwise.

## Latest Promoted Result

December ISLP guard validation:

| Model | Previous No-M1-Shock | Dec-ISLP-Off | Decision |
| --- | ---: | ---: | --- |
| Model0 total | `+$4,495.93` | `+$8,768.34` | Guard wins |
| Model1 total | `+$14,739.08` | `+$15,361.76` | Guard wins |
| Model2 total | `+$17,890.63` | `+$15,361.76` | Previous wins |
| Model4 real-tick total | `+$4,075.62` | `+$7,469.00` | Guard wins |

Continuous-window comparison:

| Model | Previous No-M1-Shock | Dec-ISLP-Off |
| --- | ---: | ---: |
| Model0 continuous | `+$1,288.93` | `+$5,386.54` |
| Model1 continuous | `+$9,753.58` | `+$10,127.76` |
| Model2 continuous | `+$12,054.55` | `+$10,127.76` |
| Model4 real-tick continuous | `+$1,288.93` | `+$4,507.51` |

Why it was promoted:

- Diagnostics showed the Q4 2024 real-tick red window came from one December ISLP loss.
- Disabling December ISLP removed that weak window.
- Model0, Model1, and Model4 improved.
- Model2 is the caveat: it still prefers the previous no-m1-shock profile.

## Latest Monthly Real-Tick Gate

Wider monthly real-tick validation was run on 2026-07-12:

- Package: `outputs/realtick_dec_islp_monthly_validation_package`
- Runner CSV: `outputs/REALTICK_DEC_ISLP_MONTHLY_VALIDATION_RUN.csv`
- Configs: `62`
- Report files: `62 / 62` returned `NO_REPORT`
- Log parsing: recovered `62 / 62` final-balance results
- Result: Dec-ISLP-Off beat prior no-m1-shock `+$3,779.52` vs `+$3,687.00`
- Losing months: Dec-ISLP-Off `0`, prior no-m1-shock `2`
- Decision: validation credit for monthly net-profit comparison only; no full drawdown/trade-stat credit

Current local safety after that attempt:

- `work/MT5_LOCAL_LAUNCH_DISABLED.lock` restored
- MT5 safety audit: `PASS`, `39 / 39`

## Latest Quarterly Real-Tick Gate

Quarterly real-tick validation was run on 2026-07-12:

- Package: `outputs/realtick_dec_islp_quarterly_validation_package`
- Runner CSV: `outputs/REALTICK_DEC_ISLP_QUARTERLY_VALIDATION_RUN.csv`
- Configs: `22`
- Report files: `22 / 22` returned `NO_REPORT`
- Log parsing: recovered `22 / 22` final-balance results
- Result: Dec-ISLP-Off beat prior no-m1-shock `+$3,455.89` vs `+$3,404.59`
- Losing quarters: Dec-ISLP-Off `0`, prior no-m1-shock `1`
- Decision: supports keeping Dec-ISLP-Off promoted for net-profit/quarter comparison

## Latest Code Probe

FMR location-extreme strict mode was tested on 2026-07-12:

- Change: when `InpFlatMonthMicroReversionRequireVWAP=true`, flat-month micro-reversion also requires a nearby liquidity/structure extreme.
- Intent: improve flat-window quality without Adaptive Reverse or pure ATR-only logic.
- Result: tied current Dec-ISLP-Off on the compact Model4 probe, `+$204.86` vs `+$204.86`.
- Decision: not promoted.
- Research note: `research/2026-07-12-fmr-location-extreme-probe-note.md`

Important tester note:

- Full local EA source is too input-heavy for MT5 Strategy Tester right now.
- Validation packages should use compact tester source generation.
- Latest compact probe kept `334` tester inputs and converted `1105` inactive inputs to globals.

## Evidence Files

Primary status:

- `outputs/CURRENT_RESEARCH_BEST_PROFILE.md`
- `research/2026-07-12-december-islp-guard-promotion-note.md`
- `outputs/DEC_ISLP_GUARD_DECISION_SUMMARY.csv`

December ISLP guard validation:

- `outputs/REALTICK_DEC_ISLP_GUARD_LOG_RESULTS.csv`
- `outputs/MODEL1_DEC_ISLP_GUARD_LOG_RESULTS.csv`
- `outputs/MODEL2_DEC_ISLP_GUARD_LOG_RESULTS.csv`
- `outputs/MODEL0_DEC_ISLP_GUARD_LOG_RESULTS.csv`

Real-tick profile showdown:

- `outputs/REALTICK_PROFILE_SHOWDOWN_LOG_RESULTS.csv`
- `outputs/REALTICK_PROFILE_SHOWDOWN_DECISION_SUMMARY.csv`
- `research/2026-07-12-realtick-profile-showdown-note.md`

Earlier Score7 and regime validation:

- `outputs/MODEL1_SCORE7_REGIME_NO_M1SHOCK_LOG_RESULTS.csv`
- `outputs/MODEL1_SCORE7_REGIME_NO_M1SHOCK_QTR_LOG_RESULTS.csv`
- `outputs/MODEL2_SCORE7_REGIME_NO_M1SHOCK_LOG_RESULTS.csv`
- `outputs/MODEL4_SCORE7_VS_NO_M1SHOCK_PROBE_LOG_RESULTS.csv`

Synced monthly parsed-log evidence:

- `outputs/REALTICK_DEC_ISLP_MONTHLY_VALIDATION_DIFF.csv`
- `outputs/REALTICK_DEC_ISLP_MONTHLY_VALIDATION_PROFILE_SUMMARY.csv`
- `outputs/REALTICK_DEC_ISLP_MONTHLY_VALIDATION_DECISION_SUMMARY.csv`
- `research/2026-07-12-december-islp-monthly-validation-note.md`

Synced quarterly parsed-log evidence:

- `outputs/REALTICK_DEC_ISLP_QUARTERLY_VALIDATION_DIFF.csv`
- `outputs/REALTICK_DEC_ISLP_QUARTERLY_VALIDATION_PROFILE_SUMMARY.csv`
- `outputs/REALTICK_DEC_ISLP_QUARTERLY_VALIDATION_DECISION_SUMMARY.csv`
- `research/2026-07-12-december-islp-quarterly-validation-note.md`

Local FMR strict-mode probe evidence:

- `outputs/REALTICK_FMR_LOCATION_EXTREME_PROBE_DIFF.csv`
- `outputs/REALTICK_FMR_LOCATION_EXTREME_PROBE_PROFILE_SUMMARY.csv`
- `outputs/REALTICK_FMR_LOCATION_EXTREME_PROBE_DECISION_SUMMARY.csv`
- `research/2026-07-12-fmr-location-extreme-probe-note.md`

Local-only monthly raw files:

- `outputs/REALTICK_DEC_ISLP_MONTHLY_VALIDATION_RUN.csv`
- `outputs/REALTICK_DEC_ISLP_MONTHLY_VALIDATION_LOG_RESULTS.csv`
- `outputs/REALTICK_DEC_ISLP_QUARTERLY_VALIDATION_RUN.csv`
- `outputs/REALTICK_DEC_ISLP_QUARTERLY_VALIDATION_LOG_RESULTS.csv`
- `outputs/REALTICK_FMR_LOCATION_EXTREME_PROBE_RUN.csv`
- `outputs/REALTICK_FMR_LOCATION_EXTREME_PROBE_LOG_RESULTS.csv`

## What Changed Recently

The current promoted profile keeps the prior Score7/Regime work and adds one narrow guard:

- `InpISLPTradeDecember=false`

It does not enable martingale, grid, averaging down, or recovery logic.

Current strategy direction:

- Adaptive Reverse remains disabled to avoid stop-and-reverse whipsaw.
- Flat Month Structural Displacement remains a tightly gated opportunity lane.
- Flat Month Micro Reversion is limited to July and October at reduced risk.
- Range Elite Micro Reversion remains low-frequency and strict.
- MFE Failure Exit is enabled only in March.
- In-Session Liquidity Pullback remains enabled only for selected months, with December now disabled.
- Spread-regime guard is enabled.
- M1 spread-shock guard is disabled because it created Model2 compatibility problems without adding Model1 profit.
- Adaptive Reverse is internally locked off in local source to reduce whipsaw risk and tester input count.
- Dormant generic flat-month probe/stale/missed-move/breakout-probe controls were frozen as globals; active current-best lanes remain configurable.

## What The Numbers Mean

Do not read the test numbers as guaranteed live profit.

Useful interpretation:

- `+$10,127.76` is the best current Model1 continuous research result.
- `+$4,507.51` is the current Model4 real-tick continuous result.
- `+$7,469.00` is the Model4 total across sampled validation windows.
- Monthly Model4 parsed-log validation also supports the guard: `+$3,779.52` vs `+$3,687.00`, and `0` losing months vs `2`.
- Quarterly Model4 parsed-log validation supports the same guard: `+$3,455.89` vs `+$3,404.59`, and `0` losing quarters vs `1`.
- Model2 still argues for caution because it prefers the previous no-m1-shock profile.

Bottom line: the profile is worth more testing, not live deployment yet.

## Next Research Gates

Next useful work:

1. Fix report generation or add richer trade/stat extraction so Model4 runs include drawdown, trades, and profit factor.
2. Investigate why Model2 prefers the previous profile.
3. Use compact tester-source generation for future validation until the full EA input surface is reduced.
4. Continue looking for profit lanes that add trades without creating losing windows.
5. Only raise risk after the profile survives wider real-tick validation.

## Rules For Future Updates

When Codex changes the bot or runs meaningful tests, update this README with:

1. Current best profile, or say the old best still stands.
2. Exact tester model: `Model=0`, `Model=1`, `Model=2`, or `Model=4`.
3. Exact date window.
4. Net profit, worst window, losing-window count, and failures.
5. Evidence CSV or research note.
6. Promotion decision: promoted, rejected, or probe only.

If a run returns `NO_REPORT`, it does not count as proof.

## GitHub Actions

GitHub Actions should stay manual-only. Monthly Actions usage is already high, and heavy MT5 runs belong on the local PC, a spare machine, or a VPS.

## Source Sync Status

Local `Professional_XAUUSD_EA.mq5` is ahead of the GitHub source. The README, research notes, builders, and result CSVs are the main synced dashboard right now. Do not assume GitHub contains every local EA source change until this section says the full EA source has been synced.
