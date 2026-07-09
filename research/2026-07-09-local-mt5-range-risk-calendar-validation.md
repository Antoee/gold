# 2026-07-09 Local MT5 Validation Continuation

Repository: `Antoee/gold`

Local workspace: `C:\Users\Ant\Documents\Codex\2026-07-03\absolutely-here-s-a-summary-you`

## Summary

The current best profile remains the guarded liquidity-stop/chop baseline:

- Candidate set: `outputs\CANDIDATE_PEAK15_LIQUIDITY_STOP_CHOP_PROFILE.set`
- Core result: `2024_to_2026` net `+801.84` on `1000` deposit
- 2026 YTD standalone: `+84.72`
- 2025 standalone: `+124.51`
- 2024 standalone: `+801.84`
- Weak standalone 2026 months remain March `-84.88`, May `-99.55`, June `-70.90`

No tested change should be promoted yet. The current profile is still the least-bad validated candidate.

## What Was Tested

### Range, VWAP, And Flat-Month Lanes

Evidence file: `outputs\LOCAL_MT5_RANGE_FLAT_SUMMARY.csv`

Profiles tested:

- `range_safe`
- `range_loose`
- `range_vwap_pullback`
- `flat_probe_range`
- `flat_probe_recovery`
- `flat_stale_nudge`
- `flat_missed_move`

Result:

- Most safe variants matched base exactly, meaning they did not activate enough to change behavior.
- `range_loose` changed behavior but reduced `2024_to_2026` from `+801.84` to `+596.98`.
- `flat_probe_recovery` reduced `2024_to_2026` to `+757.10`.

Decision: reject for promotion.

### Profit-Pressure / Risk Scaling

Evidence file: `outputs\LOCAL_MT5_PROFIT_PRESSURE_SUMMARY.csv`

Profiles tested:

- 1.5%, 2.0%, 2.5% risk
- relaxed equity peak trail
- no equity peak trail
- drawdown floor variant
- corrected flat-month catch-up risk
- winner scale-in

Result:

- Base remained best at `+801.84` continuous.
- `risk200` fell to `+378.52` continuous and `-343.93` 2026 YTD.
- `risk250` improved some single moves but produced `-365.35` 2026 YTD.
- `risk150` reduced continuous performance to `+262.45`.

Decision: reject. More risk did not translate to better robust profit.

### Weak-Month Trade Diagnostics

Diagnostic file: `C:\Users\Ant\AppData\Roaming\MetaQuotes\Terminal\Common\Files\TradeDiag_20260709.csv`

The weak months each had one early-month losing trade:

- 2026-03-02 sell, diagnostic fallback, `-84.88`
- 2026-05-01 buy, liquidity sweep plus diagnostic fallback, `-99.55`
- 2026-06-01 buy, diagnostic fallback, `-70.90`

This suggested testing month-start filters and fallback-specific month-start guards.

### Month-Start Filters

Evidence file: `outputs\LOCAL_MT5_MONTH_START_SUMMARY.csv`

Profiles tested:

- block all trades before day 2
- block all trades before day 3
- block all trades before day 4

Result:

- Day 2 improved May but cut continuous profit to `+557.99`.
- Day 3 and day 4 damaged 2026 YTD and 2025.

Decision: reject for promotion.

### Month-Start Diagnostic Fallback Guard

Evidence file: `outputs\LOCAL_MT5_MONTH_START_FALLBACK_SUMMARY.csv`

Profiles tested:

- block diagnostic fallback entries before day 2
- block diagnostic fallback entries before day 3
- block diagnostic fallback entries before day 4

Result:

- Day 2 improved May but reduced continuous profit to `+557.99`.
- Day 3 and day 4 damaged 2026 YTD.

Decision: reject for promotion.

### Core Parameter Sweep

Evidence file: `outputs\LOCAL_MT5_CORE_SWEEP_SUMMARY.csv`

Profiles tested:

- tighter/wider stop and take-profit ATR pairs
- ATR trail multipliers 1.20, 2.00, 2.40
- no ATR trailing
- stricter diagnostic fallback body thresholds
- higher RR plus higher minimum score

Result:

- Base remained best at `+801.84` continuous.
- `stop16_tp32` improved 2025 to `+181.96` but cut continuous profit to `+387.80`.
- Wider stops improved 2026 YTD somewhat but destroyed continuous profit.
- No trailing and alternate trailing settings underperformed.
- Stricter fallback body thresholds reduced continuous profit and did not fix weak months.

Decision: reject for promotion.

## Code Changes Added

Added optional default-off research filters:

- `InpUseMonthStartFilter`
- `InpMonthStartMinDay`
- `InpUseMonthStartFallbackGuard`
- `InpMonthStartFallbackMinDay`

These are not enabled in the candidate profile. They remain useful for future research and optimization passes.

Source sync:

- `outputs\EA_SOURCE_ARTIFACT_SYNC.csv`
- hash `E3AD6F04AB694AFA02DAFDDA52727ECDF890FE6E6D2318793E0690141A98EAAF`

Smoke tests:

- `PRICE_ACTION_STRATEGY_MODULES_SMOKE_PASS`
- `PRICE_ACTION_STRATEGY_BATCH_SMOKE_PASS`

## Current Recommendation

Do not increase risk or promote calendar filters. The evidence says the EA is bottlenecked by entry quality, not leverage. Next research should focus on replacing the diagnostic fallback lane with a stronger entry model rather than adding filters around it.
