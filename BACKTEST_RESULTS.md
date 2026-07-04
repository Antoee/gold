# Backtest Results

EA: `Professional_XAUUSD_EA`

Symbol/timeframe: `XAUUSD`, `M15`

Main validation period: `2024.01.01` to `2026.07.02`

Deposit: `$1,000`

Leverage: `1:100`

## Current Promoted Robust No-Date Results

The promoted default is now the no-date BOS + liquidity-sweep profile at `1.50%` risk with a tighter `1.80` ATR stop:

- `InpRiskPercent=1.50`
- `InpStopATRMultiplier=1.80`
- `InpTakeProfitATRMultiplier=3.50`
- `InpMinRiskReward=1.50`
- `InpUseDateBuyBlock=false`
- `InpUseDateBuyBlock2=false`
- `InpUseDateSellBlock=false`
- `InpUseEMACrossEntry=false`
- `InpUseMomentumCandle=false`
- `InpUseEngulfing=false`
- `InpUseBOS=true`
- `InpUseLiquiditySweep=true`
- `InpMinimumConfirmations=2`

Full real-tick period `2024.01.01` to `2026.07.02`:

- Final balance: `$1,521.12`
- Net profit: `+$521.12`

Yearly windows:

- `2024`: `+$230.04`
- `2025`: `+$245.12`
- `2026 YTD`: `$0.00`

Half-year windows:

- `2024 H1`: `-$148.99`
- `2024 H2`: `+$444.38`
- `2025 H1`: `$0.00`
- `2025 H2`: `+$245.12`
- `2026 H1`: `$0.00`

Quarterly windows:

- Quarterly total: `+$540.51`
- Worst quarter: `-$148.99`
- Profitable quarters: `2`
- Flat quarters: `7`
- Losing quarters: `1`

Monthly windows:

- Monthly total: `+$540.51`
- Worst month: `-$148.99`
- Profitable months: `2`
- Flat months: `27`
- Losing months: `1`

Split-window aggregate:

- Total across yearly/half/full windows: `+$1,536.79`
- Worst split window: `-$148.99`
- Best split window: `+$521.12`
- Profitable split windows: `5`
- Flat split windows: `3`
- Losing split windows: `1`

Conclusion: tightening the ATR stop from `2.20` to `1.80` improved full-period profit from `+$452.75` to `+$521.12`, improved monthly/quarter aggregate from `+$487.46` to `+$540.51`, and kept one losing monthly/quarter/split window. A `2.00%` risk variant had zero losing monthly/quarterly/split windows, but lower full-period profit at `+$321.72`.

## Aggressive Date-Block Benchmark

Previous aggressive date-block validation:

- Full period net profit: `+$4,153.12`
- Quarterly total: `+$1,661.98`
- Monthly total: `+$1,903.98`
- Monthly losing windows: `17` out of `30`
- Worst quarter: `-$206.77`
- Worst month: `-$83.61`

Conclusion: the date-block profile remains the highest-profit historical benchmark, but it is not the promoted default because it relies on hard-coded date filters and has poor monthly start-window robustness.

## Other Research

- BOS+sweep at `1.75%` risk: stress-window total `+$560.41`, but worst loss worsened to `-$172.80`, so it was not promoted.
- BOS+sweep at `1.50%` risk with `2.20` stop ATR: full period `+$452.75`, monthly `+$487.46`, 1 losing month; previous default.
- BOS+sweep at `2.00%` risk: full period `+$321.72`, zero losing monthly/quarterly/split windows; safer but lower profit than `1.50%`.
- BOS+sweep at `1.00%` risk: full period `+$319.26`, monthly `+$314.76`, 1 losing month; older default.
- Momentum+sweep no-date profile: full period `+$664.59`, but still had 17 losing months, so it was not promoted.
- BOS/sweep variants with `MinimumConfirmations=1`, BOS-only, or sweep-only made more in stress windows but brought back larger losses.
- No-trail reduced the worst quarter but cut total quarterly net too much.
- Monthly ADX filters reduced profit without improving losing-month count.

## Next Target

Increase profit from the robust BOS+sweep profile without bringing back many losing monthly windows. The next sweeps should focus on conservative entry expansion, exact BOS/sweep definitions, and adding drawdown/profit-factor extraction from reports.
