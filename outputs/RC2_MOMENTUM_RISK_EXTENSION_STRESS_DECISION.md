# RC2 Momentum-Risk Extension Stress Decision

**Decision: STRESS GATE FAILED. This does not change the frozen forward candidate or approve real money.**

- Exact trades: `362`
- Ledger SHA-256: `80E2E741EA508DCC2D048661FF266A72F6708812F4F75EBB96DCB1136247CE59`
- Cost gate: `True`; Monte Carlo gate: `False`

## Deterministic Added Cost

| Scenario | Added R/trade | Extra cost | Net | CAGR | PF | Closed DD | Older | Middle | Recent | Gate |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| base | 0.00R | $0.00 | +$1,812.42 | 1.454%/yr | 1.500 | 2.840% | +$925.26 | +$237.45 | +$649.71 | True |
| light | 0.02R | $149.51 | +$1,662.91 | 1.342%/yr | 1.449 | 3.006% | +$865.21 | +$183.38 | +$614.33 | True |
| moderate | 0.05R | $373.77 | +$1,438.65 | 1.172%/yr | 1.375 | 3.258% | +$775.13 | +$102.27 | +$561.25 | True |
| severe | 0.10R | $747.54 | +$1,064.88 | 0.881%/yr | 1.263 | 3.807% | +$625.00 | -$32.92 | +$472.80 | True |

## Bootstrap Monte Carlo

| Scenario | Trials | P05 net | Median net | Median PF | P95 closed DD | P95 loss run | Red trials | Gate |
|---|---:|---:|---:|---:|---:|---:|---:|---|
| standard | 10000 | +$158.22 | +$1,132.10 | 1.293 | 6.383% | 15 | 2.770% | False |
| severe | 10000 | -$539.32 | +$435.84 | 1.105 | 9.629% | 16 | 23.330% | False |

Closed-trade drawdown does not include intratrade equity movement. Bootstrap stress measures sensitivity to sampled historical outcomes and execution degradation; it cannot prove future profitability.
