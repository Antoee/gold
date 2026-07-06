# Recent 2026 Fast Triage Status

Updated locally on 2026-07-06.

## Safety

- Local MT5/MetaEditor/Strategy Tester launch remains locked.
- Current work was done with hidden/no-window PowerShell only.
- Final local scan before this status update: no `terminal`, `terminal64`, `metatester`, `metatester64`, `MetaEditor`, or `metaeditor64` processes found.
- Quiet stop marker remains present: `work/STOP_MT5_FOCUS_WATCHDOG`.
- No watchdog process is intentionally running right now; the repo is in quiet no-resident-helper mode.

## Current EA Source

- Canonical source: `outputs/Professional_XAUUSD_EA.mq5`.
- Root/package source sync: PASS.
- Current synced source SHA256: `DBE2C19B8AA8B750D2D7D5907F497B76CC05AB1051AABFB260F0F7169C10A9D5`.

## Strategy-Code Work

The EA includes optional, independently configurable strategy modules for actual price-action, market-state, tick-tape, intermarket confirmation, weighted setup-quality logic, profit protection, and early loss control:

- CHoCH, FVG, order-block retest, liquidity sweep, previous/session levels, VWAP, candle anatomy, market phase, RSI, MACD, Bollinger, and tick microstructure confirmations.
- Correlated-market confirmation using configurable same-direction or inverse-direction symbol momentum.
- Weighted entry-quality score.
- Quality-based risk scaling.
- Regime-quality confirmation using ADX, EMA slope, and ATR regime.
- ATR-based profit-lock stop.
- Adverse-R early exit.

## Correlated-Market Confirmation Addition

Added optional intermarket confirmation so XAUUSD entries can require agreement from a correlated or inverse symbol:

- `InpUseCorrelationConfirmation=false` by default.
- `InpCorrelationSymbol=XAGUSD` by default.
- `InpCorrelationTimeframe=PERIOD_M15`.
- `InpCorrelationLookbackBars=8`.
- `InpCorrelationMinMovePoints=20.0`.
- `InpCorrelationMode=CORRELATION_SAME_DIRECTION` by default.
- `InpWeightCorrelation=1`.
- Same-direction mode can test gold/silver confirmation, such as XAUUSD buy only when XAGUSD has positive momentum.
- Inverse-direction mode can be used for symbols such as DXY if the broker provides the symbol and tester data.
- If the symbol data is unavailable, the confirmation fails instead of forcing a trade.

The `vwap_momentum_phase` and `weighted_quality_confluence` research profiles now enable XAGUSD same-direction confirmation for testing.

## Decision Gate Discipline

The offline price-action decision gate rejects or reviews aggressively before any candidate can pass fast triage:

- `MinTradesPerWindow=5`.
- `MinProfitFactor=1.10`.
- `MinRecoveryFactor=1.00`.
- `MaxProfitFactorDegradation=0.05`.
- Higher net profit alone is not enough when PF, recovery, drawdown, compile proof, or report coverage is weak.

## Recent EA Risk Features

Adverse-R early exit:

- `InpUseAdverseRExit=false` by default.
- `InpAdverseExitR=0.75`.
- Selected high-confluence research profiles enable this with `0.75R` to `0.80R` thresholds.

Profit-lock stop:

- `InpUseProfitLockStop=false` by default.
- `InpProfitLockTriggerATR=1.50`.
- `InpProfitLockATR=0.35`.
- Selected high-confluence research profiles enable this for testing.

Regime-quality score:

- `InpUseRegimeQualityScore=false` by default.
- Uses ADX, EMA slope direction, and current ATR versus recent ATR average.

## Price-Action Research Batch

Fast research batch for actual strategy-code variants:

- Batch: `outputs/PRICE_ACTION_STRATEGY_BATCH.csv`.
- Profiles: 10.
- Runs: 30.
- Windows: `2026_Q2`, `2026_ytd`, `2025_Q2`.
- Estimated tester runtime: about 10.5 minutes before platform overhead.
- Handoff zip: `outputs/price_action_strategy_handoff.zip`.
- Parallel lanes zip: `outputs/price_action_parallel_lanes.zip`.

Research profiles:

- `baseline_promoted`
- `fvg_sweep_confluence`
- `choch_bos_shift`
- `orderblock_fvg_retest`
- `liquidity_level_reversal`
- `vwap_momentum_phase` includes XAGUSD correlation confirmation.
- `tick_vwap_momentum`
- `indicator_phase_filter`
- `weighted_quality_confluence` includes XAGUSD correlation confirmation.
- `pa_full_confluence`

## Current Decision State

- Overall: `COMPILE_REQUIRED`.
- Decisions: 27.
- Pass: 0.
- Reject: 0.
- Waiting: 27.
- Compile trust: `STALE`.
- No profit claim is made.

## Offline Evidence

- `PRICE_ACTION_STRATEGY_MODULES_SMOKE_PASS`.
- `PRICE_ACTION_STRATEGY_BATCH_SMOKE_PASS`.
- `EA_SOURCE_ARTIFACT_SYNC_SMOKE_PASS`.
- Full offline refresh: PASS, 39 steps, 0 failed.
- Report import preflight rows:
  - Price-action strategy modules smoke: PASS.
  - Price-action strategy batch smoke: PASS.
  - Price-action strategy handoff smoke: PASS.
  - Price-action strategy decision: `COMPILE_REQUIRED`, with 27 waiting report decisions and stale compile trust.
  - Source hash status smoke: PASS.
  - Local safety: PASS, 39 safety checks pass.
  - Compile status: `STALE`.
  - External MT5 package: PASS, 26 package checks pass.
- External MT5 package audit: PASS, 26 checks passed, 0 failed.

## Hashes

- EA source: `DBE2C19B8AA8B750D2D7D5907F497B76CC05AB1051AABFB260F0F7169C10A9D5`.
- Base profile: `AF8DD59ECBC5A5810BF61A1115CE44C6FBC1B52670496B3715142A491A62606C`.
- Price-action batch CSV: `903827B590601032A7A70DABEBD76776A74CDD40CD4C103FEB0574FC2D00BED6`.
- Price-action handoff zip: `A9F6F269CDC87812418A961163EF29C492842712A4A216F7CE9A4EFB3CC2E4E9`.
- Price-action parallel lanes zip: `BCC020770B44DC096D667380FC23DC3DE6A48FA87E68F7650B6C0216E7E47718`.
- External validation package zip: `A1C296B6CCB4A4EDA2B70F262D9CE3F50DBAED5BD3FDBCA7F1568C4D6F0E5487`.
- Price-action modules smoke: `EDF72274614CEDB70C3F0E5B9604028AF684E53456E1B8C7FACA2CCA365B9116`.
- Price-action batch smoke: `93D33A064BEB87FC28B329414E1FD884426FFC691A30279316FFB55866CAED30`.
- Price-action batch builder: `92FF3F30C176FB43A56FCBDC75211CFF236E08DCABBDE784348C30DE84387FFB`.

## Caveat

No profit claim is made from this update. Compile/test evidence is intentionally stale because MT5 and MetaEditor were not launched to avoid interrupting normal PC usage. Next performance step is a controlled external or truly non-interactive MT5 compile and backtest run using the rebuilt package or the new price-action lane zips, followed by importing reports through the stricter decision gate.