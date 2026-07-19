# Residual-Risk V2 Model4 Characterization Decision

**Decision: CHARACTERIZATION FAILED THE FROZEN RISK-EFFICIENCY GATE. BROAD MODEL 4 ERAS REMAIN CLOSED. NO NEW BEST.**

The previously rejected V2 center and its immediate `0.170`/`0.180` momentum-ceiling neighbors were characterized on continuous Model 4 real ticks. This did not relax or reverse the prior neighborhood decision. Every expanded entry first had to be tradable at original ATB150 base risk, so no minimum-lot-only signal could enter.

- Source SHA-256: `D468B984972E84FE2F0E368035EB74841D8B1856AEA56A893FB819DFE4C482E4`
- Exact shared portable EX5 SHA-256: `C19BD6F70AF367F0A486B4EE8A7732307D9F5AD972D0DCC48D41B317EF37ECBD`
- Compile: `0 errors, 0 warnings`; one compile distributed byte-identically to four workers
- Controlled evidence: `4 / 4` reports, four parallel workers, zero report errors, launch locks restored
- Model: `4` real ticks, `$10,000`, 2015-01-01 through 2026-07-12
- Gate: center CAGR at least `0.25` points above control, PF at least `1.60`, DD at most `2.25%`, recovery and return/drawdown each at least `95%` of control, and no adjacent collapse

| Profile | Net | Increase | CAGR | PF | Trades | Max DD | Recovery | Return/DD | Decision |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| Disabled control | +$2,105.08 | +21.05% | +1.67%/yr | 1.81 | 404 | 1.15% | 15.67 | 18.30 | Control |
| Momentum ceiling 0.170% | +$2,497.64 | +24.98% | +1.95%/yr | 1.77 | 404 | 1.68% | 13.38 | 14.87 | Reject |
| Center 0.175% | +$2,531.00 | +25.31% | +1.98%/yr | 1.77 | 404 | 1.71% | 13.24 | 14.80 | Reject |
| Momentum ceiling 0.180% | +$2,488.79 | +24.89% | +1.95%/yr | 1.73 | 404 | 1.79% | 12.47 | 13.91 | Reject |

The center gained `$425.92` and `0.31` CAGR points with exactly the same 404 trades, confirming that V2 fixed V1's minimum-lot trade-universe expansion. It still retained only `84.51%` of control recovery and `80.86%` of control return/drawdown, well below the frozen `95%` requirements. Both adjacent settings showed the same risk-efficiency deterioration.

Paired trade-ledger attribution explains the result. Reversion remained nearly unchanged at about `+$1,370` and PF near `3.9`; expanded momentum added about `$341` and expanded adaptive trend about `$81`, but those lanes carried much lower PF and produced the larger drawdown path. This supports testing residual allocation only on already-eligible reversion entries, not reopening this trend-lane pair.

ATB150 and the frozen forward registration remain unchanged. This is historical characterization, not forward evidence or real-money approval.
