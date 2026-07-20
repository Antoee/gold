# Three-Lane Reversion Lot-Cap Discovery Decision

**Decision: REJECTED IN DISCOVERY. No holdout, Model 4, promotion, forward change, or live approval is permitted.**

- Reports: `15 / 15` parsed with exact source, EX5, config, and report identity
- Attempts: `15`; identity refusals: `0` (excluded)
- Exact ATB150 source SHA-256: `2F1C1C74067DA6173EB4133DB75C0B0DB4DE7BE46F2BB7A453AEE044536B2158`
- Exact EX5 SHA-256: `A1B25C0FF17C891DA1C955D442BA39EF86722A5933FA6DEE9CC989517765492F`
- Starting balance: `$10,000`; discovery data: `2015-01-01` through `2020-12-31`; model: MT5 Model 1
- Only trading input changed: `InpRVMaximumPositionLots`; requested reversion risk stayed `0.45%`
- Real-account trading: disabled

| Reversion lot cap | 2015-18 | 2019-20 | Continuous | Return | CAGR | PF | Trades | DD | Recovery | Return/DD |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 0.10 | +$860.86 | +$330.02 | +$1,191.69 | 11.92% | 1.89%/yr | 1.77 | 265 | 1.02% | 10.5778 | 11.6863 |
| 0.12 | +$961.25 | +$343.82 | +$1,286.73 | 12.87% | 2.04%/yr | 1.81 | 265 | 1.12% | 10.8722 | 11.4911 |
| **0.15 center** | +$1,075.75 | +$370.41 | +$1,419.25 | 14.19% | 2.24%/yr | 1.85 | 267 | 1.3% | 10.3136 | 10.9154 |
| 0.18 | +$1,150.40 | +$388.14 | +$1,516.24 | 15.16% | 2.38%/yr | 1.88 | 267 | 1.47% | 9.6656 | 10.3129 |
| 0.20 | +$1,155.36 | +$388.14 | +$1,530.07 | 15.3% | 2.4%/yr | 1.88 | 267 | 1.59% | 9.0158 | 9.6226 |

## Frozen Gate

- Every report profitable: `True` (PASS)
- Center changed behavior: `True` (PASS)
- Center no worse in both disjoint eras: `True` (PASS)
- Center continuous growth: `True` (PASS)
- Center CAGR improvement: `True` (PASS)
- Center PF/recovery/return-DD retention: `False` (FAIL)
- Center drawdown: `False` (FAIL)
- Center trade count: `True` (PASS)
- 0.12 lower neighbor: `True` (PASS)
- 0.18 upper neighbor: `False` (FAIL)
- 0.20 upper stress: `False` (FAIL)

## Boundary

The lot cap is not a new risk percentage. It only determines whether an already-approved 0.45% reversion risk request can reach its broker-calculated lot size. Initial-stop valuation, the 0.75% portfolio exposure cap, post-fill reconciliation, period loss limits, and the 5% equity guard remain authoritative.

The sealed family did not establish a robust risk-adjusted improvement. Recent data and Model 4 remain unopened, and no different cap may be selected from these results.

ATB150 remains the historical champion unless and until all later gates pass. The registered forward candidate, invalid-account boundary, evidence logs, and real-account lock remain unchanged.
