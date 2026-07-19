# Three-Lane Trade-Ready RC2 Decision

**Decision: PROMOTE AS THE EXACT TRADE-READY HISTORICAL CANDIDATE. DO NOT REGISTER FORWARD OR ENABLE REAL MONEY YET.**

## Identity

- Source SHA-256: `2F1C1C74067DA6173EB4133DB75C0B0DB4DE7BE46F2BB7A453AEE044536B2158`
- Center profile SHA-256: `60BF5D013153E3A38A6BD932E88CB41BD8FEAB5108648DDCBA1CCCCDD4D737F3`
- Continuous report SHA-256: `325427B38F59F1788B814C08DF7B868C61640F72F1156874A8467AAD58C95C26`
- Continuous-run binary SHA-256: `E24203F2E7AF184B6B6BB3902F7C8711DD887B0E0346C22ED87E8F07EB1AC7B8`

## Result

Final-source MT5 Model 4 real ticks, XAUUSD, `$10,000`, 2015-01-01 through 2026-07-12:

| Metric | Result |
|---|---:|
| Net profit | `+$1,994.62` |
| Return / CAGR | `+19.95% / +1.59%` |
| Profit factor | `1.82` |
| Trades | `367` |
| Maximum equity drawdown | `$139.11 / 1.19%` |
| Recovery factor | `14.3384` |

## Final Gates

| Gate | Result |
|---|---|
| MetaEditor | `0 errors, 0 warnings` |
| Model 1 critical | `4/4 parsed and profitable` |
| Model 4 critical | `4/4 parsed and profitable` |
| Model 4 broad | `8/8 parsed, profitable, and exactly equal to RC1 metrics` |
| Model 4 annual/YTD | `12/12 parsed, profitable, and exactly equal to RC1 metrics` |
| Continuous ledger | `367/367 trades behavior-equivalent to RC1` |
| Hard-risk ledger | `367/367 pass` |
| Deterministic cost stress | `4/4 pass` |
| Seeded Monte Carlo | `8/8 pass` |
| RC2 safety suite | `79/79 pass` |

The final code review found and closed one live-only residual-order risk: an ambiguous market request can remain active after a non-final `PLACED` response. RC2 now rejects that response as final, deletes owned residual orders, closes invalid fills, verifies cleanup, and blocks further entries if cleanup or persistent safety state cannot be confirmed.

## Decision Boundary

RC2 replaces RC1 as the repository's strongest exact historical candidate because it preserves the same strategy behavior while adding fail-closed execution controls. It does not replace the registered forward candidate. The attached `$100,000` demo violates the frozen `$10,000` contract, so its days and trades remain invalid.

The next admissible gates are broker-specification variation and a new, preregistered, untouched `$10,000` demo run. Real-account trading remains disabled and is not recommended.
