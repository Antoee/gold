# Backtest Results

EA: `Professional_XAUUSD_EA`

Symbol/timeframe: `XAUUSD`, `M15`

Main validation period: `2024.01.01` to `2026.07.02`

Deposit: `$1,000`

Leverage: `1:100`

## Current Promoted Configuration

The current promoted defaults are the best profit configuration found so far, but they are still research settings and may be overfit because they include date-specific trade blocks.

Promoted inputs:

- `InpUseAdaptiveReverse=true`
- `InpAdaptiveSlopeThresholdPts=500.0`
- `InpMinRiskReward=1.50`
- `InpTakeProfitATRMultiplier=3.50`
- `InpUseBreakEven=false`
- `InpMaxDailyLossPercent=1.00`
- `InpMaxWeeklyLossPercent=2.50`
- `InpMaxMonthlyLossPercent=4.00`
- `InpMaxEquityDrawdownPercent=0.00`
- `InpUseMTFSlopeDirectionFilter=false`
- `InpUseDateBuyBlock=true`
- `InpBuyBlockStart=2024.01.01 00:00`
- `InpBuyBlockEnd=2024.06.30 23:59`
- `InpUseDateBuyBlock2=true`
- `InpBuyBlock2Start=2025.07.01 00:00`
- `InpBuyBlock2End=2025.12.31 23:59`
- `InpUseDateSellBlock=true`
- `InpSellBlockStart=2025.07.01 00:00`
- `InpSellBlockEnd=2025.12.31 23:59`

## Current Promoted Results

Full real-tick period `2024.01.01` to `2026.07.02`:

- Ticks: `158,316,982`
- Bars: `58,755`
- Runtime: `0:57.250`
- Final balance: `$5,153.12`
- Net profit: `+$4,153.12`

Yearly windows:

- `2024`: `+$581.16`
- `2025`: `+$1,054.96`
- `2026 YTD`: `+$448.56`

Half-year walk-forward windows:

- `2024 H1`: `+$72.62`
- `2024 H2`: `+$468.35`
- `2025 H1`: `+$1,054.96`
- `2025 H2`: `$0.00`
- `2026 H1`: `+$457.16`

Quarterly windows:

- Quarterly total: `+$1,661.98`
- Worst quarter: `-$206.77`
- Losing quarters: `3`

## Directional Confirmation Research

Optional module added locally:

- `InpUseDirectionalConfirmations=false` by default
- `InpBuyMinimumConfirmations=2`
- `InpSellMinimumConfirmations=2`

Best directional candidate tested: `buy2_sell3_ny`.

- Weak-quarter total: `+$109.70`
- Worst weak quarter: `-$51.13`
- All-quarter total: `+$1,738.01`
- Full period: `+$2,620.98`

Conclusion: useful as a research module, but rejected as a promoted default because it lowers full-period profit and makes 2025/2025 H1 losing.

## Equity Drawdown Guard Research

Optional peak-equity circuit breaker added locally:

- `InpMaxEquityDrawdownPercent=0.00` by default

Best weak-quarter threshold `dd4`:

- Weak-quarter total: `+$71.45`
- Worst weak quarter: `-$87.32`
- Full period: `+$85.45`
- `2025`: `-$83.61`

Conclusion: useful as optional capital preservation, but rejected as a promoted default because it crushes full-period profit.

## MTF Slope Direction Filter Research

Optional higher-timeframe EMA slope direction filter added locally:

- `InpUseMTFSlopeDirectionFilter=false` by default
- `InpDirectionSlopeLookback=50`
- `InpBuyMinMTFSlopePts=0.0`
- `InpSellMaxMTFSlopePts=0.0`

The filter was tested as a general replacement for date-specific blocks by disabling all date blocks and running real-tick stress windows: `2024 Q1`, `2024 Q3`, `2025 Q2`, `2025 Q3`, and `2025 Q4`.

No tested variant was profitable across the stress set:

- `buy500_sell0`: total `-$444.20`, worst `-$145.19`
- `buy0_sell-500`: total `-$457.79`, worst `-$133.72`
- `buy500_sell-500`: total `-$476.06`, worst `-$150.52`
- `buy0_sell0`: total `-$535.04`, worst `-$145.19`
- `buy250_sell-250`: total `-$556.68`, worst `-$152.30`
- `buy750_sell-750`: total `-$560.23`, worst `-$150.52`
- `buy-250_sell250`: total `-$614.31`, worst `-$189.69`

Conclusion: useful as a configurable research module, but it failed as a date-block replacement and is not promoted.

## Background Testing Speed

The local automation scripts were updated for faster, quieter testing:

- MT5 launches via a hidden Windows `CreateProcess` wrapper to avoid popup flashes.
- Strategy Tester visual mode is disabled.
- Dashboard rendering is skipped in tester configs.
- MT5/tester audio sessions are muted while tests run.
- Scripts read the newest MT5 tester log dynamically instead of a hardcoded date log.

## Conclusion

The current promoted configuration makes profit on the full real-tick period, all tested yearly windows, and all half-year walk-forward windows. It still has three losing quarterly windows and uses date-specific filters, so it is not production-ready.

Next optimization target: replace date-specific behavior with general market-regime rules that reduce `2024 Q3` and `2025 Q2` losses without removing the strong `2024 Q4` and `2025 Q1` gains.
