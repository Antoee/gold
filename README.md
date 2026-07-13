# Professional XAUUSD EA

Professional-grade MetaTrader 5 Expert Advisor research project for XAUUSD / Gold.

This is not a martingale, grid, averaging-down, or recovery-system bot. Risk control stays above profit chasing. Heavy optimization and validation should run locally, hidden in the background, not in GitHub Actions.

## Latest Status

Last updated: 2026-07-12.

Use this README as the status board. If you want to know what changed without asking Codex, start here.

## Read This First

Quick answer:

- Current best research profile: `Score7 Regime No-M1-Shock Dec-ISLP-Off + ISLP LowATR OrderFlow`
- Old `$866 in 2.5 years` result: outdated baseline, not the current best
- Best current continuous research result: `+$10,127.76` on `Model=1`, `2024.01.01` to `2026.07.12`
- Best current real-tick continuous result: `+$4,507.51` on `Model=4`, `2024.01.01` to `2026.07.12`
- Best sampled real-tick validation total: `+$7,469.00` across six Model4 windows
- Latest promoted change: Low-ATR ISLP trades now require order-flow confirmation
- Latest validation decision: Flat-month probes and liquidity-stop extension probes were tested and rejected; LowATR OrderFlow remains best
- Live trading status: research only, not live-ready
- GitHub Actions status: keep manual-only to protect monthly Actions usage
- Source status: local folder is not a valid Git checkout right now; `.git` exists but is empty

Current decision: keep `Score7 Regime No-M1-Shock Dec-ISLP-Off + ISLP LowATR OrderFlow` as the stability-best research profile while continuing local hidden MT5 validation.

| Item | Current State |
| --- | --- |
| Current research-best | `Score7 Regime No-M1-Shock Dec-ISLP-Off + ISLP LowATR OrderFlow` |
| What changed | Low-ATR ISLP trades require order-flow confirmation |
| Best continuous result | `+$10,127.76` on `Model=1`, `2024.01.01` to `2026.07.12` |
| Best real-tick result | `+$4,507.51` continuous on `Model=4`, `2024.01.01` to `2026.07.12` |
| Full sampled real-tick total | `+$7,469.00` across the six Model4 validation windows |
| Monthly real-tick gate | LowATR OrderFlow beat Dec-ISLP-Off `+$3,682.17` vs `+$3,637.53`, with `0` losing months vs `1` |
| Quarterly real-tick gate | LowATR OrderFlow beat Dec-ISLP-Off `+$3,435.65` vs `+$3,421.49`, with worst quarter improved from `-$44.64` to `-$30.48` |
| Monthly tester stats | LowATR OrderFlow parsed `31 / 31`, total trades `38`, worst equity DD `30.9408%` |
| Quarterly tester stats | LowATR OrderFlow parsed `11 / 11`, total trades `34`, worst equity DD `30.9408%` |
| Latest code probe | Flat-month probes and liquidity-stop extension probes failed to improve current and were rejected |
| Old `$866` result | Outdated baseline, no longer the current research-best |
| Live-ready? | No. Still a research candidate |
| GitHub Actions | Manual-only; do not use for heavy tester runs |
| Local MT5 safety | Latest audit passed `39 / 39` checks |
| Repository cleanup | Generated logs/temp artifacts archived; active cleanup candidates now `0` |

Plain English: the bot is no longer at the old `$866 in 2.5 years` baseline. The newest stability-best profile improves the prior Dec-ISLP-Off profile in sampled, monthly, and quarterly real-tick parsed-log gates. The latest flat-month work did not produce a better profile: conservative/balanced FMB tied current, loose FMB added losing trades, expanded micro-reversion added losing trades, wake-up tied current, and probe-mode reduced existing winners. Extra liquidity-stop extensions also failed; the current base liquidity-aware structure stop remains better. The bot is still not a live-profit promise. Tester-stat extraction now works, and the biggest warning is the `30.9408%` worst equity drawdown reading in the monthly/quarterly summaries.

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

1. Rerun Model1 and Model2 validation on the LowATR OrderFlow candidate.
2. Add hold-time, average winner/loser, largest loss, consecutive loss, exposure, spread, swap, commission, and slippage evidence.
3. Run older-data, walk-forward, Monte Carlo, and broker-variation validation before considering live use.
4. Attack zero-trade months with a different entry mechanism; FSD relaxation and FMW tied current, FMP reduced winners, and FMB/FMR added losing trades.
5. Keep all heavy tests local and hidden, not on GitHub Actions.

Repository cleanup completed on 2026-07-12:

- Archived generated runtime/log/temp artifacts and old MT5 package folders into `archive/generated_artifacts_*`.
- Compressed old archive folders into ignored zip files.
- Removed active `outputs/offline_refresh_logs/`.
- Archived the generated FMB/FMR/FMW/FMP/liquidity-stop package folders/logs and generated compact/tester `.mq5` sources.
- Active generated cleanup candidates after latest pass: `0`.
- Local file count reduced from about `46k` files to about `4.2k` filesystem items.
- Local workspace size after latest zip cleanup: about `90.4 MB`.
- `work/` reduced from about `143 MB` to about `4 MB`.
- `outputs/` now keeps current promoted validation package folders, root evidence CSV/source artifacts, and only one canonical `.mq5` source copy.

Known cautions:

- The full local EA source is too input-heavy for MT5 Strategy Tester, so current validation packages use compact tester-source generation until the input surface is reduced.
- This workspace is not currently a valid Git checkout. The `.git` directory exists but is empty, so GitHub publishing needs a fresh clone/sync path or connector credentials.

## Current Best Profile

Profile name:

`Score7 Regime No-M1-Shock Dec-ISLP-Off + ISLP LowATR OrderFlow`

Generated locally by:

`work/build_realtick_islp_lowatr_orderflow_probe_package.ps1`

Local generated `.set` file:

`outputs/CANDIDATE_DEC_ISLP_OFF_ISLP_LOWATR_ORDERFLOW_PROFILE.set`

SHA-256:

`D0867E0333D3F110EF47410A2B2FF46402AAD96FC70B0DBF9506836124D633BC`

Important GitHub note: the status files and generated `.set` can be synced, but the full local EA source may still be ahead of GitHub. Treat GitHub as the research dashboard unless the source-sync section says otherwise.

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

Liquidity-stop extension variants were tested on 2026-07-12 and rejected:

- Intent: improve the already-active base liquidity-aware structure stop with cluster, previous-day, and pocket extensions.
- Compile result: `0 errors, 0 warnings` through compact tester-source generation.
- Model4 result across 12 weak/flat windows: current `+$508.07`, cluster `+$387.68`, cluster+pocket `+$122.50`, previous-day `-$90.55`.
- Previous-day liquidity produced a losing window in `2026_05`; cluster variants mostly reduced existing winners.
- Decision: not promoted. Keep the current base liquidity-aware structure stop, but reject the extra extensions.
- Research note: `research/2026-07-12-liquidity-stop-extension-probe-note.md`

Flat-month probe-mode reality was tested on 2026-07-12 and rejected:

- Intent: verify whether the old flat-month probe-mode settings could really be tested once exposed as inputs.
- Code change: made dormant flat-month probe-mode controls optimizer-visible, all default-off.
- Compile result: `0 errors, 0 warnings` through compact tester-source generation.
- Model4 result across 12 weak/flat windows: current `+$508.07`, strict low-risk `+$453.17`, quality-ramp `+$453.17`, tiny discovery `+$444.02`.
- Probe-mode did not add useful flat-month trades; it mostly reduced size on existing winners.
- Decision: not promoted. The current stability-best profile remains LowATR OrderFlow.
- Research note: `research/2026-07-12-flat-month-probe-mode-reality-note.md`

Flat-month wake-up / stale-entry was tested on 2026-07-12 and rejected:

- Intent: verify whether missed-move wake-up, stale-entry nudge, or elite fallback could add safe flat-month trades once exposed as inputs.
- Code change: made dormant flat-month wake-up/stale/elite controls optimizer-visible, all default-off.
- Compile result: `0 errors, 0 warnings` through compact tester-source generation.
- Model4 result across 12 weak/flat windows: current `+$508.07`, wake strict `+$508.07`, wake balanced `+$508.07`, stale elite `+$508.07`.
- Active windows stayed `3 / 12`; zero-trade windows stayed `9 / 12`.
- Decision: not promoted. The current stability-best profile remains LowATR OrderFlow.
- Research note: `research/2026-07-12-flat-month-wakeup-probe-note.md`

Flat-month micro-reversion expansion was tested on 2026-07-12 and rejected:

- Intent: increase flat-month participation without Adaptive Reverse, martingale, grid, averaging down, or pure ATR-only stop logic.
- Change: tested stricter and softer all-month FMR variants at lower risk.
- Compile result: `0 errors, 0 warnings` through compact tester-source generation.
- Model4 result across 12 weak/flat windows: current `+$508.07`, strict expansion `+$484.43`, soft expansion `+$477.12`.
- Strict expansion reduced zero-trade windows from `9` to `8`, but added a `2025_04` loser.
- Soft expansion reduced zero-trade windows from `9` to `7`, but added `2025_04` and `2026_01` losers.
- Decision: not promoted. The current stability-best profile remains LowATR OrderFlow.
- Research note: `research/2026-07-12-flat-month-micro-reversion-expansion-probe-note.md`

Flat-month breakout structural and activation probes were tested on 2026-07-12 and rejected:

- Intent: create more useful flat-month trades without Adaptive Reverse, martingale, grid, averaging down, or pure ATR-only stops.
- Code change: made the existing FMB lane optimizer-visible and added optional direct structural stop/target controls.
- Compile result: `0 errors, 0 warnings`.
- First full-source tester run failed with `too many input parameters (1484)`, so the probe was rerun through compact tester-source generation.
- Structural Model4 result across 12 weak/flat windows: current `+$508.07`, conservative FMB `+$508.07`, balanced FMB `+$508.07`.
- Activation Model4 result: current `+$508.07`, tape FMB `+$508.07`, loose FMB `+$490.65`.
- Loose activation did reduce zero-trade windows from `9` to `7`, but it added two losing windows (`2024_10` and `2025_04`) and reduced total net.
- Decision: not promoted. The current stability-best profile remains LowATR OrderFlow.
- Research notes:
  - `research/2026-07-12-flat-month-breakout-structural-probe-note.md`
  - `research/2026-07-12-flat-month-breakout-activation-probe-note.md`

Flat-month FSD efficiency relaxation was tested on 2026-07-12 and rejected:

- Intent: increase active months without enabling Adaptive Reverse, martingale, grid, or pure ATR-only stops.
- Change: added optional `InpUseFlatMonthStructuralDisplacementEfficiencyRelaxation` and related relaxed FSD thresholds, all defaulted off.
- Compile result: `0 errors, 0 warnings`.
- Model4 sampled result across 12 weak/flat windows: current `+$508.07`, 48h relaxation `+$508.07`, 24h relaxation `+$508.07`.
- Active windows: all three profiles had `3 / 12`; zero-trade windows stayed `9 / 12`.
- Decision: not promoted. The current stability-best profile remains LowATR OrderFlow.
- Research note: `research/2026-07-12-fsd-efficiency-relaxation-probe-note.md`

ISLP LowATR OrderFlow was promoted as the stability-best research profile on 2026-07-12:

- Diagnosis: the `2024_06` ISLP winner was low ATR but had `ISLP order flow`; the `2024_10` ISLP loser was low ATR without order-flow confirmation.
- Change: added optional `InpInSessionLiquidityPullbackLowATRRequireOrderFlow`.
- Candidate settings: `InpInSessionLiquidityPullbackLowATRRequireOrderFlow=true`, `InpInSessionLiquidityPullbackLowATRThreshold=5.00`, `InpInSessionLiquidityPullbackMinATR=0.00`.
- Sampled Model4 result: `+$316.06` vs `+$271.42`, with losing windows improving from `1` to `0`.
- Monthly Model4 result: `+$3,682.17` vs `+$3,637.53`, with losing months improving from `1` to `0`.
- Quarterly Model4 result: `+$3,435.65` vs `+$3,421.49`, with worst quarter improving from `-$44.64` to `-$30.48`.
- Monthly tester-stat result: `31 / 31` stats parsed; LowATR OrderFlow had `38` trades and `30.9408%` worst equity DD.
- Quarterly tester-stat result: `11 / 11` stats parsed; LowATR OrderFlow had `34` trades and `30.9408%` worst equity DD.
- Decision: promoted as stability-best research profile, not live-ready.
- Research note: `research/2026-07-12-islp-lowatr-orderflow-promotion-note.md`

ISLP MinATR5 was tested on 2026-07-12:

- Diagnosis: the current `2024_10` Model4 loss was an ISLP sell with entry ATR around `3.74`; the `2025_10` winner was the same ISLP setup type with entry ATR around `13.19`.
- Change: added optional `InpInSessionLiquidityPullbackMinATR`, default `0.0`.
- Candidate: `InpInSessionLiquidityPullbackMinATR=5.0`.
- Small probe result: sampled Model4 total improved from `+$204.86` to `+$249.50`, with losing windows improving from `1` to `0`.
- Monthly gate result: `islp_min_atr5` made `+$3,615.61` vs `+$3,637.53` for Dec-ISLP-Off.
- Monthly tradeoff: it removed the `2024_10` `-$44.64` loser but also blocked the `2024_06` `+$66.56` winner.
- Decision: not promoted as primary; keep only as a conservative risk-smoothing candidate.
- Research note: `research/2026-07-12-islp-min-atr-probe-note.md`
- Monthly note: `research/2026-07-12-islp-min-atr-monthly-validation-note.md`

Prior FMR location-extreme strict mode was tested on 2026-07-12:

- Change: when `InpFlatMonthMicroReversionRequireVWAP=true`, flat-month micro-reversion also requires a nearby liquidity/structure extreme.
- Intent: improve flat-window quality without Adaptive Reverse or pure ATR-only logic.
- Result: tied current Dec-ISLP-Off on the compact Model4 probe, `+$204.86` vs `+$204.86`.
- Decision: not promoted.
- Research note: `research/2026-07-12-fmr-location-extreme-probe-note.md`

Important tester note:

- Full local EA source is too input-heavy for MT5 Strategy Tester right now.
- Validation packages should use compact tester source generation.
- Latest FSD relaxation compact probe kept `344` tester inputs and converted `1106` inactive inputs to globals.

## Evidence Files

Primary status:

- `outputs/CURRENT_RESEARCH_BEST_PROFILE.md`
- `research/2026-07-12-islp-lowatr-orderflow-promotion-note.md`
- `research/2026-07-12-fsd-efficiency-relaxation-probe-note.md`
- `research/2026-07-12-december-islp-guard-promotion-note.md`
- `outputs/DEC_ISLP_GUARD_DECISION_SUMMARY.csv`

Flat-month FSD efficiency relaxation rejection:

- `outputs/FLAT_MONTH_EFFICIENCY_RELAXATION_PROBE_RESULTS.csv`
- `outputs/FLAT_MONTH_EFFICIENCY_RELAXATION_PROBE_SUMMARY.csv`
- `outputs/FLAT_MONTH_EFFICIENCY_RELAXATION_PROBE_RUN.csv`
- `outputs/FLAT_MONTH_EFFICIENCY_RELAXATION_PROBE_MANIFEST.csv`

Flat-month breakout rejection:

- `outputs/FLAT_MONTH_BREAKOUT_STRUCTURAL_PROBE_RESULTS.csv`
- `outputs/FLAT_MONTH_BREAKOUT_STRUCTURAL_PROBE_SUMMARY.csv`
- `outputs/FLAT_MONTH_BREAKOUT_ACTIVATION_PROBE_RESULTS.csv`
- `outputs/FLAT_MONTH_BREAKOUT_ACTIVATION_PROBE_SUMMARY.csv`
- `research/2026-07-12-flat-month-breakout-structural-probe-note.md`
- `research/2026-07-12-flat-month-breakout-activation-probe-note.md`

Flat-month micro-reversion expansion rejection:

- `outputs/FLAT_MONTH_MICRO_REVERSION_EXPANSION_PROBE_RESULTS.csv`
- `outputs/FLAT_MONTH_MICRO_REVERSION_EXPANSION_PROBE_SUMMARY.csv`
- `outputs/FLAT_MONTH_MICRO_REVERSION_EXPANSION_PROBE_RUN.csv`
- `outputs/FLAT_MONTH_MICRO_REVERSION_EXPANSION_PROBE_MANIFEST.csv`
- `research/2026-07-12-flat-month-micro-reversion-expansion-probe-note.md`

Flat-month wake-up and probe-mode rejections:

- `outputs/FLAT_MONTH_WAKEUP_PROBE_RESULTS.csv`
- `outputs/FLAT_MONTH_WAKEUP_PROBE_SUMMARY.csv`
- `outputs/FLAT_MONTH_PROBE_MODE_REALITY_RESULTS.csv`
- `outputs/FLAT_MONTH_PROBE_MODE_REALITY_SUMMARY.csv`
- `research/2026-07-12-flat-month-wakeup-probe-note.md`
- `research/2026-07-12-flat-month-probe-mode-reality-note.md`

Liquidity-stop extension rejection:

- `outputs/LIQUIDITY_STOP_EXTENSION_PROBE_RESULTS.csv`
- `outputs/LIQUIDITY_STOP_EXTENSION_PROBE_SUMMARY.csv`
- `outputs/LIQUIDITY_STOP_EXTENSION_PROBE_RUN.csv`
- `outputs/LIQUIDITY_STOP_EXTENSION_PROBE_MANIFEST.csv`
- `research/2026-07-12-liquidity-stop-extension-probe-note.md`

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

Local ISLP MinATR probe evidence:

- `outputs/REALTICK_ISLP_MIN_ATR_PROBE_DIFF.csv`
- `outputs/REALTICK_ISLP_MIN_ATR_PROBE_PROFILE_SUMMARY.csv`
- `outputs/REALTICK_ISLP_MIN_ATR_PROBE_DECISION_SUMMARY.csv`
- `research/2026-07-12-islp-min-atr-probe-note.md`

Local ISLP MinATR monthly validation evidence:

- `outputs/REALTICK_ISLP_MIN_ATR_MONTHLY_VALIDATION_DIFF.csv`
- `outputs/REALTICK_ISLP_MIN_ATR_MONTHLY_VALIDATION_PROFILE_SUMMARY.csv`
- `outputs/REALTICK_ISLP_MIN_ATR_MONTHLY_VALIDATION_DECISION_SUMMARY.csv`
- `research/2026-07-12-islp-min-atr-monthly-validation-note.md`

Local ISLP LowATR OrderFlow promotion evidence:

- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_PROBE_DIFF.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_PROBE_PROFILE_SUMMARY.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_PROBE_DECISION_SUMMARY.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_MONTHLY_VALIDATION_DIFF.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_MONTHLY_VALIDATION_PROFILE_SUMMARY.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_MONTHLY_VALIDATION_DECISION_SUMMARY.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_QUARTERLY_VALIDATION_DIFF.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_QUARTERLY_VALIDATION_PROFILE_SUMMARY.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_QUARTERLY_VALIDATION_DECISION_SUMMARY.csv`
- `research/2026-07-12-islp-lowatr-orderflow-promotion-note.md`

Local-only monthly raw files:

- `outputs/REALTICK_DEC_ISLP_MONTHLY_VALIDATION_RUN.csv`
- `outputs/REALTICK_DEC_ISLP_MONTHLY_VALIDATION_LOG_RESULTS.csv`
- `outputs/REALTICK_DEC_ISLP_QUARTERLY_VALIDATION_RUN.csv`
- `outputs/REALTICK_DEC_ISLP_QUARTERLY_VALIDATION_LOG_RESULTS.csv`
- `outputs/REALTICK_FMR_LOCATION_EXTREME_PROBE_RUN.csv`
- `outputs/REALTICK_FMR_LOCATION_EXTREME_PROBE_LOG_RESULTS.csv`
- `outputs/REALTICK_ISLP_MIN_ATR_PROBE_RUN.csv`
- `outputs/REALTICK_ISLP_MIN_ATR_PROBE_LOG_RESULTS.csv`
- `outputs/REALTICK_ISLP_MIN_ATR_MONTHLY_VALIDATION_RUN.csv`
- `outputs/REALTICK_ISLP_MIN_ATR_MONTHLY_VALIDATION_LOG_RESULTS.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_PROBE_RUN.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_PROBE_LOG_RESULTS.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_MONTHLY_VALIDATION_RUN.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_MONTHLY_VALIDATION_LOG_RESULTS.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_QUARTERLY_VALIDATION_RUN.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_QUARTERLY_VALIDATION_LOG_RESULTS.csv`

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
- Low-ATR ISLP entries now require order-flow confirmation in the stability-best profile.
- ISLP MinATR5 remains rejected as the primary because it blocked the June 2024 winner.
- Spread-regime guard is enabled.
- M1 spread-shock guard is disabled because it created Model2 compatibility problems without adding Model1 profit.
- Adaptive Reverse is internally locked off in local source to reduce whipsaw risk and tester input count.
- Dormant flat-month probe/stale/missed-move controls were made optimizer-visible as default-off inputs; tests rejected those settings, so active current-best lanes remain unchanged.

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
