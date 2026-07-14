# Current Research Best Profile

Last updated: 2026-07-14.

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

Most recent reproduced continuous check before the trade-environment guard source update:

Return math uses a `$1,000` starting balance and CAGR over `2024.01.01` to `2026.07.12` (`2.53` years).

| Profile | Continuous | Total Return | CAGR/yr | 2024 Full | 2025 Full | 2026 YTD | Worst Equity DD % |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `dec_islp_off` | `+1,195.04` | `+119.50%` | `+36.49%/yr` | `+1,340.55` | `+214.30` | `+955.21` | `28.2997` |
| `islp_lowatr_of` | `+1,195.69` | `+119.57%` | `+36.51%/yr` | `+1,353.53` | `+214.30` | `+955.21` | `28.2785` |

The older `+4,507.51` Dec-ISLP-Off Model4 continuous result equals `+450.75%` total and about `+96.43%/yr` CAGR from a `$1,000` start, but it is now treated as historical/stale until it is reproduced on the current local source and compact tester path.

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
- The most recent reproduced continuous Model4 check is only `+1,195.69` (`+119.57%` total, `+36.51%/yr` CAGR); the historical `+4,507.51` continuous headline needs reproduction before it should be used as the current headline.
- After that continuous check, the local source changed again to add the trade-environment guard and update candidate profile hashes. No new backtest has promoted source hash `5D148DAE2335F9037BDED3C9A82BD916C1FCFB6F43EE2EC5EAAE7E67384ED412` yet.
- Hold-time stats still need richer extraction.
- Model1 and Model2 have not yet been rerun on this LowATR OrderFlow candidate.
- Local `Professional_XAUUSD_EA.mq5` is ahead of the GitHub source and contains newer default-off flat-month probe/wake-up infrastructure.
- The local workspace is not currently a valid Git checkout because `.git` exists but is empty.

Adaptive Reverse remains disabled and is now source-quarantined against accidental stop-and-reverse research reuse. If it is manually re-enabled for a future experiment, the default guard chain now also blocks alternating guarded reverse-loss whipsaws and requires a deferred displacement break followed by a controlled retest/hold of the broken level.

## Latest Default-Off Research Code

On 2026-07-13, the EA source gained a new default-off Flat Month Liquidity Reclaim lane tagged `FMLR;`.

Status:

- Not part of the current research-best profile.
- Not promoted.
- Not backtested yet.
- Added to both `Professional_XAUUSD_EA.mq5` and `outputs/Professional_XAUUSD_EA.mq5`.
- Offline package builder: `work/build_flat_month_liquidity_reclaim_probe_package.ps1`.
- Fast screen builder: `work/build_flat_month_liquidity_reclaim_fast_probe_package.ps1`, which prepares `162` Model4 configs before spending time on the full `480`-config package.
- Superseded default-off addition: optional FMLR failed-breakout trap was added as isolated profile `fmlr_failed_breakout_trap`, alongside the existing FMLR liquidity-reclaim, structural-retest, runner, and stop-pocket profiles. It fades a failed compression-box break only after snapback/reclaim confirmation, optional volume expansion, range-phase gating, forward target checks, and a stop behind the failed-break wick/box structure. Adaptive Reverse remains quarantined. Current FMLR packages now prepare `480` full configs and `162` fast configs after the later tick-speed and activity-blend package additions.
- No-new-input target refinement: failed-breakout traps now return the opposite side of the failed-break box as a structural range target and log `FMLR failed breakout target` / `FMLR failed breakout range target` when used.
- No-new-input target-priority refinement: generic FMLR liquidity targets no longer overwrite an accepted failed-breakout box target; the EA logs `FMLR liquidity target preserved` when that priority rule is active.
- No-new-input target-fallback refinement: if the failed-breakout box target is too close to satisfy the range-target minimum, the setup can use the existing forward-liquidity target instead of being rejected immediately. The EA logs `FMLR failed breakout target fallback` when this path is used.
- No-new-input forward-target selector refinement: `FlatMonthLiquidityReclaimForwardLiquidityDistance` now applies `minTargetDistance` before selecting the nearest target candidate, so a too-close liquidity level does not block a farther valid target.
- No-new-input forward-clearance selector refinement: the same helper now accepts `minimumCandidateDistance`, and the FMLR clearance gate passes its minimum clearance distance through it so a too-close level does not block a farther valid clearance level.
- No-new-input forward-RR target refinement: if structural stop widening makes an FMLR setup fail minimum RR, the EA can use an existing forward-liquidity target to repair RR only when that target still satisfies `InpFlatMonthLiquidityReclaimMinRR`; the EA logs `FMLR forward RR target`.
- No-new-input structural-target fallback refinement: if an HTF, opening-range, VWAP-deviation, or range-failure structural target is invalid or too close, the setup can use an existing valid forward-liquidity target instead of rejecting immediately. If no valid fallback exists, the original structural-target rejection remains; the EA logs `FMLR structural target fallback`.
- No-new-input structural-target priority refinement: if an HTF, opening-range, VWAP-deviation, or range-failure structural target is accepted, a generic forward-liquidity target can extend it when farther but cannot shrink it when closer; the EA logs `FMLR structural target preserved` or `FMLR structural target extended`.
- No-new-input protected-runner target-path refinement: FMLR runner-stretch protection now uses the shared `structuralTargetAccepted` flag instead of a duplicated structural-target list, so accepted VWAP-deviation structural targets count as protected runner paths.
- No-new-input runner-phase consistency refinement: FMLR runner phase permission now reuses the shared `structuralRunnerSetup` flag instead of a duplicated setup list, so session-range and compression breakout runner setups are not excluded by stale phase-gate logic.
- No-new-input structural-target runner eligibility refinement: accepted HTF, opening-range, VWAP-deviation, range-failure, and failed-breakout structural targets now qualify as `structuralTargetRunnerSetup` under the existing runner-stretch controls; the EA logs `FMLR structural target runner`.
- No-new-input structural-target unlimited-runner refinement: `FlatMonthLiquidityReclaimUnlimitedRunnerAllows` keeps the original strict sweep runner path and adds a structural-target runner path that requires both `FMLR structural target runner` and `FMLR forward clearance` evidence before allowing the no-fixed-TP FMLR runner.
- No-new-input unlimited-runner stretch-evidence refinement: FMLR no-fixed-TP runner permission now requires `runnerStretchEvidence`, meaning either `FMLR runner target stretch` or `FMLR runner liquidity stretch` must be present in the signal before the unlimited runner can open.
- No-new-input structure-trail broker-distance refinement: confirmed-swing FMLR structure trails now use `structureTrailMinDistance = MinimumBrokerStopDistance()` before accepting a trail stop, matching fallback-lock broker-distance realism.
- No-new-input structural-fallback runner refinement: structural-target fallback setups that use a valid forward-liquidity target can now qualify as protected structural runner setups; the EA logs `FMLR structural fallback runner` before the shared structural-runner marker when this path participates.
- No-new-input FMLR catch-up threshold refinement: `activeFmlrMinScore` and the active FMLR minimum RR now use the existing flat-month, catch-up, and late-catch-up discounts inside the FMLR lane itself; the EA logs `FMLR active min score` and `FMLR active min RR` when the lane threshold is relaxed.
- No-new-input FMLR catch-up risk refinement: `ActiveFlatMonthLiquidityReclaimRiskMultiplier()` lets FMLR ramp from `InpFlatMonthLiquidityReclaimRiskMultiplier` toward the existing `InpFlatMonthProbeRiskMultiplier` cap only when the existing catch-up risk ramp/protected-floor/liquid-session gates allow it; the EA logs `FMLR active risk x`. The isolated `fmlr_catch_up_risk` package profile now tests this path in the 480-config full package and the 162-config fast screen.
- No-new-input FMLR equal-level stop-pool refinement: if an equal-high/low structural stop anchor is selected and the existing FMLR stop-cluster buffer is enabled, the EA treats that two-touch level as liquidity-pool evidence and can add the existing extra stop buffer before RR is checked; the EA logs `FMLR equal-level stop pool`. Source hash: `24698D8AB5D799275958AF9369EF6949D114F12DE5E2013BC423F655DDEC4ABA`.
- No-new-input FMLR catch-up cadence refinement: FMLR now computes catch-up/late-catch-up state before checking lane cap and spacing. Existing late-catch-up controls can raise the active FMLR monthly cap, and catch-up progress can reduce active FMLR spacing by up to 50% with a 30-minute floor; the EA logs `FMLR active monthly cap` and `FMLR active spacing`. Source hash: `842EB39FC61E3FC1329DB7F272F65D6B722AA556CF7C04D77DD15C6335A769BD`.
- No-new-input shared structure-stop refinement: equal-high/low liquidity stop anchors now pass confirmed equal-level evidence into the shared `LiquidityClusterAdjustedBuffer()` helper, so the broader `StructureStopDistance()` path can use the existing cluster extra buffer without re-proving the same two-touch pool. Source hash: `E83C7A92A8757B100361A9A17CFB6445102CD5D6DE3E87F6C323CF61516457E3`.
- No-new-input shared previous-period stop-pocket refinement: `LiquidityPocketStopLevel()` now also checks enabled previous-day/week/month liquidity stop levels when the existing liquidity-pocket stop shift is active. This lets shared structural stops move beyond higher-timeframe liquidity pockets instead of sitting inside them. Source hash: `778E168D96A8185FBA8781210794A6B4547341D4D95F0470134EAC4E5F72C38F`.
- No-new-input FMLR protected-loss catch-up refinement: FMLR can request a protected catch-up version of the flat-month opportunity gate during shallow red months, while normal flat-month lanes still honor `InpFlatMonthRequireNoMonthlyLoss`. The exception is capped by existing monthly-loss/catch-up settings and still respects protected-floor and liquid-session requirements; the EA logs `FMLR protected loss catch-up`. Source hash: `686F80DA9CB4DE36E564C47A5C3AE4B5A6CAF62B8BF90250729E9FF751602CDF`.
- No-new-input FMLR sweep-runner target refinement: non-structural liquidity-sweep reclaims can now use the existing runner-target stretch path when forward liquidity, sweep evidence, and quality confirmation exist; the EA logs `FMLR sweep runner` only when the target actually stretches. Source hash: `10D1007CFD4CB124C8DE6EC247E1DE1611F1A7955E4E8EC2F9816B2A238DFA04`.
- No-new-input FMLR sweep-runner package refinement: added isolated `fmlr_sweep_runner` validation profile to exercise the non-structural sweep-runner payoff path without requiring sweep-displacement BOS. Superseded package size after the sweep-unlimited runner addition: full package `444` Model4 configs / `37` profiles; fast screen `144` Model4 configs / `24` profiles.
- No-new-input FMLR sweep unlimited runner refinement: no-fixed-TP FMLR runner permission now recognizes proven non-structural sweep-runner setups when forward clearance, runner-stretch evidence, and FMLR structure trailing are present. The entry log can add `FMLR sweep unlimited runner`. Added isolated `fmlr_sweep_unlimited_runner` package profile.
- Default-off FMLR tick-speed reclaim refinement: FMLR can now tag `FMLR tick-speed reclaim` when an existing sweep/reclaim context is followed by a directional tick-speed impulse through `InpUseTickSpeedImpulse`. Added isolated `fmlr_tick_speed_reclaim` package profile. Source hash: `B6AA1915D2CA7483B1066C227F2506D7A85756D918820FF1100BAF66B0FBDBBE`.
- FMLR flat-month activity-blend package refinement: added `fmlr_activity_blend` and `fmlr_activity_blend_tight` package profiles. They combine already-protected FMLR structural triggers at tiny risk, require order flow, forward clearance, liquidity targets, stop-pocket/cluster structural stops, and keep Adaptive Reverse disabled. No MT5 profit result yet.
  - `outputs/CANDIDATE_FMLR_ACTIVITY_BLEND_PROFILE.set`: `149481621EC3194A08CF2B291033FEA38AE7D40B1EDA677820780A51F9A9DBDB`
  - `outputs/CANDIDATE_FMLR_ACTIVITY_BLEND_TIGHT_PROFILE.set`: `50F2000B153458B5DB494DD6AA873BDD6256F2C8B3AE11BABE5E4C615E2BC67A`
- Money-ready demo/forward-test candidate: `outputs/CANDIDATE_MONEY_READY_PROFILE.set`, SHA-256 `553A967B5FCE72AF31126A78CFDCDA035A953BF55D9DBEB8F56D64D723C3AE3E`. The alias `outputs/CANDIDATE_TRADE_READINESS_PROFILE.set` has the same hash. This candidate enables the EA symbol, trade-readiness, real-account, and trade-environment safety gates, caps risk at `0.50%`, caps open risk at `0.75%`, caps lots at `0.05`, allows one position, blocks real-account trading by default, keeps Adaptive Reverse/FMLR/tick-speed experiments off, stamps evidence identity, keeps live approval identity disabled, and requires spread, trading-cost, margin, loss, profit-giveback, break-even, ATR trailing, MFE protection, sane symbol specs, fresh quotes, and available tick value. This is demo/forward-test only and does not replace the current research-best profile.
- Conservative trade-ready candidate: `outputs/CANDIDATE_TRADE_READY_CONSERVATIVE_PROFILE.set`, SHA-256 `82530801102198E81E08E1EF772D5501B52FB88CCFD67E6651CE32EF1D055665`. The first-pass validation queue, next-run package, and parallel lanes were rebuilt on 2026-07-14 from this current profile hash.
- Source-level trade-readiness safety gate: `InpUseTradeReadinessSafetyGate` refuses initialization when enabled if the profile is loosened past configured risk/spread/margin/exit caps. `TradeEnvironmentAllows()` blocks new entries when enabled if quotes, history, symbol specs, trade mode, broker stop/freeze levels, or tick value are unsafe. `SymbolSafetyLockAllows()` blocks wrong-symbol initialization, and `RealAccountSafetyLockAllows()` blocks real-account initialization unless explicit approval code, approval profile id, approval source hash, evidence profile id/source hash, evidence run label, and trade-readiness gate requirements are all satisfied. Current source hash: `5D148DAE2335F9037BDED3C9A82BD916C1FCFB6F43EE2EC5EAAE7E67384ED412`.
- Evidence identity refinement: trade logs now include `profile_id`, `source_hash`, and `run_label`; conservative returned logs are expected to prove `profile_id=trade_ready_conservative` and `source_hash=5D148DAE2335F9037BDED3C9A82BD916C1FCFB6F43EE2EC5EAAE7E67384ED412` before trade-quality or Monte Carlo evidence is trusted.
- Money-ready audit: `outputs/MONEY_READY_PROFILE_AUDIT.md` reports `79` guardrail/prep checks passing, `0` critical failures, and `4` open proof gaps: exact Model4 real-tick backtest, forward test, Monte Carlo execution stress, and broker-variation testing.
- Money-ready validation package: `outputs/money_ready_validation_package` is prepared with `53` staged configs: `4` fast Model1 checks, `4` exact Model4 continuous/year-split checks, `11` real-tick quarterly checks, `31` real-tick monthly checks, and `3` real-tick stress variants. This package is not run yet because the local MT5 launch lock remains active.
- Money-ready broker-proxy package: `outputs/money_ready_broker_proxy_package` is prepared with `10` Model4 configs across base, wide-spread, high-commission, tight-slippage, and margin-pressure proxies. This approximates broker variation through EA cost/spread/margin inputs but still does not replace testing on another broker's actual XAUUSD contract.
- Money-ready decision gate: `outputs/MONEY_READY_VALIDATION_DECISION.md` is currently `PENDING` with `1` passing prep gate, `16` pending result gates, and `0` failures because `outputs/MONEY_READY_VALIDATION_RESULTS.csv` and `outputs/MONEY_READY_BROKER_PROXY_RESULTS.csv` have not been returned yet. The gate will fail automatically on red exact Model4 splits, red quarterly/monthly windows, stress losses, broker-proxy losses, drawdown above `10%`, weak PF/recovery, or too few continuous trades.
- Conservative trade-ready Monte Carlo gate: `outputs/TRADE_READY_CONSERVATIVE_MONTE_CARLO.md` is prepared and currently `PENDING` with `1000` seeded trials, `0` returned trade-log files, `0` R trades, `3` pending gates, and `0` failures. It will stress returned conservative logs by shuffling trade order and applying slippage, delay, spread-shock, and missed-winner degradation.
- Conservative trade-ready external evidence gates: `outputs/TRADE_READY_CONSERVATIVE_FORWARD_TEST.md` and `outputs/TRADE_READY_CONSERVATIVE_SECOND_BROKER_DECISION.md` are prepared and currently `PENDING` with `0` returned evidence rows. They evaluate returned CSV evidence only and do not launch MT5.
- Conservative trade-ready live-readiness gate: `outputs/TRADE_READY_LIVE_READINESS_DECISION.md` is the final approval gate for the conservative candidate and is currently `PENDING` with `5` passing gates, `8` pending gates, and `0` failures. It does not unlock real-account trading; it requires current-source compile proof, full validation, trade quality, Monte Carlo, forward/demo, second-broker, safety, local reproducibility freeze, and GitHub/source-publication sync evidence. The publication sync evidence now lives in `outputs/GITHUB_PUBLICATION_SYNC.md` and is still `PENDING`.
- Compact-source prep: `work/prepare_flat_month_liquidity_reclaim_compact_source.ps1`.
- Source smoke: `PRICE_ACTION_STRATEGY_MODULES_SMOKE_PASS`.
- Source/artifact sync smoke: `EA_SOURCE_ARTIFACT_SYNC_SMOKE_PASS`.
- Package-builder smoke: `FLAT_MONTH_LIQUIDITY_RECLAIM_PROBE_PACKAGE_SMOKE_PASS`.
- Fast package-builder smoke: `FLAT_MONTH_LIQUIDITY_RECLAIM_FAST_PROBE_PACKAGE_SMOKE_PASS`.
- Compact-source smoke: `FLAT_MONTH_LIQUIDITY_RECLAIM_COMPACT_SOURCE_SMOKE_PASS`.
- Adaptive Reverse quarantine smoke: `ADAPTIVE_REVERSE_QUARANTINE_SMOKE_PASS`.
- Monte Carlo trade-stress smoke: `MONTE_CARLO_TRADE_STRESS_SMOKE_PASS`.
- External evidence smoke: `TRADE_READY_EXTERNAL_EVIDENCE_SMOKE_PASS`.
- Trade-ready live-readiness smoke: `TRADE_READY_LIVE_READINESS_SMOKE_PASS`.
- Hidden-launcher lock smoke: `MT5_HIDDEN_LAUNCHER_LOCK_SMOKE_PASS`.
- MT5 local safety audit: `PASS 39 / 39`.
- Compile/backtest: pending while `work/MT5_LOCAL_LAUNCH_DISABLED.lock` remains active.

Research note:

`research/2026-07-13-flat-month-liquidity-reclaim-lane-note.md`

Additional source-refinement note:

`research/2026-07-13-fmlr-structure-trail-broker-distance-note.md`

`research/2026-07-13-fmlr-structural-fallback-runner-note.md`

`research/2026-07-13-fmlr-catch-up-threshold-note.md`

`research/2026-07-13-fmlr-catch-up-risk-note.md`

Structural-stop note:

`research/2026-07-13-fmlr-structural-stop-pocket-note.md`

Session/Asian reclaim note:

`research/2026-07-13-fmlr-session-asian-reclaim-note.md`

Equal-level reclaim note:

`research/2026-07-13-fmlr-equal-level-reclaim-note.md`

Swing-sweep reclaim note:

`research/2026-07-13-fmlr-swing-sweep-reclaim-note.md`

Previous-period reclaim note:

`research/2026-07-13-fmlr-previous-period-reclaim-note.md`

Daily-open reclaim note:

`research/2026-07-13-fmlr-daily-open-reclaim-note.md`

Higher-open reclaim note:

`research/2026-07-13-fmlr-higher-open-reclaim-note.md`

Open stop-pocket note:

`research/2026-07-13-fmlr-open-stop-pocket-note.md`

Open liquidity target note:

`research/2026-07-13-fmlr-open-liquidity-target-note.md`

Continuation-retest note:

`research/2026-07-13-fmlr-continuation-retest-note.md`

Compression-breakout note:

`research/2026-07-13-fmlr-compression-breakout-note.md`

Session-range breakout note:

`research/2026-07-13-fmlr-session-range-breakout-note.md`

Opening-range reclaim note:

`research/2026-07-13-fmlr-opening-range-reclaim-note.md`

VWAP-deviation reclaim note:

`research/2026-07-13-fmlr-vwap-deviation-reclaim-note.md`

Fast validation package note:

`research/2026-07-13-fmlr-fast-validation-package-note.md`

Engulfing-reclaim note:

`research/2026-07-13-fmlr-engulfing-reclaim-note.md`

Tick-pressure reclaim note:

`research/2026-07-13-fmlr-tick-pressure-reclaim-note.md`

Breakout-retest note:

`research/2026-07-13-fmlr-breakout-retest-note.md`

Failed-breakout-trap note:

`research/2026-07-13-fmlr-failed-breakout-trap-note.md`

Sweep-displacement BOS note:

`research/2026-07-13-fmlr-sweep-displacement-bos-note.md`

Range-failure reclaim note:

`research/2026-07-13-fmlr-range-failure-reclaim-note.md`

HTF liquidity reclaim note:

`research/2026-07-13-fmlr-htf-liquidity-reclaim-note.md`

Imbalance-continuation note:

`research/2026-07-13-fmlr-imbalance-continuation-note.md`

Runner-target stretch note:

`research/2026-07-13-fmlr-runner-target-stretch-note.md`

Sweep-runner package profile note:

`research/2026-07-13-fmlr-sweep-runner-profile-note.md`

Sweep unlimited runner note:

`research/2026-07-13-fmlr-sweep-unlimited-runner-note.md`

Structural-runner trail note:

`research/2026-07-13-fmlr-structural-runner-trail-note.md`

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
