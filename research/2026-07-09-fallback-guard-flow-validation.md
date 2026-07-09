# Fallback Guard Flow Validation

Date: 2026-07-09

This continuation found and fixed a strategy-flow issue in the diagnostic fallback lane.

## Code change

The diagnostic fallback entry previously returned immediately from `CEntryEngine::Build()` before the optional guard stack ran. That meant fallback entries bypassed checks such as:

- Entry shock guard
- Dynamic ATR regime guard
- Gap/failed-breakout guards
- Tick-volume and volume dry-up guards
- Chop, impulse, consecutive-candle, daily/session range exhaustion guards
- Market phase and adaptive regime gates
- VWAP distance and indicator exhaustion guards

The early return was removed. The fallback entry is now applied through the normal confirmation path after guards, using the existing later `AddConfirmation(DiagnosticTrendFallback(...))` call.

## Source checks

- `test_price_action_strategy_modules.ps1`: PASS
- `test_price_action_strategy_batch.ps1`: PASS
- `sync_ea_source_artifacts.ps1`: PASS
- Synced source hash: `B1F94E6234ABA48A6E71A32583BFFFFCBB9C99E73B909C7BBEB50BBCB0018FD2`

## Current best candidate profile

A compact candidate set was generated locally:

`outputs/CANDIDATE_PEAK15_LIQUIDITY_STOP_CHOP_PROFILE.set`

Core idea:

- Risk: `InpRiskPercent=1.00`
- Equity peak protection: `InpUseEquityProfitPeakTrail=true`, 3% start, 15% giveback
- Stop logic: `InpUseLiquidityAwareStructureStop=true`
- Entry lane: diagnostic trend fallback remains enabled
- Added post-patch guard: `InpUseChopFilter=true`

## Post-patch guard validation

All figures are net profit on a $1,000 test deposit.

| Profile | 2024-2026 Continuous | 2026 YTD | 2025 Full | 2024 Full | Jan | Feb | Mar | Apr | May | Jun | MinNet |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| liq_base_guarded | 786.27 | 84.72 | 124.51 | 786.27 | 84.72 | 78.78 | -84.88 | 192.20 | -99.55 | -70.90 | -99.55 |
| chop | 801.84 | 84.72 | 124.51 | 801.84 | 84.72 | 78.78 | -84.88 | 192.20 | -99.55 | -70.90 | -99.55 |
| daily_exhaust | 786.27 | 84.72 | 135.20 | 786.27 | 84.72 | 78.78 | -84.88 | 192.20 | -99.55 | -70.90 | -99.55 |
| entryshock | 2.22 | 84.54 | -255.32 | 2.22 | 84.54 | -62.32 | -84.88 | 296.41 | -99.55 | -70.90 | -255.32 |
| vwap_guard | -461.53 | -241.43 | -435.67 | -170.02 | -95.48 | -89.34 | 157.02 | -47.55 | -99.55 | -64.62 | -461.53 |

## Interpretation

The guard-flow fix is important for future optimization because optional filters now actually apply to fallback entries. However, most stronger filters were too destructive in this validation. The chop filter is the only guard that improved continuous performance without damaging the already-positive 2026 YTD branch.

The 2-3% monthly objective is still not proven. March, May, and June 2026 remain negative in the current best branch, so this remains a research candidate rather than a final promoted strategy.
