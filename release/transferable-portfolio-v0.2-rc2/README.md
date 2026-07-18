# Transferable Portfolio v0.2-rc2

Dedicated-account and funding-drift hardened release candidate for the current best validated XAUUSD strategy.

## Status

**Research and correctly capitalized demo use only. Real-account trading is disabled by default.**

rc2 does not claim more profit than v0.1 or rc1. It preserves the same Band/VWAP reversion and E20 momentum behavior while making the persisted account contract fail closed after funding changes or unrelated trading.

| Model | Net | PF | Trades | Max equity DD | Recovery | Fidelity |
|---|---:|---:|---:|---:|---:|---|
| Model1 | +$1,616.49 | 1.58 | 370 | 3.24% | 4.56 | 740/740 events exact |
| Model4 real ticks | +$1,615.36 | 1.58 | 362 | 2.83% | 5.22 | 724/724 events exact |

Test window: 2015-01-01 through 2026-07-16, `$10,000` initial balance.

## rc2 Safety

- New portfolio identity prevents accidental reuse of rc1's persisted approval.
- USD account and `$10,000` first-attachment contract, with 1% tolerance.
- Funding-history baseline covers balance, credit, charge, correction, bonus, standalone commission, and interest records.
- Any later funding-history change locks new risk pending manual review.
- Non-portfolio buy/sell history locks the dedicated account.
- A portfolio magic used on a symbol other than the allowed XAUUSD also locks the account.
- Account-history checks are invalidated after each transaction rather than rescanned on every tick.
- rc1's weekly/monthly loss, loss-streak cooldown, margin floor, missing-stop fail-close, drawdown, open-risk, hedging, symbol, and real-account controls remain.

## Dynamic Canary

The exact final source was run with a deliberate `$100,000` tester deposit. MT5 recorded the wrong deposit and canary identity, the EA logged the starting-capital initialization lock, MT5 stopped on nonzero `OnInit`, and the report stayed flat with zero trades and zero net profit.

Tester mode cannot create realistic post-registration deposits or unrelated live-account transactions. Those paths are compile-checked and source-audited but still require observation on a correctly registered demo.

## Files

- `Professional_XAUUSD_Operational_Hardening_Portfolio_RC2.mq5`: exact tested source.
- `OPERATIONAL_HARDENING_PROFILE.set`: exact Model4-tested profile.
- `evidence/OPERATIONAL_HARDENING_RC2_DECISION.md`: promotion decision and limitations.
- `evidence/OPERATIONAL_HARDENING_RC2_FIDELITY.csv`: exact event and metric comparison.
- `evidence/OPERATIONAL_HARDENING_RC2_CONTRACT_CANARY*`: executable wrong-capital evidence.
- `evidence/*RESULTS.csv`: parsed Model1 and Model4 evidence.
- `evidence/*COMPILE.log`: compile evidence.
- `MANIFEST.csv`: SHA-256 identity for every release file except the manifest itself.

## Identity

- Source SHA-256: `9141137A9550F3394DE85E1725E018671B4F2A2FF0F43A3EF23F9FB1238CD302`
- Compiled binary SHA-256: `710C20730933E6EB2AE1AD14079C67E33C592881E1471BF0110E045335153EE5`
- Profile SHA-256: `5C45D578B42609D3792EA692D5A13A9E0D90C8C14D0376F807E6F6079EC6B827`
- Compile result: `0 errors, 0 warnings`.

## Forward Requirement

rc2 has no valid forward evidence. The existing frozen v0.1 attachment remains invalid on a `$100,000` demo against its `$10,000` contract. rc2 requires a separate immutable registration on a fresh `$10,000` USD demo hedging account before its own 90-day/30-trade clock can begin.

Backtests do not prove future profit. Broker specifications, spreads, slippage, outages, cash adjustments, and market regimes can materially change results.
