# Three-Lane DDB 0.45 Decision

Date: 2026-07-16

Verdict: **PROVISIONAL RESEARCH BEST / DEMO FORWARD-TEST CANDIDATE. NOT MONEY-READY. NOT APPROVED FOR LIVE TRADING.**

## Frozen identity

- EA source: `work/Professional_XAUUSD_EA_THREE_LANE_ISOLATED.mq5`
- Source SHA-256: `45B3D0704CFAD1B30E1E5E4C7C7079B6188A674546F8F2EB70DC72BF1A97EF90`
- Frozen daily Donchian dependency: `outputs/three_lane_ddb045_model4_validation_package/dependencies/daily_donchian/Professional_XAUUSD_EA.mq5` (`D387779DC3BABD6A8294C46E5827D1029AA536EA29F91C06C357D66D2B098153`)
- Profile: `outputs/three_lane_ddb045_model4_validation_package/profiles/three_lane_ddb045.set`
- Profile SHA-256: `2E02246D24250D71DEC59A42AD1D7DE793614EBECEB309A879FE873D8F886312`
- MT5: MetaQuotes-Demo Build 5989
- Starting balance: `$10,000`
- Compile: `0 errors, 0 warnings`

The source combines the isolated M15 maintained lane, isolated H1 Bollinger/VWAP reversion lane, and isolated daily Donchian breakout lane. Account-level exposure, drawdown, loss, spread, cost, margin, and maximum-position guards remain shared. The Donchian lane uses `0.45x` of the base risk request; the profile still caps effective trade risk at `0.50%` and account exposure at `0.75%`.

## Main evidence

| Window | Tick quality | Net | Total return | Annualized | CAGR | PF | Trades | Max DD | Recovery |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 2015-2026 continuous | 65% real ticks | `+$526.20` | `+5.26%` | `+0.46%/yr` | `+0.45%/yr` | `3.26` | `51` | `0.77%` | `6.54` |
| 2015-2018 restarted | 0% real ticks | `+$184.36` | `+1.84%` | `+0.46%/yr` | `+0.46%/yr` | `9.38` | `7` | `0.72%` | `2.53` |
| 2019-2022 restarted | 99% real ticks | `+$217.29` | `+2.17%` | `+0.54%/yr` | `+0.54%/yr` | `3.12` | `25` | `0.78%` | `2.70` |
| 2023-2026 restarted | 100% real ticks | `+$148.64` | `+1.49%` | `+0.42%/yr` | `+0.42%/yr` | `2.30` | `20` | `0.60%` | `2.46` |
| 2019-2026 continuous | 99% real ticks | `+$380.23` | `+3.80%` | `+0.51%/yr` | `+0.50%/yr` | `2.80` | `46` | `0.78%` | `4.73` |

The 2015-2018 broker history is modeled ticks, not real-tick proof. It is retained only as broad-regime evidence. The 2019-2026 result is the higher-quality continuous headline.

## Matched stability comparison

On the same source, broker, dates, and 99%-real-tick 2019-2026 path:

| Candidate | Net | Annualized | PF | Trades | Max DD | Recovery |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Three-lane DDB 0.45 | `+$380.23` | `+0.51%/yr` | `2.80` | `46` | `0.78%` | `4.73` |
| Frozen two-lane risk010 | `+$347.94` | `+0.46%/yr` | `2.80` | `42` | `0.59%` | `5.75` |

The third lane adds `$32.29` (`+9.28%`) and four trades, but worsens drawdown and recovery. It is the higher-profit provisional candidate; the two-lane profile remains the stability benchmark.

## Robustness checks

- Model1 neighboring Donchian allocations from `0.40x` through `0.60x` kept every broad era profitable. This is a plateau, not a one-value profit spike.
- Restarted yearly Model4: 10 positive years, one flat/no-trade year, and one losing year. The only loss was 2017 at `-$3.29`; worst yearly drawdown was `0.59%`.
- Five Model4 execution proxies all stayed profitable. The harshest high-commission proxy made `+$326.98`, PF `2.54`, with `0.83%` drawdown; the wide-spread and tight-slippage proxies made `+$342.84`, PF `2.60`, with `0.88%` drawdown. These are same-broker input proxies, not second-broker proof.
- 10,000-trial realized-R stress: 5th-percentile net `+30.12R`, median `+37.27R`, and worst trial `+19.20R`.
- The same stress still failed the strict `6R` drawdown cap (`6.56R`) and five-loss-streak cap (`7`). This blocks money-ready status.

## Decision

Freeze this source/profile pair for unseen demo-forward testing after 2026-07-12. Do not tune it using new forward results unless the frozen evaluation period is first closed and recorded.

Do not replace the maintained A167 source or remove the real-account lock. Live review still requires a second broker with actual XAUUSD contract data, forward/demo evidence, execution-cost validation, and a passing loss-streak/drawdown stress policy.
