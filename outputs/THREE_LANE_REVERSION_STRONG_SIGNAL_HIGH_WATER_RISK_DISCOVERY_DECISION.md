# Three-Lane Strong-Signal High-Water Risk Discovery Decision

**Decision: REJECTED IN DISCOVERY. No holdout, Model 4, promotion, forward change, or live approval is permitted.**

- Reports: `15 / 15` parsed with exact source, EX5, config, and report identity
- Attempts: `16`; source-identity refusals: `1` (preserved and excluded)
- Exact source SHA-256: `38CA497BB6E0E013927B2FAC2C4D4350AFC476C8EAC837FACE6C6D0991B5D232`
- Exact EX5 SHA-256: `A8774A7477E9C65F4A7263A930F97CE4AB1A62DB5BA53FC82835E28DEAA199FA`
- Starting balance: `$10,000`; discovery data: `2015-01-01` through `2020-12-31`; model: MT5 Model 1
- Real-account trading: disabled

| Profile | 2015-18 | 2019-20 | Continuous | Return | CAGR | PF | Trades | DD | Recovery | Return/DD |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Champion control | +$860.86 | +$330.02 | +$1,191.69 | 11.92% | 1.89%/yr | 1.77 | 265 | 1.02% | 10.5778 | 11.6863 |
| Unconditional strong risk | +$860.86 | +$330.02 | +$1,191.69 | 11.92% | 1.89%/yr | 1.77 | 265 | 1.02% | 10.5778 | 11.6863 |
| Throttle 0.15% | +$860.86 | +$330.02 | +$1,191.69 | 11.92% | 1.89%/yr | 1.77 | 265 | 1.02% | 10.5778 | 11.6863 |
| Center throttle 0.30% | +$860.86 | +$330.02 | +$1,191.69 | 11.92% | 1.89%/yr | 1.77 | 265 | 1.02% | 10.5778 | 11.6863 |
| Throttle 0.45% | +$860.86 | +$330.02 | +$1,191.69 | 11.92% | 1.89%/yr | 1.77 | 265 | 1.02% | 10.5778 | 11.6863 |

## Frozen Gate

- Every report profitable: `True` (PASS)
- Unconditional strong-risk reference active: `False` (FAIL)
- Center changed behavior: `False` (FAIL)
- Center no worse in both disjoint eras: `True` (PASS)
- Center continuous growth: `False` (FAIL)
- Center CAGR improvement: `False` (FAIL)
- Center PF/recovery/return-DD: `True` (PASS)
- Center drawdown: `True` (PASS)
- Center trade count: `True` (PASS)
- Retains 60% of unconditional incremental net: `False` (FAIL)
- Improves DD/recovery/return-DD versus unconditional: `False` (FAIL)
- 0.15% neighbor: `False` (FAIL)
- 0.45% neighbor: `False` (FAIL)

## Interpretation

All five profiles produced exactly `+$1,191.69` continuous net, `1.89%` CAGR, PF `1.77`, `265` trades, `1.02%` drawdown, recovery `10.5778`, and return/drawdown `11.6863`. The unconditional higher-risk reference itself was inactive, so none of the throttle thresholds could demonstrate an executable effect.

The profile inputs and report hashes differ, but the complete trading metrics do not. In these sealed pre-2021 windows the requested 0.70% strong allocation did not change the executable portfolio, consistent with the existing lot cap/step boundary. An inactive mechanism cannot establish growth or neighbor support, so 2021-2026 and Model 4 remain unopened and no threshold rescue is permitted.

ATB150 remains the historical champion. The registered forward candidate, invalid-account boundary, evidence logs, and real-account lock remain unchanged.
