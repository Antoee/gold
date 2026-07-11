# Flat Efficiency Current-Candidate Validation

Date: 2026-07-11

## Purpose

Tested default-off flat-month efficiency lanes from the current promoted candidate:

- `CANDIDATE_MARCH110_MAY325_MAYCAP17_LOT040_PROFILE`
- Current broad baseline: `6346.38` total net, zero losing broad windows

The goal was to increase productive trade frequency outside the March/May month gate without adding martingale, grid, averaging down, or recovery behavior.

## Code Change

Added tester-configurable M5 tight-liquidity secondary-lane inputs and a default-off outside-month-filter bypass:

- `InpUseM5TightLiquiditySecondaryLane`
- `InpAllowM5TightLiquidityOutsideMonthFilter`
- M5 lane ADX, slope, BOS/sweep, stop, TP, RR, and monthly-entry controls

The bypass only applies when:

- the signal is an M5 tight-liquidity signal,
- flat-month opportunity mode is active,
- the optional liquid-session requirement is satisfied.

## Validation

Package:

- Builder: `work/build_flat_efficiency_current_package.ps1`
- Broad manifest: `outputs/FLAT_EFFICIENCY_CURRENT_BROAD_MANIFEST.csv`
- Broad run: `outputs/FLAT_EFFICIENCY_M5_BROAD_RUN.csv`
- Results: `outputs/FLAT_EFFICIENCY_M5_BROAD_LOG_RESULTS.csv`
- Summary: `outputs/FLAT_EFFICIENCY_M5_BROAD_LOG_SUMMARY.csv`
- Compact source audit: `outputs/FLAT_EFFICIENCY_M5_COMPACT_SOURCE_AUDIT.csv`
- Compact compile: `outputs/FLAT_EFFICIENCY_M5_COMPACT_COMPILE.log`
- Full restore compile: `outputs/RESTORE_FULL_AFTER_FLAT_EFFICIENCY_M5_COMPILE.log`

## Results

| Profile | Total Net | Continuous | YTD | Full 2025 | Full 2024 | Worst Window | Losing Windows |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| base_current | 6346.38 | 853.90 | 1002.20 | 230.19 | 853.90 | 0.00 | 0 |
| m5_tight_liq_loose | 4844.54 | 792.58 | 51.28 | 173.49 | 792.58 | 0.00 | 0 |
| m5_tight_liq | 4032.39 | 225.90 | 35.54 | 138.86 | 225.90 | 0.00 | 0 |

Earlier broad flat probes in the same package:

- `breakout_probe`: identical to base, no improvement.
- `missed_move`: identical to base, no improvement.
- `micro_reversion`: `5757.99`, below base.
- `combined_soft_whip`: `5799.67`, below base.

## Decision

No promotion.

The M5 tight-liquidity lane is now configurable and available for future search, but these tested settings reduce profit too much. Keep the promoted March/May lot-capped candidate unchanged.

Next best direction: search for a higher-quality outside-month entry source or a profit-expansion exit on already-profitable March/May trades, rather than adding low-timeframe entries broadly.
