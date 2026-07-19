# Independent M15 ADR-Exhaustion Reversion Decision

Decision date: 2026-07-19

**Verdict: rejected during frozen Model 1 discovery. No 2021-2026 holdout was opened, Model 4 was skipped, no new best was promoted, and real-account trading remains disabled.**

## Test Contract

The standalone EA measured the current intraday range against the prior 20 completed daily ranges, required a directional ADR extension and a fresh M15 rejection candle, and targeted the pre-signal daily anchored VWAP. It used an H1 ADX/range-regime guard, a structure stop behind the rejection wick, broker-native `OrderCalcProfit` sizing, and a maximum `$8` stop-price distance.

- Source: `work/Independent_XAUUSD_M15_ADR_Exhaustion_Reversion.mq5`
- Source SHA-256: `3965C11212CC615675F13118E711F6D62805218124FC0A707EBE838DD446E281`
- Compile: `0 errors, 0 warnings`
- Discovery data only: 2015-01-01 through 2020-12-31
- Identity-valid reports: `33 / 33`
- Candidate variants: `11`
- Risk per accepted trade: `0.10%` on `$10,000`
- Post-2020 configurations: `0`
- Model 4 configurations: `0`

Worker 2 failed its assigned rows before report export. The exact eleven unchanged configurations were rerouted to worker 3 and all completed. The canonical run contains one identity-valid report per frozen queue row.

## Discovery Evidence

Ten profiles made zero trades in 2015-2018. The only profile that traded in that era, `aer_adx36`, lost `$8.64`. No row came remotely close to the frozen minimum of 80 continuous trades.

| Candidate | 2015-18 | PF | Trades | 2019-20 | PF | Trades | Continuous | PF | Trades | DD | Decision |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| `aer_adr075` | `$0.00` | `0.00` | `0` | `+$20.08` | `1.80` | `6` | `+$20.08` | `1.80` | `6` | `0.17%` | rejected |
| `aer_adr095` | `$0.00` | `0.00` | `0` | `+$15.62` | `0.00` | `1` | `+$15.62` | `0.00` | `1` | `0.06%` | rejected |
| `aer_wick50` | `$0.00` | `0.00` | `0` | `+$7.54` | `1.93` | `2` | `+$7.54` | `1.93` | `2` | `0.14%` | rejected |
| `aer_center` | `$0.00` | `0.00` | `0` | `+$0.01` | `1.00` | `3` | `+$0.01` | `1.00` | `3` | `0.14%` | rejected |
| `aer_move045` | `$0.00` | `0.00` | `0` | `+$0.01` | `1.00` | `3` | `+$0.01` | `1.00` | `3` | `0.14%` | rejected |
| `aer_move065` | `$0.00` | `0.00` | `0` | `+$0.01` | `1.00` | `3` | `+$0.01` | `1.00` | `3` | `0.14%` | rejected |
| `aer_vol000` | `$0.00` | `0.00` | `0` | `+$0.01` | `1.00` | `3` | `+$0.01` | `1.00` | `3` | `0.14%` | rejected |
| `aer_vol110` | `$0.00` | `0.00` | `0` | `+$0.01` | `1.00` | `3` | `+$0.01` | `1.00` | `3` | `0.14%` | rejected |
| `aer_rr135` | `$0.00` | `0.00` | `0` | `+$0.01` | `1.00` | `3` | `+$0.01` | `1.00` | `3` | `0.14%` | rejected |
| `aer_adx28` | `$0.00` | `0.00` | `0` | `-$7.53` | `0.00` | `1` | `-$7.53` | `0.00` | `1` | `0.08%` | rejected |
| `aer_adx36` | `-$8.64` | `0.00` | `1` | `+$0.01` | `1.00` | `3` | `-$8.63` | `0.64` | `4` | `0.22%` | rejected |

The tester diagnostics confirm this was not a broker-minimum or execution artifact: minimum-lot rejects were zero, exposure rejects were zero, and order failures were zero. Thousands of partial ADR-exhaustion candidates collapsed to only a handful of complete signals after candle direction, fresh-extreme, VWAP, regime, and minimum-RR requirements.

## Decision

- Reject the current ADR-exhaustion/VWAP-reversion family before recent data.
- Do not loosen its filters against these observed failures or use 2021-2026 to rescue it.
- Skip Model 4, annual, cost, and Monte Carlo work because the fast broad-era gate failed activity and consistency.
- Keep the RC2 ATB150 source/profile unchanged as the historical best.
- Preserve the frozen forward registration, invalid-account boundary, evidence logs, and hard real-account lock.

## Evidence

- `outputs/INDEPENDENT_M15_ADR_EXHAUSTION_REVERSION_DISCOVERY_MODEL1_RESULTS.csv`
- `outputs/INDEPENDENT_M15_ADR_EXHAUSTION_REVERSION_DISCOVERY_MODEL1_SUMMARY.csv`
- `outputs/INDEPENDENT_M15_ADR_EXHAUSTION_REVERSION_DISCOVERY_MODEL1_RUN.csv`
- `outputs/INDEPENDENT_M15_ADR_EXHAUSTION_REVERSION_DISCOVERY_DECISION.csv`
- `outputs/INDEPENDENT_M15_ADR_EXHAUSTION_REVERSION_DISCOVERY_COMPILE.log`
