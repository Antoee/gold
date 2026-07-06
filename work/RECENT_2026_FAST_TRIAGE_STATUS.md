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
- Current synced source SHA256: `F8538DE547B8C14D60CA15766574E9378ECD3881D60FD6144F0EB44C2B55DA26`.

## Strategy-Code Work

The EA includes optional, independently configurable strategy modules for actual price-action, market-state, tick-tape, weighted setup-quality logic, profit protection, and early loss control:

- CHoCH, FVG, order-block retest, liquidity sweep, previous/session levels, VWAP, candle anatomy, market phase, RSI, MACD, Bollinger, and tick microstructure confirmations.
- Weighted entry-quality score.
- Quality-based risk scaling.
- Regime-quality confirmation using ADX, EMA slope, and ATR regime.
- ATR-based profit-lock stop.
- Adverse-R early exit.

## Decision Gate Tightening

The offline price-action decision gate now rejects or reviews more aggressively before any candidate can pass fast triage:

- New parameter: `MinTradesPerWindow=5`.
- New parameter: `MinProfitFactor=1.10`.
- New parameter: `MinRecoveryFactor=1.00`.
- New parameter: `MaxProfitFactorDegradation=0.05`.
- Added `Resolve-RecoveryFactor()` so missing recovery factor can be estimated from net profit / max drawdown when possible.
- Added output columns for candidate/baseline recovery factor and recovery delta.
- A candidate now gets `REJECT_WEAK_PROFIT_FACTOR` when PF is below the minimum threshold.
- A candidate now gets `REJECT_WEAK_RECOVERY` when recovery factor is below the minimum threshold.
- A candidate now gets `REVIEW_LOWER_RECOVERY` when it beats net profit but has weaker recovery than baseline.
- The decision report now prints the active minimum trade, PF, recovery, and PF-degradation thresholds.

This makes the pipeline harder to fool: higher net profit alone is no longer enough if the run has weak PF, weak recovery, too few trades, higher drawdown, stale compile proof, or missing reports.

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
- `vwap_momentum_phase`
- `tick_vwap_momentum`
- `indicator_phase_filter`
- `weighted_quality_confluence`
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

- `PRICE_ACTION_STRATEGY_DECISION_SMOKE_PASS`.
- `REPORT_IMPORT_PREFLIGHT_SMOKE_PASS`.
- Full offline refresh: PASS, 39 steps, 0 failed.
- Report import preflight rows:
  - Price-action strategy decision: `COMPILE_REQUIRED`, with 27 waiting report decisions and stale compile trust.
  - Source hash status smoke: PASS.
  - Local safety: PASS, 39 safety checks pass.
  - Compile status: `STALE`.
  - External MT5 package: PASS, 26 package checks pass.
- External MT5 package audit: PASS, 26 checks passed, 0 failed.

## Hashes

- EA source: `F8538DE547B8C14D60CA15766574E9378ECD3881D60FD6144F0EB44C2B55DA26`.
- Price-action decision CSV: `7646F4CD657C3A15DD1ED1E1A8393F6F1F462826FB38793FF6F5D4C88277C00F`.
- Price-action decision report: `F1C94A7765B95D5646E780FC7EED42635AAC2022A73F8603F7E72955060F949A`.
- Report import preflight CSV: `FAC97A86AB47EC8429C22E135D7E012173FEEBA4D7CDC1894A8525E7321E29E1`.
- External validation package zip: `F456B10260656A27AE35391FCDF28EAA2C2C979551C762155CE8C6BE70760678`.
- Decision builder: `53A9B3F7E8DBD42DC993B0BEA17AEBF613E58E3AF0B5C7F65746093B164B4140`.
- Decision smoke: `64B3BEBB3E30714A64B32085697F30BC19E03D898D078372C5235EF0D4D1B2FC`.
- Report preflight smoke: `F05D46D11B3FBE71FAEDBA475EDAF3BAE7133008FDC0677BA95230DCC6541BB8`.

## Caveat

No profit claim is made from this update. Compile/test evidence is intentionally stale because MT5 and MetaEditor were not launched to avoid interrupting normal PC usage. Next performance step is a controlled external or truly non-interactive MT5 compile and backtest run using the rebuilt package or the new price-action lane zips, followed by importing reports through the stricter decision gate.