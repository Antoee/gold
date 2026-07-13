# Shared Previous-Period Stop Pocket Note

Date: 2026-07-13

Status: source-level refinement only. Not MT5-backtested and not promoted.

## Purpose

The shared structural stop path already had liquidity-aware stop extensions, equal-level buffers, and generic stop-pocket shifting. However, the generic pocket shift only searched recent M15 highs/lows near the proposed stop.

That left a gap: if a structural stop landed near an enabled previous-day, previous-week, or previous-month high/low, the stop could still sit inside an obvious higher-timeframe liquidity pocket unless that level had already become the primary structural anchor.

## Change

`LiquidityPocketStopLevel()` now also checks enabled previous-period liquidity levels when `InpUseLiquidityPocketStopShift=true`.

It reuses existing inputs only:

- `InpLiquidityStopUsePreviousDay`
- `InpLiquidityStopUsePreviousWeek`
- `InpLiquidityStopUsePreviousMonth`
- `InpLiquidityPocketProximityATR`
- `InpLiquidityPocketProximityPoints`
- `InpLiquidityPocketBufferATR`
- `InpLiquidityPocketBufferPoints`

No new optimizer inputs were added.

## Expected Behavior

When the current structural stop price is near an enabled previous-period high/low:

- buy stops can shift below the previous-period low,
- sell stops can shift above the previous-period high,
- the existing pocket buffer is applied,
- and `usedLiquidityStop` is set through the existing structure-stop path.

This moves the EA farther away from pure ATR stop placement and closer to structural/liquidity-aware placement.

## Source Identity

Local source copies match:

`778E168D96A8185FBA8781210794A6B4547341D4D95F0470134EAC4E5F72C38F`

## Validation

Local static validation only so far. MT5 was not launched.

Required before promotion:

- compile in MT5,
- run current-best same-source Model4 control,
- run the 162-config FMLR fast screen,
- compare stop widening, RR rejects, net profit, drawdown, and losing-window counts.
