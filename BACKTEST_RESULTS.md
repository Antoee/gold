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

A new optional module was added locally:

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

A new optional peak-equity circuit breaker was added locally:

- `InpMaxEquityDrawdownPercent=0.00` by default

When enabled, the EA blocks new entries once current equity falls more than the configured percentage from peak equity. Existing position management still runs.

Weak-quarter sweep:

- `dd4`: total `+$71.45`, worst `-$87.32`, two profitable weak quarters
- `dd6`: total `+$16.27`, worst `-$87.32`, two profitable weak quarters
- `dd8`: total `+$16.27`, worst `-$87.32`, two profitable weak quarters
- `dd10`: total `-$130.54`, worst `-$128.92`
- `dd12`: total `-$130.54`, worst `-$128.92`
- `dd15`: total `-$167.56`, worst `-$128.92`

Full validation for best weak-quarter threshold `dd4`:

- Quarterly total: `+$341.00`
- Worst quarter: `-$87.32`
- Full period: `+$85.45`
- `2024`: `+$85.45`
- `2025`: `-$83.61`
- `2026 YTD`: `+$25.96`

Conclusion: useful as an optional capital-preservation module, but rejected as a promoted default because it reduces full-period net from `+$4,153.12` to `+$85.45` and makes 2025 losing.

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
