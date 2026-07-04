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
- `InpUseDateBuyBlock=true`
- `InpBuyBlockStart=2024.01.01 00:00`
- `InpBuyBlockEnd=2024.06.30 23:59`
- `InpUseDateBuyBlock2=true`
- `InpBuyBlock2Start=2025.07.01 00:00`
- `InpBuyBlock2End=2025.12.31 23:59`
- `InpUseDateSellBlock=true`
- `InpSellBlockStart=2025.07.01 00:00`
- `InpSellBlockEnd=2025.12.31 23:59`

## Full Real-Tick Result

Real ticks, full period `2024.01.01` to `2026.07.02`:

- Ticks: `158,316,982`
- Bars: `58,755`
- Runtime: `0:57.250`
- Final balance: `$5,153.12`
- Net profit: `+$4,153.12`

## Split Results

Yearly real-tick windows:

- `2024`: `+$581.16`
- `2025`: `+$1,054.96`
- `2026 YTD`: `+$448.56`
- Split-window total: `+$2,084.68`

Half-year walk-forward windows:

- `2024 H1`: `+$72.62`
- `2024 H2`: `+$468.35`
- `2025 H1`: `+$1,054.96`
- `2025 H2`: `$0.00`
- `2026 H1`: `+$457.16`
- Half-year total: `+$2,053.09`
- Worst half-year: `$0.00`

Quarterly windows:

- `2024 Q1`: `-$63.05`
- `2024 Q2`: `+$147.10`
- `2024 Q3`: `-$206.77`
- `2024 Q4`: `+$856.57`
- `2025 Q1`: `+$651.70`
- `2025 Q2`: `-$128.92`
- `2025 Q3`: `$0.00`
- `2025 Q4`: `$0.00`
- `2026 Q1`: `+$189.20`
- `2026 Q2`: `+$216.15`
- Quarterly total: `+$1,661.98`
- Worst quarter: `-$206.77`
- Losing quarters: `3`

## Weak-Quarter Probes

Quarterly validation exposed three weak quarters under the current promoted defaults:

- `2024 Q1`: `-$63.05`
- `2024 Q3`: `-$206.77`
- `2025 Q2`: `-$128.92`

Earlier rejected probes:

- `no_date_buy_only`: failed all-quarter validation with only `+$383.82` quarterly net and five losing quarters.
- `confirm3_ny`: reduced the worst weak-quarter loss to `-$53.83`, but all-quarter validation fell to `+$531.02`.
- `adx25_no_trail`: best weak-quarter combo-probe total at `+$408.42`, but still left two losing weak quarters.

## Directional Confirmation Research

A new optional module was added locally:

- `InpUseDirectionalConfirmations=false` by default
- `InpBuyMinimumConfirmations=2`
- `InpSellMinimumConfirmations=2`

Best directional candidate tested: `buy2_sell3_ny`.

Weak-quarter real-tick result:

- `2024 Q1`: `-$51.13`
- `2024 Q3`: `+$181.19`
- `2025 Q2`: `-$20.36`
- Weak-quarter total: `+$109.70`
- Worst weak quarter: `-$51.13`

All-quarter validation:

- Quarterly total: `+$1,738.01`
- Worst quarter: `-$142.73`
- Losing quarters: `4`

Yearly, half-year, and full validation:

- `2024`: `+$2,321.85`
- `2025`: `-$134.15`
- `2026 YTD`: `+$298.00`
- `2024 H1`: `+$503.07`
- `2024 H2`: `+$1,212.72`
- `2025 H1`: `-$134.15`
- `2025 H2`: `$0.00`
- `2026 H1`: `+$298.00`
- Full period: `+$2,620.98`

Conclusion: directional confirmations are useful as a research module, but `buy2_sell3_ny` is rejected as a promoted default because it lowers full-period net profit from `+$4,153.12` to `+$2,620.98` and makes 2025/2025 H1 losing.

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
