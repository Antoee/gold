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

Monthly windows:

- Monthly total: `+$1,903.98`
- Worst month: `-$83.61`
- Best month: `+$952.38`
- Profitable months: `7`
- Flat months: `6`
- Losing months: `17`

Important finding: the current promoted build is profitable over larger windows because a few very strong months carry many small losing months. This is profitable, but it does not yet satisfy the goal of being robust from any start point.

Largest profitable months:

- `2025_03`: `+$952.38`
- `2024_12`: `+$846.52`
- `2026_06`: `+$382.53`
- `2026_03`: `+$300.46`
- `2024_04`: `+$274.11`

Worst losing months:

- `2025_01`: `-$83.61`
- `2024_08`: `-$83.26`
- `2025_02`: `-$82.94`
- `2024_09`: `-$79.83`
- `2024_03`: `-$66.04`

## Monthly Confirmation Filter Research

Stricter confirmation filters were tested across the same 30 monthly windows.

Results:

- Baseline: total `+$1,903.98`, worst `-$83.61`, profitable `7`, flat `6`, losing `17`
- `buy2_sell3`: total `+$1,492.91`, worst `-$83.61`, profitable `10`, flat `6`, losing `14`
- `confirm3`: total `+$487.71`, worst `-$84.75`, profitable `7`, flat `10`, losing `13`
- `buy3_sell2`: total `+$331.04`, worst `-$83.26`, profitable `8`, flat `7`, losing `15`
- `confirm4`: total `$0.00`, all 30 months flat

Conclusion: `buy2_sell3` improves monthly start-window consistency by reducing losing months from `17` to `14`, but it reduces total monthly net by about `$411`. It is useful as a smoother alternate profile, but it is not promoted because the current defaults make more profit.

## Other Rejected Research Paths

- Directional confirmation `buy2_sell3_ny`: full period `+$2,620.98`, 2025/2025 H1 losing.
- Equity drawdown guard `dd4`: full period `+$85.45`, 2025 losing.
- MTF slope direction no-date filter: best stress-set total `-$444.20`.
- H4 no-date signal timeframe: full validation `-$136.90`, no profitable validation windows.

## Background Testing Speed

The local automation scripts were updated for faster, quieter testing:

- MT5 launches via a hidden Windows `CreateProcess` wrapper to avoid popup flashes.
- Strategy Tester visual mode is disabled.
- Dashboard rendering is skipped in tester configs.
- MT5/tester audio sessions are muted while tests run.
- Scripts read the newest MT5 tester log dynamically instead of a hardcoded date log.

## Conclusion

The current promoted configuration makes profit on the full real-tick period, all tested yearly windows, and all half-year walk-forward windows. Monthly validation now shows the start-point problem more clearly: `17` of `30` monthly windows are losing. The EA is still not production-ready.

Next optimization target: reduce the many small losing months without removing the few large winning months.
