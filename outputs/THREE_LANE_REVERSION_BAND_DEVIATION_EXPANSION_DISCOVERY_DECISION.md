# Reversion Band-Deviation Expansion Discovery Decision

**Decision: REJECTED IN DISCOVERY. No Model 4 run, promotion, forward change, or real trading is permitted.**

- Exact accepted Model 1 reports: `20/20`; preserved first-pass identity refusal: `1`; successful isolated recovery: `1`
- Source SHA-256: `B6810B305549968E2273DAAF736A63759FE5C16F3B416F5C69E39840FBE5173E`
- EX5 SHA-256: `D0619DFEF164F5A70F5AC48D124F553C554F30CE613C9A2A208B150B2E71C7FC`
- Manifest SHA-256: `C8C81D2FA812C73B87F1C8E8DDDDA98570FE4ECECAFBF096D2A7BF11EAE43042`
- One-factor contract: only `InpRVBollingerDeviation` and the evidence run label changed from the exact leader.
- Test contract: XAUUSD M15, `$10,000`, Model 1, four disjoint eras plus continuous 2015-01-01 through 2026-07-12.

| Band deviation | 2015-18 | 2019-20 | 2021-23 | 2024-26 | Continuous | CAGR | PF | Trades | RV trades | RV net | DD | Recovery | Return/DD | Gate |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| 2 | +$1,036.19 | +$370.60 | +$629.61 | +$434.36 | +$2,660.57 | 2.07%/yr | 1.98 | 411 | 38 | +$1,698.53 | 1.15% | 18.9068 | 23.1391 | CONTROL |
| 1.9 | +$757.22 | +$207.54 | +$766.20 | +$407.76 | +$2,270.43 | 1.79%/yr | 1.85 | 406 | 35 | +$1,409.71 | 1.33% | 14.3236 | 17.0677 | False |
| **1.80 center** | +$671.92 | +$111.27 | +$612.68 | +$367.16 | +$1,915.92 | 1.53%/yr | 1.68 | 407 | 39 | +$1,045.73 | 1.37% | 12.3385 | 13.9854 | False |
| 1.7 | +$374.25 | +$169.69 | +$327.09 | +$363.42 | +$1,260.43 | 1.04%/yr | 1.44 | 400 | 37 | +$535.78 | 1.8% | 6.4647 | 7 | False |

## Interpretation

Lowering the band produced monotonic deterioration: continuous net fell from `+$2,660.57` at 2.00 to `+$2,270.43`, `+$1,915.92`, and `+$1,260.43`. Drawdown rose from `1.15%` to as high as `1.8%`.

The looser thresholds entered earlier but did not create a robust activity expansion. The 1.90 candidate added five unique reversion trades worth `+$306.12`, while displacing eight control reversion trades worth `+$583.66`. The 1.80 and 1.70 candidates displaced even stronger control cohorts. This family is closed rather than rescued with another threshold.

The verified Model 4 same-side exit-cooldown leader remains unchanged. The invalid `$100,000` demo is not forward evidence, the registered candidate is unchanged, and real-account trading remains disabled.
