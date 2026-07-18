# RDMC Money-Ready Gate Repair Executable Contract

**NOT A NEW BEST AND NOT MONEY-READY.** This is the full requalification contract for the static-admission successor.

## Identity

- Source SHA-256: `104F1B2D77876FA9856C8BECF7BF2D81DAB187F54BF3ED12C07493BCD6F6D6C8`
- Profile SHA-256: `8A2D3B36ACD6A7B754B20A5D8AF8A98ED2F2AFD739B03CC3EE1A82BD8C2E3E3E`
- Manifest SHA-256: `EB48BDE3D67F9D16BAD427AB5ACC25BC8DFF8D8F29839EB95ADE615F59668972`
- Initial deposit: `$10,000 USD`
- Signal chart: `XAUUSD M15`

## Efficient gate order

1. Wave 1: Model1 2019 and 2022. Reject immediately on nonpositive net, low PF/activity, or drawdown above `3%`.
2. Wave 2: three disjoint Model1 eras plus continuous Model1. Model1 remains reject-only.
3. Wave 3: Model4 real ticks for 2019 and 2022.
4. Wave 4: three disjoint Model4 eras, verified tick-cache union, then continuous Model4.
5. Wave 5: all 12 annual/YTD Model4 restarts, with every row required profitable.

Continuous Model4 must exceed PF `1.30`, 250 trades, recovery `3`, CAGR `1.00%`, and stay at or below `5%` drawdown. Passing this queue still opens, but does not satisfy, identity-bound executable-ledger cost/Monte Carlo stress, distinct-broker validation, and valid forward testing.

Both local launch locks are currently present. No compile, report, profit, forward substitution, or real-account approval is inferred from static equivalence. Real-account trading remains disabled.
