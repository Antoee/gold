# Prior-Month Defensive Regime Research Note

Date: 2026-07-09

## Purpose

The monthly matrix showed that switching between the current high-profit profile and the smoother balanced profile still leaves too many red months. This experiment added a live-feasible prior-month defensive regime switch:

- It only reads the completed prior monthly candle.
- It can apply defensive month-start protection.
- It can activate the existing weak-regime entry block.
- It is default-off and fully configurable.

## Code added

Default-off inputs were added to `Professional_XAUUSD_EA.mq5`:

- `InpUsePriorMonthDefensiveRegime`
- `InpPriorMonthDefensiveATRPeriod`
- `InpPriorMonthDefensiveMaxBodyPercent`
- `InpPriorMonthDefensiveMaxRangeATR`
- `InpPriorMonthDefensiveMinScore`
- `InpPriorMonthDefensiveUseMonthStart`
- `InpPriorMonthDefensiveMonthStartMinDay`
- `InpPriorMonthDefensiveUseWeakRegimeBlock`

Helpers and hooks:

- `PriorMonthDefensiveRegimeActive()`
- `MonthStartFilterAllows()` can now use prior-month defensive mode.
- `WeakRegimeEntryBlockActive()` can now use prior-month defensive mode.

## Validation package

Package builder:

- `work/build_prior_month_defensive_package.ps1`

Evidence:

- `outputs/LOCAL_MT5_PRIOR_MONTH_DEFENSIVE_LOG_SUMMARY.csv`
- `outputs/LOCAL_MT5_PRIOR_MONTH_DEFENSIVE_LOG_RESULTS.csv`

## Result

None of the tested prior-month defensive variants beat the current baselines.

Best baselines:

- `block115_base`: TotalNet `1759.56`, Continuous `806.46`, YTD `98.84`, WeakSum `-106.10`.
- `block_base`: TotalNet `1728.03`, Continuous `801.84`, YTD `84.72`, WeakSum `-84.88`.

Best prior-month defensive variants:

- `block_pmd_strict`: TotalNet `1239.74`, Continuous `563.23`, YTD `84.72`, WeakSum `-84.88`.
- `block115_pmd_strict`: TotalNet `1231.32`, Continuous `549.09`, YTD `98.84`, WeakSum `-106.10`.

Looser prior-month modes often damaged 2026 YTD:

- `block_pmd_body35`: YTD `-237.06`.
- `block115_pmd_body35`: YTD `-249.61`.

## Decision

Do not promote prior-month defensive mode into the active candidate profile.

Keep the feature default-off because it is live-feasible and may be useful later, but the tested thresholds are not good enough. The evidence again points away from simple defensive filters and toward a genuinely different entry edge.

## Next direction

The next research should target new entries rather than more gating:

- Build a separate trend-expansion lane that only participates in high-efficiency, high-ADX months.
- Build a separate mean-reversion lane that trades flat/range months with explicitly different stop and target logic.
- Validate each lane independently with the monthly matrix before combining them.
