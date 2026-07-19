# Independent M15 Dual-Regime Normalized-Stop Model 1 Decision

**Decision: REJECTED IN MODEL 1. No Model 4 run, portfolio integration, promotion, forward change, or live approval is permitted.**

- Reports: `25 / 25` parsed and exact source/binary identity valid; identity retries: `3`
- Source SHA-256: `E6AB84CA7780A47FDE04A01CB74966204220B91B2DA97B65F1095066A10D2F50`
- EX5 SHA-256: `7DB6E68B540055739E9D4F6F6A74B37358DE1F9B286E22684009ADCDFDC5D7D4`
- Real-account trading: disabled
- Evidence class: historical structural repair; 2024-2026 is not untouched holdout data

| Profile | 2015-18 | 2019-20 | 2021-23 | 2024-26 | Continuous | CAGR | PF | Trades | DD | Recovery | Gate |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| Fixed $6 control | +$187.20 | +$59.59 | +$181.94 | -$66.41 | +$364.60 | 0.31%/yr | 1.22 | 351 | 1.07% | 3.2565 | False |
| Price cap 0.25% | +$190.09 | +$74.62 | +$103.87 | -$18.42 | +$350.15 | 0.3%/yr | 1.21 | 352 | 1.09% | 3.0968 | False |
| Price cap 0.30% center | +$187.20 | +$65.02 | +$187.84 | -$7.93 | +$430.93 | 0.37%/yr | 1.25 | 366 | 1.01% | 4.0704 | False |
| Price cap 0.35% | +$187.20 | +$59.59 | +$181.94 | -$7.93 | +$423.08 | 0.36%/yr | 1.25 | 368 | 1.04% | 4.0787 | False |
| ATR-only diagnostic | +$187.20 | +$59.59 | +$181.94 | -$7.93 | +$423.08 | 0.36%/yr | 1.25 | 368 | 1.04% | 4.0787 | False |

## Frozen Gate

| Requirement | Result | Status |
|---|---|---|
| Center positive in all four eras | `False` | FAIL |
| Recent net > 0 | -$7.93 | FAIL |
| Recent PF >= 1.05 | `0.98` | FAIL |
| Continuous net >= control +25% | +$430.93 vs required +$455.75 | FAIL |
| Continuous PF >= 1.25 | `1.25` | PASS |
| Trades >= 300 | `366` | PASS |
| DD <= 2.00% | `1.01%` | PASS |
| At least one adjacent percentage profile passes | lower=False; upper=False | FAIL |

## Interpretation

The structural rewrite worked mechanically. The 0.30% center increased recent trades from 54 to 71, improved recent PF from `0.76` to `0.98`, reduced the recent loss from `-$66.41` to `-$7.93`, raised continuous net from `+$364.60` to `+$430.93`, and reduced continuous drawdown from `1.07%` to `1.01%.`

It did not restore a positive recent edge. The center, upper neighbor, and ATR-only diagnostic all remained negative in 2024-2026, while the lower neighbor was worse. The center also missed the frozen +25% continuous-net hurdle. The fixed price ceiling was a real geometry weakness, but not the root cause of the signal-family decay.

This family is rejected without Model 4 or portfolio integration. ATB150 remains the historical champion, and the registered forward candidate, invalid-account boundary, and real-account lock remain unchanged.
