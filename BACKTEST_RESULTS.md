# Backtest Results

EA: `Professional_XAUUSD_EA`

Symbol/timeframe: `XAUUSD`, `M15`

Main validation period: `2024.01.01` to `2026.07.02`

Deposit: `$1,000`

Leverage: `1:100`

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

## Monthly Confirmation Filter Research

- Baseline: total `+$1,903.98`, worst `-$83.61`, profitable `7`, flat `6`, losing `17`
- `buy2_sell3`: total `+$1,492.91`, worst `-$83.61`, profitable `10`, flat `6`, losing `14`
- `confirm3`: total `+$487.71`, worst `-$84.75`, profitable `7`, flat `10`, losing `13`
- `buy3_sell2`: total `+$331.04`, worst `-$83.26`, profitable `8`, flat `7`, losing `15`
- `confirm4`: total `$0.00`, all 30 months flat

Conclusion: `buy2_sell3` improves monthly start-window consistency, but it gives up about `$411` of monthly net and is not promoted.

## Monthly Regime And Trailing Research

Completed ADX results:

- `adx22`: total `+$972.38`, worst `-$83.61`, profitable `7`, flat `6`, losing `17`
- `adx25`: total `+$352.74`, worst `-$83.26`, profitable `5`, flat `6`, losing `19`
- `adx30`: total `+$104.14`, worst `-$82.94`, profitable `7`, flat `6`, losing `17`

Conclusion: stricter ADX filtering is rejected because it removes too much profit without improving monthly robustness.

No-trailing-stop monthly result:

- `InpUseATRTrailing=false`
- Monthly total: `+$1,902.84`
- Worst month: `-$74.68`
- Best month: `+$937.98`
- Profitable months: `7`
- Flat months: `7`
- Losing months: `16`

Conclusion: disabling ATR trailing is the best monthly robustness lead so far. It nearly matches baseline monthly net while improving worst month and reducing losing months by one. It is not promoted yet because broader split validation needs a clean rerun before changing defaults.

## Other Rejected Research Paths

- Directional confirmation `buy2_sell3_ny`: full period `+$2,620.98`, 2025/2025 H1 losing.
- Equity drawdown guard `dd4`: full period `+$85.45`, 2025 losing.
- MTF slope direction no-date filter: best stress-set total `-$444.20`.
- H4 no-date signal timeframe: full validation `-$136.90`, no profitable validation windows.

## Conclusion

The current promoted configuration makes profit on the full real-tick period, all tested yearly windows, and all half-year walk-forward windows. Monthly validation now shows the start-point problem clearly: `17` of `30` monthly windows are losing. The EA is still not production-ready.

Next optimization target: cleanly rerun no-trail split validation, because it is the first candidate to preserve monthly profit while slightly improving monthly robustness.
