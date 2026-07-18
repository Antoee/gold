# RDMC Money-Ready Gate Repair Second-Broker Validation Contract

Status: **PREREGISTERED / PRIMARY PREREQUISITE LOCKED / ZERO SECOND-BROKER REPORTS / NOT PROMOTED**

**SUCCESSOR-SPECIFIC IDENTITY. NO PRIMARY OR OLDER SECOND-BROKER EVIDENCE IS INHERITED.**

This gate tests whether the exact combined candidate transfers to genuinely different XAUUSD broker data and trading specifications. Broker-proxy input changes on the primary data cannot satisfy it.

## Frozen Identity

- Source SHA-256: `104F1B2D77876FA9856C8BECF7BF2D81DAB187F54BF3ED12C07493BCD6F6D6C8`
- Profile SHA-256: `8A2D3B36ACD6A7B754B20A5D8AF8A98ED2F2AFD739B03CC3EE1A82BD8C2E3E3E`
- Manifest SHA-256: `30A508459E0C408BFF9A905F5C9AEB01AF9D411C39165734F197CC2928CE6CB5`
- Starting capital: `10,000 USD`
- Symbol/timeframe/model: `XAUUSD M15`, Model4 real ticks
- Data cutoff: `2026.07.12`
- Rows: `18`, with every config SHA-256 pinned in the manifest

All 52 stored MT5 reports have one primary broker-company fingerprint, and all four local portable runtimes contain only the same primary `MetaQuotes-Demo` data family. None is second-broker evidence.

## Admission Order

1. The primary 24-row executable gate must pass.
2. The exact primary continuous executable ledger must pass deterministic cost and order-aware Monte Carlo stress.
3. One anonymized, valid, distinct-broker specification row must be supplied.
4. Second-broker wave 1 may then start. Later waves remain closed until every earlier row passes.

Evidence supplied before these prerequisites is recorded but not admitted. The current state is `AWAITING_PRIMARY_EXECUTABLE_LEDGER_STRESS`.

## Specification Contract

The secondary specification uses SHA-256 fingerprints of normalized company and server names. Raw account identifiers are prohibited, and the published specification contains no raw company/server names.

Required specification fields include:

- distinct company and server fingerprints;
- `XAUUSD`, `USD`, hedging mode, full trading mode, and terminal build at least `5989`;
- contract size, point, tick size, profit/loss tick values, digits, volume minimum/maximum/step, stop/freeze levels, and swap terms;
- frozen source/profile identities and a UTC capture timestamp;
- `AccountIdentifierPublished=False`.

The company fingerprint must differ from the primary fingerprint. A renamed file, broker proxy, or second account on the same company fingerprint is insufficient.

## Efficient Real-Tick Waves

| Wave | Runs | Purpose |
|---:|---:|---|
| 1 | 2 | Reject immediately on the known 2019 and 2022 failure years |
| 2 | 4 | Check older, middle, recent, and continuous risk-normalized performance |
| 3 | 12 | Require every annual/YTD restart positive and test cross-broker consistency |

The package is sequential by default because only one genuine secondary runtime is assumed. It uses no Model1 promotion proxy.

## Frozen Row Gates

- Critical 2019/2022: positive net, PF at least `1.05`, frozen activity floor, and equity drawdown at most `3%`.
- Broad eras: positive net, PF at least `1.20`, frozen activity floor, and equity drawdown at most `5%`.
- Continuous: positive net, PF at least `1.30`, at least 250 trades, equity drawdown at most `5%`, recovery at least `3`, and CAGR at least `1.00%`.
- Annual/YTD: all 12 rows positive with their frozen activity floors and equity drawdown at most `3%`.

## Identity-Bound Report Admission

- Every canonical result must use the exact report directory, expected filename, adjacent sidecar, config hash, source hash, profile hash, report hash, compiled-binary hash, and broker-specification hash.
- The sidecar must pass schema, byte-count, UTC timestamp, and embedded-source validation.
- The evaluator extracts the report company fingerprint and requires it to match the distinct specification.
- Supplied deposit, net, balance, PF, expected payoff, Sharpe, trades, equity drawdown, recovery, win rate, loss streak, and calculated CAGR must reproduce the bound report.
- The collector accepts only the currently admitted wave, rejects account-number fields before publication, and requires one compiled-binary identity across every secondary row.
- Missing, moved, renamed, tampered, incomplete, or same-broker evidence fails closed.

## Consistency Gates

After all 18 rows pass:

- summed annual net / secondary continuous net must remain within `0.75x` to `1.25x`;
- secondary continuous net / primary continuous net must remain within `0.50x` to `1.50x`;
- secondary continuous trades / primary continuous trades must remain within `0.70x` to `1.30x`.

These limits reject both strategy collapse and suspiciously different execution paths.

## Hard Boundary

- Both local MT5 launch locks remain active; package construction and evaluation launch no terminal, tester, or MetaEditor process.
- A second-broker pass is portability evidence, not proof of future profit or real-money approval.
- The unchanged candidate must still complete the valid frozen `$10,000` forward-demo contract.
- The registered forward candidate, binary/run evidence, and real-account safety lock remain unchanged.
