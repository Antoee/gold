# Residual-Risk V2 Reversion-Focus Decision

**Decision: REJECT BEFORE MODEL 4. NO NEW BEST.**

This screen allocated residual risk only to already-eligible reversion entries. Momentum and adaptive trend stayed at the frozen ATB150 base risk, entry and exit signals were unchanged, and the account-wide protected-risk cap remained `0.75%`.

- Source SHA-256: `D468B984972E84FE2F0E368035EB74841D8B1856AEA56A893FB819DFE4C482E4`
- Exact shared portable EX5 SHA-256: `C19BD6F70AF367F0A486B4EE8A7732307D9F5AD972D0DCC48D41B317EF37ECBD`
- Model: `1`, `$10,000`, three disjoint eras plus continuous 2015-2026
- Evidence: `20 / 20` reports parsed; the initial four-worker pass exported 14 reports and six startup-race rows were rerun successfully on one prepared worker
- Identity: one shared EX5 hash, zero worker recompiles, no additional trades versus the 415-trade exact Model 1 control
- Gate: every era positive, continuous CAGR at least `0.25` points above control, PF at least `1.75`, DD at most `1.50%`, no loss of recovery or return/drawdown, and at least three adjacent supporting ceilings

| Profile | Net | Increase | CAGR | PF | Trades | Max DD | Recovery | Return/DD | Decision |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| Disabled control | +$2,195.53 | +21.96% | +1.74%/yr | 1.83 | 415 | 1.17% | 15.82 | 18.77 | Control |
| Reversion ceiling 0.50% | +$2,264.12 | +22.64% | +1.79%/yr | 1.85 | 415 | 1.22% | 15.68 | 18.56 | Reject |
| Reversion ceiling 0.55% | +$2,387.36 | +23.87% | +1.87%/yr | 1.89 | 415 | 1.55% | 12.47 | 15.40 | Reject |
| Reversion ceiling 0.60% | +$2,398.23 | +23.98% | +1.88%/yr | 1.90 | 415 | 1.54% | 12.53 | 15.57 | Reject |
| Reversion ceiling 0.65% | +$2,458.12 | +24.58% | +1.93%/yr | 1.92 | 415 | 1.54% | 12.84 | 15.96 | Reject |

Every disjoint era remained profitable and PF improved monotonically, so the lane attribution was directionally useful. The strongest row added `$262.59` and `0.19` CAGR points, but the frozen hurdle required `0.25` points without weakening risk efficiency. It also exceeded the `1.50%` drawdown ceiling and retained only `81.19%` of control recovery and `85.04%` of control return/drawdown. The conservative `0.50%` row stayed below the drawdown ceiling, but added only `0.05` CAGR points and was also slightly worse on both efficiency measures.

No setting passed the complete gate, so Model 4 escalation is closed. ATB150 and the frozen forward registration remain unchanged. These are historical research results, not forward evidence or real-money approval.
