# Transferable Portfolio v0.2-rc1

Operationally hardened release candidate for the current best validated XAUUSD strategy.

## Status

**Research and correctly capitalized demo use only. Real-account trading is disabled by default.**

This release does not claim more profit than v0.1. It preserves the same Band/VWAP reversion and E20 momentum trades while adding shared operational safeguards.

| Model | Net | PF | Trades | Max equity DD | Recovery | Fidelity |
|---|---:|---:|---:|---:|---:|---|
| Model1 | +$1,616.49 | 1.58 | 370 | 3.24% | 4.56 | 740/740 events exact |
| Model4 real ticks | +$1,615.36 | 1.58 | 362 | 2.83% | 5.22 | 724/724 events exact |

Test window: 2015-01-01 through 2026-07-16, `$10,000` initial balance.

## Added Safety

- USD account and `$10,000` initial attachment contract, with 1% tolerance.
- 1.25% shared weekly loss limit.
- 1.50% shared monthly loss limit.
- 48-hour cooldown after nine consecutive portfolio losses.
- 300% minimum margin level before adding risk.
- Immediate close attempt if a managed position loses its stop.
- Existing 0.75% daily loss, 0.75% open-risk, 5% equity-drawdown, hedging-account, symbol, and real-account locks remain.

The weekly, monthly, and streak thresholds were frozen above the worst validated Model4 observations before testing. They remained dormant historically, as required by the zero-drift gate.

## Files

- `Professional_XAUUSD_Operational_Hardening_Portfolio.mq5`: exact tested source.
- `OPERATIONAL_HARDENING_PROFILE.set`: exact Model4-tested profile.
- `evidence/OPERATIONAL_HARDENING_PORTFOLIO_DECISION.md`: promotion decision and limitations.
- `evidence/OPERATIONAL_HARDENING_PORTFOLIO_FIDELITY.csv`: event and metric comparisons.
- `evidence/*RESULTS.csv`: parsed Model1 and Model4 reports.
- `evidence/*COMPILE.log`: compile evidence.
- `MANIFEST.csv`: SHA-256 identity for every release file except the manifest itself.

## Identity

- Source SHA-256: `015DCCDBA020796895C1A71B150C31B4F0F276A9334243BD7474293F73385EB4`
- Compiled binary SHA-256: `4C0BF9BEF949772DA537091EB8E3464FCF9910F9AF55D2A17B7305E1E8ED4756`
- Profile SHA-256: `7E7081A9BF179BC1B93623316D8EFFFB3C0CED91ACF0FFDE91BD61ABD712F6B2`
- Compile result: `0 errors, 0 warnings`.

## Forward Requirement

v0.2-rc1 has no valid forward evidence yet. The existing v0.1 attachment is on a `$100,000` demo and violates its frozen `$10,000` contract, so its days and trades remain excluded. v0.2-rc1 requires a new immutable registration on a correctly capitalized `$10,000` demo before its own 90-day/30-trade clock can begin.

Backtests do not prove future profit. Broker specifications, spreads, slippage, outages, and market regimes can materially change results.
