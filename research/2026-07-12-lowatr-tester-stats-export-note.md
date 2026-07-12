# LowATR OrderFlow Tester-Stats Export Note

Date: 2026-07-12

## Purpose

Reduce dependence on MT5 HTML/XML report export, which has been returning `NO_REPORT` during local hidden validation.

The EA now emits a machine-readable `TESTER_STATS` line from `OnTester()`. The local collector parses those lines alongside final balance so validation CSVs can include more than net profit.

## Code Change

Added a tester-stat print line for:

- net profit
- ending balance
- profit factor
- recovery factor
- Sharpe ratio
- equity drawdown percent
- trade count

Updated `work/collect_local_mt5_log_results.ps1` to parse those values into result and summary CSVs.

## Compile Check

Hidden compile of `outputs/ISLP_LOWATR_ORDERFLOW_PROBE_COMPACT.mq5`:

- Result: `0 errors, 0 warnings`
- Log: `outputs/MT5_HIDDEN_COMPILE_ISLP_LOWATR_TESTER_STATS.log`

## Smoke Run

Package:

`outputs/realtick_islp_lowatr_orderflow_probe_package`

Run CSV:

`outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_PROBE_STATS_RUN.csv`

Stats result CSV:

`outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_PROBE_STATS_RESULTS.csv`

Stats summary CSV:

`outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_PROBE_STATS_SUMMARY.csv`

## Result

| Profile | Parsed | Stats Parsed | Total Net | Losing Windows | Trades | Worst Equity DD % |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `dec_islp_off` | `7 / 7` | `7 / 7` | `+271.42` | `1` | `12` | `7.3344` |
| `islp_lowatr_of` | `7 / 7` | `7 / 7` | `+316.06` | `0` | `11` | `7.3344` |

The smoke run confirms the stats parser works on hidden local MT5 runs.

## Interpretation

This does not make the strategy live-ready.

It does improve the validation workflow because future runs can capture basic risk stats even when MT5 does not export report files.

Important caveat: MT5 may return `profit_factor=0` for zero-trade or one-sided single-trade windows, so the summary keeps raw profit factor and also reports nonzero profit-factor samples separately.

## Next

Run the monthly and quarterly LowATR OrderFlow validation packages again with tester-stat export enabled, then update the research-best evidence with drawdown, trade count, recovery factor, and profit factor context.
