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

## Files

Probe:

- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_PROBE_STATS_RUN.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_PROBE_STATS_RESULTS.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_PROBE_STATS_SUMMARY.csv`

Monthly:

- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_MONTHLY_STATS_RESULTS.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_MONTHLY_STATS_SUMMARY.csv`

Quarterly:

- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_QUARTERLY_STATS_RESULTS.csv`
- `outputs/REALTICK_ISLP_LOWATR_ORDERFLOW_QUARTERLY_STATS_SUMMARY.csv`

## Result

Probe smoke:

| Profile | Parsed | Stats Parsed | Total Net | Losing Windows | Trades | Worst Equity DD % |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `dec_islp_off` | `7 / 7` | `7 / 7` | `+271.42` | `1` | `12` | `7.3344` |
| `islp_lowatr_of` | `7 / 7` | `7 / 7` | `+316.06` | `0` | `11` | `7.3344` |

Monthly stats rerun:

| Profile | Parsed | Stats Parsed | Total Net | Losing Windows | Trades | Worst Equity DD % | Min Recovery Factor |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `dec_islp_off` | `31 / 31` | `31 / 31` | `+3,637.53` | `1` | `39` | `30.9408` | `-0.9789` |
| `islp_lowatr_of` | `31 / 31` | `31 / 31` | `+3,682.17` | `0` | `38` | `30.9408` | `0.0000` |

Quarterly stats rerun:

| Profile | Parsed | Stats Parsed | Total Net | Losing Windows | Trades | Worst Equity DD % | Min Recovery Factor |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `dec_islp_off` | `11 / 11` | `11 / 11` | `+3,421.49` | `1` | `34` | `30.9408` | `-0.9789` |
| `islp_lowatr_of` | `11 / 11` | `11 / 11` | `+3,435.65` | `1` | `34` | `30.9408` | `-0.5184` |

The smoke run confirmed the stats parser works on hidden local MT5 runs. The monthly and quarterly reruns then added trade count, profit factor, recovery factor, Sharpe, and equity drawdown context to the same LowATR comparison.

## Interpretation

This does not make the strategy live-ready.

It does improve the validation workflow because future runs can capture basic risk stats even when MT5 does not export report files.

The most important risk finding is the `30.9408%` worst equity drawdown reading seen in both monthly and quarterly summaries. LowATR OrderFlow is still the current stability-best candidate because it improves net result, losing-window count, and/or worst losing window versus Dec-ISLP-Off, but this drawdown level is not acceptable evidence for live funding by itself.

Important caveat: MT5 may return `profit_factor=0` for zero-trade or one-sided single-trade windows, so the summary keeps raw profit factor and also reports nonzero profit-factor samples separately.

## Next

Use these stats to drive the next validation pass:

- Rerun Model1 and Model2 on the LowATR OrderFlow candidate.
- Add hold-time, average winner/loser, largest loss, consecutive loss, exposure, spread, swap, commission, and slippage evidence.
- Run older-data, walk-forward, Monte Carlo, and broker-variation validation before considering live use.
