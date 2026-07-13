# Flat Month Liquidity Reclaim Lane Note

Date: 2026-07-13

Status: code-only, default-off, not promoted.

## Intent

The current research-best profile still leaves too many weak/flat windows with no trades. Prior attempts to loosen flat-month behavior either tied the current profile or added losing windows.

This change adds a different entry mechanism instead of only relaxing old filters:

- Require a liquidity sweep and reclaim on the prior signal candle.
- Require rejection wick and close-location strength.
- Optionally require VWAP reclaim.
- Optionally require order-flow confirmation.
- Use a direct structural stop beyond the swept liquidity level.
- Optionally target the nearest opposing forward liquidity instead of a fixed ATR take-profit.
- Optionally trade a retest after a recent sweep/reclaim instead of requiring the sweep to happen only on the immediately previous candle.
- Optionally require enough forward room toward session or Asian-range liquidity before taking the retest.
- Optionally use FVG/order-block retests as a controlled substitute when tick/order-flow confirmation is missing.
- Optionally target confirmed swing highs/lows as forward liquidity instead of using only ATR distance.
- Optionally require phase alignment so the lane can distinguish trend pullbacks, range reclaims, and transition noise.
- Optionally widen stops around clustered liquidity and shift stops beyond nearby stop pockets.
- Optionally require a continuation retest after the sweep/reclaim, with EMA/VWAP hold controls and a max pullback distance.
- Optionally allow a tight compression-box breakout as a substitute setup, with the stop anchored beyond the opposite side of the box.
- Optionally allow an Asian/rolling session-range breakout as a substitute setup, with the stop anchored beyond the opposite side of the selected range.

## New Lane

Tag:

`FMLR;`

Primary switch:

`InpUseFlatMonthLiquidityReclaimLane=false`

Key controls:

- `InpFlatMonthLiquidityReclaimRiskMultiplier=0.20`
- `InpFlatMonthLiquidityReclaimMaxMonthlyEntries=4`
- `InpFlatMonthLiquidityReclaimSpacingMinutes=360`
- `InpFlatMonthLiquidityReclaimMinScore=6`
- `InpFlatMonthLiquidityReclaimRequireLiquidSession=true`
- `InpFlatMonthLiquidityReclaimRequireOrderFlow=true`
- `InpFlatMonthLiquidityReclaimUseImbalanceRetest=false`
- `InpFlatMonthLiquidityReclaimRequireImbalanceRetest=false`
- `InpFlatMonthLiquidityReclaimAllowImbalanceInsteadOfOrderFlow=false`
- `InpFlatMonthLiquidityReclaimImbalanceLookbackBars=18`
- `InpFlatMonthLiquidityReclaimRequireVWAPReclaim=false`
- `InpFlatMonthLiquidityReclaimLookbackBars=18`
- `InpFlatMonthLiquidityReclaimMinWickPercent=32.0`
- `InpFlatMonthLiquidityReclaimMinCloseLocation=0.58`
- `InpFlatMonthLiquidityReclaimStopBufferATR=0.14`
- `InpFlatMonthLiquidityReclaimStopBufferPoints=30.0`
- `InpFlatMonthLiquidityReclaimTakeProfitATR=1.20`
- `InpFlatMonthLiquidityReclaimMinRR=0.90`
- `InpFlatMonthLiquidityReclaimUseEqualLevels=true`
- `InpFlatMonthLiquidityReclaimUsePreviousDay=true`
- `InpFlatMonthLiquidityReclaimUsePreviousWeek=false`
- `InpFlatMonthLiquidityReclaimUseLiquidityTarget=false`
- `InpFlatMonthLiquidityReclaimTargetUseEqualLevels=true`
- `InpFlatMonthLiquidityReclaimTargetUsePreviousDay=true`
- `InpFlatMonthLiquidityReclaimTargetUsePreviousWeek=false`
- `InpFlatMonthLiquidityReclaimTargetUseSessionRange=false`
- `InpFlatMonthLiquidityReclaimTargetSessionLookbackHours=8`
- `InpFlatMonthLiquidityReclaimTargetUseAsianRange=false`
- `InpFlatMonthLiquidityReclaimTargetUseSwingLevels=false`
- `InpFlatMonthLiquidityReclaimSwingLookbackBars=48`
- `InpFlatMonthLiquidityReclaimSwingLeftBars=2`
- `InpFlatMonthLiquidityReclaimSwingRightBars=2`
- `InpFlatMonthLiquidityReclaimRequireForwardClearance=false`
- `InpFlatMonthLiquidityReclaimMinClearanceATR=0.90`
- `InpFlatMonthLiquidityReclaimMinTargetATR=0.80`
- `InpFlatMonthLiquidityReclaimMaxTargetATR=2.40`
- `InpFlatMonthLiquidityReclaimAllowRecentRetest=false`
- `InpFlatMonthLiquidityReclaimRetestLookbackBars=5`
- `InpFlatMonthLiquidityReclaimRetestToleranceATR=0.18`
- `InpFlatMonthLiquidityReclaimRetestTolerancePoints=40.0`
- `InpFlatMonthLiquidityReclaimRetestMinBodyPercent=20.0`
- `InpFlatMonthLiquidityReclaimUseContinuationRetest=false`
- `InpFlatMonthLiquidityReclaimRequireContinuationRetest=false`
- `InpFlatMonthLiquidityReclaimContinuationLookbackBars=8`
- `InpFlatMonthLiquidityReclaimContinuationMaxPullbackATR=0.65`
- `InpFlatMonthLiquidityReclaimContinuationMinBodyPercent=24.0`
- `InpFlatMonthLiquidityReclaimContinuationRequireEMAHold=false`
- `InpFlatMonthLiquidityReclaimContinuationRequireVWAPHold=false`
- `InpFlatMonthLiquidityReclaimUseCompressionBreakout=false`
- `InpFlatMonthLiquidityReclaimRequireCompressionBreakout=false`
- `InpFlatMonthLiquidityReclaimCompressionLookbackBars=14`
- `InpFlatMonthLiquidityReclaimCompressionMaxRangeATR=1.05`
- `InpFlatMonthLiquidityReclaimCompressionBreakBufferPoints=15.0`
- `InpFlatMonthLiquidityReclaimCompressionMinBodyPercent=40.0`
- `InpFlatMonthLiquidityReclaimCompressionMinCloseLocation=0.62`
- `InpFlatMonthLiquidityReclaimCompressionMinBreakRangeATR=0.45`
- `InpFlatMonthLiquidityReclaimUseSessionRangeBreakout=false`
- `InpFlatMonthLiquidityReclaimRequireSessionRangeBreakout=false`
- `InpFlatMonthLiquidityReclaimSessionBreakoutUseAsianRange=true`
- `InpFlatMonthLiquidityReclaimSessionBreakoutUseRollingRange=true`
- `InpFlatMonthLiquidityReclaimSessionBreakoutLookbackHours=6`
- `InpFlatMonthLiquidityReclaimSessionBreakoutMaxRangeATR=1.25`
- `InpFlatMonthLiquidityReclaimSessionBreakoutBufferPoints=20.0`
- `InpFlatMonthLiquidityReclaimSessionBreakoutMinBodyPercent=38.0`
- `InpFlatMonthLiquidityReclaimSessionBreakoutMinCloseLocation=0.62`
- `InpFlatMonthLiquidityReclaimSessionBreakoutMinBreakRangeATR=0.45`
- `InpFlatMonthLiquidityReclaimUsePhaseGate=false`
- `InpFlatMonthLiquidityReclaimAllowTrendPhase=true`
- `InpFlatMonthLiquidityReclaimAllowRangePhase=true`
- `InpFlatMonthLiquidityReclaimAllowTransitionPhase=true`
- `InpFlatMonthLiquidityReclaimTrendRequireEMASlope=true`
- `InpFlatMonthLiquidityReclaimPhaseLookbackBars=18`
- `InpFlatMonthLiquidityReclaimTrendMinADX=21.0`
- `InpFlatMonthLiquidityReclaimRangeMaxADX=18.0`
- `InpFlatMonthLiquidityReclaimTrendMinSlopePoints=25.0`
- `InpFlatMonthLiquidityReclaimRangeMaxNetMoveATR=1.15`
- `InpFlatMonthLiquidityReclaimRangeMinAlternationPercent=45.0`
- `InpFlatMonthLiquidityReclaimUseStopClusterBuffer=false`
- `InpFlatMonthLiquidityReclaimStopClusterMinTouches=3`
- `InpFlatMonthLiquidityReclaimStopClusterProximityATR=0.20`
- `InpFlatMonthLiquidityReclaimStopClusterProximityPoints=50.0`
- `InpFlatMonthLiquidityReclaimStopClusterExtraBufferATR=0.10`
- `InpFlatMonthLiquidityReclaimStopClusterExtraBufferPoints=30.0`
- `InpFlatMonthLiquidityReclaimUseStopPocketShift=false`
- `InpFlatMonthLiquidityReclaimStopPocketLookbackBars=24`
- `InpFlatMonthLiquidityReclaimStopPocketProximityATR=0.18`
- `InpFlatMonthLiquidityReclaimStopPocketProximityPoints=45.0`
- `InpFlatMonthLiquidityReclaimStopPocketBufferATR=0.22`
- `InpFlatMonthLiquidityReclaimStopPocketBufferPoints=55.0`

Month-filter bypass controls were also added but default off:

- `InpAllowFlatMonthLiquidityReclaimOutsideMonthFilter=false`
- `InpFlatMonthLiquidityReclaimBypassMinQualityScore=7`
- `InpFlatMonthLiquidityReclaimBypassMinPriceActionScore=0`
- `InpFlatMonthLiquidityReclaimBypassRequireLiquidSession=true`

## Validation

Completed local checks:

- `work/test_price_action_strategy_modules.ps1`: `PRICE_ACTION_STRATEGY_MODULES_SMOKE_PASS`
- `work/test_flat_month_liquidity_reclaim_probe_package.ps1`: `FLAT_MONTH_LIQUIDITY_RECLAIM_PROBE_PACKAGE_SMOKE_PASS`
- `work/test_flat_month_liquidity_reclaim_compact_source.ps1`: `FLAT_MONTH_LIQUIDITY_RECLAIM_COMPACT_SOURCE_SMOKE_PASS`
- `work/test_adaptive_reverse_quarantine.ps1`: `ADAPTIVE_REVERSE_QUARANTINE_SMOKE_PASS`
- `work/audit_mt5_local_safety.ps1`: `PASS`, `39 / 39`
- Root and canonical EA copies match: `Professional_XAUUSD_EA.mq5` equals `outputs/Professional_XAUUSD_EA.mq5`

Offline validation package builder:

- `work/build_flat_month_liquidity_reclaim_probe_package.ps1`
- Default package path: `outputs/flat_month_liquidity_reclaim_probe_package`
- Default manifest: `outputs/FLAT_MONTH_LIQUIDITY_RECLAIM_PROBE_MANIFEST.csv`
- Compact-source prep: `work/prepare_flat_month_liquidity_reclaim_compact_source.ps1`
- Default compact source: `outputs/FLAT_MONTH_LIQUIDITY_RECLAIM_COMPACT.mq5`
- Default compact audit: `outputs/FLAT_MONTH_LIQUIDITY_RECLAIM_COMPACT_AUDIT.csv`
- Profiles prepared for later MT5 execution:
  - `lowatr_current`
  - `fmlr_conservative`
  - `fmlr_balanced`
  - `fmlr_vwap_discovery`
  - `fmlr_liquidity_target`
  - `fmlr_recent_retest`
  - `fmlr_session_target`
  - `fmlr_imbalance_retest`
  - `fmlr_swing_target`
  - `fmlr_phase_aligned`
  - `fmlr_structural_stop`
  - `fmlr_continuation_retest`
  - `fmlr_compression_breakout`
  - `fmlr_session_range_breakout`
- Windows prepared: 12 weak/flat/control windows from 2024-2026, now `168` configs total.

Compact-source safeguard:

- Required FMLR inputs are preserved as optimizer-visible `input` values.
- The forward-liquidity target controls are preserved for the `fmlr_liquidity_target` profile.
- The recent-sweep retest controls are preserved for the `fmlr_recent_retest` profile.
- The session/Asian forward-clearance controls are preserved for the `fmlr_session_target` profile.
- The FVG/order-block imbalance retest controls are preserved for the `fmlr_imbalance_retest` profile.
- The confirmed-swing forward target controls are preserved for the `fmlr_swing_target` profile.
- The lane-specific phase gate controls are preserved for the `fmlr_phase_aligned` profile.
- The stop cluster/pocket controls are preserved for the `fmlr_structural_stop` profile.
- The continuation-retest controls are preserved for the `fmlr_continuation_retest` profile.
- The compression-breakout controls are preserved for the `fmlr_compression_breakout` profile.
- The session-range breakout controls are preserved for the `fmlr_session_range_breakout` profile.
- Unrelated inactive knobs, including winner scale-in inputs, are converted to globals.
- The smoke test enforces a maximum kept-input count of `450` before any MT5 compile/backtest attempt.

Not yet completed:

- MT5 compile.
- MT5 backtest.
- Model4 weak-window probe.
- Monthly/quarterly validation.

Reason:

`work/MT5_LOCAL_LAUNCH_DISABLED.lock` remains active to prevent MT5 or MetaEditor from stealing focus. Do not override that lock unless hidden/external MT5 execution is explicitly being used and focus risk is accepted.

GitHub sync caveat:

This note is safe to publish as a dashboard update, but the full local EA source and long package-builder scripts may still be ahead of GitHub until source publishing is repaired. Treat this note as the current local research status, not proof that every implementation file on GitHub has already caught up.

Structural-stop follow-up note:

`research/2026-07-13-fmlr-structural-stop-pocket-note.md`

Continuation-retest follow-up note:

`research/2026-07-13-fmlr-continuation-retest-note.md`

Compression-breakout follow-up note:

`research/2026-07-13-fmlr-compression-breakout-note.md`

Session-range breakout follow-up note:

`research/2026-07-13-fmlr-session-range-breakout-note.md`

## Decision

Do not promote. This is infrastructure for the next research probe only.

The current stability-best profile remains:

`Score7 Regime No-M1-Shock Dec-ISLP-Off + ISLP LowATR OrderFlow`
