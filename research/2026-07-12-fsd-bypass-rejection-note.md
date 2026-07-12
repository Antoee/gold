# FSD Month-Filter Bypass Rejection - 2026-07-12

Added a defaults-off controlled bypass for the flat-month structural-displacement lane:

- `InpAllowFlatMonthStructuralDisplacementOutsideMonthFilter`
- `InpFlatMonthStructuralDisplacementBypassMinQualityScore`
- `InpFlatMonthStructuralDisplacementBypassMinPriceActionScore`
- `InpFlatMonthStructuralDisplacementBypassRequireLiquidSession`

This was tested because blocker diagnostics showed a small number of higher-quality flat structural-displacement rows blocked by the month filter.

## Validation Package

Package: `outputs/fsd_bypass_variant_package`

Profiles:

- `baseline`
- `fsd_bypass`

Windows:

- `2024_Q3`
- `2024_Q4`
- `2025_Q2`
- `2025_Q4`
- `2026_YTD`

## Result

Both profiles produced identical parsed log results:

| Profile | Parsed | Total Net | YTD 2026 | Losing Windows |
| --- | ---: | ---: | ---: | ---: |
| baseline | 5/5 | 1475.08 | 1375.04 | 0 |
| fsd_bypass | 5/5 | 1475.08 | 1375.04 | 0 |

Per-window net profit was unchanged:

- `2024_Q3`: `12.04`
- `2024_Q4`: `46.75`
- `2025_Q2`: `0.00`
- `2025_Q4`: `41.25`
- `2026_YTD`: `1375.04`

## Decision

Rejected as a promoted profile change. The switch remains defaults-off as a testable research control, but it does not increase profit on the focused validation set.

Next likely search direction: do not spend more time on this exact bypass. The diagnostic evidence points toward either a new in-session setup generator for `no setup` periods or a better month-filter expansion rule that produces materially more than the 19 high-quality blocked FSD candidates.
