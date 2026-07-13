# Current Research Best Profile

Last updated: 2026-07-13.

## Profile

Current stability-best research profile:

`Score7 Regime No-M1-Shock Dec-ISLP-Off + ISLP LowATR OrderFlow`

Profile file:

`outputs/CANDIDATE_DEC_ISLP_OFF_ISLP_LOWATR_ORDERFLOW_PROFILE.set`

SHA-256:

`D0867E0333D3F110EF47410A2B2FF46402AAD96FC70B0DBF9506836124D633BC`

Research note:

`research/2026-07-12-islp-lowatr-orderflow-promotion-note.md`

Stats export note:

`research/2026-07-12-lowatr-tester-stats-export-note.md`

Latest stats summaries:

- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_PROBE_STATS_SUMMARY.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_MONTHLY_STATS_SUMMARY.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_QUARTERLY_STATS_SUMMARY.csv`

## Change

The current best keeps the Dec-ISLP-Off profile and adds a smarter low-volatility ISLP guard:

- `InpInSessionLiquidityPullbackMinATR=0.00`
- `InpInSessionLiquidityPullbackLowATRRequireOrderFlow=true`
- `InpInSessionLiquidityPullbackLowATRThreshold=5.00`

Meaning:

Low-ATR ISLP trades are still allowed, but only when order flow confirms.

## Why It Replaced Dec-ISLP-Off

The blunt MinATR5 guard was rejected because it removed the October 2024 loser but also deleted a larger June 2024 winner.

The LowATR OrderFlow guard fixed that tradeoff:

- It kept the June 2024 low-ATR ISLP winner because order flow confirmed.
- It blocked the October 2024 low-ATR ISLP loser because order flow did not confirm.

## Model4 Evidence

Sampled probe:

| Profile | Parsed | Total | Losing Windows | Worst |
| --- | ---: | ---: | ---: | ---: |
| `dec_islp_off` | `7` | `+271.42` | `1` | `-44.64` |
| `islp_lowatr_of` | `7` | `+316.06` | `0` | `0.00` |

Monthly validation:

| Profile | Parsed | Total | Losing Windows | Worst |
| --- | ---: | ---: | ---: | ---: |
| `dec_islp_off` | `31` | `+3,637.53` | `1` | `-44.64` |
| `islp_lowatr_of` | `31` | `+3,682.17` | `0` | `0.00` |

Monthly tester-stat rerun:

| Profile | Stats Parsed | Total Net | Trades | Worst Equity DD % | Nonzero PF Samples | Min Nonzero PF |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `dec_islp_off` | `31 / 31` | `+3,637.53` | `39` | `30.9408` | `7` | `1.4914` |
| `islp_lowatr_of` | `31 / 31` | `+3,682.17` | `38` | `30.9408` | `7` | `1.4914` |

Quarterly validation:

| Profile | Parsed | Total | Losing Windows | Worst |
| --- | ---: | ---: | ---: | ---: |
| `dec_islp_off` | `11` | `+3,421.49` | `1` | `-44.64` |
| `islp_lowatr_of` | `11` | `+3,435.65` | `1` | `-30.48` |

Quarterly tester-stat rerun:

| Profile | Stats Parsed | Total Net | Trades | Worst Equity DD % | Min Recovery Factor | Avg Sharpe |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `dec_islp_off` | `11 / 11` | `+3,421.49` | `34` | `30.9408` | `-0.9789` | `3.2935` |
| `islp_lowatr_of` | `11 / 11` | `+3,435.65` | `34` | `30.9408` | `-0.5184` | `3.2828` |

Fresh current-source continuous check:

| Profile | Continuous | 2024 Full | 2025 Full | 2026 YTD | Worst Equity DD % |
| --- | ---: | ---: | ---: | ---: | ---: |
| `dec_islp_off` | `+1,195.04` | `+1,340.55` | `+214.30` | `+955.21` | `28.2997` |
| `islp_lowatr_of` | `+1,195.69` | `+1,353.53` | `+214.30` | `+955.21` | `28.2785` |

The older `+4,507.51` Dec-ISLP-Off Model4 continuous result is now treated as historical/stale until it is reproduced on the current local source and compact tester path.

Decision:

Promoted as the current stability-best research profile.

## Evidence Files

- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_PROBE_DIFF.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_PROBE_PROFILE_SUMMARY.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_PROBE_DECISION_SUMMARY.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_PROBE_STATS_RESULTS.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_PROBE_STATS_SUMMARY.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_MONTHLY_VALIDATION_DIFF.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_MONTHLY_VALIDATION_PROFILE_SUMMARY.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_MONTHLY_VALIDATION_DECISION_SUMMARY.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_MONTHLY_STATS_RESULTS.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_MONTHLY_STATS_SUMMARY.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_QUARTERLY_VALIDATION_DIFF.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_QUARTERLY_VALIDATION_PROFILE_SUMMARY.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_QUARTERLY_VALIDATION_DECISION_SUMMARY.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_QUARTERLY_STATS_RESULTS.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_QUARTERLY_STATS_SUMMARY.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_CONTINUOUS_CHECK_RESULTS.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_CONTINUOUS_CHECK_SUMMARY.csv`
- `research/2026-07-12-islp-lowatr-orderflow-promotion-note.md`
- `research/2026-07-12-lowatr-tester-stats-export-note.md`
- `research/2026-07-12-block-diagnostics-and-risk-shape-note.md`

## Caveats

This is not a live-ready production profile.

Remaining gaps:

- MT5 report export still returns `NO_REPORT`; results are parsed from tester logs.
- Monthly and quarterly tester-stat reruns are complete, but they show a high worst equity drawdown reading of `30.9408%`.
- Fresh current-source continuous Model4 is only `+1,195.69`; the historical `+4,507.51` continuous headline needs reproduction before it should be used as the current headline.
- Hold-time stats still need richer extraction.
- Model1 and Model2 have not yet been rerun on this LowATR OrderFlow candidate.
- Local `Professional_XAUUSD_EA.mq5` is ahead of the GitHub source and contains newer default-off flat-month probe/wake-up infrastructure.
- The local workspace is not currently a valid Git checkout because `.git` exists but is empty.

Adaptive Reverse remains disabled and is now source-quarantined against accidental stop-and-reverse research reuse.

## Latest Default-Off Research Code

On 2026-07-13, the EA source gained a new default-off Flat Month Liquidity Reclaim lane tagged `FMLR;`.

Status:

- Not part of the current research-best profile.
- Not promoted.
- Not backtested yet.
- Added to both `Professional_XAUUSD_EA.mq5` and `outputs/Professional_XAUUSD_EA.mq5`.
- Offline package builder: `work/build_flat_month_liquidity_reclaim_probe_package.ps1`.
- Latest default-off addition: optional FMLR forward-liquidity target, recent-sweep retest, session/Asian target, imbalance-retest, swing-target, and forward-clearance controls with `fmlr_liquidity_target`, `fmlr_recent_retest`, `fmlr_session_target`, `fmlr_imbalance_retest`, and `fmlr_swing_target` probe profiles.
- Compact-source prep: `work/prepare_flat_month_liquidity_reclaim_compact_source.ps1`.
- Source smoke: `PRICE_ACTION_STRATEGY_MODULES_SMOKE_PASS`.
- Package-builder smoke: `FLAT_MONTH_LIQUIDITY_RECLAIM_PROBE_PACKAGE_SMOKE_PASS`.
- Compact-source smoke: `FLAT_MONTH_LIQUIDITY_RECLAIM_COMPACT_SOURCE_SMOKE_PASS`.
- Adaptive Reverse quarantine smoke: `ADAPTIVE_REVERSE_QUARANTINE_SMOKE_PASS`.
- MT5 local safety audit: `PASS 39 / 39`.
- Compile/backtest: pending while `work/MT5_LOCAL_LAUNCH_DISABLED.lock` remains active.

Research note:

`research/2026-07-13-flat-month-liquidity-reclaim-lane-note.md`

Adaptive Reverse quarantine note:

`research/2026-07-13-adaptive-reverse-quarantine-note.md`

## Latest Rejected Probes

Block diagnostics, month-filter bypass, and March/May risk-shape probes were tested on 2026-07-12 and rejected.

Summary:

| Profile | Continuous | 2026 YTD | Full 2025 | Worst Window | Losing Windows | Worst Equity DD % |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `current` | `+1,195.69` | `+955.21` | `+214.30` | `+214.30` | `0` | `30.9408` |
| `mar200_may220` | `+993.28` | `+1,238.40` | `+105.51` | `-196.16` | `1` | `28.6598` |
| `mar175_may280` | `+464.46` | `+1,032.92` | `-8.60` | `-8.60` | `2` | `30.9408` |
| `mar150_may280` | `+395.91` | `+901.82` | `-8.35` | `-8.35` | `2` | `30.9408` |
| `mar150_may240` | `+395.91` | `+931.99` | `-8.35` | `-8.35` | `2` | `35.9388` |
| `mar125_may280` | `+73.92` | `+691.74` | `+262.02` | `-122.22` | `1` | `30.9408` |

Month-filter bypass summary:

| Profile | Total Net | Active Windows | Losing Windows | Trades | Worst Equity DD % |
| --- | ---: | ---: | ---: | ---: | ---: |
| `current` | `+508.07` | `3` | `0` | `6` | `30.9408` |
| `highpa_q5_pa24` | `+508.07` | `3` | `0` | `6` | `30.9408` |
| `fsd_q6_pa18` | `+434.29` | `6` | `3` | `9` | `30.9408` |
| `combo` | `+434.29` | `6` | `3` | `9` | `30.9408` |

Decision:

Do not promote. FSD bypass added losing trades; high-price-action bypass changed nothing; March/May risk scaling either reduced continuous profit or introduced losing windows.

Research note:

`research/2026-07-12-block-diagnostics-and-risk-shape-note.md`

Liquidity-stop extension variants were tested on 2026-07-12 and rejected.

Summary:

| Profile | Parsed | Active Windows | Zero-Trade Windows | Total Net | Losing Windows | Total Trades | Worst Equity DD % |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `lowatr_current` | `12 / 12` | `3` | `9` | `+508.07` | `0` | `6` | `30.9408` |
| `lstop_cluster` | `12 / 12` | `3` | `9` | `+387.68` | `0` | `5` | `31.7511` |
| `lstop_cluster_pocket` | `12 / 12` | `3` | `9` | `+122.50` | `0` | `5` | `29.0642` |
| `lstop_prevday` | `12 / 12` | `2` | `10` | `-90.55` | `1` | `2` | `16.4294` |

Decision:

Do not promote. The current base liquidity-aware structure stop is already active and remains better than the extra cluster / previous-day / pocket extensions.

Research note:

`research/2026-07-12-liquidity-stop-extension-probe-note.md`

Flat-month wake-up and flat-month probe-mode reality checks were tested on 2026-07-12 and rejected.

Summary:

| Profile | Parsed | Active Windows | Zero-Trade Windows | Total Net | Losing Windows | Total Trades | Worst Equity DD % |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `lowatr_current` | `12 / 12` | `3` | `9` | `+508.07` | `0` | `6` | `30.9408` |
| `fmw_wake_strict` | `12 / 12` | `3` | `9` | `+508.07` | `0` | `6` | `30.9408` |
| `fmw_wake_balanced` | `12 / 12` | `3` | `9` | `+508.07` | `0` | `6` | `30.9408` |
| `fmw_stale_elite` | `12 / 12` | `3` | `9` | `+508.07` | `0` | `6` | `30.9408` |
| `fmp_strict_low_risk` | `12 / 12` | `3` | `9` | `+453.17` | `0` | `6` | `30.9408` |
| `fmp_quality_ramp` | `12 / 12` | `3` | `9` | `+453.17` | `0` | `6` | `30.9408` |
| `fmp_tiny_discovery` | `12 / 12` | `2` | `10` | `+444.02` | `0` | `5` | `30.9408` |

Decision:

Do not promote. Wake-up tied current; probe-mode reduced existing winners and did not create useful new flat-month trades.

Research notes:

- `research/2026-07-12-flat-month-wakeup-probe-note.md`
- `research/2026-07-12-flat-month-probe-mode-reality-note.md`

Flat-month micro-reversion expansion was tested on 2026-07-12 and rejected.

Summary:

| Profile | Parsed | Active Windows | Zero-Trade Windows | Total Net | Losing Windows | Total Trades | Worst Equity DD % |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `lowatr_current` | `12 / 12` | `3` | `9` | `+508.07` | `0` | `6` | `30.9408` |
| `fmr_expand_strict` | `12 / 12` | `4` | `8` | `+484.43` | `1` | `7` | `30.9408` |
| `fmr_expand_soft` | `12 / 12` | `5` | `7` | `+477.12` | `2` | `8` | `30.9408` |

Decision:

Do not promote. The expanded candidates increased activity, but the added trades were losers in `2025_04` and `2026_01`.

Research note:

`research/2026-07-12-flat-month-micro-reversion-expansion-probe-note.md`

Flat-month breakout structural and activation probes were tested on 2026-07-12 and rejected.

Summary:

| Profile | Parsed | Active Windows | Zero-Trade Windows | Total Net | Losing Windows | Total Trades | Worst Equity DD % |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `lowatr_current` | `12 / 12` | `3` | `9` | `+508.07` | `0` | `6` | `30.9408` |
| `fmb_struct_conservative` | `12 / 12` | `3` | `9` | `+508.07` | `0` | `6` | `30.9408` |
| `fmb_struct_balanced` | `12 / 12` | `3` | `9` | `+508.07` | `0` | `6` | `30.9408` |
| `fmb_activation_tape` | `12 / 12` | `3` | `9` | `+508.07` | `0` | `6` | `30.9408` |
| `fmb_activation_loose` | `12 / 12` | `5` | `7` | `+490.65` | `2` | `8` | `30.9408` |
 
Decision:

Do not promote. Conservative and balanced FMB tied current; loose activation created extra trades but lowered total net and added losing windows.

Research notes:

- `research/2026-07-12-flat-month-breakout-structural-probe-note.md`
- `research/2026-07-12-flat-month-breakout-activation-probe-note.md`

Flat-month FSD efficiency relaxation was tested on 2026-07-12 and rejected.

Summary:

| Profile | Parsed | Active Windows | Zero-Trade Windows | Total Net | Total Trades | Worst Equity DD % |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `lowatr_current` | `12 / 12` | `3` | `9` | `+508.07` | `6` | `30.9408` |
| `fsd_relaxed_48h` | `12 / 12` | `3` | `9` | `+508.07` | `6` | `30.9408` |
| `fsd_relaxed_24h` | `12 / 12` | `3` | `9` | `+508.07` | `6` | `30.9408` |

Decision:

Do not promote. The relaxation did not add active windows, reduce zero-trade windows, or improve net profit.

Research note:

`research/2026-07-12-fsd-efficiency-relaxation-probe-note.md`
