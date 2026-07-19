# Three-Lane Adaptive Trend RC1

**Classification: best validated historical stability candidate. Not registered for forward trading and not approved for real money.**

## Files

- `Professional_XAUUSD_Three_Lane_Adaptive_Trend_RC1.mq5`: exact tested source.
- `THREE_LANE_ADAPTIVE_TREND_RC1.set`: exact tested center profile.

## Identity

| Artifact | SHA-256 |
|---|---|
| Source | `51AE67DB56C3B584E8DA3A64C4B43ECAAE9ACE7E96541C22C9C5AC10E389FABB` |
| Profile | `48636124EE5E38D516A48D7551F401F4B179A34296B6373C317F843CD3DEF1B1` |
| Continuous report | `D946E7E90AE4E17BEE43282E97EFFD9826B8C3EB489AC367B3A67AA67E361271` |
| Continuous-run binary | `6229E0023D3F54CA9A3404EA0584E97010230FECF4B1C99F6E034880A97039FC` |

MetaEditor builds are not bit-reproducible across the four isolated local runtimes, so the binary hash above identifies the exact executable that produced the continuous report. The repository release distributes source and profile, not an unverified `.ex5`.

## Validated Result

MT5 Model 4 real ticks, XAUUSD, `$10,000`, 2015-01-01 through 2026-07-12:

| Metric | Value |
|---|---:|
| Net / return | `+$1,994.62 / +19.95%` |
| CAGR | `+1.59%` |
| Profit factor | `1.82` |
| Trades | `367` |
| Maximum equity drawdown | `$139.11 / 1.19%` |
| Recovery factor | `14.34` |

The exact profile passed:

- 2/2 prior failure years on real ticks.
- 3/3 disjoint broad eras plus the continuous real-tick window.
- 12/12 annual/YTD real-tick restarts.
- 367/367 initial-risk checks.
- Four deterministic cost scenarios through `0.10R` added per trade.
- Eight seeded 10,000-trial order-aware Monte Carlo scenarios.

## Safety Contract

- Real-account trading defaults disabled and requires a hard-coded approval handshake.
- XAUUSD, USD currency, `$10,000` initial balance, hedging, and dedicated-account contracts.
- Lane risk: reversion `0.45%`, momentum `0.15%`, adaptive trend `0.10%`.
- Account-wide open-risk cap `0.75%`; maximum three positions.
- Broker-valued stop risk, required protective stops, spread/margin gates, and daily/weekly/monthly/equity loss limits.
- No martingale, grid, averaging down, or recovery sizing.

## Do Not Attach Yet

This package is published for reproducible review. It is not the registered forward candidate. The next admissible step is a safety-hardened exact derivative, followed by equivalence testing, broker variation, and a new preregistered `$10,000` demo attachment. Do not alter the current invalid demo registration to make this package pass.
