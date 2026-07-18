# Momentum Breakout Quality Discovery Decision

**Decision: REJECTED IN DISCOVERY. The frozen forward candidate and real-account lock are unchanged.**

- Exact source: `7BCFE5C270F0B9B62121164877A88F0D6212C6B7090438400DBA9391D99C6F3A`
- Reports parsed: `21 / 21`; identity retries: `2`
- Discovery-eligible profiles: `0`

| Profile | Older net | 2019-20 net | Continuous net | Return | PF | Trades | DD | Return/DD | Basic | Quality | Neighbor | Decision |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|---|---|---|
| `mbq_center_vol090` | +$628.38 | -$121.62 | +$497.79 | 4.98% | 1.43 | 146 | 2.49% | 2 | False | False | False | REJECT_BEFORE_HOLDOUT |
| `mbq_center_vol100` | +$629.48 | -$228.38 | +$381.32 | 3.81% | 1.35 | 133 | 2.81% | 1.3559 | False | False | False | REJECT_BEFORE_HOLDOUT |
| `mbq_center_vol110` | +$433.69 | -$227.69 | +$194.14 | 1.94% | 1.19 | 117 | 2.67% | 0.7266 | False | False | False | REJECT_BEFORE_HOLDOUT |
| `mbq_fixed_control` | +$814.70 | -$105.45 | +$694.13 | 6.94% | 1.42 | 225 | 2.77% | 2.5054 | False | False | False | CONTROL_ONLY |
| `mbq_price_center` | +$844.36 | -$191.13 | +$632.12 | 6.32% | 1.46 | 181 | 2.99% | 2.1137 | False | False | False | REJECT_BEFORE_HOLDOUT |
| `mbq_price_loose` | +$862.82 | -$131.99 | +$707.26 | 7.07% | 1.47 | 203 | 2.72% | 2.5993 | False | True | False | REJECT_BEFORE_HOLDOUT |
| `mbq_price_strict` | +$694.95 | -$176.43 | +$504.54 | 5.05% | 1.4 | 163 | 2.71% | 1.8635 | False | False | False | REJECT_BEFORE_HOLDOUT |

## Interpretation

- Highest non-control continuous net: `mbq_price_loose` at +$707.26, PF `1.47`, versus control +$694.13, PF `1.42`.
- No filter repaired 2019-2020. The least-negative candidate was `mbq_center_vol090` at -$121.62, versus control -$105.45.
- Tick-volume confirmation reduced activity and did not improve the weak era. Recent data therefore remains unopened.

The family is closed before post-2020 holdout and Model4. No threshold may be changed after seeing this decision.

This discovery result is not forward evidence and is not a real-money approval.
