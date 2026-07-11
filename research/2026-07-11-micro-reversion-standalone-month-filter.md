# 2026-07-11 Micro-Reversion Standalone Month Filter

## Problem

The unrestricted `micro_clean` flat-month lane improved continuous profit, but collapsed 2026 YTD:

| Profile | Continuous | YTD | Full2025 | Full2024 | WorstWindow | LosingWindows |
|---|---:|---:|---:|---:|---:|---:|
| micro_clean | 5046.57 | 8.17 | 159.48 | 2046.01 | 2.90 | 0 |
| base_mar10_may10 | 3746.45 | 1107.93 | 214.30 | 1409.57 | 0.00 | 0 |

Monthly attribution showed `micro_clean` only had consistent add-on value in July and October. But the old `InpUseFlatMonthProbeMonthFilter` gates all flat-probe bypasses, not only micro-reversion. That made the July/October-only test preserve 2026 but damage 2024 continuous behavior.

## Code Change

Added a micro-reversion-specific active path:

- `InpFlatMonthMicroReversionStandaloneActive`
- `InpUseFlatMonthMicroReversionMonthFilter`
- `InpFlatMicroRevTradeJanuary` through `InpFlatMicroRevTradeDecember`
- `FlatMonthMicroReversionActive()`
- `FlatMonthMicroReversionMonthFilterAllows()`

Defaults are backward-compatible. If `InpFlatMonthMicroReversionStandaloneActive=false`, the lane still uses the old `FlatMonthOpportunityActive()` behavior.

## Candidate

New candidate profile:

- `outputs/CANDIDATE_MICRO_DEDICATED_JULOCT_PROFILE.set`
- Profile SHA-256: `AE5B2B986EE5B716C6C2FA3A146CDA8F49D6DF58F28A24718EB728FC6312557C`
- Key behavior:
  - `InpUseFlatMonthOpportunityMode=false`
  - `InpFlatMonthMicroReversionStandaloneActive=true`
  - `InpUseFlatMonthMicroReversionMonthFilter=true`
  - micro-reversion enabled only in July and October

## Validation

Fast broad validation, open prices model, compact tester source:

| Profile | Continuous | YTD | Full2025 | Full2024 | WorstWindow | LosingWindows |
|---|---:|---:|---:|---:|---:|---:|
| micro_dedicated_jul_oct | 4061.66 | 1107.93 | 214.30 | 1505.93 | 0.00 | 0 |
| base_mar10_may10 | 3746.45 | 1107.93 | 214.30 | 1409.57 | 0.00 | 0 |

Target windows:

| Profile | 2025 Jul-Oct | 2024 Jul-Oct | 2026 Jan |
|---|---:|---:|---:|
| micro_dedicated_jul_oct | 55.75 | 57.86 | 0.00 |
| base_mar10_may10 | 0.00 | 0.00 | 0.00 |

## Decision

Promising, not fully promoted yet.

This is a real improvement over the current promoted baseline in the fast broad screen:

- Continuous: +315.21
- Full2024: +96.36
- 2026 YTD: unchanged
- Full2025: unchanged
- Losing windows: unchanged at 0

Next gate: run a slower confirmation package with real-tick/less-compressed settings and month-level checks for July/October only. If it survives, promote `CANDIDATE_MICRO_DEDICATED_JULOCT_PROFILE.set` as the new best candidate.