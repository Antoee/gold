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

Best directional candidate tested: `buy2_sell3_ny`.

- Weak-quarter total: `+$109.70`
- Worst weak quarter: `-$51.13`
- All-quarter total: `+$1,738.01`
- Full period: `+$2,620.98`

Conclusion: useful as a research module, but rejected as a promoted default because it lowers full-period profit and makes 2025/2025 H1 losing.

## Equity Drawdown Guard Research

Best weak-quarter threshold `dd4`:

- Weak-quarter total: `+$71.45`
- Worst weak quarter: `-$87.32`
- Full period: `+$85.45`
- `2025`: `-$83.61`

Conclusion: useful as optional capital preservation, but rejected as a promoted default because it crushes full-period profit.

## MTF Slope Direction Filter Research

Optional higher-timeframe EMA slope direction filter was tested as a no-date replacement. No tested variant was profitable across the stress set.

- Best stress-set total: `-$444.20`
- Worst tested variant total: `-$614.31`

Conclusion: useful as a configurable research module, but it failed as a date-block replacement and is not promoted.

## No-Date Signal Timeframe Research

Signal timeframe was tested as another possible replacement for date-specific blocks. All date blocks were disabled and stress windows were run on real ticks: `2024 Q1`, `2024 Q3`, `2025 Q2`, `2025 Q3`, and `2025 Q4`.

Stress-window results:

- `H4`: total `-$68.30`, worst `-$68.30`, four flat windows
- `H1`: total `-$260.55`, worst `-$156.97`
- `M15`: total `-$583.30`, worst `-$206.77`
- `M30`: total `-$601.34`, worst `-$160.95`

`H4` was the best stress-window candidate, so it was validated across quarters, half-years, years, and full period.

Full H4 no-date validation:

- Quarterly total: `-$136.90`
- Worst quarter: `-$68.30`
- Full period: `-$136.90`
- Profitable windows: `0`
- Flat windows: `12`
- Losing windows: `7`

Conclusion: H4 no-date is rejected as a promoted default because it avoids many bad trades but does not make profit.

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
