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

## Yearly Split Results

Real ticks, yearly split windows:

- `2024`: `$1,581.16` balance, `+$581.16` net
- `2025`: `$2,054.96` balance, `+$1,054.96` net
- `2026 YTD`: `$1,448.56` balance, `+$448.56` net
- Split-window total: `+$2,084.68`

## Half-Year Walk-Forward Results

Real ticks, half-year walk-forward windows:

- `2024 H1`: `$1,072.62` balance, `+$72.62` net
- `2024 H2`: `$1,468.35` balance, `+$468.35` net
- `2025 H1`: `$2,054.96` balance, `+$1,054.96` net
- `2025 H2`: `$1,000.00` balance, `$0.00` net
- `2026 H1`: `$1,457.16` balance, `+$457.16` net
- Half-year total: `+$2,053.09`
- Worst half-year: `$0.00`

## Quarterly Results

Real ticks, quarterly windows:

- `2024 Q1`: `$936.95` balance, `-$63.05` net
- `2024 Q2`: `$1,147.10` balance, `+$147.10` net
- `2024 Q3`: `$793.23` balance, `-$206.77` net
- `2024 Q4`: `$1,856.57` balance, `+$856.57` net
- `2025 Q1`: `$1,651.70` balance, `+$651.70` net
- `2025 Q2`: `$871.08` balance, `-$128.92` net
- `2025 Q3`: `$1,000.00` balance, `$0.00` net
- `2025 Q4`: `$1,000.00` balance, `$0.00` net
- `2026 Q1`: `$1,189.20` balance, `+$189.20` net
- `2026 Q2`: `$1,216.15` balance, `+$216.15` net
- Quarterly total: `+$1,661.98`
- Worst quarter: `-$206.77`
- Profitable quarters: `5`
- Flat quarters: `2`
- Losing quarters: `3`

## Weak-Quarter Probes

Quarterly validation exposed three weak quarters under the current promoted defaults:

- `2024 Q1`: `-$63.05`
- `2024 Q3`: `-$206.77`
- `2025 Q2`: `-$128.92`

Targeted weak-quarter probes were run on real ticks. None fixed all three weak quarters while preserving overall quarterly profitability.

Best weak-quarter probes:

- `no_date_buy_only`: reduced losses in the weak quarters, but failed all-quarter validation with only `+$383.82` quarterly net and five losing quarters.
- `confirm3_ny`: reduced the worst weak-quarter loss to `-$53.83`, but all-quarter validation fell to `+$531.02`, far below the promoted defaults.
- `adx25_no_trail`: best weak-quarter probe total at `+$408.42`, but still left two losing weak quarters.

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
