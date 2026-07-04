# Backtest Results

EA: `Professional_XAUUSD_EA`

Symbol/timeframe: `XAUUSD`, `M15`

Main validation period: `2024.01.01` to `2026.07.02`

Deposit: `$1,000`

Leverage: `1:100`

## Current Promoted Robust No-Date Results

The promoted default is now the no-date BOS + liquidity-sweep profile at `1.00%` risk:

- `InpRiskPercent=1.00`
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

- Final balance: `$1,319.26`
- Net profit: `+$319.26`

Yearly windows:

- `2024`: `+$135.42`
- `2025`: `+$153.20`
- `2026 YTD`: `$0.00`

Half-year windows:

- `2024 H1`: `-$99.84`
- `2024 H2`: `+$261.40`
- `2025 H1`: `$0.00`
- `2025 H2`: `+$153.20`
- `2026 H1`: `$0.00`

Quarterly windows:

- Quarterly total: `+$314.76`
- Worst quarter: `-$99.84`
- Profitable quarters: `2`
- Flat quarters: `7`
- Losing quarters: `1`

Monthly windows:

- Monthly total: `+$314.76`
- Worst month: `-$99.84`
- Profitable months: `2`
- Flat months: `27`
- Losing months: `1`

Conclusion: this profile makes much less historical profit than the date-block profile, but it is the best validated default so far for improving start-date robustness without hard-coded calendar behavior.

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

- Momentum+sweep no-date profile: full period `+$664.59`, but still had 17 losing months, so it was not promoted.
- BOS+sweep at `0.50%` risk: monthly `+$157.38`, 1 losing month; safer but lower profit.
- BOS/sweep variants with `MinimumConfirmations=1`, BOS-only, or sweep-only made more in stress windows but brought back larger losses.
- No-trail reduced the worst quarter but cut total quarterly net too much.
- Monthly ADX filters reduced profit without improving losing-month count.

## Next Target

Increase profit from the robust BOS+sweep profile without bringing back many losing monthly windows. The next sweeps should focus on conservative risk scaling, session filters, and exact BOS/sweep definitions.
