# Profit Search Config Pack

Generated without launching MT5.

This pack searches for more profit around the current no-date BOS + liquidity-sweep profile while keeping the no-martingale/no-grid/no-averaging design intact.

## Phase 1

- Folder: `phase1_fast_triage/`
- Model: `2`, fast tester model.
- Purpose: cheap pruning across 16 candidates and 8 stress/opportunity windows.
- Promotion: never promote from phase 1 alone.

## Phase 2

- Folder: `phase2_real_tick_validation/`
- Model: `4`, real ticks.
- Purpose: deeper validation for baseline plus the highest-priority TP/SL candidates.

## Files

- `PROFIT_SEARCH_PROFILES.csv`
- `PROFIT_SEARCH_CONFIG_MANIFEST.csv`
- `profiles/*.set`

Local MT5 launch remains locked unless `ALLOW_MT5_FOCUS_RISK=1` and `work\ALLOW_MT5_LOCAL_LAUNCH.unlock` are both deliberately set.
