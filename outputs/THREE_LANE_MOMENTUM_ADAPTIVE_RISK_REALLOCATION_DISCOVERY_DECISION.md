# Momentum-Adaptive Risk Reallocation Discovery Decision

**Decision: REJECTED IN DISCOVERY. Newer data, Model 4, promotion, forward change, and real trading remain closed.**

- Exact accepted Model 1 reports: `15/15`; preserved first-pass identity refusals: `3`
- Source SHA-256: `B6810B305549968E2273DAAF736A63759FE5C16F3B416F5C69E39840FBE5173E`
- EX5 SHA-256: `0BF7AEEE1D5F9496A6C7A88012D7059A8D894B2475097C158254670E1A189883`
- Manifest SHA-256: `1A22157C6C27F4DF07B7FF82B4AC8100A5D785DC212169EBD9A8E3137D1CC938`
- `$10,000`; 2015-2020 discovery; reversion risk `0.45%`; total declared lane risk and portfolio cap fixed at `0.75%`

| Allocation (MO / ATB) | 2015-18 | 2019-20 | Continuous | CAGR | PF | Trades | DD | Recovery | Return/DD | Gate |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| Control 0.15 / 0.15 | +$1,036.19 | +$370.60 | +$1,379.93 | 2.18%/yr | 1.88 | 261 | 1.05% | 11.6775 | 13.1429 | CONTROL |
| 0.16 / 0.14 | +$978.02 | +$331.93 | +$1,348.66 | 2.13%/yr | 1.82 | 256 | 1.15% | 11.112 | 11.7304 | False |
| 0.175 / 0.125 | +$1,043.51 | +$322.55 | +$1,314.27 | 2.08%/yr | 1.75 | 246 | 1.26% | 9.2613 | 10.4286 | False |
| 0.19 / 0.11 | +$1,074.79 | +$270.30 | +$1,435.37 | 2.26%/yr | 1.78 | 239 | 1.39% | 9.2557 | 10.3237 | False |
| **Center 0.20 / 0.10** | +$1,123.10 | +$313.36 | +$1,519.85 | 2.39%/yr | 1.8 | 228 | 1.4% | 9.6849 | 10.8571 | False |

## Frozen Gate

- Every disjoint-era row profitable: `True`
- Center no worse than control in both eras: `False`
- Center continuous net at least 5% above control: `True`
- Center CAGR at least 0.08 point above control: `True`
- Center retains 97% of PF, recovery, and return/DD: `False`
- Center drawdown no more than 1.25%: `False`
- Center retains at least 98% of trades: `False`
- Lower rungs passing: `0/3`; required: `2/3`

## Interpretation

The center increased continuous net by `+$139.92`, but 2019-2020 profit fell from `+$370.60` to `+$313.36`. Drawdown rose from `1.05%` to `1.4%`, PF fell from `1.88` to `1.8`, and trades fell from `261` to `228`.

No lower rung passed the full frozen gate. The best headline row was `marr_center_020_010` at `+$1,519.85`, but selecting it would exchange broad-era stability, activity, and drawdown efficiency for a higher in-sample net result.

The published same-side exit-cooldown leader and registered forward candidate remain unchanged. The invalid `$100,000` demo is not forward evidence, and real-account trading remains disabled.
