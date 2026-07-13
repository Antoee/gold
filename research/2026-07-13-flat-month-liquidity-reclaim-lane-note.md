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
- `InpFlatMonthLiquidityReclaimMinTargetATR=0.80`
- `InpFlatMonthLiquidityReclaimMaxTargetATR=2.40`
- `InpFlatMonthLiquidityReclaimAllowRecentRetest=false`
- `InpFlatMonthLiquidityReclaimRetestLookbackBars=5`
- `InpFlatMonthLiquidityReclaimRetestToleranceATR=0.18`
- `InpFlatMonthLiquidityReclaimRetestTolerancePoints=40.0`
- `InpFlatMonthLiquidityReclaimRetestMinBodyPercent=20.0`

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
- Windows prepared: 12 weak/flat/control windows from 2024-2026, now `72` configs total.

Compact-source safeguard:

- Required FMLR inputs are preserved as optimizer-visible `input` values.
- The forward-liquidity target controls are preserved for the `fmlr_liquidity_target` profile.
- The recent-sweep retest controls are preserved for the `fmlr_recent_retest` profile.
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

## Decision

Do not promote. This is infrastructure for the next research probe only.

The current stability-best profile remains:

`Score7 Regime No-M1-Shock Dec-ISLP-Off + ISLP LowATR OrderFlow`
