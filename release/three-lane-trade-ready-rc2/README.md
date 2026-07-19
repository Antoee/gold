# Three-Lane Trade-Ready RC2

**Classification: exact historically validated trade-ready safety candidate. Not registered for forward trading and not approved for real money.**

## Files

- `Professional_XAUUSD_Three_Lane_Trade_Ready_RC2.mq5`: exact tested source.
- `THREE_LANE_TRADE_READY_RC2.set`: exact tested center profile.

## Identity

| Artifact | SHA-256 |
|---|---|
| Source | `2F1C1C74067DA6173EB4133DB75C0B0DB4DE7BE46F2BB7A453AEE044536B2158` |
| Profile | `60BF5D013153E3A38A6BD932E88CB41BD8FEAB5108648DDCBA1CCCCDD4D737F3` |
| Continuous report | `325427B38F59F1788B814C08DF7B868C61640F72F1156874A8467AAD58C95C26` |
| Continuous-run binary | `E24203F2E7AF184B6B6BB3902F7C8711DD887B0E0346C22ED87E8F07EB1AC7B8` |

MetaEditor output was 0 errors and 0 warnings. Builds are not bit-reproducible across isolated MT5 runtimes, so the binary hash identifies the exact executable that produced the continuous report. This package distributes source and profile, not an unverified `.ex5`.

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

The final RC2 source exactly reproduced RC1 across eight broad rows and 12 annual/YTD rows. Its continuous 367-trade ledger matched RC1 on every field except a non-economic displayed stop comment; entry, exit, profit, and risk fields were identical.

## Added Hardening

- Final-result confirmation for entries, closes, modifications, and order deletion; `PLACED` is not accepted as a final fill.
- Ownership-checked position close/modify and residual-order deletion.
- Post-fill reconciliation of exact position count, side, volume step/caps, SL/TP geometry, lane risk, and account-wide risk.
- Fail-closed cleanup of positions and active orders after ambiguous or invalid fills.
- Unexpected portfolio-order audit at initialization, on ticks, and on the timer.
- Verified persistent safety-state writes/deletes; persistence failure blocks new entries.
- Terminal/account permission, quote-age, spread, stops-level, freeze-level, margin, symbol, currency, and starting-capital guards.
- Real-account trading remains disabled in the tested profile.

The static and evidence suite passed `79/79` checks. No martingale, grid, averaging down, or recovery sizing is present.

## Remaining Boundary

This is the strongest exact executable package in the repository, but historical equivalence is not forward evidence. It still requires broker-specification variation and a new preregistered untouched `$10,000` demo sample. The current `$100,000` attachment remains invalid and must count as zero days and zero trades. Do not alter its registration to make it pass, and do not use RC2 on a real account.
