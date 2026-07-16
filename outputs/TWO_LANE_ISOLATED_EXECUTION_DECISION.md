# Two-Lane Isolated-Execution Decision

Date: 2026-07-16

## Decision

Accept `two_lane_risk010` as a **low-drawdown demo forward-test candidate only**.

It is not the maintained profit best, is not approved for real money, and does not prove future profitability. The maintained EA and real-account hard lock remain unchanged.

## Frozen identity

- Experimental source: `work/Professional_XAUUSD_EA_TWO_LANE_ISOLATED.mq5`
- Source SHA-256: `007B8DCF4A9A66652B1F34A32893ECA676165B88239119270A9B4D138F184472`
- Profile: `outputs/two_lane_isolated_execution_screen_package/profiles/two_lane_risk010.set`
- Profile SHA-256: `7CABA7BFB0C24BE307B261E892F36D7F8C5609B4265E5951543487E95EBDA44D`
- Starting balance: `$10,000`
- Model4 data end: `2026-07-12`
- Compile result: `0 errors, 0 warnings`

## Broad-window evidence

| Window | Model1 net | Model4 net | Model1 PF | Model4 PF | Model1 trades | Model4 trades | Model4 max DD |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Continuous 2015-2026 YTD | `+$427.61` | `+$361.04` | `2.83` | `2.83` | `51` | `45` | `0.58%` |
| Older 2015-2018 | `+$13.07` | `+$13.10` | `4.86` | `4.85` | `3` | `3` | `0.07%` |
| Middle 2019-2022 | `+$285.68` | `+$185.00` | `4.25` | `3.18` | `26` | `21` | `0.35%` |
| Recent 2023-2026 YTD | `+$114.48` | `+$148.64` | `1.78` | `2.30` | `21` | `20` | `0.60%` |

The fixed acceptance rule passed: every broad era remained profitable on real ticks, continuous PF stayed above `1.20`, all reports returned, and Model4 did not reverse the Model1 result.

## Yearly Model1 gate

The conservative candidate returned all `12 / 12` restarted yearly reports. The aggregate restart-window score was `+$491.82` on `53` trades, with a worst yearly result of `-$3.39` and worst yearly drawdown of `0.69%`. The negative years were tiny one-trade outcomes in 2015, 2017, and 2019; 2016 was inactive.

This is preferable to the neighboring `risk030` candidate, which earned more in aggregate but had larger negative restarted years, more losing years, and a near-flat negative 2024.

## Why this is not future-proof

Testing 2015-2026 reduces dependence on the 2024-now regime, but no historical period can contain an unseen future regime. Gold can change through volatility, liquidity, spread, policy, broker execution, and market-participant behavior.

The continuous real-tick sample is only `45` trades and annualized return is approximately `0.31%` at the tested sizing. The older era contains only three trades. Those are insufficient for a live-money claim even though drawdown and PF are encouraging.

## Required next evidence

1. Freeze source and profile; do not tune them using forward outcomes.
2. Run demo forward testing on data after `2026-07-12` with broker costs and execution recorded.
3. Test a second broker with different XAUUSD contract, spread, swap, and session specifications.
4. Monitor rolling trade frequency, PF, realized R, slippage, and drawdown against predeclared pause limits.
5. Re-run walk-forward and Monte Carlo gates before any live-readiness review.

Exact comparison: `outputs/TWO_LANE_MODEL1_MODEL4_COMPARISON.csv`  
Model4 reports: `outputs/TWO_LANE_RISK010_MODEL4_RESULTS.csv`  
Yearly Model1 reports: `outputs/TWO_LANE_YEARLY_MODEL1_RESULTS.csv`
