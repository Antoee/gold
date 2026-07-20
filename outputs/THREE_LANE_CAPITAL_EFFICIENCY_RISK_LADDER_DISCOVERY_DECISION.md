# Capital-Efficiency Risk Ladder Discovery Decision

**Decision: REJECTED IN DISCOVERY. No Model 4 run, promotion, forward change, or real trading is permitted.**

- Exact accepted Model 1 reports: `20/20`; preserved first-pass identity refusal: `1`; successful isolated recovery: `1`
- Source SHA-256: `B6810B305549968E2273DAAF736A63759FE5C16F3B416F5C69E39840FBE5173E`
- EX5 SHA-256: `D0619DFEF164F5A70F5AC48D124F553C554F30CE613C9A2A208B150B2E71C7FC`
- Manifest SHA-256: `36BADB8D3656E921BD544F35FA4DA6B2B95438DF200EC0866723B4E75566584E`
- Test contract: XAUUSD M15, `$10,000`, Model 1, 2015-01-01 through 2026-07-12
- The `5%` equity drawdown lock and daily, weekly, monthly, cooldown, entry, and exit controls were unchanged.

| Risk scale | 2015-18 | 2019-20 | 2021-23 | 2024-26 | Continuous | CAGR | PF | Trades | DD | Recovery | Return/DD | Gate |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| 1.00x | +$1,036.19 | +$370.60 | +$629.61 | +$434.36 | +$2,660.57 | 2.07%/yr | 1.98 | 411 | 1.15% | 18.9068 | 23.1391 | CONTROL |
| 1.25x | +$640.21 | +$172.67 | +$480.85 | +$727.55 | +$2,177.34 | 1.72%/yr | 1.7 | 409 | 1.77% | 10.9994 | 12.2994 | False |
| **1.50x center** | +$1,056.17 | +$411.18 | +$746.48 | +$726.64 | +$3,145.43 | 2.4%/yr | 1.69 | 455 | 2.26% | 11.7279 | 13.9159 | False |
| 1.75x | +$760.53 | +$429.63 | +$792.77 | +$1,190.09 | +$3,347.90 | 2.54%/yr | 1.67 | 452 | 3.43% | 8.4381 | 9.7609 | False |

## Frozen Gate

- Every row and all four disjoint eras profitable: `True`
- Center continuous net at least 20% above control: `False`
- Center CAGR at least 0.30 point above control: `True`
- Center retains 90% of PF: `False`
- Center retains 80% of recovery and return/DD: `False`
- Center drawdown no greater than 2.00%: `False`
- Both adjacent profiles pass their 10% growth, 80% quality, and 2.25% DD gates: `False`

## Interpretation

The 1.50x center raised continuous net from `+$2,660.57` to `+$3,145.43` and CAGR from `2.07%` to `2.4%`. It did not earn the required 20% improvement, while PF fell from `1.98` to `1.69`, drawdown rose from `1.15%` to `2.26%`, recovery fell from `18.9068` to `11.7279`, and return/DD fell from `23.1391` to `13.9159`.

The best headline row was `cerl_high175` at `+$3,347.90`, but neither adjacent profile passed. Increasing risk changed position eligibility and skipped-trade behavior, so the ladder was not a clean proportional return increase. Model 4 is closed under the preregistered gate.

The verified Model 4 same-side exit-cooldown leader remains unchanged. The invalid `$100,000` demo is not forward evidence, the registered candidate is unchanged, and real-account trading remains disabled.
